<template>
  <div class="visitor-page">
    <!-- GPS Permission Gate - BLOCKING, harus granted dulu -->
    <div v-if="!gpsGranted" class="v-state">
      <div class="v-icon-wrap" :class="gpsError ? 'v-icon-error' : 'v-icon-gps'">
        <svg v-if="!gpsError" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/>
          <circle cx="12" cy="10" r="3"/>
        </svg>
        <svg v-else width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="12" cy="12" r="10"/><path d="m15 9-6 6M9 9l6 6"/>
        </svg>
      </div>
      <h2 class="v-state-title">{{ gpsError ? 'GPS Diperlukan' : 'Izinkan Akses Lokasi' }}</h2>
      <p class="v-state-desc" v-if="!gpsError">{{ appName }} membutuhkan GPS untuk menavigasi Anda ke slot parkir terdekat</p>
      <p class="v-state-desc" v-else>{{ gpsError }}</p>
      <button class="btn-allow-gps" @click="requestGps" :disabled="gpsLoading">
        <span v-if="gpsLoading" class="spinner-sm"></span>
        <svg v-else width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
          <path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/>
          <circle cx="12" cy="10" r="3"/>
        </svg>
        {{ gpsLoading ? 'Mencari lokasi...' : gpsError ? 'Coba Lagi' : 'Aktifkan GPS' }}
      </button>
      <p v-if="gpsError" class="v-state-desc" style="margin-top:12px;font-size:12px;">
        Pastikan GPS/Lokasi aktif di pengaturan perangkat Anda
      </p>
    </div>

    <!-- Semua content visitor HANYA muncul kalau GPS granted -->
    <template v-else>

    <!-- Loading state -->
    <div v-if="state === 'loading'" class="v-state">
      <div class="v-spinner">
        <svg class="v-spinner-ring" viewBox="25 25 50 50">
          <circle cx="50" cy="50" r="20" fill="none" stroke-width="3" />
        </svg>
      </div>
      <p class="v-loading-text">Memvalidasi tiket...</p>
    </div>

    <!-- No ticket ID -->
    <div v-else-if="state === 'no-ticket'" class="v-state">
      <div class="v-icon-wrap v-icon-warn">
        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
          <line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/>
        </svg>
      </div>
      <h2 class="v-state-title">Tiket Tidak Ditemukan</h2>
      <p class="v-state-desc">Tidak ada ID tiket pada URL ini. Silakan scan ulang QR code di karcis parkir Anda.</p>
    </div>

    <!-- Error state -->
    <div v-else-if="state === 'error'" class="v-state">
      <div class="v-icon-wrap v-icon-error">
        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="12" cy="12" r="10"/><path d="m15 9-6 6M9 9l6 6"/>
        </svg>
      </div>
      <h2 class="v-state-title">Tiket Tidak Valid</h2>
      <p class="v-state-desc">{{ errorMsg }}</p>
    </div>

    <!-- Expired state -->
    <div v-else-if="state === 'expired'" class="v-state">
      <div class="v-icon-wrap v-icon-error">
        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>
        </svg>
      </div>
      <h2 class="v-state-title">Tiket Kedaluwarsa</h2>
      <p class="v-state-desc">Tiket ini sudah tidak dapat digunakan.</p>
    </div>

    <!-- Done state -->
    <div v-else-if="state === 'done'" class="v-state">
      <div class="v-icon-wrap v-icon-success">
        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
          <path d="M20 6 9 17l-5-5"/>
        </svg>
      </div>
      <h2 class="v-state-title">Parkir Selesai</h2>
      <p class="v-state-desc">Terima kasih telah menggunakan {{ appName }}!</p>
      <div v-if="ticket" class="v-done-card">
        <div class="v-done-row">
          <span>Tiket</span>
          <span class="font-mono">{{ ticket.ticket_code }}</span>
        </div>
        <div class="v-done-row" v-if="session">
          <span>Durasi</span>
          <span>{{ session.duration_minutes }} menit</span>
        </div>
        <div class="v-done-row" v-if="session?.cost_rupiah">
          <span>Biaya</span>
          <span>{{ formatRupiah(session.cost_rupiah) }}</span>
        </div>
      </div>
    </div>

    <!-- Valid / Active ticket -->
    <div v-else-if="state === 'valid'" class="v-main">

      <!-- Header -->
      <header class="v-header">
        <div class="v-logo">
          <div class="v-logo-icon">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
              <rect x="3" y="11" width="18" height="11" rx="2"/>
              <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
            </svg>
          </div>
          <span>{{ appName }}</span>
        </div>
        <span class="v-status-badge" :class="ticketStatusClass">
          <span class="v-badge-dot"></span>
          {{ statusLabel }}
        </span>
      </header>

      <!-- Ticket Card -->
      <section class="v-ticket-card">
        <div class="v-ticket-top">
          <div class="v-ticket-code font-mono">{{ ticket.ticket_code }}</div>
          <div class="v-ticket-time">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
              <circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>
            </svg>
            Masuk {{ formatTime(ticket.created_at) }}
          </div>
        </div>

        <div class="v-ticket-divider">
          <div class="v-ticket-notch left"></div>
          <div class="v-ticket-dashes"></div>
          <div class="v-ticket-notch right"></div>
        </div>

        <div class="v-ticket-bottom">
          <div class="v-ticket-info">

            <div class="v-info-item">
              <span class="v-info-label">Status</span>
              <span class="v-info-val">{{ statusLabel }}</span>
            </div>
            <div class="v-info-item">
              <span class="v-info-label">Slot/Gate</span>
              <span class="v-info-val">{{ slotGateDisplay }}</span>
            </div>
          </div>
          <div class="v-ticket-duration">
            <span class="v-duration-num">{{ elapsedTime }}</span>
            <span class="v-duration-label">durasi</span>
          </div>
        </div>
      </section>

      <!-- Map Placeholder -->
      <section class="v-map-section">

        <!-- NAVIGASI: tampil saat active atau exiting (ada tujuan) -->
        <template v-if="ticket.status === 'active' || exitMode">
          <div class="v-map-header">
            <div>
              <h2 class="v-section-title">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                  <polygon points="3 11 22 2 13 21 11 13 3 11"/>
                </svg>
                {{ exitMode ? 'Navigasi ke Pintu Keluar' : 'Navigasi ke Slot Parkir' }}
              </h2>
              <p class="v-section-desc">{{ exitMode ? 'Ikuti panduan menuju gate keluar' : 'Ikuti panduan di bawah untuk menemukan slot parkir Anda' }}</p>
            </div>
          </div>

          <!-- Locked Slot Info -->
          <div v-if="lockedSlot && ticket.status === 'active'" class="locked-slot-card">
            <div class="locked-slot-header">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polygon points="3 11 22 2 13 21 11 13 3 11"/>
              </svg>
              <span v-if="!isRerouting">Mengarahkan ke slot</span>
              <span v-else class="reroute-text">Rerouting...</span>
            </div>
            <div class="locked-slot-name">{{ lockedSlot.name }}</div>
            <p class="locked-slot-hint">Slot ini sudah di-lock untuk Anda</p>
          </div>

          <div v-if="!lockedSlot && ticket.status === 'active'" class="locked-slot-card locked-slot-empty">
            <p>Tidak ada slot tersedia saat ini</p>
          </div>

          <!-- Map -->
          <ParkingMap3D
            v-if="userLat !== 0 && userLng !== 0 && mapEngine === 'maplibre'"
            :userLat="userLat"
            :userLng="userLng"
            :targetSlot="lockedSlot"
            :slots="allSlots"
            :debug="fakeGps.active"
            :lineColor="navLineColor"
            @update:userLat="v => userLat = v"
            @update:userLng="v => userLng = v"
          />
          <ParkingMap
            v-else-if="userLat !== 0 && userLng !== 0"
            :userLat="userLat"
            :userLng="userLng"
            :targetSlot="lockedSlot"
            :slots="allSlots"
            :debug="fakeGps.active"
            :lineColor="navLineColor"
            @update:userLat="v => userLat = v"
            @update:userLng="v => userLng = v"
          />
          <div v-else class="v-map-placeholder">
            <div class="v-map-overlay">
              <span class="spinner-sm" style="border-top-color:#6366f1; width:24px; height:24px;"></span>
              <p class="v-map-text" style="margin-top: 10px;">Menunggu data lokasi...</p>
            </div>
          </div>

          <!-- Nav Info below map -->
          <div v-if="lockedSlot && !exitMode" class="nav-info">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
              <polygon points="3 11 22 2 13 21 11 13 3 11"/>
            </svg>
            <span>Navigasi ke slot <strong>{{ lockedSlot.name }}</strong></span>
          </div>

          <!-- Tombol "Saya sudah parkir di slot berbeda" -->
          <div v-if="showDifferentSlotButton && ticket?.status === 'active' && !exitMode" class="different-slot-section">
            <div v-if="!showDifferentSlotInput" >
              <button class="btn-different-slot" @click="showDifferentSlotInput = true">
                Saya sudah parkir di slot berbeda
              </button>
            </div>
            <div v-else class="different-slot-form">
              <input type="text" v-model="differentSlotInput" placeholder="Nama slot (cth: A3)" class="different-slot-field" />
              <button class="btn-different-confirm" @click="handleOccupiedDifferentSlot" :disabled="!differentSlotInput">Konfirmasi</button>
              <button class="btn-different-cancel" @click="showDifferentSlotInput = false; differentSlotInput = ''">Batal</button>
            </div>
          </div>
        </template>

        <!-- SEDANG PARKIR: cuma tombol keluar -->
        <!-- Tombol Keluar Parkir (muncul saat sudah parkir, disabled kalau cooldown) -->
        <button v-if="!exitMode && ticket?.status === 'parked'" class="btn-exit-parking" :class="{ 'btn-exit-disabled': !exitCooldownDone }" @click="exitCooldownDone ? enterExitMode() : null">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
            <polyline points="16 17 21 12 16 7"/>
            <line x1="21" y1="12" x2="9" y2="12"/>
          </svg>
          <span v-if="exitCooldownDone">Saya ingin keluar parkir</span>
          <span v-else>Tersedia dalam {{ exitCooldownRemaining }}</span>
        </button>

        <!-- Exit Mode: Barcode + Tunjukkan ke petugas -->
        <div v-if="exitMode" class="exit-card">
          <div class="exit-barcode">
            <img v-if="qrExitUrl" :src="qrExitUrl" alt="Barcode Keluar" class="exit-barcode-img" />
          </div>
          <p class="exit-ticket-code">{{ ticket?.ticket_code }}</p>
          <p class="exit-instruction">Tunjukkan ke petugas parkir saat keluar</p>
        </div>
      </section>

      <!-- Help section -->
      <section class="v-help" v-if="!isDebugMode">
        <div class="v-help-item">
          <div class="v-help-icon">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="10"/><path d="M12 8v4l3 3"/>
            </svg>
          </div>
          <div>
            <p class="v-help-title">Simpan tiket Anda</p>
            <p class="v-help-desc">Karcis diperlukan saat keluar area parkir</p>
          </div>
        </div>
        <div class="v-help-item">
          <div class="v-help-icon">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <polygon points="3 11 22 2 13 21 11 13 3 11"/>
            </svg>
          </div>
          <div>
            <p class="v-help-title">Ikuti navigasi</p>
            <p class="v-help-desc">Sistem akan memandu Anda ke slot terdekat</p>
          </div>
        </div>
        <div class="v-help-item">
          <div class="v-help-icon">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M18 6H5a2 2 0 0 0-2 2v3a2 2 0 0 0 2 2h13l4-3.5L18 6Z"/>
              <path d="M12 13v9M8 13v9"/>
            </svg>
          </div>
          <div>
            <p class="v-help-title">Parkirkan kendaraan</p>
            <p class="v-help-desc">Konfirmasi slot saat sudah berada di posisi</p>
          </div>
        </div>
      </section>

      <!-- DEBUG PANEL -->
      <section v-if="isDebugMode" class="debug-panel">
        <div class="debug-panel-header">
          <span class="debug-badge">🐛 DEBUG MODE</span>
        </div>

        <!-- Fake Actions -->
        <div class="debug-actions">
          <button class="debug-btn debug-btn-blue" @click="debugFakeScanQR" :disabled="ticket?.status !== 'active'" title="Simulasi visitor buka halaman tiket → lock slot terdekat dan mulai idle timer.">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/>
              <rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/>
            </svg>
            Scan QR (Lock Slot)
          </button>
          <button class="debug-btn" @click="debugFakeParked" :disabled="ticket?.status !== 'active' || !lockedSlot" title="Simulasi sensor MQTT detect mobil → langsung Auto-Park (sama dengan flow handleOccupiedYes).">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M20 6 9 17l-5-5"/>
            </svg>
            Auto-Park (Sensor)
          </button>
          <button class="debug-btn" @click="debugSimulateStolen" :disabled="!lockedSlot || ticket?.status !== 'active'" title="Simulasi slot diambil user lain → locked_by dikosongkan, auto-reroute ke slot baru.">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>
            </svg>
            Simulasi Slot Diambil
          </button>
          <button class="debug-btn debug-btn-orange" @click="debugSimulateIdle" :disabled="ticket?.status !== 'active'" title="Langsung trigger popup idle timeout tanpa nunggu.">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>
            </svg>
            Simulasi Idle Timeout
          </button>
          <button class="debug-btn debug-btn-orange" @click="debugFakeDone" :disabled="ticket?.status !== 'parked'" title="Simulasi klik 'Saya ingin keluar parkir' → enter exit mode, muncul barcode keluar.">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M18 6H5a2 2 0 0 0-2 2v3a2 2 0 0 0 2 2h13l4-3.5L18 6Z"/>
            </svg>
            Simulasi Keluar Parkir
          </button>
          <button class="debug-btn debug-btn-red" @click="debugUnlockAll" title="Clear locked_by + set semua slot ke available.">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="3" y="11" width="18" height="11" rx="2"/>
              <path d="M7 11V7a5 5 0 0 1 9.9-1"/>
            </svg>
            Unlock Semua Slot
          </button>
          <button class="debug-btn debug-btn-red" @click="debugResetTicket" title="Reset SEMUA: unlock slot, tiket ke active, hapus session, lock slot baru, timer dari 0.">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/>
            </svg>
            Reset Tiket & Slot
          </button>
        </div>

        <!-- Fake GPS Toggle -->
        <div class="debug-gps">
          <div class="debug-gps-header">
            <span>📍 Fake GPS (Joystick)</span>
            <button 
              class="debug-gps-toggle"
              :class="{ active: fakeGps.active }"
              @click="toggleFakeGps"
            >
              {{ fakeGps.active ? 'ON' : 'OFF' }}
            </button>
          </div>
          <p v-if="fakeGps.active" class="debug-gps-info">Gunakan joystick di peta untuk bergerak</p>
          <p v-else class="debug-gps-info">OFF = pakai GPS asli perangkat</p>
        </div>

        <!-- Debug Info -->
        <div class="debug-info">
          <div class="debug-info-row">
            <span>Ticket ID</span>
            <code>{{ ticket?.id }}</code>
          </div>
          <div class="debug-info-row">
            <span>Status</span>
            <code>{{ ticket?.status }}</code>
          </div>
          <div class="debug-info-row">
            <span>Session</span>
            <code>{{ session ? 'Active' : 'None' }}</code>
          </div>
        </div>
      </section>

    </div>
    <!-- Idle Popup -->
    <div v-if="showIdlePopup" class="idle-overlay">
      <div class="idle-popup">
        <div class="idle-icon">
          <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>
          </svg>
        </div>
        <h3>Sepertinya Anda tidak menuju tempat parkir</h3>
        <p>Slot parkir Anda akan dilepas dalam <strong>{{ idleCountdown }}</strong> detik</p>
        <div class="idle-actions">
          <button class="idle-btn idle-btn-yes" @click="handleIdleYes">
            Saya masih menuju parkir
          </button>
          <button class="idle-btn idle-btn-no" @click="handleIdleNo">
            Saya ingin keluar
          </button>
        </div>
      </div>
    </div>

    <!-- Stolen Popup (slot diambil orang lain) -->
    <div v-if="showStolenPopup" class="idle-overlay">
      <div class="idle-popup">
        <div class="idle-icon" style="color:#ef4444;">
          <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="12" cy="12" r="10"/><path d="m15 9-6 6M9 9l6 6"/>
          </svg>
        </div>
        <h3>Maaf, slot {{ lockedSlot?.name }} diambil</h3>
        <p>Anda akan dialihkan ke slot terdekat lainnya...</p>
      </div>
    </div>

    </template><!-- end GPS granted -->
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import { supabase } from '../lib/supabase.js'
import ParkingMap from '../components/ParkingMap.vue'
import ParkingMap3D from '../components/ParkingMap3D.vue'

