<template>
  <div class="exit-page">
    <!-- Login Screen -->
    <div v-if="!loggedIn" class="exit-login">
      <div class="exit-login-card">
        <div class="exit-login-header">
          <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
            <polyline points="16 17 21 12 16 7"/>
            <line x1="21" y1="12" x2="9" y2="12"/>
          </svg>
          <h1>Gate Keluar {{ gateNumber }}</h1>
          <p>Login untuk mengakses gate</p>
        </div>
        <form @submit.prevent="handleLogin">
          <div class="exit-form-group">
            <input type="text" v-model="loginForm.username" placeholder="Username" required />
          </div>
          <div class="exit-form-group">
            <input type="password" v-model="loginForm.password" placeholder="Password" required />
          </div>
          <button type="submit" class="exit-btn-login" :disabled="loginLoading">
            {{ loginLoading ? 'Loading...' : 'Masuk' }}
          </button>
          <p v-if="loginError" class="exit-error">{{ loginError }}</p>
        </form>
      </div>
    </div>

    <!-- Gate Dashboard -->
    <div v-else class="exit-dashboard">
      <header class="exit-header">
        <div class="exit-header-left">
          <h2>Gate {{ gateNumber }}</h2>
          <span class="exit-user">{{ currentUser }}</span>
        </div>
        <button class="exit-btn-logout" @click="handleLogout">Keluar</button>
      </header>

      <!-- Input Kode Tiket -->
      <div class="exit-input-section">
        <h3>Scan atau Input Kode Tiket</h3>
        <div class="exit-input-row">
          <input 
            type="text" 
            v-model="ticketCode" 
            placeholder="Masukkan kode tiket..." 
            @keyup.enter="lookupTicket"
            ref="ticketInput"
          />
          <button @click="lookupTicket" :disabled="!ticketCode || lookupLoading">
            {{ lookupLoading ? '...' : 'Cari' }}
          </button>
        </div>
      </div>

      <!-- Ticket Detail -->
      <div v-if="ticketData" class="exit-ticket-detail">
        <div class="exit-detail-header">
          <span class="exit-detail-code">{{ ticketData.ticket_code }}</span>
          <span class="exit-detail-status" :class="'status-' + ticketData.status">{{ getStatusLabel(ticketData.status) }}</span>
        </div>

        <!-- Foto Kendaraan -->
        <div v-if="ticketData.vehicle_image" class="exit-photo-wrap">
          <div class="exit-photo-label">Foto Kendaraan Masuk</div>
          <div class="exit-photo-frame" @click="openLightbox(ticketData.vehicle_image)">
            <img :src="ticketData.vehicle_image" alt="Foto kendaraan" />
            <div class="exit-photo-zoom-hint">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/><line x1="11" y1="8" x2="11" y2="14"/><line x1="8" y1="11" x2="14" y2="11"/></svg>
            </div>
          </div>
        </div>
        <div v-else class="exit-no-photo">
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <rect x="3" y="3" width="18" height="18" rx="2"/>
            <circle cx="8.5" cy="8.5" r="1.5"/>
            <path d="M21 15l-5-5L5 21"/>
          </svg>
          <span>Tidak ada foto kendaraan</span>
        </div>

        <!-- Detail Lengkap -->
        <div class="exit-detail-grid">
          <div class="exit-detail-item">
            <span class="exit-detail-label">Waktu Masuk</span>
            <span class="exit-detail-value">{{ formatDateTime(ticketData.created_at) }}</span>
          </div>
          <div class="exit-detail-item">
            <span class="exit-detail-label">Waktu Parkir</span>
            <span class="exit-detail-value">{{ ticketData.parked_at ? formatDateTime(ticketData.parked_at) : '—' }}</span>
          </div>
          <div class="exit-detail-item">
            <span class="exit-detail-label">Slot Parkir</span>
            <span class="exit-detail-value">{{ sessionData?.slot_name || '—' }}</span>
          </div>
          <div class="exit-detail-item">
            <span class="exit-detail-label">Area</span>
            <span class="exit-detail-value">{{ sessionData?.area_name || '—' }}</span>
          </div>
          <div class="exit-detail-item">
            <span class="exit-detail-label">Durasi Total</span>
            <span class="exit-detail-value exit-duration">{{ calcDuration(ticketData.created_at) }}</span>
          </div>
          <div class="exit-detail-item">
            <span class="exit-detail-label">Durasi Parkir</span>
            <span class="exit-detail-value">{{ ticketData.parked_at ? calcDuration(ticketData.parked_at) : '—' }}</span>
          </div>
        </div>

        <!-- Biaya -->
        <div class="exit-price-section">
          <div class="exit-price-row">
            <span>Total Biaya</span>
            <span class="exit-price-amount">Rp {{ formatNumber(calcPrice(ticketData.created_at)) }}</span>
          </div>
          <div class="exit-price-detail">
            <span v-if="pricingSettings.free_parking_enabled === 'true'">
              Gratis {{ pricingSettings.free_duration }} {{ getUnitLabel(pricingSettings.free_duration_unit) }} pertama
            </span>
            <span v-if="pricingSettings.pricing_mode === 'per_hour'">
              Tarif: Rp {{ formatNumber(pricingSettings.price_first_hour) }}/jam
            </span>
            <span v-else>
              Tarif: Rp {{ formatNumber(pricingSettings.price_per_minute) }}/menit
            </span>
          </div>
        </div>

        <!-- Step Pembayaran -->
        <div v-if="(ticketData.status === 'parked' || ticketData.status === 'active' || ticketData.status === 'exiting') && !paymentDone" class="exit-payment-section">
          <h4>Metode Pembayaran</h4>
          <div class="exit-payment-options">
            <button 
              class="exit-payment-btn" 
              :class="{ active: paymentMethod === 'cash' }"
              @click="paymentMethod = 'cash'"
            >
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="2" y="6" width="20" height="12" rx="2"/><line x1="2" y1="12" x2="22" y2="12"/>
              </svg>
              Cash
            </button>
          </div>

          <button 
            class="exit-btn-process" 
            @click="processExit"
            :disabled="processLoading || !paymentMethod"
          >
            {{ processLoading ? 'Memproses...' : 'Bayar & Proses Keluar — Rp ' + formatNumber(calcPrice(ticketData.created_at)) }}
          </button>
        </div>

        <!-- Sukses -->
        <div v-if="paymentDone" class="exit-success-badge">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <path d="M20 6 9 17l-5-5"/>
          </svg>
          <span>Pembayaran berhasil — Silakan keluar</span>
        </div>

        <div v-if="ticketData.status === 'done' && !paymentDone" class="exit-done-badge">
          ✅ Tiket sudah selesai — Keluar {{ formatDateTime(ticketData.exited_at) }}
        </div>
      </div>

      <!-- Error -->
      <div v-if="lookupError" class="exit-error-card">
        {{ lookupError }}
      </div>
    </div>

    <!-- Photo Lightbox -->
    <Teleport to="body">
      <div v-if="lightboxOpen" class="lightbox-overlay" @click.self="closeLightbox">
        <button class="lightbox-close" @click="closeLightbox">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
        </button>
        <div 
          class="lightbox-img-wrap" 
          @wheel.prevent="onLightboxWheel"
          @mousedown="onDragStart"
          @mousemove="onDragMove"
          @mouseup="onDragEnd"
          @mouseleave="onDragEnd"
          @touchstart.prevent="onTouchStart"
          @touchmove.prevent="onTouchMove"
          @touchend="onDragEnd"
        >
          <img 
            :src="lightboxSrc" 
            :style="{ transform: `translate(${lightboxX}px, ${lightboxY}px) scale(${lightboxZoom})` }" 
            draggable="false" 
          />
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import { supabase } from '../lib/supabase.js'
import { getStatusLabel, formatDateTime, formatNumber, getUnitLabel } from '../lib/formatters.js'

