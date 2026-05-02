<template>
  <div class="admin-map-wrap" :class="{ 'admin-map-fullscreen': isFullscreen }">
    <div ref="mapRef" class="admin-map"></div>
    
    <div class="admin-map-controls">
      <button class="btn-map-ctrl" @click="recenterMap" title="Kembali ke semua slot">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>
          <polyline points="9 22 9 12 15 12 15 22"/>
        </svg>
      </button>
      <button class="btn-map-ctrl" @click="toggleFullscreen" :title="isFullscreen ? 'Keluar Fullscreen' : 'Fullscreen'">
        <svg v-if="!isFullscreen" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="15 3 21 3 21 9"/><polyline points="9 21 3 21 3 15"/><line x1="21" y1="3" x2="14" y2="10"/><line x1="3" y1="21" x2="10" y2="14"/>
        </svg>
        <svg v-else width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="4 14 10 14 10 20"/><polyline points="20 10 14 10 14 4"/><line x1="14" y1="10" x2="21" y2="3"/><line x1="3" y1="21" x2="10" y2="14"/>
        </svg>
      </button>
    </div>

    <div class="admin-map-legend">
      <span class="legend-item"><span class="legend-dot green"></span> Kosong</span>
      <span class="legend-item"><span class="legend-dot red"></span> Terisi</span>
      <span class="legend-item"><span class="legend-dot blue"></span> Locked</span>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, watch } from 'vue'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'

const props = defineProps({
  slots: { type: Array, default: () => [] },
  centerLat: { type: Number, default: -7.2650876 },
  centerLng: { type: Number, default: 112.783217 }
})

const mapRef = ref(null)
const isFullscreen = ref(false)
let map = null
let slotLayers = []

function toggleFullscreen() {
  isFullscreen.value = !isFullscreen.value
  setTimeout(() => { if (map) map.invalidateSize() }, 100)
}

const METER_TO_DEG = 0.000009

onMounted(() => {
  // Delay init supaya container udah visible & punya size
  setTimeout(initMap, 100)
})

function initMap() {
  if (!mapRef.value) return

  // Find center from slots or use props default
  let center = [props.centerLat, props.centerLng]
  let zoom = 18
  const slotsWithCoords = props.slots.filter(s => s.lat && s.lng)
  if (slotsWithCoords.length > 0) {
    const avgLat = slotsWithCoords.reduce((sum, s) => sum + parseFloat(s.lat), 0) / slotsWithCoords.length
    const avgLng = slotsWithCoords.reduce((sum, s) => sum + parseFloat(s.lng), 0) / slotsWithCoords.length
    center = [avgLat, avgLng]
  }

  map = L.map(mapRef.value, {
    center,
    zoom,
    zoomControl: true,
    attributionControl: false
  })

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 22
  }).addTo(map)

  // Fix map setengah abu-abu saat tab dibuka
  const resizeObserver = new ResizeObserver(() => {
    if (map) map.invalidateSize()
  })
  resizeObserver.observe(mapRef.value)

  // Force awal
  setTimeout(() => { if (map) map.invalidateSize() }, 300)

  drawSlots()
}

onUnmounted(() => { if (map) map.remove() })

function recenterMap() {
  if (!map) return
  
  const slotsWithCoords = props.slots.filter(s => s.lat && s.lng)
  if (slotsWithCoords.length > 1) {
    const bounds = slotsWithCoords.map(s => [parseFloat(s.lat), parseFloat(s.lng)])
    map.fitBounds(bounds, { padding: [40, 40], maxZoom: 19 })
  } else if (slotsWithCoords.length === 1) {
    map.setView([parseFloat(slotsWithCoords[0].lat), parseFloat(slotsWithCoords[0].lng)], 19)
  } else {
    map.setView([props.centerLat, props.centerLng], 18)
  }
}