const route = useRoute()
const state = ref('loading') // loading | no-ticket | error | expired | done | valid
const ticket = ref(null)
const session = ref(null)
const errorMsg = ref('')
const confirmingParking = ref(false)
const isDebugMode = ref(false)

// GPS gate - WAJIB granted sebelum lanjut
const gpsGranted = ref(false)
const gpsLoading = ref(false)
const gpsError = ref('')

// Locked slot (slot yang di-lock untuk user ini)
const lockedSlot = ref(null)
const isRerouting = ref(false)
const allSlots = ref([])

// GPS position (default overwritten by settings + GPS)
const userLat = ref(0)
const userLng = ref(0)
let gpsWatchId = null

// Map settings (loaded from DB)
const mapEngine = ref('maplibre')
const navLineColor = ref('#4285F4')
const appName = ref('SmartPark')

// Exit mode (cooldown dari settings, pake elapsedSeconds biar reactive)
const exitCooldownMinutes = ref(5)
const exitCooldownDone = computed(() => {
  void elapsedSeconds.value
  if (!ticket.value?.parked_at) return false
  const parkedAt = new Date(ticket.value.parked_at).getTime()
  return (Date.now() - parkedAt) >= exitCooldownMinutes.value * 60 * 1000
})
const slotGateDisplay = computed(() => {
  if (exitMode.value) {
    const parkedSlotName = session.value?.slot?.name || '—'
    const targetGateName = lockedSlot.value?.name || '—'
    return `${parkedSlotName}/${targetGateName}`
  }
  
  // Belum exit mode
  if (ticket.value?.status === 'parked') {
    return `${session.value?.slot?.name || '—'}/—`
  }
  
  // Masih cari slot (active)
  return `${lockedSlot.value?.name || '—'}/—`
})

const exitCooldownRemaining = computed(() => {
  void elapsedSeconds.value
  if (!ticket.value?.parked_at) return ''
  const parkedAt = new Date(ticket.value.parked_at).getTime()
  const elapsed = Math.floor((Date.now() - parkedAt) / 1000)
  const total = exitCooldownMinutes.value * 60
  const remaining = total - elapsed
  if (remaining <= 0) return ''
  const m = Math.floor(remaining / 60)
  const s = remaining % 60
  return `${m}:${String(s).padStart(2, '0')}`
})
const exitMode = ref(false)
const qrExitUrl = ref(null)