const route = useRoute()
const gateNumber = ref(route.query.gate || '1')

// Lightbox
const lightboxOpen = ref(false)
const lightboxSrc = ref('')
const lightboxZoom = ref(1)
const lightboxX = ref(0)
const lightboxY = ref(0)
let isDragging = false
let dragStartX = 0
let dragStartY = 0
let dragOffsetX = 0
let dragOffsetY = 0

function openLightbox(src) {
  lightboxSrc.value = src
  lightboxZoom.value = 1
  lightboxX.value = 0
  lightboxY.value = 0
  lightboxOpen.value = true
}

function closeLightbox() {
  lightboxOpen.value = false
}

function onLightboxWheel(e) {
  const delta = e.deltaY > 0 ? -0.2 : 0.2
  lightboxZoom.value = Math.min(Math.max(lightboxZoom.value + delta, 0.5), 6)
}

function onDragStart(e) {
  isDragging = true
  dragStartX = e.clientX - dragOffsetX
  dragStartY = e.clientY - dragOffsetY
}

function onDragMove(e) {
  if (!isDragging) return
  dragOffsetX = e.clientX - dragStartX
  dragOffsetY = e.clientY - dragStartY
  lightboxX.value = dragOffsetX
  lightboxY.value = dragOffsetY
}

function onDragEnd() {
  isDragging = false
}

