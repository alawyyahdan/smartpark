const path = require('path')
require('dotenv').config({ path: path.resolve(__dirname, '../.env') })
const mqtt = require('mqtt')
const { createClient } = require('@supabase/supabase-js')

// ===== CONSTANTS =====
const MAX_LOGS = 200
const POLL_INTERVAL_MS = 5000
const STATUS_REPORT_INTERVAL_MS = 60000
const LOG_CLEANUP_INTERVAL_MS = 300000 // 5 menit
const RECONNECT_PERIOD_MS = 5000
const CONNECT_TIMEOUT_MS = 10000
const MESSAGE_BATCH_SIZE = 5

const SUPABASE_URL = process.env.VITE_SUPABASE_URL
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_KEY

if (!SUPABASE_URL || !SUPABASE_KEY) {
  console.error('❌ Set VITE_SUPABASE_URL dan SUPABASE_SERVICE_KEY di .env root project')
  process.exit(1)
}

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY)
let mqttClient = null
let topics = []
let messageCount = 0
let enabled = false
let currentBroker = null
let currentUsername = null
let currentPassword = null

// ===== LOG (console + DB) =====
async function log(type, msg) {
  const time = new Date().toLocaleString('id-ID')
  const prefix = { info: 'ℹ️', success: '✅', error: '❌', mqtt: '📡', db: '💾' }
  console.log(`[${time}] ${prefix[type] || '•'} ${msg}`)
  
  try {
    await supabase.from('mqtt_logs').insert([{ type, message: msg }])
  } catch (e) {
    console.error('Log DB error:', e.message)
  }
}

// Periodic log cleanup (setiap 5 menit, bukan setiap message)
async function cleanupOldLogs() {
  try {
    const { count } = await supabase.from('mqtt_logs').select('*', { count: 'exact', head: true })
    if (count > MAX_LOGS) {
      const { data: old } = await supabase.from('mqtt_logs').select('id').order('id', { ascending: true }).limit(count - MAX_LOGS)
      if (old && old.length > 0) {
        await supabase.from('mqtt_logs').delete().lte('id', old[old.length - 1].id)
      }
    }
  } catch (e) {
    console.error('Log cleanup error:', e.message)
  }
}

// ===== FETCH SETTINGS =====
async function fetchSettings() {
  const { data } = await supabase
    .from('settings')
    .select('key, value')
    .in('key', ['mqtt_broker', 'mqtt_username', 'mqtt_password', 'mqtt_enabled'])
  const s = {}
  if (data) data.forEach(r => { s[r.key] = r.value })
  return s
}

async function fetchTopics() {
  const { data } = await supabase.from('parking_areas').select('mqtt_prefix')
  if (!data) return []
  return data.filter(a => a.mqtt_prefix).map(a => a.mqtt_prefix.endsWith('/') ? `${a.mqtt_prefix}#` : `${a.mqtt_prefix}/#`)
}

async function updateStatus(status) {
  const updates = [{ key: 'mqtt_status', value: status, updated_at: new Date().toISOString() }]
  if (status === 'online') updates.push({ key: 'mqtt_connected_at', value: new Date().toISOString(), updated_at: new Date().toISOString() })
  await supabase.from('settings').upsert(updates, { onConflict: 'key' })
}

async function updateMessages() {
  try {
    await supabase.from('settings').upsert([{ key: 'mqtt_messages', value: String(messageCount), updated_at: new Date().toISOString() }], { onConflict: 'key' })
  } catch (e) {
    console.error('Update messages error:', e.message)
  }
}

// ===== HANDLE MESSAGE =====
async function handleMessage(topic, message) {
  try {
    const payload = JSON.parse(message.toString())
    const status = payload.status
    if (!status || !['diambil', 'tersedia'].includes(status)) return

    messageCount++
    await log('mqtt', `${topic} → ${status}`)

    const { data } = await supabase
      .from('parking_slots')
      .update({ status, updated_at: new Date().toISOString() })
      .eq('mqtt_topic', topic)
      .select('name')

    if (data && data.length > 0) await log('db', `Slot ${data[0].name} → ${status}`)
    if (messageCount % MESSAGE_BATCH_SIZE === 0) updateMessages()
  } catch (err) {
    await log('error', `Parse: ${err.message}`)
  }
}