// Idle lock timer
const idleTimeout = ref(20) // menit, dari settings
const showIdlePopup = ref(false)
const showStolenPopup = ref(false)
const differentSlotInput = ref('')
const showDifferentSlotInput = ref(false)
const showDifferentSlotButton = ref(false) // tombol di bawah map
let differentSlotTimer = null
const idleCountdown = ref(0)
let idleTimer = null
let idleCountdownTimer = null
let settingsChannel = null

// Fake GPS (default overwritten by settings)
const fakeGps = ref({
  lat: 0,
  lng: 0,
  active: false
})

// Elapsed time timer
const elapsedSeconds = ref(0)
let timerInterval = null

const elapsedTime = computed(() => {
  const h = Math.floor(elapsedSeconds.value / 3600)
  const m = Math.floor((elapsedSeconds.value % 3600) / 60)
  const s = elapsedSeconds.value % 60
  if (h > 0) return `${h}j ${m}m`
  if (m > 0) return `${m}m ${String(s).padStart(2,'0')}d`
  return `${s}d`
})

const statusLabel = computed(() => {
  if (!ticket.value) return ''
  const map = { active: 'Belum Parkir', parked: 'Sedang Parkir', exiting: 'Keluar', done: 'Selesai', expired: 'Kedaluwarsa' }
  return map[ticket.value.status] || ticket.value.status
})

const ticketStatusClass = computed(() => {
  if (!ticket.value) return ''
  const map = {
    active: 'v-status-active',
    parked: 'v-status-parked',
    exiting: 'v-status-exiting',
    done: 'v-status-done',
    expired: 'v-status-expired'
  }
  return map[ticket.value.status] || ''
})

function formatTime(isoStr) {
  if (!isoStr) return '—'
  return new Date(isoStr).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })
}

function formatRupiah(amount) {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(amount)
}

function startTimer(entryIso) {
  if (timerInterval) clearInterval(timerInterval)
  const entryMs = new Date(entryIso).getTime()
  elapsedSeconds.value = Math.floor((Date.now() - entryMs) / 1000)
  timerInterval = setInterval(() => {
    elapsedSeconds.value = Math.floor((Date.now() - entryMs) / 1000)
  }, 1000)
}

function requestGps() {
  gpsLoading.value = true
  gpsError.value = ''

  const ticketId = route.query.t

  // Debug mode: skip real GPS
  if (ticketId === 'debug') {
    // fetchMapSettings dulu oke karena debug bukan real gesture
    fetchMapSettings().then(async () => {
      fakeGps.value.active = true

      const { data: coordSettings } = await supabase
        .from('settings')
        .select('key, value')
        .in('key', ['default_lat', 'default_lng'])

      let defLat = -7.2650876
      let defLng = 112.783217
      if (coordSettings) {
        coordSettings.forEach(s => {
          if (s.key === 'default_lat' && s.value) defLat = parseFloat(s.value)
          if (s.key === 'default_lng' && s.value) defLng = parseFloat(s.value)
        })
      }

      fakeGps.value.lat = defLat
      fakeGps.value.lng = defLng
      userLat.value = defLat
      userLng.value = defLng

      gpsGranted.value = true
      gpsLoading.value = false
      loadTicket()
    })
    return
  }

  // Cek apakah browser support geolocation
  if (!('geolocation' in navigator)) {
    gpsLoading.value = false
    gpsError.value = 'Browser Anda tidak mendukung GPS. Gunakan browser lain (Chrome/Safari).'
    return
  }

  // ⚠️ PENTING UNTUK SAFARI: getCurrentPosition() HARUS dipanggil SYNCHRONOUS
  // langsung dari event click, TANPA ada await apapun sebelumnya.
  // Kalau ada await sebelum ini, Safari akan diam-diam menolak tanpa popup permission.
  navigator.geolocation.getCurrentPosition(
    function onSuccess(pos) {
      userLat.value = pos.coords.latitude
      userLng.value = pos.coords.longitude
      gpsGranted.value = true
      gpsLoading.value = false
      // Fetch settings setelah GPS berhasil, urutan sudah aman
      fetchMapSettings().then(() => loadTicket())
    },
    function onError(err) {
      gpsLoading.value = false
      const isSafari = /^((?!chrome|android).)*safari/i.test(navigator.userAgent)
      const isHTTP = location.protocol === 'http:'
      
      switch (err.code) {
        case 1: // PERMISSION_DENIED
          if (isSafari) {
            gpsError.value = 'Safari: Buka Settings > Safari > Location Services > izinkan "While Using". Lalu refresh halaman ini.'
          } else {
            gpsError.value = 'Akses lokasi ditolak. Tap icon kunci/gembok di address bar > izinkan Location/Lokasi.'
          }
          break
        case 2: // POSITION_UNAVAILABLE
          gpsError.value = 'GPS tidak tersedia. Pastikan GPS/Location Services sudah dinyalakan di Settings perangkat.'
          break
        case 3: // TIMEOUT
          gpsError.value = 'Gagal mendapatkan lokasi (timeout). Coba pindah ke area terbuka dengan sinyal GPS lebih baik.'
          break
        default:
          gpsError.value = 'Gagal mendapatkan lokasi.'
      }

      if (isHTTP) {
        gpsError.value += '\n\n⚠️ GPS membutuhkan HTTPS. Saat ini menggunakan HTTP yang tidak aman.'
      }
    },
    {
      enableHighAccuracy: true,
      timeout: 15000,
      maximumAge: 0
    }
  )
}

async function loadTicket() {
  const ticketId = route.query.t
  if (!ticketId) { state.value = 'no-ticket'; return }

  // Debug mode
  if (ticketId === 'debug') {
    // Cek debug mode dari DATABASE (bukan localStorage, biar jalan di private/device lain)
    const { data: debugSetting } = await supabase
      .from('settings')
      .select('value')
      .eq('key', 'debug_mode')
      .single()

    if (!debugSetting || debugSetting.value !== 'true') {
      errorMsg.value = 'Debug mode tidak aktif. Aktifkan di Admin Panel.'
      state.value = 'error'
      return
    }
    
    isDebugMode.value = true

    // Cari tiket debug yang udah ada (reuse, ga bikin baru tiap kali)
    let debugTicket = null
    const { data: existingDebug } = await supabase
      .from('tickets')
      .select('*')
      .eq('ticket_code', 'SP-DEBUG-PERMANENT')
      .maybeSingle()

    if (existingDebug) {
      // Reset status ke active kalau bukan active
      if (existingDebug.status !== 'active') {
        await supabase
          .from('tickets')
          .update({ status: 'active', parked_at: null, exited_at: null })
          .eq('id', existingDebug.id)
        existingDebug.status = 'active'
        existingDebug.parked_at = null
        existingDebug.exited_at = null
      }
      debugTicket = existingDebug
      console.log('[DEBUG] Reusing ticket:', debugTicket.id)
    } else {
      // Bikin 1x aja
      const { data: newTicket, error: debugErr } = await supabase
        .from('tickets')
        .insert([{ ticket_code: 'SP-DEBUG-PERMANENT', qr_data: '', status: 'active' }])
        .select()
        .single()

      if (debugErr || !newTicket) {
        errorMsg.value = 'Gagal buat debug ticket: ' + (debugErr?.message || 'unknown')
        state.value = 'error'
        return
      }
      debugTicket = newTicket
      console.log('[DEBUG] Ticket created:', debugTicket.id)
    }

    ticket.value = debugTicket
    
    // Fetch slots, settings, GPS
    await fetchAllSlots()
    console.log('[DEBUG] allSlots fetched:', allSlots.value.length)
    startGpsTracking()

    // Lock slot terdekat
    await lockNearestSlot(debugTicket.id)
    console.log('[DEBUG] After lockNearestSlot, lockedSlot:', lockedSlot.value?.name || 'NULL')

    state.value = 'valid'
    startTimer(debugTicket.created_at)
    watchTicketStatus()
    if (lockedSlot.value) {
      console.log('[DEBUG] Starting watchLockedSlot for:', lockedSlot.value.id, lockedSlot.value.name)
      watchLockedSlot()
    } else {
      console.log('[DEBUG] No lockedSlot, watchLockedSlot NOT started')
    }
    return
  }

  try {
    const { data, error } = await supabase
      .from('tickets')
      .select('*')
      .eq('id', ticketId)
      .single()

    if (error || !data) {
      errorMsg.value = 'Tiket tidak ditemukan di sistem.'
      state.value = 'error'
      return
    }

    ticket.value = data

    // Broadcast ticket accessed event to close QR on kiosk
    const channel = supabase.channel(`ticket-${ticketId}`)
    await channel.subscribe(async (status) => {
      if (status === 'SUBSCRIBED') {
        await channel.send({
          type: 'broadcast',
          event: 'ticket_accessed',
          payload: { ticketId, timestamp: new Date().toISOString() }
        })
        // Unsubscribe after sending
        setTimeout(() => supabase.removeChannel(channel), 1000)
      }
    })

    if (data.status === 'expired') { state.value = 'expired'; return }
    if (data.status === 'done') {
      // Fetch session for summary
      const { data: s } = await supabase
        .from('sessions')
        .select('*, slot:parking_slots(name)')
        .eq('ticket_id', data.id)
        .order('entry_time', { ascending: false })
        .limit(1)
        .single()
      session.value = s
      state.value = 'done'
      return
    }

    // active, parked, or exiting
    if (data.status === 'exiting' || data.status === 'parked') {
      const { data: s } = await supabase
        .from('sessions')
        .select('*, slot:parking_slots(name, lat, lng)')
        .eq('ticket_id', data.id)
        .is('exit_time', null)
        .single()
      session.value = s
      
      if (data.status === 'exiting') {
        // Restore exit mode
        exitMode.value = true
        
        // Generate QR barcode untuk keluar
        const QRCode = (await import('qrcode')).default
        qrExitUrl.value = await QRCode.toDataURL(data.ticket_code, {
          width: 200,
          margin: 2,
          color: { dark: '#0f172a', light: '#ffffff' }
        })

        // Fetch gate terdekat (panggil enterExitMode tapi jangan update DB lagi)
        await enterExitMode(true) 
      } else {
        if (s?.slot) lockedSlot.value = s.slot
      }
    }

    // Kalau active, cari dan lock slot terdekat
    if (data.status === 'active') {
      await lockNearestSlot(data.id)
    }

    state.value = 'valid'

    // Timer SELALU mulai dari created_at tiket (saat ambil tiket)
    startTimer(data.created_at)

    // Watch ticket status realtime (auto selesai dari gate)
    watchTicketStatus()

    // Fetch all slots for map display
    await fetchAllSlots()

    // Start GPS tracking (real or fake)
    startGpsTracking()

  } catch (e) {
    errorMsg.value = e.message
    state.value = 'error'
  }
}

