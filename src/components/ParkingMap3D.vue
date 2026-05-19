<template>
  <div class="parking-map-container" :class="{ fullscreen: isFullscreen }">
    <div ref="mapRef" class="parking-map"></div>

    <!-- Joystick Debug -->
    <div v-if="debug" class="joystick">
      <button class="joy-btn" @mousedown="startMove('up')" @mouseup="stopMove" @mouseleave="stopMove" @touchstart.prevent="startMove('up')" @touchend="stopMove">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="18 15 12 9 6 15"/></svg>
      </button>
      <div class="joy-mid">
        <button class="joy-btn" @mousedown="startMove('left')" @mouseup="stopMove" @mouseleave="stopMove" @touchstart.prevent="startMove('left')" @touchend="stopMove">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="15 18 9 12 15 6"/></svg>
        </button>
        <div class="joy-center"></div>
        <button class="joy-btn" @mousedown="startMove('right')" @mouseup="stopMove" @mouseleave="stopMove" @touchstart.prevent="startMove('right')" @touchend="stopMove">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="9 18 15 12 9 6"/></svg>
        </button>
      </div>
      <button class="joy-btn" @mousedown="startMove('down')" @mouseup="stopMove" @mouseleave="stopMove" @touchstart.prevent="startMove('down')" @touchend="stopMove">
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
import maplibregl from 'maplibre-gl'
import 'maplibre-gl/dist/maplibre-gl.css'
// Fix MapLibre worker di production build — tanpa ini map blank di npm run build
import MaplibreWorker from 'maplibre-gl/dist/maplibre-gl-csp-worker?worker&inline'
maplibregl.workerClass = MaplibreWorker
import { computeSlotCornersGeoJSON, calcHeading, DEFAULT_LAT, DEFAULT_LNG } from '../lib/geo.js'

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
  // Resize map after toggle
  setTimeout(() => { if (map) map.resize() }, 100)
}

const mapRef = ref(null)
let map = null
let slotLabelMarker = null
let lastHeading = 0
let prevLat = null
let prevLng = null
let routeUpdateTimer = null
let currentSpeed = 0
let userInteracting = false
let interactionTimer = null
let lastRouteCoords = null // cache route coordinates

const MAX_SPEED = 0.00003  // max speed per frame
const ACCELERATION = 0.000002  // speed increase per frame
const DECELERATION = 0.6  // friction multiplier
const TURN_SPEED = 3  // degrees per frame
const FRAME_RATE = 30  // ms per frame
const OSRM_URL = 'https://router.project-osrm.org/route/v1/driving'

onMounted(() => initMap())
onUnmounted(() => {
  activeDir = null
  if (animFrame) cancelAnimationFrame(animFrame)
  if (routeUpdateTimer) clearTimeout(routeUpdateTimer)
  if (map) map.remove()
})

function initMap() {
  map = new maplibregl.Map({
    container: mapRef.value,
    style: 'https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json',
    center: [props.userLng, props.userLat],
    zoom: 18,
    pitch: 60,
    bearing: lastHeading,
    antialias: true
  })

  // Detect user interaction (drag/pinch/rotate)
  map.on('dragstart', () => {
    userInteracting = true
    if (interactionTimer) clearTimeout(interactionTimer)
  })
  map.on('touchstart', () => {
    userInteracting = true
    if (interactionTimer) clearTimeout(interactionTimer)
  })
  map.on('dragend', () => {
    if (interactionTimer) clearTimeout(interactionTimer)
    interactionTimer = setTimeout(() => { userInteracting = false }, 5000)
  })
  map.on('touchend', () => {
    if (interactionTimer) clearTimeout(interactionTimer)
    interactionTimer = setTimeout(() => { userInteracting = false }, 5000)
  })

  map.on('load', () => {
    // User marker (segitiga biru)
    addUserMarker()
    
    // Slot rectangles
    drawSlots()

    // Target + Route
    if (props.targetSlot && props.targetSlot.lat) {
      addTargetMarker()
      fetchRoute(props.userLat, props.userLng, parseFloat(props.targetSlot.lat), parseFloat(props.targetSlot.lng))
    }
  })
}

