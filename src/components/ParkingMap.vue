<template>
  <div class="parking-map-container" :class="{ fullscreen: isFullscreen }">
    <div ref="mapRef" class="parking-map"></div>

    <!-- Joystick Debug -->
    <div v-if="debug" class="joystick">
      <button class="joy-btn joy-up" @mousedown="startMove('up')" @mouseup="stopMove" @mouseleave="stopMove" @touchstart.prevent="startMove('up')" @touchend="stopMove">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="18 15 12 9 6 15"/></svg>
      </button>
      <div class="joy-mid">
        <button class="joy-btn joy-left" @mousedown="startMove('left')" @mouseup="stopMove" @mouseleave="stopMove" @touchstart.prevent="startMove('left')" @touchend="stopMove">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="15 18 9 12 15 6"/></svg>
        </button>
        <div class="joy-center"></div>
        <button class="joy-btn joy-right" @mousedown="startMove('right')" @mouseup="stopMove" @mouseleave="stopMove" @touchstart.prevent="startMove('right')" @touchend="stopMove">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="9 18 15 12 9 6"/></svg>
        </button>
      </div>
      <button class="joy-btn joy-down" @mousedown="startMove('down')" @mouseup="stopMove" @mouseleave="stopMove" @touchstart.prevent="startMove('down')" @touchend="stopMove">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="6 9 12 15 18 9"/></svg>
      </button>
    </div>

    <!-- Map Controls -->
    <div class="map-controls">
      <button class="map-ctrl-btn" @click="recenter" title="Recenter">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="12" cy="12" r="3"/><path d="M12 2v4m0 12v4M2 12h4m12 0h4"/>
        </svg>
      </button>
      <button class="map-ctrl-btn" @click="toggleFullscreen" :title="isFullscreen ? 'Keluar Fullscreen' : 'Fullscreen'">
        <svg v-if="!isFullscreen" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="15 3 21 3 21 9"/><polyline points="9 21 3 21 3 15"/><line x1="21" y1="3" x2="14" y2="10"/><line x1="3" y1="21" x2="10" y2="14"/>
        </svg>
        <svg v-else width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="4 14 10 14 10 20"/><polyline points="20 10 14 10 14 4"/><line x1="14" y1="10" x2="21" y2="3"/><line x1="3" y1="21" x2="10" y2="14"/>
        </svg>
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, watch } from 'vue'
import L from 'leaflet'
import { computeSlotCorners, calcHeading, DEFAULT_LAT, DEFAULT_LNG } from '../lib/geo.js'
import { createLeafletMap } from '../composables/useLeafletMap.js'

const props = defineProps({
  userLat: { type: Number, default: DEFAULT_LAT },
  userLng: { type: Number, default: DEFAULT_LNG },
  targetSlot: { type: Object, default: null },
  slots: { type: Array, default: () => [] },
  lineColor: { type: String, default: '#4285F4' },
  debug: { type: Boolean, default: false }
})

const emit = defineEmits(['update:userLat', 'update:userLng'])

const isFullscreen = ref(false)

function toggleFullscreen() {
  isFullscreen.value = !isFullscreen.value
  setTimeout(() => { if (map) map.invalidateSize() }, 100)
}

const mapRef = ref(null)
let map = null
let userMarker = null
let userCircle = null
let targetMarker = null
let routeLine = null
let routeOutline = null
let slotRectangles = []
let moveInterval = null
let lastHeading = 0
let prevLat = null
let prevLng = null

const STEP = 0.00008
const OSRM_URL = 'https://router.project-osrm.org/route/v1/driving'

let mapHandle = null

onMounted(() => initMap())
onUnmounted(() => {
  stopMove()
  if (mapHandle) mapHandle.destroy()
})

function initMap() {
  mapHandle = createLeafletMap(mapRef.value, {
    center: [props.userLat, props.userLng],
    zoom: 18,
    zoomControl: false,
    attributionControl: false
  })
  map = mapHandle.map

  // User accuracy circle
  userCircle = L.circle([props.userLat, props.userLng], {
    radius: 15,
    color: '#4285F4',
    fillColor: '#4285F4',
    fillOpacity: 0.1,
    weight: 1
  }).addTo(map)

  // User arrow marker (segitiga)
  updateUserMarker(props.userLat, props.userLng, 0)

  drawSlots()

  if (props.targetSlot && props.targetSlot.lat) {
    drawTarget()
    fetchRoute(props.userLat, props.userLng, props.targetSlot.lat, props.targetSlot.lng)
  }
}