function onTouchStart(e) {
  if (e.touches.length === 1) {
    isDragging = true
    dragStartX = e.touches[0].clientX - dragOffsetX
    dragStartY = e.touches[0].clientY - dragOffsetY
  }
}

function onTouchMove(e) {
  if (!isDragging || e.touches.length !== 1) return
  dragOffsetX = e.touches[0].clientX - dragStartX
  dragOffsetY = e.touches[0].clientY - dragStartY
  lightboxX.value = dragOffsetX
  lightboxY.value = dragOffsetY
}

// Login
const loggedIn = ref(false)
const currentUser = ref('')
const loginForm = ref({ username: '', password: '' })
const loginLoading = ref(false)
const loginError = ref('')
let accountId = null

// Ticket lookup
const ticketCode = ref('')
const ticketData = ref(null)
const sessionData = ref(null)
const lookupLoading = ref(false)
const lookupError = ref('')
const processLoading = ref(false)
const ticketInput = ref(null)

// Payment
const paymentMethod = ref('cash')
const paymentDone = ref(false)

// Pricing settings
const pricingSettings = ref({})

// Heartbeat
let heartbeatInterval = null

async function handleLogin() {
  loginLoading.value = true
  loginError.value = ''

  try {
    const { data: rpcData, error } = await supabase
      .rpc('verify_gate_login', {
        p_username: loginForm.value.username,
        p_password: loginForm.value.password
      })

    if (error || !rpcData || rpcData.length === 0) {
      loginError.value = 'Username atau password salah'
      loginLoading.value = false
      return
    }

    const data = rpcData[0]

    // Login berhasil - set online + current gate
    const gateId = await getGateId()
    await supabase
      .from('gate_accounts')
      .update({ is_online: true, current_gate: gateId, last_active: new Date().toISOString() })
      .eq('id', data.id)

    accountId = data.id
    currentUser.value = data.username
    loggedIn.value = true
    loginLoading.value = false

    // Start heartbeat
    heartbeatInterval = setInterval(async () => {
      await supabase
        .from('gate_accounts')
        .update({ last_active: new Date().toISOString() })
        .eq('id', accountId)
    }, 30000)

    // Load pricing
    await loadPricing()

    // Focus input
    setTimeout(() => { if (ticketInput.value) ticketInput.value.focus() }, 100)
  } catch (err) {
    loginError.value = err.message
    loginLoading.value = false
  }
}

async function handleLogout() {
  if (accountId) {
    await supabase
      .from('gate_accounts')
      .update({ is_online: false, current_gate: null })
      .eq('id', accountId)
  }
  if (heartbeatInterval) clearInterval(heartbeatInterval)
  loggedIn.value = false
  currentUser.value = ''
  accountId = null
}

async function getGateId() {
  const { data } = await supabase
    .from('exit_gates')
    .select('id')
    .eq('gate_number', parseInt(gateNumber.value))
    .single()
  return data?.id || null
}