// ===== USER MARKER (segitiga) =====
function addUserMarker() {
  // User arrow as GeoJSON
  map.addSource('user-pos', {
    type: 'geojson',
    data: userPointGeoJSON(props.userLat, props.userLng)
  })

  // Accuracy circle
  map.addLayer({
    id: 'user-accuracy',
    type: 'circle',
    source: 'user-pos',
    paint: {
      'circle-radius': 30,
      'circle-color': '#4285F4',
      'circle-opacity': 0.15,
      'circle-stroke-color': '#4285F4',
      'circle-stroke-width': 1,
      'circle-stroke-opacity': 0.3
    }
  })

  // Inner dot
  map.addLayer({
    id: 'user-dot',
    type: 'circle',
    source: 'user-pos',
    paint: {
      'circle-radius': 8,
      'circle-color': '#4285F4',
      'circle-stroke-color': '#ffffff',
      'circle-stroke-width': 3
    }
  })
}

function userPointGeoJSON(lat, lng) {
  return { type: 'Feature', geometry: { type: 'Point', coordinates: [lng, lat] } }
}

// ===== TARGET MARKER =====
function addTargetMarker() {
  if (!props.targetSlot || !props.targetSlot.lat) return

  if (map.getSource('target-pos')) {
    map.getSource('target-pos').setData(
      userPointGeoJSON(props.targetSlot.lat, props.targetSlot.lng)
    )
    return
  }

  map.addSource('target-pos', {
    type: 'geojson',
    data: userPointGeoJSON(props.targetSlot.lat, props.targetSlot.lng)
  })

  map.addLayer({
    id: 'target-outer',
    type: 'circle',
    source: 'target-pos',
    paint: {
      'circle-radius': 16,
      'circle-color': '#22c55e',
      'circle-opacity': 0.3,
      'circle-stroke-color': '#22c55e',
      'circle-stroke-width': 2
    }
  })

  map.addLayer({
    id: 'target-inner',
    type: 'circle',
    source: 'target-pos',
    paint: {
      'circle-radius': 6,
      'circle-color': '#22c55e',
      'circle-stroke-color': '#ffffff',
      'circle-stroke-width': 2
    }
  })
}

// ===== SLOT RECTANGLES =====
function drawSlots() {
  if (slotLabelMarker) {
    slotLabelMarker.remove()
    slotLabelMarker = null
  }

  props.slots.forEach((_, i) => {
    if (map.getLayer(`slot-${i}`)) map.removeLayer(`slot-${i}`)
    if (map.getLayer(`slot-outline-${i}`)) map.removeLayer(`slot-outline-${i}`)
    if (map.getSource(`slot-${i}`)) map.removeSource(`slot-${i}`)
  })

  props.slots.forEach((slot, i) => {
    if (!slot.lat || !slot.lng) return

    const isTarget = props.targetSlot && props.targetSlot.name === slot.name
    if (!isTarget) return
    const color = slot.status === 'diambil' ? '#ef4444' : '#22c55e'
    const rotation = parseFloat(slot.rotation || 0)
    const widthM = parseFloat(slot.slot_width || 3)
    const heightM = parseFloat(slot.slot_height || 5)
    const lat = parseFloat(slot.lat)
    const lng = parseFloat(slot.lng)

    const corners = computeSlotCornersGeoJSON(lat, lng, rotation, widthM, heightM)

    const srcId = `slot-${i}`
    map.addSource(srcId, {
      type: 'geojson',
      data: { type: 'Feature', geometry: { type: 'Polygon', coordinates: [corners] }, properties: { name: slot.name } }
    })

    // 3D extrusion (kotak timbul, keliatan di semua device)
    map.addLayer({
      id: srcId,
      type: 'fill-extrusion',
      source: srcId,
      paint: {
        'fill-extrusion-color': color,
        'fill-extrusion-height': isTarget ? 2 : 1,
        'fill-extrusion-base': 0,
        'fill-extrusion-opacity': slot.status === 'diambil' ? 0.7 : isTarget ? 0.6 : 0.4
      }
    })

    // Outline tetap ada (flat)
    map.addLayer({
      id: `slot-outline-${i}`,
      type: 'line',
      source: srcId,
      paint: { 'line-color': color, 'line-width': isTarget ? 4 : 2 }
    })

    // Label nama slot (Cuma buat target)
    if (isTarget) {
      const el = document.createElement('div')
      el.className = 'slot-3d-label'
      el.innerHTML = `<span>${slot.name}</span>`
      
      if (slotLabelMarker) slotLabelMarker.remove()
      slotLabelMarker = new maplibregl.Marker({ element: el })
        .setLngLat([lng, lat])
        .addTo(map)
    }
  })
}

