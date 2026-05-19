<template>
  <div class="kiosk">

    <!-- WELCOME SCREEN -->
    <div v-if="!showQR" class="welcome-screen">

      <!-- Top bar -->
      <header class="kiosk-header">
        <div class="kiosk-logo">
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
            <rect x="3" y="11" width="18" height="11" rx="2"/>
            <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
          </svg>
          {{ appName }}
        </div>
        <div class="kiosk-clock">{{ clock }}</div>
        <div class="kiosk-date">{{ dateStr }}</div>
      </header>

      <!-- Main Content - 2 Columns -->
      <main class="kiosk-main">
        
        <!-- LEFT COLUMN - Camera -->
        <div class="left-column">
          <div class="camera-section">
            <CameraCapture ref="cameraRef" />
          </div>
        </div>

        <!-- RIGHT COLUMN - Info & Controls -->
        <div class="right-column">
          <div class="greeting-section">
            <p class="greeting-sub">{{ greetingIcon }} {{ greeting }}</p>
            <h1 class="greeting-title">Selamat Datang</h1>
            <p class="greeting-desc">Posisikan kendaraan di depan kamera, lalu tekan tombol untuk mendapatkan tiket parkir</p>
          </div>

          <!-- Stats -->
          <div class="stats-row">
            <div class="stat-card">
              <span class="stat-num">{{ slots.total }}</span>
              <span class="stat-label">Total Slot</span>
            </div>
            <div class="stat-card stat-green">
              <span class="stat-num">{{ slots.available }}</span>
              <span class="stat-label">Tersedia</span>
            </div>
            <div class="stat-card stat-red">
              <span class="stat-num">{{ slots.occupied }}</span>
              <span class="stat-label">Terisi</span>
            </div>
          </div>

          <!-- Slot availability bar -->
          <div class="slot-bar-wrap">
            <div class="slot-bar">
              <div class="slot-bar-fill" :style="{ width: occupiedPct + '%' }"></div>
            </div>
            <span class="slot-bar-label">{{ occupiedPct }}% kapasitas terisi</span>
          </div>

          <!-- CTA Button -->
          <button class="btn-cetak" @click="generateTicket" :disabled="loading || slots.available === 0" id="btn-cetak-tiket">
            <svg v-if="!loading" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
              <path d="M2 9a3 3 0 0 1 0 6v2a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-2a3 3 0 0 1 0-6V7a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2Z"/>
            </svg>
            <span v-if="loading" class="btn-spinner"></span>
            {{ loading ? 'Membuat tiket...' : slots.available === 0 ? 'Parkir Penuh' : 'Ambil Tiket' }}
          </button>

          <p v-if="error" class="error-msg">⚠️ {{ error }}</p>
        </div>

      </main>

      <!-- Footer -->
      <footer class="kiosk-footer">
        <span>{{ appName }} v1.0</span>
      </footer>
    </div>

    <!-- QR SCREEN -->
    <div v-else class="qr-screen" @click="resetScreen">
      <div class="qr-card" @click.stop>
        <div class="qr-header">
          <div class="qr-badge">✅ Tiket Berhasil</div>
          <p class="qr-code-text">{{ ticket.ticket_code }}</p>
        </div>

        <div class="qr-box">
          <img v-if="qrUrl" :src="qrUrl" alt="QR Code" class="qr-img" />
          <div v-else class="qr-loading">
            <span class="btn-spinner" style="width:40px;height:40px;border-width:4px;border-color:rgba(99,102,241,.2);border-top-color:#6366f1;"></span>
          </div>
        </div>

        <p class="qr-instruction">Scan QR code ini dengan kamera HP Anda</p>
        <p class="qr-instruction" style="font-size:13px;opacity:.5;">Lalu ikuti panduan menuju slot parkir</p>

        <!-- Debug URL (only show if debug mode enabled) -->
        <div class="debug-url" v-if="isDebugMode">
          <span class="debug-label">🔗 Debug URL</span>
          <a :href="ticket?.qr_data" target="_blank" class="debug-link">{{ ticket?.qr_data }}</a>
        </div>

        <!-- Countdown -->
        <div class="qr-countdown">
          <div class="countdown-ring">
            <svg viewBox="0 0 36 36" class="countdown-svg">
              <circle cx="18" cy="18" r="15.9" fill="none" stroke="rgba(255,255,255,.1)" stroke-width="2.5"/>
              <circle cx="18" cy="18" r="15.9" fill="none" stroke="#6366f1" stroke-width="2.5"
                stroke-dasharray="100" :stroke-dashoffset="100 - (countdown / resetAfter * 100)"
                stroke-linecap="round" transform="rotate(-90 18 18)" />
            </svg>
            <span class="countdown-num">{{ countdown }}</span>
          </div>
          <span class="countdown-label">Layar reset otomatis</span>
        </div>

        <div class="qr-actions">
          <button class="btn-print" @click="handlePrint">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
              <polyline points="6 9 6 2 18 2 18 9"/>
              <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/>
              <rect x="6" y="14" width="12" height="8" rx="1"/>
            </svg>
            Cetak / PDF
          </button>
          <button class="btn-reset" @click="resetScreen">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
              <path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/>
            </svg>
            Selesai
          </button>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { supabase } from '../lib/supabase.js'