function updateUserMarker(lat, lng, heading) {
  const arrowSvg = `
    <svg width="40" height="40" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <filter id="shadow" x="-20%" y="-20%" width="140%" height="140%">
          <feDropShadow dx="0" dy="1" stdDeviation="2" flood-color="#000" flood-opacity="0.4"/>
        </filter>
      </defs>
      <g transform="rotate(${heading}, 20, 20)" filter="url(#shadow)">
        <polygon points="20,4 32,32 20,26 8,32" fill="#4285F4" stroke="white" stroke-width="2" stroke-linejoin="round"/>
      </g>
    </svg>`

  const icon = L.divIcon({
    className: 'user-arrow-marker',
    html: arrowSvg,
    iconSize: [40, 40],
    iconAnchor: [20, 20]
  })

  if (userMarker) {
    userMarker.setLatLng([lat, lng])
    userMarker.setIcon(icon)
  } else {
    userMarker = L.marker([lat, lng], { icon, zIndexOffset: 1000 }).addTo(map)
  }

  userCircle.setLatLng([lat, lng])
}

// ===== OSRM ROUTING (ikut jalan) =====
async function fetchRoute(fromLat, fromLng, toLat, toLng) {
  try {
    const url = `${OSRM_URL}/${fromLng},${fromLat};${toLng},${toLat}?overview=full&geometries=geojson`
    const res = await fetch(url)
    const data = await res.json()

    if (data.routes && data.routes.length > 0) {
      const coords = data.routes[0].geometry.coordinates.map(c => [c[1], c[0]])
      drawRouteLine(coords)
    } else {
      // Fallback: garis lurus
      drawRouteLine([[fromLat, fromLng], [toLat, toLng]])
    }
  } catch (err) {
    console.error('OSRM error:', err)
    drawRouteLine([[fromLat, fromLng], [toLat, toLng]])
  }
}

function drawRouteLine(coords) {
  if (routeOutline) map.removeLayer(routeOutline)
  if (routeLine) map.removeLayer(routeLine)

  // Outline (border tebal)
  routeOutline = L.polyline(coords, {
    color: '#1a56db',
    weight: 8,
    opacity: 0.4,
    lineCap: 'round',
    lineJoin: 'round'
  }).addTo(map)

  // Main line
  routeLine = L.polyline(coords, {
    color: props.lineColor,
    weight: 5,
    opacity: 0.9,
    lineCap: 'round',
    lineJoin: 'round'
  }).addTo(map)
}

// ===== SLOTS =====
function drawSlots() {
  slotRectangles.forEach(r => map.removeLayer(r))
  slotRectangles = []

  props.slots.forEach(slot => {
    if (!slot.lat || !slot.lng) return
    const isTarget = props.targetSlot && props.targetSlot.name === slot.name
    if (!isTarget) return
    const color = slot.status === 'diambil' ? '#ef4444' : '#22c55e'
    const rotation = parseFloat(slot.rotation || 0)
    const widthM = parseFloat(slot.slot_width || 3)
    const heightM = parseFloat(slot.slot_height || 5)
    const lat = parseFloat(slot.lat)
    const lng = parseFloat(slot.lng)

    const corners = computeSlotCorners(lat, lng, rotation, widthM, heightM)

    const poly = L.polygon(corners, {
      color,
      weight: 3,
      fillOpacity: slot.status === 'diambil' ? 0.5 : 0.4,
      fillColor: color
    }).addTo(map)

    if (isTarget) {
      poly.bindTooltip(slot.name, {
        permanent: true, direction: 'center', className: 'slot-label'
      })
    }

    slotRectangles.push(poly)
  })
}

function drawTarget() {
  if (targetMarker) map.removeLayer(targetMarker)
  if (!props.targetSlot || !props.targetSlot.lat) return

  const icon = L.divIcon({
    className: 'target-marker',
    html: `<div class="target-pin"><svg width="28" height="36" viewBox="0 0 24 30" fill="#22c55e" stroke="white" stroke-width="1.5"><path d="M12 0C5.4 0 0 5.4 0 12c0 9 12 18 12 18s12-9 12-18C24 5.4 18.6 0 12 0z"/><circle cx="12" cy="12" r="5" fill="white"/><circle cx="12" cy="12" r="3" fill="#22c55e"/></svg></div>`,
    iconSize: [28, 36],
    iconAnchor: [14, 36]
  })

  targetMarker = L.marker([props.targetSlot.lat, props.targetSlot.lng], { icon, zIndexOffset: 900 }).addTo(map)
}

// ===== UPDATE POSITION =====
function updateUserPosition(lat, lng) {
  if (!map || !userMarker) return

  // Calculate heading from movement
  if (prevLat !== null && prevLng !== null) {
    const dist = Math.sqrt((lat - prevLat) ** 2 + (lng - prevLng) ** 2)
    if (dist > 0.000005) { // Only update heading if moved enough
      lastHeading = calcHeading(prevLat, prevLng, lat, lng)
    }
  }
  prevLat = lat
  prevLng = lng

  updateUserMarker(lat, lng, lastHeading)
  map.panTo([lat, lng], { animate: true, duration: 0.3 })
}