// ===== OSRM ROUTING =====
async function fetchRoute(fromLat, fromLng, toLat, toLng) {
  try {
    const fLat = parseFloat(fromLat)
    const fLng = parseFloat(fromLng)
    const tLat = parseFloat(toLat)
    const tLng = parseFloat(toLng)
    
    if (isNaN(fLat) || isNaN(fLng) || isNaN(tLat) || isNaN(tLng)) return

    const url = `${OSRM_URL}/${fLng},${fLat};${tLng},${tLat}?overview=full&geometries=geojson`
    const res = await fetch(url)
    const data = await res.json()

    if (data.code === 'Ok' && data.routes && data.routes.length > 0) {
      drawRoute(data.routes[0].geometry.coordinates)
    } else {
      // Fallback garis lurus kalau OSRM ga bisa route
      drawRoute([[fLng, fLat], [tLng, tLat]])
    }
  } catch (err) {
    console.warn('OSRM route fetch failed, using straight line:', err.message)
    const fLng = parseFloat(fromLng)
    const fLat = parseFloat(fromLat)
    const tLng = parseFloat(toLng)
    const tLat = parseFloat(toLat)
    drawRoute([[fLng, fLat], [tLng, tLat]])
  }
}

function drawRoute(coords) {
  lastRouteCoords = coords // Cache
  const geojson = { type: 'Feature', geometry: { type: 'LineString', coordinates: coords } }

  if (map.getSource('route')) {
    map.getSource('route').setData(geojson)
    return
  }

  map.addSource('route', { type: 'geojson', data: geojson })

  // Outline
  map.addLayer({
    id: 'route-outline',
    type: 'line',
    source: 'route',
    layout: { 'line-join': 'round', 'line-cap': 'round' },
    paint: { 'line-color': '#1a56db', 'line-width': 10, 'line-opacity': 0.3 }
  }, 'user-accuracy')

  // Main route
  map.addLayer({
    id: 'route-main',
    type: 'line',
    source: 'route',
    layout: { 'line-join': 'round', 'line-cap': 'round' },
    paint: { 'line-color': props.lineColor, 'line-width': 6, 'line-opacity': 0.9 }
  }, 'user-accuracy')
}

// Update route start point secara lokal (instant, tanpa fetch OSRM)
function updateRouteStart(lng, lat) {
  if (!lastRouteCoords || lastRouteCoords.length < 2) return
  if (!map || !map.getSource('route')) return

  // Ganti titik pertama route ke posisi user sekarang
  const updated = [[lng, lat], ...lastRouteCoords.slice(1)]
  
  // Hapus titik-titik yang udah dilewati (jarak < 10m dari user)
  while (updated.length > 2) {
    const nextPoint = updated[1]
    const dist = Math.sqrt((nextPoint[0] - lng) ** 2 + (nextPoint[1] - lat) ** 2)
    if (dist < 0.0001) { // ~10 meter
      updated.splice(1, 1) // Hapus titik yang udah dilewati
    } else {
      break
    }
  }

  lastRouteCoords = updated
  map.getSource('route').setData({
    type: 'Feature',
    geometry: { type: 'LineString', coordinates: updated }
  })
}

// ===== UPDATE POSITION (sticky + rotate) =====
function updateUserPosition(lat, lng) {
  if (!map) return

  if (prevLat !== null && prevLng !== null) {
    const dist = Math.sqrt((lat - prevLat) ** 2 + (lng - prevLng) ** 2)
    if (dist > 0.000002) {
      lastHeading = calcHeading(prevLat, prevLng, lat, lng)
    }
  }
  prevLat = lat
  prevLng = lng

  // Update user marker position (selalu)
  if (map.getSource('user-pos')) {
    map.getSource('user-pos').setData(userPointGeoJSON(lat, lng))
  }

  // Auto-center HANYA kalau user TIDAK sedang geser map
  if (!userInteracting) {
    map.easeTo({
      center: [lng, lat],
      bearing: lastHeading,
      pitch: 60,
      zoom: 18,
      duration: 300
    })
  }

  // Route: update lokal LANGSUNG + re-fetch OSRM tiap 1 detik
  if (props.targetSlot && props.targetSlot.lat) {
    updateRouteStart(lng, lat)
    
    if (routeUpdateTimer) clearTimeout(routeUpdateTimer)
    routeUpdateTimer = setTimeout(() => {
      fetchRoute(lat, lng, parseFloat(props.targetSlot.lat), parseFloat(props.targetSlot.lng))
    }, 1000)
  }
}