import { generateTicketCode, generateQRDataUrl, printThermalPDF } from '../lib/ticketGenerator.js'
import CameraCapture from '../components/CameraCapture.vue'

// Clock
const now = ref(new Date())
let clockInterval = null

// Camera ref
const cameraRef = ref(null)

// Realtime subscription
let realtimeChannel = null

// Debug mode - check from DB
const isDebugMode = ref(false)
async function checkDebugMode() {
  try {
    const { data } = await supabase
      .from('settings')
      .select('value')
      .eq('key', 'debug_mode')
      .single()
    isDebugMode.value = data?.value === 'true'
  } catch {
    isDebugMode.value = false
  }
}

const clock = computed(() => now.value.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', second: '2-digit' }))
const dateStr = computed(() => now.value.toLocaleDateString('id-ID', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }))

const greeting = computed(() => {
  const h = now.value.getHours()
  if (h >= 5 && h < 11)  return 'Selamat Pagi'
  if (h >= 11 && h < 15) return 'Selamat Siang'
  if (h >= 15 && h < 18) return 'Selamat Sore'
  return 'Selamat Malam'
})

const greetingIcon = computed(() => {
  const h = now.value.getHours()
  if (h >= 5 && h < 11)  return '🌤️'
  if (h >= 11 && h < 15) return '☀️'
  if (h >= 15 && h < 18) return '🌆'
  return '🌙'
})

// App settings from DB
const appUrl = ref(import.meta.env.VITE_APP_URL || 'http://localhost:5173')
const ticketPrefix = ref('SP')
const appName = ref('SmartPark')

// Slots
const slots = ref({ total: 0, available: 0, occupied: 0 })
const occupiedPct = computed(() => slots.value.total ? Math.round(slots.value.occupied / slots.value.total * 100) : 0)

// Ticket / QR state
const showQR = ref(false)
const ticket = ref(null)
const qrUrl = ref(null)
const loading = ref(false)
const error = ref('')

// Countdown
const resetAfter = 20
const countdown = ref(resetAfter)
let countdownInterval = null

async function fetchSlots() {
  try {
    const { data, error } = await supabase.from('parking_slots').select('status')
    
    if (error) {
      console.error('Fetch slots error:', error)
      return
    }
    
    // Update stats (kalau data kosong, jadi 0 semua)
    slots.value.total = data?.length || 0
    slots.value.available = data?.filter(s => s.status === 'tersedia').length || 0
    slots.value.occupied = data?.filter(s => s.status === 'diambil').length || 0
  } catch (err) {
    console.error('Fetch slots error:', err)
  }
}