// ===== CONNECT =====
async function connect() {
  const settings = await fetchSettings()
  
  if (!settings.mqtt_broker) {
    await log('error', 'Broker URL belum di-set di admin')
    return
  }

  topics = await fetchTopics()
  currentBroker = settings.mqtt_broker
  currentUsername = settings.mqtt_username
  currentPassword = settings.mqtt_password
  await log('info', `Connecting to ${settings.mqtt_broker}...`)
  await log('info', `Topics: ${topics.length > 0 ? topics.join(', ') : '(none)'}`)

  const keepalive = parseInt(process.env.MQTT_KEEPALIVE || '30')

  mqttClient = mqtt.connect(settings.mqtt_broker, {
    username: settings.mqtt_username || undefined,
    password: settings.mqtt_password || undefined,
    reconnectPeriod: RECONNECT_PERIOD_MS,
    connectTimeout: CONNECT_TIMEOUT_MS,
    keepalive
  })

  mqttClient.on('connect', async () => {
    await log('success', `Connected to ${settings.mqtt_broker}`)
    await updateStatus('online')
    topics.forEach(t => {
      mqttClient.subscribe(t, async (err) => {
        if (!err) await log('info', `Subscribed: ${t}`)
        else await log('error', `Subscribe failed: ${t}`)
      })
    })
  })

  mqttClient.on('message', handleMessage)
  
  mqttClient.on('error', async (err) => {
    await log('error', `MQTT Error: ${err.message}`)
  })
  
  mqttClient.on('close', async () => {
    await updateStatus('offline')
    await log('info', 'Disconnected from broker')
  })
  
  mqttClient.on('reconnect', async () => {
    await log('info', 'Reconnecting to broker...')
  })
  
  mqttClient.on('offline', async () => {
    await log('info', 'MQTT client offline')
  })
}

function disconnect() {
  return new Promise((resolve) => {
    if (!mqttClient) { resolve(); return }
    const client = mqttClient
    mqttClient = null
    client.end(true, {}, () => resolve())
  })
}

// ===== POLL SETTINGS & RECONNECT =====
async function pollSettingsAndReconnect() {
  const settings = await fetchSettings()
  const shouldBeEnabled = settings.mqtt_enabled === 'true'

  if (shouldBeEnabled && !enabled) {
    enabled = true
    await log('success', 'Bridge ENABLED (dinyalakan dari admin)')
    await connect()
  } else if (!shouldBeEnabled && enabled) {
    enabled = false
    await disconnect()
    await updateStatus('offline')
    await log('info', 'Bridge DISABLED (dimatikan dari admin)')
  }

  // Cek broker berubah
  if (enabled && mqttClient) {
    if (settings.mqtt_broker !== currentBroker || settings.mqtt_username !== currentUsername || settings.mqtt_password !== currentPassword) {
      await log('info', 'MQTT settings changed, reconnecting...')
      await disconnect()
      await connect()
      return
    }

    // Refresh topics tiap cycle
    const newTopics = await fetchTopics()
    const added = newTopics.filter(t => !topics.includes(t))
    if (added.length > 0 && mqttClient.connected) {
      added.forEach(t => mqttClient.subscribe(t))
      topics = newTopics
      await log('info', `New topics subscribed: ${added.join(', ')}`)
    }
  }
}

// ===== MAIN LOOP =====
async function mainLoop() {
  await log('info', '=== MQTT Bridge Started ===')

  // Check enabled/disabled tiap 5 detik
  setInterval(pollSettingsAndReconnect, POLL_INTERVAL_MS)

  // Status report tiap 60 detik
  setInterval(() => { if (enabled) updateMessages() }, STATUS_REPORT_INTERVAL_MS)

  // Log cleanup tiap 5 menit
  setInterval(cleanupOldLogs, LOG_CLEANUP_INTERVAL_MS)

  // Initial check
  const settings = await fetchSettings()
  if (settings.mqtt_enabled === 'true') {
    enabled = true
    await connect()
  } else {
    await log('info', 'Bridge disabled. Enable from Admin Panel.')
  }
}

async function gracefulShutdown(signal) {
  await log('info', `Bridge shutting down (${signal})`)
  await disconnect()
  await updateStatus('offline')
  process.exit(0)
}

process.on('SIGINT', () => gracefulShutdown('SIGINT'))
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'))

mainLoop()