// ===== FETCH SLOTS & GPS =====

async function fetchAllSlots() {
  try {
    const { data } = await supabase
      .from('parking_slots')
      .select('*')
      .order('name')
    allSlots.value = data || []
  } catch (err) {
    console.error('Fetch all slots error:', err)
  }
}

async function fetchMapSettings() {
  try {
    const { data } = await supabase
      .from('settings')
      .select('*')
      .in('key', ['map_engine', 'nav_line_color', 'idle_timeout', 'default_lat', 'default_lng', 'exit_cooldown', 'app_name', 'app_favicon'])
    
    if (data) {
      data.forEach(s => {
        if (s.key === 'map_engine') mapEngine.value = s.value || 'maplibre'
        if (s.key === 'nav_line_color') navLineColor.value = s.value || '#4285F4'
        if (s.key === 'idle_timeout') idleTimeout.value = parseInt(s.value) || 20
        if (s.key === 'exit_cooldown') exitCooldownMinutes.value = parseInt(s.value) || 5
        if (s.key === 'default_lat') {
          const v = parseFloat(s.value)
          if (!isNaN(v)) {
            if (userLat.value === 0) userLat.value = v
            fakeGps.value.lat = v
          } else {
            fakeGps.value.lat = -7.2650876
          }
        }
        if (s.key === 'default_lng') {
          const v = parseFloat(s.value)
          if (!isNaN(v)) {
            if (userLng.value === 0) userLng.value = v
            fakeGps.value.lng = v
          } else {
            fakeGps.value.lng = 112.783217
          }
        }
        if (s.key === 'app_name') {
          appName.value = s.value || 'SmartPark'
          document.title = appName.value + ' — Panduan Parkir'
        }
        if (s.key === 'app_favicon' && s.value) {
          let link = document.querySelector("link[rel~='icon']")
          if (!link) { link = document.createElement('link'); link.rel = 'icon'; document.head.appendChild(link) }
          link.href = s.value
        }
      })
    }
  } catch (err) {
    console.error('Fetch map settings error:', err)
  }
}

function startGpsTracking() {
  // Kalau fake GPS aktif, skip real GPS
  if (fakeGps.value.active) {
    userLat.value = fakeGps.value.lat
    userLng.value = fakeGps.value.lng
    return
  }

  // Real GPS tracking
  if ('geolocation' in navigator) {
    // Get initial position first
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        userLat.value = pos.coords.latitude
        userLng.value = pos.coords.longitude
      },
      () => {
        console.warn('GPS initial position failed, using default')
      },
      { enableHighAccuracy: true, timeout: 5000 }
    )

    // Then watch continuously
    gpsWatchId = navigator.geolocation.watchPosition(
      (pos) => {
        userLat.value = pos.coords.latitude
        userLng.value = pos.coords.longitude
      },
      (err) => {
        console.warn('GPS watch error:', err.message)
      },
      { enableHighAccuracy: true, timeout: 15000, maximumAge: 3000 }
    )
  }
}

// ===== SLOT LOCKING & REROUTE =====

function getDistance(lat1, lng1, lat2, lng2) {
  // Haversine formula
  const R = 6371e3 // meters
  const toRad = deg => deg * Math.PI / 180
  const dLat = toRad(lat2 - lat1)
  const dLng = toRad(lng2 - lng1)
  const a = Math.sin(dLat/2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng/2) ** 2
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
}

function getUserPosition() {
  // GPS udah didapet dari gate, pake userLat/userLng yang udah di-set
  return { lat: userLat.value, lng: userLng.value }
}

async function lockNearestSlot(ticketId) {
  try {
    console.log('[LOCK] Start lockNearestSlot, ticketId:', ticketId)
    
    // 0. Kalau tiket udah parked/exiting, ga perlu lock
    if (ticket.value && (ticket.value.status === 'parked' || ticket.value.status === 'exiting')) {
      console.log('[LOCK] Skip: ticket status is', ticket.value.status)
      return
    }

    // 1. Cek apakah tiket ini udah punya lock
    const { data: myLocks, error: lockErr } = await supabase
      .from('parking_slots')
      .select('*')
      .eq('locked_by', ticketId)

    console.log('[LOCK] Step 1 - myLocks:', myLocks?.length, 'error:', lockErr?.message)

    if (myLocks && myLocks.length > 0) {
      lockedSlot.value = myLocks[0]
      console.log('[LOCK] Already locked:', myLocks[0].name, 'status:', myLocks[0].status)
      // Kalau slot udah occupied tapi masih locked_by kita, langsung auto-park
      if (myLocks[0].status === 'occupied') {
        console.log('[LOCK] Slot already occupied! Auto-parking.')
        handleOccupiedYes()
      } else {
        // Start watching + idle timer (includes different slot button)
        watchLockedSlot()
        startIdleTimer()
      }
      return
    }

    // 2. Fetch all slots
    const { data: allSlots, error: allErr } = await supabase
      .from('parking_slots')
      .select('*')

    console.log('[LOCK] Step 2 - allSlots:', allSlots?.length, 'error:', allErr?.message)

    if (!allSlots || allSlots.length === 0) {
      console.log('[LOCK] No slots in DB!')
      return
    }

    // Clear stale locks
    for (const slot of allSlots) {
      if (!slot.locked_by) continue
      const { data: t } = await supabase
        .from('tickets')
        .select('status')
        .eq('id', slot.locked_by)
        .maybeSingle()
      
      if (!t || t.status !== 'active') {
        await supabase
          .from('parking_slots')
          .update({ locked_by: null })
          .eq('id', slot.id)
        slot.locked_by = null
      }
    }

    // 3. Ambil slot available yang ga di-lock
    const freeSlots = allSlots.filter(s => s.status === 'available' && !s.locked_by)

    console.log('[LOCK] Step 3 - freeSlots:', freeSlots.length, 'of', allSlots.length, 'total')
    console.log('[LOCK] All slot statuses:', allSlots.map(s => `${s.name}:${s.status}:${s.locked_by || 'null'}`))

    if (freeSlots.length === 0) {
      console.log('[LOCK] No free slots!')
      return
    }

    // 4. Cari terdekat dari GPS user
    let bestSlot = freeSlots[0]
    const slotsWithGps = freeSlots.filter(s => s.lat && s.lng)
    
    if (slotsWithGps.length > 0 && userLat.value && userLng.value) {
      slotsWithGps.sort((a, b) => {
        return getDistance(userLat.value, userLng.value, parseFloat(a.lat), parseFloat(a.lng)) -
               getDistance(userLat.value, userLng.value, parseFloat(b.lat), parseFloat(b.lng))
      })
      bestSlot = slotsWithGps[0]
    }

    // 5. Lock!
    await supabase
      .from('parking_slots')
      .update({ locked_by: ticketId, updated_at: new Date().toISOString() })
      .eq('id', bestSlot.id)

    lockedSlot.value = bestSlot
    lockedSlot.value.updated_at = new Date().toISOString() // set lock time
    console.log('[LOCK] Slot locked:', bestSlot.id, bestSlot.name)
    
    // Start watching + idle timer (includes different slot button at 50%)
    watchLockedSlot()
    startIdleTimer()
  } catch (err) {
    console.error('Lock nearest slot error:', err)
  }
}

// ===== IDLE LOCK TIMER =====

function startIdleTimer() {
  clearIdleTimer()
  
  // Hitung waktu dari KAPAN slot di-lock (updated_at di DB)
  // Kalau refresh, timer lanjut dari sisa waktu, bukan dari 0
  const lockTime = lockedSlot.value?.updated_at 
    ? new Date(lockedSlot.value.updated_at).getTime() 
    : Date.now()
  
  const totalMs = idleTimeout.value * 60 * 1000
  const elapsed = Date.now() - lockTime
  const remainingMs = totalMs - elapsed
  const halfMs = (totalMs / 2) - elapsed // 50% untuk tombol "slot berbeda"
  
  console.log('[IDLE] Timer started. idle_timeout:', idleTimeout.value, 'menit. Elapsed:', Math.round(elapsed/1000), 's. Remaining:', Math.round(remainingMs/1000), 's')

  // Tombol "parkir di slot berbeda" muncul di 50% waktu
  showDifferentSlotButton.value = halfMs <= 0
  if (halfMs > 0) {
    if (differentSlotTimer) clearTimeout(differentSlotTimer)
    differentSlotTimer = setTimeout(() => {
      showDifferentSlotButton.value = true
      console.log('[IDLE] Different slot button shown')
    }, halfMs)
  }

  // Popup idle muncul setelah full timeout - HANYA kalau masih active
  if (remainingMs <= 0) {
    if (ticket.value?.status === 'active') {
      showIdlePopup.value = true
      idleCountdown.value = 60
      idleCountdownTimer = setInterval(() => {
        idleCountdown.value--
        if (idleCountdown.value <= 0) handleIdleNo()
      }, 1000)
    }
  } else {
    idleTimer = setTimeout(() => {
      // Guard: cek status masih active
      if (ticket.value?.status !== 'active') return
      console.log('[IDLE] Timer fired! Showing popup')
      showIdlePopup.value = true
      idleCountdown.value = 60
      idleCountdownTimer = setInterval(() => {
        idleCountdown.value--
        if (idleCountdown.value <= 0) handleIdleNo()
      }, 1000)
    }, remainingMs)
  }
}