async function loadPricing() {
  const { data } = await supabase
    .from('settings')
    .select('key, value')
    .in('key', ['pricing_mode', 'price_per_minute', 'price_first_hour', 'price_after_first_hour', 'price_threshold', 'threshold_unit', 'special_price_enabled', 'free_parking_enabled', 'free_duration', 'free_duration_unit'])
  
  if (data) {
    data.forEach(s => { pricingSettings.value[s.key] = s.value })
  }
}

async function lookupTicket() {
  if (!ticketCode.value) return
  lookupLoading.value = true
  lookupError.value = ''
  ticketData.value = null
  sessionData.value = null
  paymentDone.value = false

  try {
    // Cari by ticket_code atau id (UUID = 36 char dengan dash pattern)
    const input = ticketCode.value.trim()
    const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(input)
    
    let query = supabase.from('tickets').select('*')
    
    if (isUUID) {
      query = query.eq('id', input)
    } else {
      query = query.eq('ticket_code', input)
    }

    const { data, error } = await query.maybeSingle()

    if (error || !data) {
      lookupError.value = 'Tiket tidak ditemukan'
      lookupLoading.value = false
      return
    }

    ticketData.value = data

    // Fetch session data (slot + area)
    const { data: sessions } = await supabase
      .from('sessions')
      .select('*, parking_slots(name, area_id, parking_areas(name))')
      .eq('ticket_id', data.id)
      .order('entry_time', { ascending: false })
      .limit(1)

    if (sessions && sessions.length > 0) {
      const s = sessions[0]
      sessionData.value = {
        slot_name: s.parking_slots?.name || '—',
        area_name: s.parking_slots?.parking_areas?.name || '—',
        entry_time: s.entry_time,
        duration_minutes: s.duration_minutes
      }
    }

    lookupLoading.value = false
  } catch (err) {
    lookupError.value = err.message
    lookupLoading.value = false
  }
}

async function processExit() {
  if (!ticketData.value) return
  processLoading.value = true

  try {
    const now = new Date().toISOString()
    const duration = Math.floor((Date.now() - new Date(ticketData.value.created_at).getTime()) / 60000)
    const cost = calcPrice(ticketData.value.created_at)

    // Update ticket → done
    await supabase
      .from('tickets')
      .update({ status: 'done', exited_at: now })
      .eq('id', ticketData.value.id)

    // Update session
    await supabase
      .from('sessions')
      .update({ exit_time: now, duration_minutes: duration, cost_rupiah: cost })
      .eq('ticket_id', ticketData.value.id)

    // Free up slot
    await supabase
      .from('parking_slots')
      .update({ status: 'tersedia', locked_by: null })
      .eq('locked_by', ticketData.value.id)

    ticketData.value.status = 'done'
    ticketData.value.exited_at = now
    paymentDone.value = true
    processLoading.value = false

    // Clear input for next ticket after 5 seconds
    setTimeout(() => {
      ticketCode.value = ''
      ticketData.value = null
      sessionData.value = null
      paymentDone.value = false
      paymentMethod.value = 'cash'
      if (ticketInput.value) ticketInput.value.focus()
    }, 5000)
  } catch (err) {
    console.error('Process exit error:', err)
    lookupError.value = 'Gagal memproses: ' + err.message
    processLoading.value = false
  }
}

function calcDuration(createdAt) {
  const mins = Math.floor((Date.now() - new Date(createdAt).getTime()) / 60000)
  const h = Math.floor(mins / 60)
  const m = mins % 60
  if (h > 0) return `${h} jam ${m} menit`
  return `${m} menit`
}