function recenter() {
  if (map) map.panTo([props.userLat, props.userLng], { animate: true })
}

// ===== JOYSTICK =====
function startMove(dir) {
  stopMove()
  doMove(dir)
  moveInterval = setInterval(() => doMove(dir), 100)
}

function stopMove() {
  if (moveInterval) { clearInterval(moveInterval); moveInterval = null }
}

function doMove(dir) {
  let lat = props.userLat
  let lng = props.userLng
  const headingRad = (lastHeading * Math.PI) / 180

  if (dir === 'up') {
    lat += STEP * Math.cos(headingRad)
    lng += STEP * Math.sin(headingRad)
  }
  if (dir === 'down') {
    lat -= STEP * Math.cos(headingRad)
    lng -= STEP * Math.sin(headingRad)
  }
  if (dir === 'left') {
    lastHeading = (lastHeading - 15 + 360) % 360
    const newRad = (lastHeading * Math.PI) / 180
    lat += STEP * 0.5 * Math.cos(newRad)
    lng += STEP * 0.5 * Math.sin(newRad)
  }
  if (dir === 'right') {
    lastHeading = (lastHeading + 15) % 360
    const newRad = (lastHeading * Math.PI) / 180
    lat += STEP * 0.5 * Math.cos(newRad)
    lng += STEP * 0.5 * Math.sin(newRad)
  }

  emit('update:userLat', lat)
  emit('update:userLng', lng)
  updateUserPosition(lat, lng)
}

// ===== WATCHERS =====
watch(() => [props.userLat, props.userLng], ([lat, lng]) => {
  updateUserPosition(lat, lng)
})

watch(() => props.targetSlot, (slot) => {
  drawSlots()
  drawTarget()
  if (slot && slot.lat) {
    fetchRoute(props.userLat, props.userLng, slot.lat, slot.lng)
  }
}, { deep: true })

watch(() => props.slots, () => drawSlots(), { deep: true })

defineExpose({ recenter, updateUserPosition, fetchRoute })
</script>

<style>
.parking-map-container {
  position: relative;
  width: 100%;
  height: 400px;
  border-radius: 16px;
  overflow: hidden;
  background: #e5e7eb;
  transition: all 0.3s ease;
  isolation: isolate;
}

.parking-map-container.fullscreen {
  position: fixed;
  inset: 0;
  height: 100vh;
  width: 100vw;
  border-radius: 0;
  z-index: 9999;
}

.parking-map { 
  width: 100%; 
  height: 100%; 
  z-index: 1;
}

/* Map Controls */
.map-controls {
  position: absolute;
  bottom: 16px;
  right: 16px;
  display: flex !important;
  flex-direction: column;
  gap: 8px;
  z-index: 9999 !important;
  transform: translate3d(0, 0, 0);
  pointer-events: auto !important;
  opacity: 1 !important;
  visibility: visible !important;
}

.fullscreen .map-controls {
  top: 50%;
  bottom: auto;
  right: 12px;
  transform: translateY(-50%);
}

.map-ctrl-btn {
  width: 40px;
  height: 40px;
  background: white;
  border: none;
  border-radius: 50%;
  color: #333;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 2px 8px rgba(0,0,0,0.25);
  transition: all 0.2s;
}

.map-ctrl-btn:hover {
  background: #f0f0f0;
  box-shadow: 0 4px 12px rgba(0,0,0,0.3);
  transform: scale(1.05);
}

/* User Arrow */
.user-arrow-marker { background: none !important; border: none !important; }

/* Target */
.target-marker { background: none !important; border: none !important; }
.target-pin { filter: drop-shadow(0 2px 6px rgba(0,0,0,0.4)); }

/* Slot Labels */
.slot-label {
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
.slot-label::before { display: none !important; }

/* Recenter */
/* Joystick */
.joystick {
  position: absolute;
  bottom: 16px;
  left: 16px;
  z-index: 9999 !important;
  transform: translate3d(0, 0, 0);
  display: flex !important;
  flex-direction: column;
  align-items: center;
  gap: 2px;
  opacity: 1 !important;
  visibility: visible !important;
}
.joy-mid { display: flex; align-items: center; gap: 2px; }

.joy-btn {
  width: 40px;
  height: 40px;
  background: white;
  border: none;
  border-radius: 50%;
  color: #333;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 2px 6px rgba(0,0,0,0.2);
  transition: all 0.15s;
}
.joy-btn:hover, .joy-btn:active { background: #4285F4; color: white; }

.joy-center {
  width: 20px;
  height: 20px;
  background: #e5e7eb;
  border-radius: 50%;
}
</style>