function clearIdleTimer() {
  if (idleTimer) { clearTimeout(idleTimer); idleTimer = null }
  if (idleCountdownTimer) { clearInterval(idleCountdownTimer); idleCountdownTimer = null }
  showIdlePopup.value = false
  idleCountdown.value = 0
}

async function handleIdleYes() {
  // User masih mau parkir → cari slot baru, lock lagi
  clearIdleTimer()
  
  // Unlock slot lama
  if (lockedSlot.value) {
    await supabase
      .from('parking_slots')
      .update({ locked_by: null })
      .eq('id', lockedSlot.value.id)
    lockedSlot.value = null
  }
  
  // Lock slot baru terdekat
  await lockNearestSlot(ticket.value.id)
  
  // Reset idle timer
  if (lockedSlot.value) {
    startIdleTimer()
  }
}

async function handleIdleNo() {
  // User ga jadi parkir → unlock slot, masuk exit mode
  clearIdleTimer()
  
  // Unlock slot
  if (lockedSlot.value) {
    await supabase
      .from('parking_slots')
      .update({ locked_by: null })
      .eq('id', lockedSlot.value.id)
    lockedSlot.value = null
  }
  
  // Masuk exit mode - navigasi ke pintu keluar
  enterExitMode()
}

async function enterExitMode(skipDbUpdate = false) {
  exitMode.value = true
  clearIdleTimer()
  
  // Update status tiket ke 'exiting' dan slot jadi available
  if (ticket.value && !skipDbUpdate) {
    ticket.value.status = 'exiting'
    await supabase
      .from('tickets')
      .update({ status: 'exiting' })
      .eq('id', ticket.value.id)
  }

  // Slot jadi available (mobil udah keluar dari slot)
  if (lockedSlot.value && lockedSlot.value.name !== 'EXIT' && lockedSlot.value.id && !skipDbUpdate) {
    await supabase
      .from('parking_slots')
      .update({ status: 'available', locked_by: null })
      .eq('id', lockedSlot.value.id)
  }

  // Fetch semua gate keluar dari DB
  const { data: gates } = await supabase
    .from('exit_gates')
    .select('*')

  if (gates && gates.length > 0) {
    // Cari gate terdekat dari posisi user
    const gatesWithCoords = gates.filter(g => g.lat && g.lng)
    let nearestGate = gatesWithCoords[0] || gates[0]

    if (gatesWithCoords.length > 0 && userLat.value && userLng.value) {
      gatesWithCoords.sort((a, b) => {
        return getDistance(userLat.value, userLng.value, parseFloat(a.lat), parseFloat(a.lng)) -
               getDistance(userLat.value, userLng.value, parseFloat(b.lat), parseFloat(b.lng))
      })
      nearestGate = gatesWithCoords[0]
    }

    lockedSlot.value = {
      name: `Gate ${nearestGate.gate_number}`,
      lat: parseFloat(nearestGate.lat),
      lng: parseFloat(nearestGate.lng)
    }
  } else {
    lockedSlot.value = null
  }

  // Generate QR barcode untuk keluar
  if (ticket.value) {
    const QRCode = (await import('qrcode')).default
    qrExitUrl.value = await QRCode.toDataURL(ticket.value.ticket_code, {
      width: 200,
      margin: 2,
      color: { dark: '#0f172a', light: '#ffffff' }
    })
  }
}

// ===== REROUTE =====

async function reroute(ticketId) {
  isRerouting.value = true
  console.log('🔄 Rerouting: locked slot is occupied, finding new slot...')

  try {
    // 1. Unlock slot lama
    if (lockedSlot.value) {
      await supabase
        .from('parking_slots')
        .update({ locked_by: null })
        .eq('id', lockedSlot.value.id)
    }

    lockedSlot.value = null

    // 2. Lock slot baru yang terdekat
    await lockNearestSlot(ticketId)

    isRerouting.value = false
  } catch (err) {
    console.error('Reroute error:', err)
    isRerouting.value = false
  }
}

// Subscribe ke realtime changes untuk reroute otomatis
let slotWatchChannel = null

let slotPollInterval = null

function watchLockedSlot() {
  if (!ticket.value || !lockedSlot.value) return
  
  // Hapus channel lama
  if (slotWatchChannel) supabase.removeChannel(slotWatchChannel)
  if (slotPollInterval) clearInterval(slotPollInterval)
  
  const slotId = lockedSlot.value.id

  // Method 1: Supabase Realtime
  slotWatchChannel = supabase
    .channel(`slot-watch-${slotId}-${Date.now()}`)
    .on('postgres_changes', {
      event: 'UPDATE',
      schema: 'public',
      table: 'parking_slots',
      filter: `id=eq.${slotId}`
    }, (payload) => {
      if (ticket.value?.status !== 'active') return
      
      const { status, locked_by } = payload.new
      
      // LOGIC PENCEGAHAN: Cek kepemilikan lock
      if (locked_by !== ticket.value.id) {
        console.log('[STOLEN] Lock changed or taken by someone else')
        handleStolen()
        return
      }

      // Lock masih milik saya, tapi terdeteksi terisi
      if (status === 'occupied') {
        console.log('[AUTO-PARK] Slot detected occupied and still locked by me. Auto-confirming.')
        handleOccupiedYes()
      }
    })
    .subscribe()

  // Method 2: Polling fallback (tiap 2 detik)
  slotPollInterval = setInterval(async () => {
    if (!lockedSlot.value || !ticket.value || ticket.value.status !== 'active') {
      return
    }
    
    const { data } = await supabase
      .from('parking_slots')
      .select('status, locked_by')
      .eq('id', slotId)
      .maybeSingle()
    
    if (data) {
      // LOGIC PENCEGAHAN: Cek kepemilikan lock
      if (data.locked_by !== ticket.value.id) {
        handleStolen()
        return
      }
      
      if (data.status === 'occupied') {
        console.log('[AUTO-PARK-POLL] Slot detected occupied and still locked by me. Auto-confirming.')
        handleOccupiedYes()
      }
    }
  }, 2000)
}

async function handleStolen() {
  console.log('🚨 Slot stolen! Initiating auto-reroute.')
  clearIdleTimer()
  if (slotPollInterval) clearInterval(slotPollInterval)
  if (slotWatchChannel) supabase.removeChannel(slotWatchChannel)
  
  showStolenPopup.value = true
  
  // Kasih waktu user baca pesan (3 detik) lalu cari slot baru
  setTimeout(async () => {
    showStolenPopup.value = false
    lockedSlot.value = null
    await lockNearestSlot(ticket.value.id)
  }, 3000)
}

// ===== WATCH TICKET STATUS (auto selesai dari gate) =====
let ticketWatchChannel = null

function watchTicketStatus() {
  if (!ticket.value || !ticket.value.id) return
  
  ticketWatchChannel = supabase
    .channel(`ticket-status-${ticket.value.id}`)
    .on('postgres_changes', {
      event: 'UPDATE',
      schema: 'public',
      table: 'tickets',
      filter: `id=eq.${ticket.value.id}`
    }, (payload) => {
      // Ticket status berubah jadi 'done' dari gate
      if (payload.new.status === 'done') {
        ticket.value.status = 'done'
        ticket.value.exited_at = payload.new.exited_at
        clearIdleTimer()
        if (timerInterval) clearInterval(timerInterval)
        state.value = 'done'
        
        // Fetch session untuk summary
        fetchSessionSummary()
      }
    })
    .subscribe()
}

async function fetchSessionSummary() {
  if (!ticket.value) return
  const { data } = await supabase
    .from('sessions')
    .select('*, slot:parking_slots(name)')
    .eq('ticket_id', ticket.value.id)
    .order('entry_time', { ascending: false })
    .limit(1)

  if (data && data.length > 0) {
    session.value = data[0]
  }
}

// ===== OCCUPIED POPUP HANDLERS =====

async function handleOccupiedYes() {
  // Auto-confirm: saya sudah parkir di slot ini
  clearIdleTimer()
  showDifferentSlotButton.value = false
  if (slotPollInterval) clearInterval(slotPollInterval)
  if (slotWatchChannel) supabase.removeChannel(slotWatchChannel)
  const now = new Date().toISOString()

  // Clear lock
  if (lockedSlot.value && lockedSlot.value.id) {
    await supabase
      .from('parking_slots')
      .update({ locked_by: null })
      .eq('id', lockedSlot.value.id)
  }

  // Update tiket jadi parked
  await supabase
    .from('tickets')
    .update({ status: 'parked', parked_at: now })
    .eq('id', ticket.value.id)

  // Buat session
  await supabase
    .from('sessions')
    .insert([{
      ticket_id: ticket.value.id,
      slot_id: lockedSlot.value.id,
      entry_time: now
    }])

  ticket.value.status = 'parked'
  ticket.value.parked_at = now
  session.value = { slot: { name: lockedSlot.value.name }, entry_time: now }
}