function recenter() {
  if (!map) return
  // Reset interaction state - kembali auto-follow
  userInteracting = false
  if (interactionTimer) clearTimeout(interactionTimer)
  map.flyTo({
    center: [props.userLng, props.userLat],
    bearing: lastHeading,
    pitch: 60,
    zoom: 18,
    duration: 500
  })
}

// ===== JOYSTICK (smooth driving) =====
let activeDir = null
let animFrame = null

function startMove(dir) {
  activeDir = dir
  if (!animFrame) driveLoop()
}

function stopMove() {
  activeDir = null
}

function driveLoop() {
  let lat = props.userLat
  let lng = props.userLng

  if (activeDir) {
    // Accelerate
    currentSpeed = Math.min(currentSpeed + ACCELERATION, MAX_SPEED)
  } else {
    // Decelerate
    currentSpeed *= DECELERATION
    if (currentSpeed < 0.0000005) {
      currentSpeed = 0
      animFrame = null
      return
    }
  }

  const headingRad = (lastHeading * Math.PI) / 180

  if (activeDir === 'up' || (!activeDir && currentSpeed > 0)) {
    lat += currentSpeed * Math.cos(headingRad)
    lng += currentSpeed * Math.sin(headingRad)
  }
  if (activeDir === 'down') {
    lat -= currentSpeed * Math.cos(headingRad)
    lng -= currentSpeed * Math.sin(headingRad)
  }
  if (activeDir === 'left') {
    lastHeading = (lastHeading - TURN_SPEED + 360) % 360
    lat += currentSpeed * Math.cos((lastHeading * Math.PI) / 180)
    lng += currentSpeed * Math.sin((lastHeading * Math.PI) / 180)
  }
  if (activeDir === 'right') {
    lastHeading = (lastHeading + TURN_SPEED) % 360
    lat += currentSpeed * Math.cos((lastHeading * Math.PI) / 180)
    lng += currentSpeed * Math.sin((lastHeading * Math.PI) / 180)
  }

  emit('update:userLat', lat)
  emit('update:userLng', lng)
  updateUserPosition(lat, lng)

  animFrame = requestAnimationFrame(driveLoop)
}

// ===== WATCHERS =====
watch(() => [props.userLat, props.userLng], ([lat, lng]) => updateUserPosition(lat, lng))

watch(() => props.targetSlot, (slot) => {
  if (!map) return
  
  // Tunggu map ready kalau belum
  if (!map.isStyleLoaded()) {
    map.once('styledata', () => {
      drawSlots()
      addTargetMarker()
      if (slot && slot.lat) fetchRoute(props.userLat, props.userLng, slot.lat, slot.lng)
    })
    return
  }
  
  drawSlots()
  addTargetMarker()
  if (slot && slot.lat) fetchRoute(props.userLat, props.userLng, slot.lat, slot.lng)
}, { deep: true, immediate: true })

watch(() => props.slots, () => { 
  if (map && map.isStyleLoaded()) drawSlots() 
}, { deep: true })

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
}

.parking-map-container.fullscreen {
  position: fixed;
  inset: 0;
  height: 100vh;
  width: 100vw;
  border-radius: 0;
  z-index: 9999;
}

.parking-map { width: 100%; height: 100%; }

/* Map Controls */
.map-controls {
  position: absolute;
  bottom: 16px;
  right: 16px;
  display: flex !important;
  flex-direction: column;
  gap: 8px;
  z-index: 9999 !important;
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

.joystick {
  position: absolute;
  bottom: 16px;
  left: 16px;
  z-index: 9999 !important;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
}

/* Slot 3D Label */
.slot-3d-label {
  background: rgba(15,23,42,0.9);
  border: 1px solid rgba(34,197,94,0.6);
  color: white;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 800;
  font-family: 'JetBrains Mono', monospace;
  white-space: nowrap;
  box-shadow: 0 4px 12px rgba(0,0,0,0.4);
  pointer-events: none;
  z-index: 2000;
}
.slot-3d-label span {
  display: block;
  text-shadow: 0 1px 2px rgba(0,0,0,0.5);
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
}
.joy-btn:hover, .joy-btn:active { background: #4285F4; color: white; }

.joy-center {
  width: 20px;
  height: 20px;
  background: #e5e7eb;
  border-radius: 50%;
}
</style>