function calcPrice(createdAt) {
  const mins = Math.floor((Date.now() - new Date(createdAt).getTime()) / 60000)
  const mode = pricingSettings.value.pricing_mode || 'per_hour'
  const specialEnabled = pricingSettings.value.special_price_enabled === 'true'
  const freeEnabled = pricingSettings.value.free_parking_enabled === 'true'

  let chargeableMins = mins

  // Free parking
  if (freeEnabled) {
    let freeMins = parseInt(pricingSettings.value.free_duration || 0)
    const freeUnit = pricingSettings.value.free_duration_unit || 'minute'
    if (freeUnit === 'hour') freeMins *= 60
    else if (freeUnit === 'second') freeMins /= 60
    if (chargeableMins <= freeMins) return 0
    chargeableMins -= freeMins
  }

  if (mode === 'per_minute') {
    const rate = parseInt(pricingSettings.value.price_per_minute || 0)
    if (specialEnabled) {
      let threshold = parseInt(pricingSettings.value.price_threshold || 60)
      const unit = pricingSettings.value.threshold_unit || 'minute'
      if (unit === 'hour') threshold *= 60
      else if (unit === 'second') threshold /= 60
      if (chargeableMins > threshold) {
        const afterRate = parseInt(pricingSettings.value.price_after_first_hour || 0)
        return (threshold * rate) + ((chargeableMins - threshold) * afterRate)
      }
    }
    return chargeableMins * rate
  }

  if (mode === 'per_hour') {
    const hours = Math.ceil(chargeableMins / 60)
    const rate = parseInt(pricingSettings.value.price_first_hour || 0)
    if (specialEnabled) {
      let threshold = parseInt(pricingSettings.value.price_threshold || 1)
      const unit = pricingSettings.value.threshold_unit || 'hour'
      if (unit === 'minute') threshold = Math.ceil(threshold / 60)
      else if (unit === 'second') threshold = Math.ceil(threshold / 3600)
      if (hours > threshold) {
        const afterRate = parseInt(pricingSettings.value.price_after_first_hour || 0)
        return (threshold * rate) + ((hours - threshold) * afterRate)
      }
    }
    return hours * rate
  }

  return 0
}



onMounted(async () => {
  gateNumber.value = route.query.gate || '1'

  // Dynamic branding
  const { data } = await supabase.from('settings').select('key, value').in('key', ['app_name', 'app_favicon'])
  if (data) {
    data.forEach(s => {
      if (s.key === 'app_name' && s.value) document.title = s.value + ' — Gate Keluar'
      if (s.key === 'app_favicon' && s.value) {
        let link = document.querySelector("link[rel~='icon']")
        if (!link) { link = document.createElement('link'); link.rel = 'icon'; document.head.appendChild(link) }
        link.href = s.value
      }
    })
  }
})

onUnmounted(() => {
  handleLogout()
})
</script>

<style scoped>
.exit-page {
  min-height: 100vh;
  background: #0f172a;
  font-family: var(--font);
  color: #f1f5f9;
}

/* Login */
.exit-login {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
}

.exit-login-card {
  background: rgba(17,24,39,0.9);
  border: 1px solid rgba(99,102,241,0.3);
  border-radius: 20px;
  padding: 40px;
  max-width: 380px;
  width: 100%;
}

.exit-login-header {
  text-align: center;
  margin-bottom: 28px;
  color: #a5b4fc;
}

.exit-login-header h1 {
  font-size: 22px;
  font-weight: 800;
  color: #f1f5f9;
  margin: 12px 0 6px;
}

.exit-login-header p {
  font-size: 14px;
  color: #64748b;
}

.exit-form-group {
  margin-bottom: 14px;
}

.exit-form-group input {
  width: 100%;
  padding: 12px 16px;
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.1);
  border-radius: 10px;
  color: #f1f5f9;
  font-size: 14px;
  outline: none;
}

.exit-form-group input:focus {
  border-color: #6366f1;
}

.exit-btn-login {
  width: 100%;
  padding: 14px;
  background: linear-gradient(135deg, #6366f1, #4f46e5);
  border: none;
  border-radius: 10px;
  color: white;
  font-size: 15px;
  font-weight: 700;
  cursor: pointer;
  margin-top: 8px;
}

.exit-btn-login:disabled { opacity: 0.5; }

.exit-error {
  color: #f87171;
  font-size: 13px;
  text-align: center;
  margin-top: 12px;
}

/* Dashboard */
.exit-dashboard {
  padding: 24px;
  max-width: 700px;
  margin: 0 auto;
}

.exit-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 28px;
  padding-bottom: 16px;
  border-bottom: 1px solid rgba(255,255,255,0.08);
}