async function handleOccupiedDifferentSlot() {
  if (!differentSlotInput.value) return
  const slotName = differentSlotInput.value.trim().toUpperCase()
  const now = new Date().toISOString()

  try {
    // Cari slot by name
    const { data: targetSlot, error: searchError } = await supabase
      .from('parking_slots')
      .select('*')
      .eq('name', slotName)
      .maybeSingle()

    if (searchError) throw searchError
    if (!targetSlot) {
      alert(`Slot "${slotName}" tidak ditemukan. Pastikan nama slot benar (contoh: A1).`)
      return
    }

    // Jika ketemu, baru mulai proses update
    showDifferentSlotInput.value = false
    clearIdleTimer()
    showDifferentSlotButton.value = false
    if (slotPollInterval) clearInterval(slotPollInterval)
    if (slotWatchChannel) supabase.removeChannel(slotWatchChannel)

  // Clear lock lama
  if (lockedSlot.value && lockedSlot.value.id) {
    await supabase
      .from('parking_slots')
      .update({ locked_by: null })
      .eq('id', lockedSlot.value.id)
  }

  // Set slot baru jadi occupied
  await supabase
    .from('parking_slots')
    .update({ status: 'occupied', locked_by: null, updated_at: now })
    .eq('id', targetSlot.id)

  // Update tiket jadi parked
  await supabase
    .from('tickets')
    .update({ status: 'parked', parked_at: now })
    .eq('id', ticket.value.id)

  // Buat session
  await supabase
    .from('sessions')
    .insert([{
      ticket_id: ticket.value.id,
      slot_id: targetSlot.id,
      entry_time: now
    }])

    ticket.value.status = 'parked'
    ticket.value.parked_at = now
    lockedSlot.value = targetSlot
    session.value = { slot: { name: targetSlot.name }, entry_time: now }
    differentSlotInput.value = ''
    
    console.log('[DIFFERENT-SLOT] Successfully parked in', targetSlot.name)
  } catch (err) {
    console.error('Error in handleOccupiedDifferentSlot:', err)
    alert('Gagal mengonfirmasi slot. Silakan coba lagi.')
  }
}

// ===== END SLOT LOCKING =====

async function confirmParking() {
  if (!ticket.value || confirmingParking.value) return
  
  clearIdleTimer() // Stop idle timer - user parkir
  confirmingParking.value = true
  
  try {
    // Pakai locked slot kalau ada, kalau ga ada cari baru
    const targetSlot = lockedSlot.value
    
    if (!targetSlot) {
      confirmingParking.value = false
      return
    }
    
    // 1. Update slot jadi occupied dan clear lock
    await supabase
      .from('parking_slots')
      .update({ status: 'occupied', locked_by: null, updated_at: new Date().toISOString() })
      .eq('id', targetSlot.id)
    
    // 2. Update ticket status jadi parked
    await supabase
      .from('tickets')
      .update({ 
        status: 'parked', 
        parked_at: new Date().toISOString() 
      })
      .eq('id', ticket.value.id)
    
    // 3. Create session
    const { data: newSession } = await supabase
      .from('sessions')
      .insert([{
        ticket_id: ticket.value.id,
        slot_id: targetSlot.id,
        entry_time: new Date().toISOString()
      }])
      .select('*, slot:parking_slots(name)')
      .single()
    
    // 5. Update local state
    ticket.value.status = 'parked'
    ticket.value.parked_at = new Date().toISOString()
    session.value = newSession
    
    // Timer udah jalan dari created_at, jangan reset
    
    confirmingParking.value = false
    
  } catch (err) {
    console.error('Confirm parking error:', err)
    alert('Gagal konfirmasi parkir: ' + err.message)
    confirmingParking.value = false
  }
}

// Debug functions
async function debugFakeScanQR() {
  // Simulasi: visitor buka halaman tiket pertama kali (active → cari slot)
  if (!ticket.value) return
  ticket.value.status = 'active'
  state.value = 'valid'
  await fetchAllSlots()
  await lockNearestSlot(ticket.value.id)
  if (lockedSlot.value) {
    watchLockedSlot()
    startIdleTimer()
  }
}

async function debugFakeParked() {
  // Simulasi: sensor deteksi mobil → auto-park (sama persis flow handleOccupiedYes)
  if (!ticket.value || ticket.value.status !== 'active') return
  await handleOccupiedYes()
}

async function debugFakeDone() {
  // Simulasi: klik "Saya ingin keluar parkir" (enterExitMode)
  if (!ticket.value || ticket.value.status !== 'parked') return
  enterExitMode()
}

async function debugSimulateStolen() {
  // Simulasi: slot diambil user lain → locked_by dikosongkan
  // watchLockedSlot akan detect locked_by bukan milik kita → auto-reroute
  if (!lockedSlot.value || !lockedSlot.value.id || ticket.value?.status !== 'active') return
  await supabase
    .from('parking_slots')
    .update({ locked_by: null, status: 'occupied', updated_at: new Date().toISOString() })
    .eq('id', lockedSlot.value.id)
  console.log('[DEBUG] Slot stolen simulated. Waiting for handleStolen...')
}

function debugSimulateIdle() {
  // Langsung trigger idle popup tanpa nunggu timer
  if (ticket.value?.status !== 'active') return
  clearIdleTimer()
  showIdlePopup.value = true
  idleCountdown.value = 60
  if (idleCountdownTimer) clearInterval(idleCountdownTimer)
  idleCountdownTimer = setInterval(() => {
    idleCountdown.value--
    if (idleCountdown.value <= 0) handleIdleNo()
  }, 1000)
}

async function debugUnlockAll() {
  // Clear SEMUA locked_by di parking_slots
  await supabase
    .from('parking_slots')
    .update({ locked_by: null, status: 'available' })
    .neq('id', '00000000-0000-0000-0000-000000000000') // match all rows
  
  lockedSlot.value = null
  await fetchAllSlots()
  console.log('[DEBUG] All slots unlocked & set available')
}

async function debugResetTicket() {
  // Reset SEMUA: unlock slot, tiket ke active, hapus session, timer dari 0. Fresh start.
  await debugUnlockAll()
  
  const now = new Date().toISOString()
  
  // Reset tiket ke active
  if (ticket.value && ticket.value.id) {
    await supabase
      .from('tickets')
      .update({ status: 'active', parked_at: null, exited_at: null, created_at: now })
      .eq('id', ticket.value.id)
    
    ticket.value.status = 'active'
    ticket.value.parked_at = null
    ticket.value.exited_at = null
    ticket.value.created_at = now
  }
  
  // Hapus session
  if (ticket.value?.id) {
    await supabase.from('sessions').delete().eq('ticket_id', ticket.value.id)
  }
  session.value = null
  
  // Reset semua state
  clearIdleTimer()
  if (timerInterval) clearInterval(timerInterval)
  if (slotPollInterval) clearInterval(slotPollInterval)
  if (slotWatchChannel) supabase.removeChannel(slotWatchChannel)
  if (differentSlotTimer) clearTimeout(differentSlotTimer)
  elapsedSeconds.value = 0
  exitMode.value = false
  showStolenPopup.value = false
  showIdlePopup.value = false
  showDifferentSlotButton.value = false
  showDifferentSlotInput.value = false
  differentSlotInput.value = ''
  qrExitUrl.value = null
  state.value = 'valid'
  lockedSlot.value = null
  
  // Lock slot baru + start idle timer + start elapsed timer
  await lockNearestSlot(ticket.value.id)
  if (lockedSlot.value) {
    watchLockedSlot()
    startIdleTimer()
  }
  startTimer(now)
  
  console.log('[DEBUG] Full reset done. Locked:', lockedSlot.value?.name)
}

function toggleFakeGps() {
  fakeGps.value.active = !fakeGps.value.active
  if (fakeGps.value.active) {
    // Fake GPS ON: stop real GPS, use joystick
    if (gpsWatchId) {
      navigator.geolocation.clearWatch(gpsWatchId)
      gpsWatchId = null
    }
    // Set start position
    userLat.value = fakeGps.value.lat
    userLng.value = fakeGps.value.lng
  } else {
    // Fake GPS OFF: start real GPS tracking
    startGpsTracking()
  }
}

onMounted(async () => {
  // Ambil nama aplikasi dan favicon untuk tampilan awal
  const { data } = await supabase.from('settings').select('key, value')
  if (data) {
    data.forEach(s => {
      if (s.key === 'app_name') {
        appName.value = s.value || 'SmartPark'
        document.title = appName.value + ' — Panduan Parkir'
      }
      if (s.key === 'app_favicon' && s.value) {
        let link = document.querySelector("link[rel~='icon']")
        if (!link) { link = document.createElement('link'); link.rel = 'icon'; document.head.appendChild(link) }
        link.href = s.value
      }
      if (s.key === 'idle_timeout') idleTimeout.value = parseInt(s.value) || 20
      if (s.key === 'exit_cooldown') exitCooldownMinutes.value = parseInt(s.value) || 5
      if (s.key === 'map_engine') mapEngine.value = s.value || 'maplibre'
      if (s.key === 'nav_line_color') navLineColor.value = s.value || '#4285F4'
    })
  }

  // Realtime settings listener
  settingsChannel = supabase.channel('public:settings')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'settings' }, payload => {
      const { key, value } = payload.new
      if (key === 'app_name') {
        appName.value = value || 'SmartPark'
        document.title = appName.value + ' — Panduan Parkir'
      }
      if (key === 'app_favicon' && value) {
        let link = document.querySelector("link[rel~='icon']")
        if (!link) { link = document.createElement('link'); link.rel = 'icon'; document.head.appendChild(link) }
        link.href = value
      }
      if (key === 'idle_timeout') {
        idleTimeout.value = parseInt(value) || 20
        // Restart idle timer if active
        if (ticket.value?.status === 'active' && lockedSlot.value) {
          startIdleTimer()
        }
      }
      if (key === 'exit_cooldown') exitCooldownMinutes.value = parseInt(value) || 5
      if (key === 'map_engine') mapEngine.value = value || 'maplibre'
      if (key === 'nav_line_color') navLineColor.value = value || '#4285F4'
    })
    .subscribe()

  // Ga auto-load lokasi. User HARUS klik "Aktifkan GPS" dulu.
  // loadTicket() dipanggil dari requestGps() setelah GPS granted.
})
onUnmounted(() => {
  if (timerInterval) clearInterval(timerInterval)
  if (slotWatchChannel) supabase.removeChannel(slotWatchChannel)
  if (slotPollInterval) clearInterval(slotPollInterval)
  if (ticketWatchChannel) supabase.removeChannel(ticketWatchChannel)
  if (settingsChannel) supabase.removeChannel(settingsChannel)
  if (gpsWatchId) navigator.geolocation.clearWatch(gpsWatchId)
  if (differentSlotTimer) clearTimeout(differentSlotTimer)
  clearIdleTimer()
})
</script>