function drawSlots() {
  if (!map) return
  
  // Clear old
  slotLayers.forEach(l => map.removeLayer(l))
  slotLayers = []

  props.slots.forEach(slot => {
    if (!slot.lat || !slot.lng) return

    const lat = parseFloat(slot.lat)
    const lng = parseFloat(slot.lng)
    const rotation = parseFloat(slot.rotation || 0)
    const widthM = parseFloat(slot.slot_width || 3)
    const heightM = parseFloat(slot.slot_height || 5)
    const w = (widthM / 2) * METER_TO_DEG
    const h = (heightM / 2) * METER_TO_DEG
    const rad = (rotation * Math.PI) / 180

    // Color based on status
    let color = '#10b981' // available = green
    if (slot.status === 'occupied') color = '#ef4444' // red
    else if (slot.locked_by) color = '#3b82f6' // locked = blue

    const corners = [[-h, -w], [-h, w], [h, w], [h, -w]].map(([dy, dx]) => {
      const ry = dy * Math.cos(rad) - dx * Math.sin(rad)
      const rx = dy * Math.sin(rad) + dx * Math.cos(rad)
      return [lat + ry, lng + rx]
    })

    const poly = L.polygon(corners, {
      color,
      weight: 2,
      fillOpacity: slot.status === 'occupied' ? 0.5 : slot.locked_by ? 0.3 : 0.2,
      fillColor: color
    }).addTo(map)

    // Label permanent di tengah slot
    poly.bindTooltip(slot.name, {
      permanent: true,
      direction: 'center',
      className: 'admin-slot-label'
    })

    slotLayers.push(poly)
  })

  // Fit bounds if slots exist
  const slotsWithCoords = props.slots.filter(s => s.lat && s.lng)
  // Fit bounds ke semua slot yang punya koordinat
  if (slotsWithCoords.length > 1) {
    const bounds = slotsWithCoords.map(s => [parseFloat(s.lat), parseFloat(s.lng)])
    map.fitBounds(bounds, { padding: [40, 40], maxZoom: 19 })
  } else if (slotsWithCoords.length === 1) {
    map.setView([parseFloat(slotsWithCoords[0].lat), parseFloat(slotsWithCoords[0].lng)], 19)
  }
}

watch(() => props.slots, () => {
  if (map) drawSlots()
}, { deep: true })
</script>

<style>
.admin-map-wrap {
  position: relative;
  border-radius: 14px;
  overflow: hidden;
  border: 1px solid rgba(255,255,255,0.1);
  margin-bottom: 20px;
  transition: all 0.3s ease;
}

.admin-map-wrap.admin-map-fullscreen {
  position: fixed;
  inset: 0;
  border-radius: 0;
  z-index: 9999;
  margin: 0;
  border: none;
}

.admin-map {
  width: 100%;
  height: 350px;
}

.admin-map-fullscreen .admin-map {
  height: 100vh;
}

.admin-map-controls {
  position: absolute;
  top: 16px;
  right: 16px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  z-index: 1000;
}

.admin-map-fullscreen .admin-map-controls {
  top: 50%;
  right: 12px;
  transform: translateY(-50%);
}

.btn-map-ctrl {
  width: 36px;
  height: 36px;
  background: white;
  border: none;
  border-radius: 8px;
  color: #333;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 2px 6px rgba(0,0,0,0.15);
  transition: all 0.2s;
}

.btn-map-ctrl:hover {
  background: #f0f0f0;
  box-shadow: 0 4px 10px rgba(0,0,0,0.2);
}

.admin-map-legend {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 10px 14px;
  background: rgba(0,0,0,0.4);
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #94a3b8;
  font-weight: 500;
}

.legend-dot {
  width: 10px;
  height: 10px;
  border-radius: 3px;
}

.legend-dot.green { background: #10b981; }
.legend-dot.red { background: #ef4444; }
.legend-dot.blue { background: #3b82f6; }

.admin-slot-label {
  background: rgba(15,23,42,0.85) !important;
  border: 1px solid rgba(99,102,241,0.4) !important;
  color: #e0e7ff !important;
  font-size: 10px !important;
  font-weight: 700 !important;
  padding: 2px 6px !important;
  border-radius: 4px !important;
  font-family: 'JetBrains Mono', monospace !important;
  box-shadow: none !important;
}
.admin-slot-label::before { display: none !important; }

.admin-slot-tooltip {
  background: rgba(15,23,42,0.95) !important;
  border: 1px solid rgba(255,255,255,0.2) !important;
  color: #f1f5f9 !important;
  font-size: 12px !important;
  padding: 6px 10px !important;
  border-radius: 8px !important;
  box-shadow: 0 4px 12px rgba(0,0,0,0.4) !important;
}
.admin-slot-tooltip::before { border-top-color: rgba(15,23,42,0.95) !important; }
</style>