.exit-header h2 {
  font-size: 20px;
  font-weight: 800;
}

.exit-user {
  font-size: 13px;
  color: #64748b;
}

.exit-btn-logout {
  padding: 8px 16px;
  background: rgba(239,68,68,0.1);
  border: 1px solid rgba(239,68,68,0.3);
  border-radius: 8px;
  color: #f87171;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
}

/* Input Section */
.exit-input-section {
  margin-bottom: 24px;
}

.exit-input-section h3 {
  font-size: 16px;
  font-weight: 700;
  margin-bottom: 12px;
}

.exit-input-row {
  display: flex;
  gap: 10px;
}

.exit-input-row input {
  flex: 1;
  padding: 14px 18px;
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.1);
  border-radius: 12px;
  color: #f1f5f9;
  font-size: 16px;
  font-family: var(--font-mono);
  outline: none;
}

.exit-input-row input:focus {
  border-color: #6366f1;
}

.exit-input-row button {
  padding: 14px 24px;
  background: #6366f1;
  border: none;
  border-radius: 12px;
  color: white;
  font-weight: 700;
  cursor: pointer;
}

.exit-input-row button:disabled { opacity: 0.5; }

/* Ticket Detail */
.exit-ticket-detail {
  background: rgba(255,255,255,0.03);
  border: 1px solid rgba(255,255,255,0.1);
  border-radius: 16px;
  padding: 24px;
}

.exit-detail-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 20px;
}

.exit-detail-code {
  font-size: 20px;
  font-weight: 800;
  font-family: var(--font-mono);
  color: #a5b4fc;
}

.exit-detail-status {
  padding: 4px 12px;
  border-radius: 100px;
  font-size: 12px;
  font-weight: 700;
}