<style scoped>
/* ============================================
   VISITOR PAGE — Mobile First Light Theme
   ============================================ */
.visitor-page {
  min-height: 100vh;
  background: #f8fafc;
  color: #0f172a;
  font-family: var(--font);
  max-width: 430px;
  margin: 0 auto;
}

/* ---- State Views (loading / error / etc) ---- */
.v-state {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40px 28px;
  text-align: center;
  gap: 16px;
}

.v-icon-wrap {
  width: 72px; height: 72px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 8px;
}
.v-icon-warn  { background: #fef9c3; color: #ca8a04; }
.v-icon-error { background: #fee2e2; color: #dc2626; }
.v-icon-gps { background: #dbeafe; color: #3b82f6; }

.btn-allow-gps {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 14px 28px;
  background: linear-gradient(135deg, #3b82f6, #2563eb);
  border: none;
  border-radius: 12px;
  color: white;
  font-size: 16px;
  font-weight: 700;
  cursor: pointer;
  box-shadow: 0 4px 12px rgba(59,130,246,0.3);
  transition: all 0.2s;
  margin-top: 8px;
}

.btn-allow-gps:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(59,130,246,0.4);
}
.v-icon-success { background: #dcfce7; color: #16a34a; }

.v-state-title {
  font-size: 22px;
  font-weight: 800;
  color: #0f172a;
  letter-spacing: -0.02em;
}

.v-state-desc {
  font-size: 14.5px;
  color: #64748b;
  max-width: 280px;
  line-height: 1.6;
}

/* Spinner */
.v-spinner {
  width: 56px; height: 56px;
  animation: spin 1.2s linear infinite;
}
.v-spinner-ring {
  width: 100%; height: 100%;
}
.v-spinner-ring circle {
  stroke: #6366f1;
  stroke-dasharray: 80;
  stroke-dashoffset: 60;
  stroke-linecap: round;
}

.v-loading-text {
  font-size: 15px;
  color: #64748b;
  font-weight: 500;
}

.v-done-card {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 14px;
  padding: 16px 20px;
  width: 100%;
  max-width: 280px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.v-done-row {
  display: flex;
  justify-content: space-between;
  font-size: 14px;
  color: #475569;
}
.v-done-row span:last-child { font-weight: 600; color: #0f172a; }

/* ============================================
   MAIN VALID STATE
   ============================================ */
.v-main {
  padding-bottom: 40px;
}

/* Header */
.v-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px 20px;
  background: white;
  border-bottom: 1px solid #f1f5f9;
  position: sticky;
  top: 0;
  z-index: 10;
}

.v-logo {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 15px;
  font-weight: 700;
  color: #0f172a;
}

.v-logo-icon {
  width: 32px; height: 32px;
  background: linear-gradient(135deg, #6366f1, #4f46e5);
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.v-status-badge {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 5px 12px;
  border-radius: 100px;
  font-size: 12px;
  font-weight: 600;
}

.v-badge-dot {
  width: 7px; height: 7px;
  border-radius: 50%;
  background: currentColor;
}

.v-status-active  { background: #eff6ff; color: #3b82f6; }
.v-status-parked  { background: #fefce8; color: #ca8a04; }
.v-status-exiting { background: #fef2f2; color: #dc2626; }
.v-status-done    { background: #f0fdf4; color: #16a34a; }
.v-status-expired { background: #fef2f2; color: #dc2626; }

/* Ticket Card */
.v-ticket-card {
  margin: 20px 16px;
  background: linear-gradient(145deg, #0f172a, #1e293b);
  border-radius: 18px;
  color: white;
  overflow: hidden;
  box-shadow: 0 8px 32px rgba(15,23,42,0.2);
}

.v-ticket-top {
  padding: 20px 22px 14px;
}

.v-ticket-code {
  font-size: 22px;
  font-weight: 700;
  color: #a5b4fc;
  letter-spacing: 0.04em;
}

.v-ticket-time {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 12.5px;
  color: #94a3b8;
  margin-top: 4px;
}

.v-ticket-divider {
  display: flex;
  align-items: center;
  gap: 0;
  padding: 0 0;
  position: relative;
}

.v-ticket-notch {
  width: 22px; height: 22px;
  background: #f8fafc;
  border-radius: 50%;
  flex-shrink: 0;
}
.v-ticket-notch.left  { margin-left: -11px; }
.v-ticket-notch.right { margin-right: -11px; }

.v-ticket-dashes {
  flex: 1;
  height: 1px;
  background: repeating-linear-gradient(
    90deg,
    rgba(255,255,255,0.15) 0px,
    rgba(255,255,255,0.15) 8px,
    transparent 8px,
    transparent 14px
  );
}

.v-ticket-bottom {
  padding: 14px 22px 20px;
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
}

.v-ticket-info {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.v-info-item {
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.v-info-label {
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.07em;
  color: #475569;
}

.v-info-val {
  font-size: 14px;
  font-weight: 600;
  color: #f1f5f9;
}

.v-ticket-duration {
  text-align: right;
}

.v-duration-num {
  display: block;
  font-size: 26px;
  font-weight: 800;
  color: #fbbf24;
  line-height: 1;
  font-family: var(--font-mono);
}

.v-duration-label {
  font-size: 10px;
  text-transform: uppercase;
  color: #64748b;
  letter-spacing: 0.06em;
}

/* Map Section */
.v-map-section {
  margin: 0 16px 20px;
}

.v-map-header {
  margin-bottom: 12px;
}

.v-section-title {
  display: flex;
  align-items: center;
  gap: 7px;
  font-size: 15px;
  font-weight: 700;
  color: #0f172a;
}

.v-section-desc {
  font-size: 13px;
  color: #64748b;
  margin-top: 2px;
}

/* Confirm Parking Section */
.confirm-parking-section {
  margin-bottom: 20px;
  text-align: center;
}

/* Locked Slot Card */
.locked-slot-card {
  margin-bottom: 16px;
  padding: 16px;
  background: linear-gradient(135deg, #f0fdf4, #dcfce7);
  border: 2px solid #10b981;
  border-radius: 14px;
  text-align: center;
}

.locked-slot-card.locked-slot-empty {
  background: #fef2f2;
  border-color: #ef4444;
  color: #dc2626;
  font-size: 14px;
  font-weight: 600;
}

.locked-slot-header {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  font-size: 13px;
  color: #059669;
  font-weight: 600;
  margin-bottom: 6px;
}

.reroute-text {
  color: #d97706;
  animation: pulse 1s ease infinite;
}

.locked-slot-name {
  font-size: 36px;
  font-weight: 900;
  color: #059669;
  font-family: var(--font-mono);
  line-height: 1;
  margin-bottom: 6px;
}

.locked-slot-hint {
  font-size: 12px;
  color: #64748b;
}

.nav-info {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 10px 16px;
  background: #f0fdf4;
  border: 1px solid #10b981;
  border-radius: 10px;
  margin-top: 10px;
  font-size: 13px;
  color: #059669;
  font-weight: 500;
}

.nav-info-exit {
  background: #fef2f2;
  border-color: #ef4444;
  color: #dc2626;
}

.btn-exit-parking {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  width: 100%;
  padding: 14px 16px;
  margin-top: 10px;
  background: #fef2f2;
  border: 2px solid #ef4444;
  border-radius: 12px;
  color: #dc2626;
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-exit-parking:hover:not(.btn-exit-disabled) {
  background: #ef4444;
  color: white;
}

.btn-exit-parking.btn-exit-disabled {
  background: #f8fafc;
  border-color: #e2e8f0;
  color: #94a3b8;
  cursor: not-allowed;
}

.exit-card {
  margin-top: 16px;
  padding: 24px 20px;
  background: white;
  border: 2px solid #0f172a;
  border-radius: 16px;
  text-align: center;
  box-shadow: 0 4px 16px rgba(0,0,0,0.1);
}

.exit-barcode {
  display: inline-flex;
  padding: 12px;
  background: white;
  border-radius: 12px;
  margin-bottom: 12px;
}

.exit-barcode-img {
  width: 160px;
  height: 160px;
}

.exit-ticket-code {
  font-size: 18px;
  font-weight: 800;
  color: #0f172a;
  font-family: var(--font-mono);
  letter-spacing: 0.04em;
  margin-bottom: 8px;
}

.exit-instruction {
  font-size: 14px;
  font-weight: 600;
  color: #dc2626;
  background: #fef2f2;
  padding: 10px 16px;
  border-radius: 8px;
  border: 1px solid #fecaca;
}

.btn-confirm-parking {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 14px 28px;
  background: linear-gradient(135deg, #10b981, #059669);
  border: none;
  border-radius: 12px;
  color: white;
  font-size: 15px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s;
  box-shadow: 0 4px 12px rgba(16,185,129,0.3);
  width: 100%;
  max-width: 320px;
}

.btn-confirm-parking:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(16,185,129,0.4);
}

.btn-confirm-parking:active:not(:disabled) {
  transform: translateY(0);
}

.btn-confirm-parking:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.spinner-sm {
  width: 16px;
  height: 16px;
  border: 2px solid rgba(255,255,255,0.3);
  border-top-color: white;
  border-radius: 50%;
  animation: spin 0.7s linear infinite;
}

.confirm-hint {
  font-size: 12px;
  color: #64748b;
  margin-top: 8px;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.v-map-placeholder {
  height: 200px;
  background: linear-gradient(145deg, #e2e8f0, #f1f5f9);
  border-radius: 16px;
  position: relative;
  overflow: hidden;
  margin-bottom: 12px;
}

.v-map-grid {
  position: absolute;
  inset: 0;
  background-image:
    linear-gradient(rgba(99,102,241,0.07) 1px, transparent 1px),
    linear-gradient(90deg, rgba(99,102,241,0.07) 1px, transparent 1px);
  background-size: 32px 32px;
}

.v-map-overlay {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 6px;
  z-index: 1;
}

.v-map-icon {
  width: 64px; height: 64px;
  background: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #6366f1;
  box-shadow: 0 4px 16px rgba(99,102,241,0.2);
  animation: pulse 2.5s ease infinite;
}

.v-map-text {
  font-size: 15px;
  font-weight: 700;
  color: #334155;
}

.v-map-subtext {
  font-size: 12px;
  color: #94a3b8;
}

/* Slot List */
.v-slots-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.v-slot-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
}

.v-slot-best {
  border-color: #a5b4fc;
  background: #f5f3ff;
}

.v-slot-rank {
  font-size: 18px;
  width: 32px;
  text-align: center;
  flex-shrink: 0;
  font-weight: 700;
  color: #94a3b8;
}

.v-slot-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.v-slot-name {
  font-size: 14px;
  font-weight: 600;
  color: #0f172a;
}

.v-slot-dist {
  font-size: 12px;
  color: #94a3b8;
}

.v-slot-status {
  font-size: 12px;
  font-weight: 600;
  padding: 3px 10px;
  border-radius: 100px;
}

.v-slot-available { background: #dcfce7; color: #16a34a; }
.v-slot-occupied  { background: #fee2e2; color: #dc2626; }

/* Help section */
.v-help {
  margin: 0 16px;
  display: flex;
  flex-direction: column;
  gap: 0;
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  overflow: hidden;
}

.v-help-item {
  display: flex;
  align-items: flex-start;
  gap: 14px;
  padding: 14px 16px;
  border-bottom: 1px solid #f1f5f9;
}

.v-help-item:last-child { border-bottom: none; }

.v-help-icon {
  width: 36px; height: 36px;
  background: #f1f5f9;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #6366f1;
  flex-shrink: 0;
}

.v-help-title {
  font-size: 13.5px;
  font-weight: 600;
  color: #0f172a;
}

.v-help-desc {
  font-size: 12.5px;
  color: #64748b;
  margin-top: 2px;
}

/* Font mono utility for this scope */
.font-mono { font-family: var(--font-mono); }

/* Idle Popup */
.idle-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.7);
  backdrop-filter: blur(6px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
  padding: 24px;
}

.idle-popup {
  background: white;
  border-radius: 20px;
  padding: 32px 28px;
  max-width: 340px;
  width: 100%;
  text-align: center;
  box-shadow: 0 20px 60px rgba(0,0,0,0.3);
}

.idle-icon {
  color: #f59e0b;
  margin-bottom: 16px;
}

.idle-popup h3 {
  font-size: 20px;
  font-weight: 800;
  color: #0f172a;
  margin-bottom: 10px;
}

.idle-popup p {
  font-size: 14px;
  color: #64748b;
  line-height: 1.6;
  margin-bottom: 20px;
}

.idle-actions {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.idle-btn {
  padding: 14px 24px;
  border-radius: 12px;
  font-size: 15px;
  font-weight: 700;
  border: none;
  cursor: pointer;
  transition: all 0.2s;
}

.idle-btn-yes {
  background: linear-gradient(135deg, #10b981, #059669);
  color: white;
  box-shadow: 0 4px 12px rgba(16,185,129,0.3);
}

.idle-btn-yes:hover {
  transform: translateY(-1px);
  box-shadow: 0 6px 16px rgba(16,185,129,0.4);
}

.idle-btn-no {
  background: #f1f5f9;
  color: #64748b;
}

.idle-btn-no:hover {
  background: #e2e8f0;
  color: #0f172a;
}

/* Different Slot Button (di bawah map) */
.different-slot-section {
  margin-top: 10px;
}

.btn-different-slot {
  width: 100%;
  padding: 12px 16px;
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  color: #64748b;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-different-slot:hover {
  background: #f8fafc;
  border-color: #6366f1;
  color: #6366f1;
}

.different-slot-form {
  display: flex;
  gap: 8px;
  align-items: center;
}

.different-slot-field {
  flex: 1;
  padding: 10px 14px;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 700;
  font-family: var(--font-mono);
  text-transform: uppercase;
  text-align: center;
  outline: none;
}

.different-slot-field:focus {
  border-color: #6366f1;
}

.btn-different-confirm {
  padding: 10px 16px;
  background: #10b981;
  border: none;
  border-radius: 8px;
  color: white;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
}

.btn-different-confirm:disabled { opacity: 0.5; }

.btn-different-cancel {
  padding: 10px 16px;
  background: #f1f5f9;
  border: none;
  border-radius: 8px;
  color: #64748b;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
}

.idle-btn-other {
  background: #f1f5f9;
  color: #475569;
}

.idle-btn-other:hover {
  background: #e2e8f0;
  color: #0f172a;
}

.different-slot-input {
  width: 100%;
  margin-bottom: 8px;
}

.different-slot-input input {
  width: 100%;
  padding: 12px 16px;
  border: 2px solid #e2e8f0;
  border-radius: 10px;
  font-size: 16px;
  font-weight: 700;
  font-family: var(--font-mono);
  text-align: center;
  text-transform: uppercase;
  outline: none;
}

.different-slot-input input:focus {
  border-color: #6366f1;
}

/* Debug Panel */
.debug-panel {
  margin: 0 16px 20px;
  background: #1a1625;
  border: 2px dashed #f59e0b;
  border-radius: 16px;
  padding: 16px;
}

.debug-panel-header {
  margin-bottom: 14px;
}

.debug-badge {
  display: inline-block;
  background: rgba(245,158,11,0.15);
  color: #f59e0b;
  font-size: 12px;
  font-weight: 800;
  padding: 4px 12px;
  border-radius: 100px;
  letter-spacing: 0.05em;
}

.debug-actions {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-bottom: 14px;
}

.debug-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 12px 16px;
  background: linear-gradient(135deg, #10b981, #059669);
  border: none;
  border-radius: 10px;
  color: white;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.debug-btn:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(16,185,129,0.3);
}

.debug-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.debug-btn-orange {
  background: linear-gradient(135deg, #f59e0b, #d97706);
}

.debug-btn-orange:hover:not(:disabled) {
  box-shadow: 0 4px 12px rgba(245,158,11,0.3);
}

.debug-btn-blue {
  background: linear-gradient(135deg, #6366f1, #4f46e5);
}

.debug-btn-blue:hover:not(:disabled) {
  box-shadow: 0 4px 12px rgba(99,102,241,0.3);
}

.debug-btn-red {
  background: linear-gradient(135deg, #ef4444, #dc2626);
}

.debug-btn-red:hover:not(:disabled) {
  box-shadow: 0 4px 12px rgba(239,68,68,0.3);
}

/* Fake GPS */
.debug-gps {
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.1);
  border-radius: 10px;
  padding: 12px;
  margin-bottom: 14px;
}

.debug-gps-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 13px;
  font-weight: 600;
  color: #e0e7ff;
}

.debug-gps-toggle {
  padding: 4px 12px;
  border-radius: 100px;
  font-size: 11px;
  font-weight: 700;
  border: none;
  cursor: pointer;
  background: rgba(255,255,255,0.1);
  color: #94a3b8;
  transition: all 0.2s;
}

.debug-gps-toggle.active {
  background: #10b981;
  color: white;
}

.debug-gps-inputs {
  margin-top: 10px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.debug-gps-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.debug-gps-row label {
  font-size: 12px;
  font-weight: 600;
  color: #64748b;
  width: 30px;
}

.debug-gps-row input {
  flex: 1;
  padding: 6px 10px;
  background: rgba(0,0,0,0.3);
  border: 1px solid rgba(255,255,255,0.1);
  border-radius: 6px;
  color: #f1f5f9;
  font-size: 13px;
  font-family: var(--font-mono);
  outline: none;
}

.debug-gps-row input:focus {
  border-color: #6366f1;
}

.debug-gps-info {
  font-size: 11px;
  color: #64748b;
  font-family: var(--font-mono);
  text-align: center;
  margin-top: 4px;
}

/* Debug Info */
.debug-info {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.debug-info-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 12px;
}

.debug-info-row span {
  color: #64748b;
}

.debug-info-row code {
  background: rgba(99,102,241,0.15);
  color: #a5b4fc;
  padding: 2px 8px;
  border-radius: 4px;
  font-family: var(--font-mono);
  font-size: 11px;
}
</style>