async function generateTicket() {
  error.value = ''
  loading.value = true
  
  try {
    // 1. Capture vehicle image
    let vehicleImageUrl = null
    if (cameraRef.value) {
      const captured = await cameraRef.value.captureImage()
      if (captured && captured.blob) {
        // Upload to Supabase Storage
        const fileName = `${Date.now()}-${Math.random().toString(36).substring(7)}.jpg`
        console.log('[Ticket] Uploading vehicle image:', fileName, 'size:', captured.blob.size)
        const { data: uploadData, error: uploadError } = await supabase.storage
          .from('vehicle-images')
          .upload(fileName, captured.blob, {
            contentType: 'image/jpeg',
            cacheControl: '3600'
          })

        if (uploadError) {
          console.error('[Ticket] Upload error:', uploadError.message, uploadError)
        } else {
          // Get public URL
          const { data: urlData } = supabase.storage
            .from('vehicle-images')
            .getPublicUrl(fileName)
          vehicleImageUrl = urlData.publicUrl
          console.log('[Ticket] Vehicle image URL:', vehicleImageUrl)
        }
      } else {
        console.warn('[Ticket] Camera capture returned empty:', captured)
      }
    } else {
      console.warn('[Ticket] No camera ref available')
    }

    // 2. Get today's count for sequence
    const today = new Date(); today.setHours(0,0,0,0)
    const { count } = await supabase.from('tickets').select('*', { count: 'exact', head: true }).gte('created_at', today.toISOString())
    const seq = (count || 0) + 1
    const ticketCode = generateTicketCode(seq, ticketPrefix.value)

    // 3. Create ticket record
    const { data, error: err } = await supabase
      .from('tickets')
      .insert([{ 
        ticket_code: ticketCode, 
        qr_data: '', 
        status: 'active',
        vehicle_image: vehicleImageUrl 
      }])
      .select().single()
    if (err) throw err

    // 4. Update with QR data
    const qrData = `${appUrl.value}/visitor?t=${data.id}`
    await supabase.from('tickets').update({ qr_data: qrData }).eq('id', data.id)
    data.qr_data = qrData
    ticket.value = data

    // 5. Show QR screen
    showQR.value = true
    checkDebugMode()
    qrUrl.value = await generateQRDataUrl(data.id, appUrl.value)
    
    // 6. Setup realtime listener for visitor access
    setupRealtimeListener(data.id)
    
    startCountdown()
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

function startCountdown() {
  countdown.value = resetAfter
  countdownInterval = setInterval(() => {
    countdown.value--
    if (countdown.value <= 0) resetScreen()
  }, 1000)
}

function setupRealtimeListener(ticketId) {
  // Subscribe to ticket_accessed event
  realtimeChannel = supabase.channel(`ticket-${ticketId}`)
    .on('broadcast', { event: 'ticket_accessed' }, (payload) => {
      console.log('Ticket accessed by visitor:', payload)
      // Auto close QR screen
      resetScreen()
    })
    .subscribe()
}

function resetScreen() {
  clearInterval(countdownInterval)
  
  // Unsubscribe from realtime
  if (realtimeChannel) {
    supabase.removeChannel(realtimeChannel)
    realtimeChannel = null
  }
  
  showQR.value = false
  ticket.value = null
  qrUrl.value = null
  countdown.value = resetAfter
  fetchSlots()
}

async function handlePrint() {
  if (ticket.value) await printThermalPDF(ticket.value, appUrl.value, appName.value)
}

async function fetchAppSettings() {
  const { data } = await supabase
    .from('settings')
    .select('key, value')
    .in('key', ['app_url', 'ticket_prefix', 'app_name', 'app_favicon'])
  
  if (data) {
    data.forEach(s => {
      if (s.key === 'app_url' && s.value) appUrl.value = s.value
      if (s.key === 'ticket_prefix' && s.value) ticketPrefix.value = s.value
      if (s.key === 'app_name' && s.value) {
        appName.value = s.value
        document.title = s.value + ' — Gate Operator'
      }
      if (s.key === 'app_favicon' && s.value) {
        let link = document.querySelector("link[rel~='icon']")
        if (!link) { link = document.createElement('link'); link.rel = 'icon'; document.head.appendChild(link) }
        link.href = s.value
      }
    })
  }
}

onMounted(async () => {
  clockInterval = setInterval(() => { now.value = new Date() }, 1000)
  checkDebugMode()
  await fetchAppSettings()
  fetchSlots()
  slotPollInterval = setInterval(fetchSlots, 10000)
})

let slotPollInterval = null

onUnmounted(() => {
  clearInterval(clockInterval)
  clearInterval(countdownInterval)
  if (slotPollInterval) clearInterval(slotPollInterval)
  
  // Cleanup realtime
  if (realtimeChannel) {
    supabase.removeChannel(realtimeChannel)
  }
  
  // Stop camera
  if (cameraRef.value) {
    cameraRef.value.stopCamera()
  }
})
</script>

<style scoped>
/* ============================================
   KIOSK GATE DISPLAY
   ============================================ */
.kiosk {
  height: 100vh;
  background: radial-gradient(ellipse at top, #1a1f3a 0%, #0a0f1e 60%);
  font-family: var(--font);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  position: relative;
}

/* Decorative bg dots */
.kiosk::before {
  content: '';
  position: fixed;
  inset: 0;
  background-image: radial-gradient(circle, rgba(99,102,241,.08) 1px, transparent 1px);
  background-size: 40px 40px;
  pointer-events: none;
}

/* ---- WELCOME SCREEN ---- */
.welcome-screen {
  height: 100vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.kiosk-header {
  display: flex;
  align-items: center;
  padding: 16px 32px;
  border-bottom: 1px solid rgba(255,255,255,.06);
  gap: 20px;
  flex-shrink: 0;
}

.kiosk-logo {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 18px;
  font-weight: 800;
  color: #a5b4fc;
  letter-spacing: -0.01em;
}

.kiosk-clock {
  font-size: 22px;
  font-weight: 700;
  font-family: var(--font-mono);
  color: #f1f5f9;
  margin-left: auto;
}

.kiosk-date {
  font-size: 13px;
  color: #64748b;
}

.kiosk-main {
  flex: 1;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 40px;
  padding: 32px 40px;
  overflow: hidden;
  min-height: 0;
}

/* LEFT COLUMN - Camera */
.left-column {
  display: flex;
  align-items: center;
  justify-content: center;
  padding-right: 20px;
}

.greeting-section {
  text-align: left;
}

/* RIGHT COLUMN - Info & Controls */
.right-column {
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 24px;
  padding-left: 20px;
}

.greeting-sub {
  font-size: 18px;
  color: #94a3b8;
  font-weight: 500;
  margin-bottom: 8px;
}

.greeting-title {
  font-size: clamp(40px, 5vw, 64px);
  font-weight: 900;
  letter-spacing: -0.03em;
  background: linear-gradient(135deg, #e0e7ff, #6366f1, #818cf8);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  line-height: 1.1;
  margin-bottom: 12px;
}

.greeting-desc {
  font-size: 15px;
  color: #64748b;
  line-height: 1.6;
  max-width: 480px;
}

/* Camera Section */
.camera-section {
  width: 100%;
  max-width: 100%;
}

/* Stats */
.stats-row {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
}

.stat-card {
  background: rgba(255,255,255,.04);
  border: 1px solid rgba(255,255,255,.08);
  border-radius: 14px;
  padding: 16px 20px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}

.stat-card.stat-green { border-color: rgba(16,185,129,.2); background: rgba(16,185,129,.05); }
.stat-card.stat-red   { border-color: rgba(239,68,68,.2);  background: rgba(239,68,68,.05); }

.stat-num {
  font-size: 36px;
  font-weight: 900;
  line-height: 1;
  color: #f1f5f9;
  font-family: var(--font-mono);
}

.stat-card.stat-green .stat-num { color: #34d399; }
.stat-card.stat-red   .stat-num { color: #f87171; }

.stat-label {
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: .06em;
  color: #64748b;
  font-weight: 600;
}

/* Slot bar */
.slot-bar-wrap {
  display: flex;
  flex-direction: column;
  gap: 6px;
  width: 100%;
}

.slot-bar {
  width: 100%;
  height: 8px;
  background: rgba(255,255,255,.06);
  border-radius: 100px;
  overflow: hidden;
}

.slot-bar-fill {
  height: 100%;
  border-radius: 100px;
  background: linear-gradient(90deg, #34d399, #f59e0b, #f87171);
  transition: width .6s ease;
}

.slot-bar-label {
  font-size: 11px;
  color: #475569;
}

/* CTA Button */
.btn-cetak {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  padding: 20px 48px;
  font-size: 20px;
  font-weight: 800;
  border-radius: 18px;
  background: linear-gradient(135deg, #6366f1, #4f46e5);
  color: white;
  border: none;
  cursor: pointer;
  box-shadow: 0 8px 32px rgba(99,102,241,.4), 0 0 0 1px rgba(255,255,255,.08);
  transition: all .2s ease;
  letter-spacing: -0.01em;
  width: 100%;
}

.btn-cetak:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 12px 40px rgba(99,102,241,.55);
}

.btn-cetak:active:not(:disabled) { transform: translateY(0); }
.btn-cetak:disabled { opacity: .5; cursor: not-allowed; }

.btn-spinner {
  width: 20px;
  height: 20px;
  border: 2.5px solid rgba(255,255,255,.2);
  border-top-color: white;
  border-radius: 50%;
  animation: spin .7s linear infinite;
  display: inline-block;
}

.error-msg {
  font-size: 14px;
  color: #f87171;
  background: rgba(239,68,68,.1);
  border: 1px solid rgba(239,68,68,.2);
  padding: 10px 18px;
  border-radius: 10px;
  text-align: center;
}

.kiosk-footer {
  padding: 12px 32px;
  text-align: center;
  font-size: 11px;
  color: #334155;
  border-top: 1px solid rgba(255,255,255,.04);
  flex-shrink: 0;
}

/* ---- QR SCREEN ---- */
.qr-screen {
  height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px 24px;
  animation: fadeIn .3s ease;
  overflow-y: auto;
}

.qr-card {
  background: rgba(17,24,39,.9);
  border: 1px solid rgba(99,102,241,.3);
  border-radius: 24px;
  padding: 32px 36px;
  text-align: center;
  max-width: 440px;
  width: 100%;
  box-shadow: 0 32px 80px rgba(0,0,0,.6), 0 0 0 1px rgba(255,255,255,.05);
  backdrop-filter: blur(20px);
  max-height: 90vh;
  overflow-y: auto;
}

.qr-header { margin-bottom: 20px; }

.qr-badge {
  display: inline-block;
  background: rgba(16,185,129,.15);
  border: 1px solid rgba(16,185,129,.3);
  color: #34d399;
  font-size: 12px;
  font-weight: 700;
  padding: 4px 12px;
  border-radius: 100px;
  margin-bottom: 8px;
}

.qr-code-text {
  font-size: 20px;
  font-weight: 800;
  color: #a5b4fc;
  font-family: var(--font-mono);
  letter-spacing: .04em;
}

.qr-box {
  background: white;
  border-radius: 14px;
  padding: 14px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 16px;
  width: 220px;
  height: 220px;
}

.qr-img {
  width: 192px;
  height: 192px;
  border-radius: 6px;
}

.qr-loading {
  display: flex;
  align-items: center;
  justify-content: center;
}

.qr-instruction {
  font-size: 14px;
  color: #94a3b8;
  margin-bottom: 3px;
}

/* Countdown */
.qr-countdown {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 5px;
  margin: 16px 0 14px;
}

.countdown-ring {
  position: relative;
  width: 48px;
  height: 48px;
}

.countdown-svg {
  width: 100%;
  height: 100%;
  transform: scale(1);
}

.countdown-num {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 15px;
  font-weight: 800;
  color: #a5b4fc;
  font-family: var(--font-mono);
}

.countdown-label {
  font-size: 11px;
  color: #475569;
}

.qr-actions {
  display: flex;
  gap: 8px;
  justify-content: center;
}

.btn-print, .btn-reset {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 9px 18px;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  border: 1px solid rgba(255,255,255,.1);
  transition: all .2s ease;
  font-family: var(--font);
}

.btn-print {
  background: linear-gradient(135deg, #059669, #10b981);
  color: white;
  border-color: transparent;
}

.btn-print:hover { opacity: .9; transform: translateY(-1px); }

.btn-reset {
  background: rgba(255,255,255,.05);
  color: #94a3b8;
}

.btn-reset:hover { background: rgba(255,255,255,.1); color: #f1f5f9; }

/* Debug */
.debug-url {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 3px;
  margin: 6px 0 0;
  padding: 6px 12px;
  background: rgba(255,255,255,.03);
  border: 1px dashed rgba(255,255,255,.1);
  border-radius: 8px;
}
.debug-label {
  font-size: 10px;
  color: #475569;
  text-transform: uppercase;
  letter-spacing: .05em;
  font-weight: 600;
}
.debug-link {
  font-size: 10.5px;
  color: #6366f1;
  font-family: var(--font-mono);
  word-break: break-all;
  text-align: center;
  text-decoration: underline;
  text-underline-offset: 2px;
  transition: color .15s;
}
.debug-link:hover { color: #a5b4fc; }

@keyframes spin    { to { transform: rotate(360deg); } }
@keyframes fadeIn  { from { opacity:0; transform: scale(.97); } to { opacity:1; transform: scale(1); } }
</style>
