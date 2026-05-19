<template>
  <div class="map-picker-wrap">
    <div ref="mapRef" class="map-picker"></div>
    <div class="map-picker-controls" v-if="lat && lng">
      <div class="picker-row">
        <span class="picker-coords">{{ Number(lat).toFixed(7) }}, {{ Number(lng).toFixed(7) }}</span>
      </div>
      <div class="picker-row">
        <label>Rotasi</label>
        <input type="range" :value="rotation" @input="onChange('rotation', $event.target.value)" min="0" max="360" step="1" />
        <span class="picker-val">{{ rotation }}°</span>
      </div>
      <div class="picker-row">
        <label>Lebar</label>
        <input type="range" :value="slotWidth" @input="onChange('slotWidth', $event.target.value)" min="1" max="20" step="0.5" />
        <span class="picker-val">{{ slotWidth }}m</span>
      </div>
      <div class="picker-row">
        <label>Panjang</label>
        <input type="range" :value="slotHeight" @input="onChange('slotHeight', $event.target.value)" min="1" max="20" step="0.5" />
        <span class="picker-val">{{ slotHeight }}m</span>
      </div>
    </div>
    <div class="map-picker-hint" v-else>
      Klik pada peta untuk set lokasi slot
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, watch } from 'vue'
import L from 'leaflet'
import { computeSlotCorners, DEFAULT_LAT, DEFAULT_LNG } from '../lib/geo.js'
import { createLeafletMap } from '../composables/useLeafletMap.js'

const props = defineProps({
  lat: { type: [Number, String], default: null },
  lng: { type: [Number, String], default: null },
  rotation: { type: [Number, String], default: 0 },
  slotWidth: { type: [Number, String], default: 3 },
  slotHeight: { type: [Number, String], default: 5 },
  existingSlots: { type: Array, default: () => [] },
  defaultLat: { type: Number, default: DEFAULT_LAT },
  defaultLng: { type: Number, default: DEFAULT_LNG }
})

const emit = defineEmits(['update:lat', 'update:lng', 'update:rotation', 'update:slotWidth', 'update:slotHeight'])

const mapRef = ref(null)
let map = null
let slotRect = null
let slotMarker = null
let mapHandle = null

const DEFAULT_CENTER = [props.defaultLat, props.defaultLng]

onMounted(() => {
  const center = (props.lat && props.lng) 
    ? [parseFloat(props.lat), parseFloat(props.lng)] 
    : DEFAULT_CENTER

  mapHandle = createLeafletMap(mapRef.value, { center, zoom: 19 })
  map = mapHandle.map

  // Draw existing slots
  props.existingSlots.forEach(s => {
    if (!s.lat || !s.lng) return
    drawRect(
      parseFloat(s.lat), parseFloat(s.lng),
      parseFloat(s.rotation || 0),
      parseFloat(s.slot_width || 3), parseFloat(s.slot_height || 5),
      '#64748b', s.name, false
    )
  })

  // Draw current slot if editing
  if (props.lat && props.lng) {
    drawCurrentSlot()
  }

  // Click to place slot
  map.on('click', (e) => {
    emit('update:lat', e.latlng.lat)
    emit('update:lng', e.latlng.lng)
    setTimeout(drawCurrentSlot, 50)
  })
})

onUnmounted(() => {
  if (mapHandle) mapHandle.destroy()
})

function drawCurrentSlot() {
  const lat = parseFloat(props.lat)
  const lng = parseFloat(props.lng)
  if (lat == null || lng == null || isNaN(lat) || isNaN(lng)) return

  if (slotRect) map.removeLayer(slotRect)
  if (slotMarker) map.removeLayer(slotMarker)

  slotRect = drawRect(
    lat, lng,
    parseFloat(props.rotation || 0),
    parseFloat(props.slotWidth || 3), parseFloat(props.slotHeight || 5),
    '#6366f1', '', true
  )

  const icon = L.divIcon({
    className: 'slot-drag-marker',
    html: '<div class="drag-dot"></div>',
    iconSize: [16, 16],
    iconAnchor: [8, 8]
  })

  slotMarker = L.marker([lat, lng], { icon, draggable: true }).addTo(map)

  slotMarker.on('drag', (e) => {
    const pos = e.target.getLatLng()
    emit('update:lat', pos.lat)
    emit('update:lng', pos.lng)
    if (slotRect) map.removeLayer(slotRect)
    slotRect = drawRect(
      pos.lat, pos.lng,
      parseFloat(props.rotation || 0),
      parseFloat(props.slotWidth || 3), parseFloat(props.slotHeight || 5),
      '#6366f1', '', true
    )
  })
}

function drawRect(lat, lng, rotation, widthM, heightM, color, label, isCurrent) {
  const corners = computeSlotCorners(lat, lng, rotation, widthM, heightM)

  const poly = L.polygon(corners, {
    color,
    weight: isCurrent ? 3 : 1.5,
    fillOpacity: isCurrent ? 0.3 : 0.15,
    fillColor: color,
    dashArray: isCurrent ? '' : '4,4'
  }).addTo(map)

  if (label) {
    poly.bindTooltip(label, {
      permanent: true,
      direction: 'center',
      className: 'slot-pick-label'
    })
  }

  return poly
}

function onChange(field, val) {
  const num = parseFloat(val)
  emit(`update:${field}`, num)
  setTimeout(drawCurrentSlot, 50)
}

watch(() => [props.lat, props.lng], ([lat, lng]) => {
  if (lat && lng && map) {
    map.panTo([parseFloat(lat), parseFloat(lng)])
  }
})
</script>

<style>
.map-picker-wrap {
  border-radius: 12px;
  overflow: hidden;
  border: 1px solid rgba(255,255,255,0.1);
}

.map-picker {
  width: 100%;
  height: 260px;
}

.map-picker-controls {
  padding: 10px 14px;
  background: rgba(0,0,0,0.5);
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.map-picker-hint {
  padding: 12px 14px;
  background: rgba(0,0,0,0.4);
  font-size: 13px;
  color: #64748b;
  text-align: center;
}

.picker-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.picker-coords {
  font-size: 11px;
  font-family: 'JetBrains Mono', monospace;
  color: #a5b4fc;
}

.picker-row label {
  font-size: 11px;
  color: #94a3b8;
  font-weight: 600;
  min-width: 50px;
}

.picker-row input[type="range"] {
  flex: 1;
  height: 4px;
  accent-color: #6366f1;
}

.picker-val {
  font-size: 11px;
  color: #a5b4fc;
  font-family: 'JetBrains Mono', monospace;
  min-width: 36px;
  text-align: right;
}

/* Drag marker */
.slot-drag-marker { background: none !important; border: none !important; }
.drag-dot {
  width: 16px;
  height: 16px;
  background: #6366f1;
  border: 2px solid white;
  border-radius: 50%;
  box-shadow: 0 0 8px rgba(99,102,241,0.6);
  cursor: grab;
}

.slot-pick-label {
  background: rgba(15,23,42,0.8) !important;
  border: 1px solid rgba(255,255,255,0.2) !important;
  color: #94a3b8 !important;
  font-size: 9px !important;
  padding: 1px 5px !important;
  border-radius: 3px !important;
  box-shadow: none !important;
}
.slot-pick-label::before { display: none !important; }
</style>