.status-active { background: rgba(59,130,246,0.15); color: #3b82f6; }
.status-parked { background: rgba(245,158,11,0.15); color: #f59e0b; }
.status-exiting { background: rgba(139,92,246,0.15); color: #8b5cf6; }
.status-done { background: rgba(16,185,129,0.15); color: #10b981; }

.exit-detail-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  margin-bottom: 20px;
}

.exit-detail-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.exit-detail-label {
  font-size: 12px;
  color: #64748b;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.exit-detail-value {
  font-size: 16px;
  font-weight: 700;
  color: #f1f5f9;
}

.exit-price {
  color: #10b981;
  font-size: 22px;
}

.exit-vehicle-img {
  width: 100%;
  max-width: 200px;
  border-radius: 8px;
  margin-top: 4px;
}

.exit-btn-process {
  width: 100%;
  padding: 16px;
  background: linear-gradient(135deg, #10b981, #059669);
  border: none;
  border-radius: 12px;
  color: white;
  font-size: 16px;
  font-weight: 800;
  cursor: pointer;
  box-shadow: 0 4px 12px rgba(16,185,129,0.3);
}

.exit-btn-process:disabled { opacity: 0.5; }

.exit-done-badge {
  text-align: center;
  padding: 14px;
  background: rgba(16,185,129,0.1);
  border: 1px solid rgba(16,185,129,0.3);
  border-radius: 10px;
  color: #34d399;
  font-weight: 700;
}

.exit-error-card {
  padding: 16px;
  background: rgba(239,68,68,0.1);
  border: 1px solid rgba(239,68,68,0.3);
  border-radius: 10px;
  color: #f87171;
  text-align: center;
}

.online-dot, .offline-dot {
  display: inline-block;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  margin-right: 4px;
}
.online-dot { background: #10b981; }
.offline-dot { background: #ef4444; }

/* Photo */
.exit-photo-wrap {
  margin-bottom: 20px;
}

.exit-photo-label {
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: #64748b;
  margin-bottom: 8px;
}

.exit-photo-frame {
  position: relative;
  width: 100%;
  border-radius: 12px;
  overflow: hidden;
  border: 1px solid rgba(255,255,255,0.1);
  background: #000;
  cursor: pointer;
}

.exit-photo-frame:hover { border-color: rgba(99,102,241,0.4); }

.exit-photo-frame img {
  display: block;
  width: 100%;
  height: auto;
  min-height: 120px;
  max-height: 300px;
  object-fit: cover;
}

.exit-photo-zoom-hint {
  position: absolute;
  bottom: 8px;
  right: 8px;
  background: rgba(0,0,0,0.6);
  backdrop-filter: blur(4px);
  border-radius: 6px;
  padding: 5px 7px;
  color: white;
  opacity: 0;
  transition: opacity 0.2s;
}
.exit-photo-frame:hover .exit-photo-zoom-hint { opacity: 1; }

.exit-no-photo {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 14px 16px;
  margin-bottom: 20px;
  color: #475569;
  font-size: 13px;
  background: rgba(255,255,255,0.03);
  border: 1px dashed rgba(255,255,255,0.08);
  border-radius: 10px;
}

/* Duration highlight */
.exit-duration {
  color: #f59e0b;
}

/* Price Section */
.exit-price-section {
  background: rgba(16,185,129,0.08);
  border: 1px solid rgba(16,185,129,0.3);
  border-radius: 12px;
  padding: 16px;
  margin-bottom: 16px;
}

.exit-price-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 6px;
}

.exit-price-row span:first-child {
  font-size: 14px;
  color: #94a3b8;
}

.exit-price-amount {
  font-size: 28px;
  font-weight: 900;
  color: #10b981;
  font-family: var(--font-mono);
}

.exit-price-detail {
  display: flex;
  flex-direction: column;
  gap: 2px;
  font-size: 12px;
  color: #64748b;
}

/* Payment */
.exit-payment-section {
  margin-top: 16px;
}

.exit-payment-section h4 {
  font-size: 14px;
  font-weight: 700;
  color: #f1f5f9;
  margin-bottom: 10px;
}

.exit-payment-options {
  display: flex;
  gap: 10px;
  margin-bottom: 14px;
}

.exit-payment-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 20px;
  background: rgba(255,255,255,0.04);
  border: 2px solid rgba(255,255,255,0.1);
  border-radius: 10px;
  color: #94a3b8;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.exit-payment-btn.active {
  border-color: #6366f1;
  background: rgba(99,102,241,0.1);
  color: #a5b4fc;
}

/* Success */
.exit-success-badge {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 18px;
  background: rgba(16,185,129,0.1);
  border: 2px solid #10b981;
  border-radius: 12px;
  color: #34d399;
  font-size: 16px;
  font-weight: 700;
  margin-top: 16px;
  animation: fadeIn 0.3s ease;
}

@keyframes fadeIn {
  from { opacity: 0; transform: scale(0.95); }
  to { opacity: 1; transform: scale(1); }
}

/* Lightbox */
.lightbox-overlay {
  position: fixed;
  inset: 0;
  z-index: 9999;
  background: rgba(0,0,0,0.75);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  display: flex;
  align-items: center;
  justify-content: center;
  animation: lbFadeIn 0.2s ease;
}

@keyframes lbFadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

.lightbox-close {
  position: fixed;
  top: 16px;
  right: 16px;
  z-index: 10000;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  border: none;
  background: rgba(255,255,255,0.12);
  color: white;
  cursor: pointer;
  transition: background 0.15s;
}
.lightbox-close:hover { background: rgba(255,255,255,0.25); }

.lightbox-img-wrap {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  cursor: grab;
}
.lightbox-img-wrap:active { cursor: grabbing; }

.lightbox-img-wrap img {
  max-width: 90%;
  max-height: 90%;
  object-fit: contain;
  border-radius: 8px;
  box-shadow: 0 20px 60px rgba(0,0,0,0.5);
  transition: transform 0.1s ease;
  user-select: none;
  -webkit-user-drag: none;
  pointer-events: none;
}
</style>
