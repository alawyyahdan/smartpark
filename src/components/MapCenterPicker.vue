<template>
  <div class="center-picker-wrap">
    <div ref="mapRef" class="center-picker-map"></div>
    <div class="center-picker-info">
      <span v-if="lat && lng">{{ Number(lat).toFixed(7) }}, {{ Number(lng).toFixed(7) }}</span>
      <span v-else>Klik pada peta untuk set lokasi default</span>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, watch } from 'vue'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'

const props = defineProps({
  lat: { type: [Number, String], default: null },
  lng: { type: [Number, String], default: null }
})

const emit = defineEmits(['update:lat', 'update:lng'])

const mapRef = ref(null)
let map = null
let marker = null

onMounted(() => {
  const center = (props.lat && props.lng)
    ? [parseFloat(props.lat), parseFloat(props.lng)]
    : [-7.2650876, 112.783217]

  // Init tanpa delay, tapi dengan ResizeObserver
  map = L.map(mapRef.value, { center, zoom: 17, zoomControl: true })

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 22
  }).addTo(map)

  // Force map reflow saat size container berubah
  const observer = new ResizeObserver(() => {
    if (map) map.invalidateSize()
  })
  if (mapRef.value) observer.observe(mapRef.value)

  setTimeout(() => { if (map) map.invalidateSize() }, 300)

  if (props.lat && props.lng) {
    placeMarker(parseFloat(props.lat), parseFloat(props.lng))
  }

  map.on('click', (e) => {
    emit('update:lat', e.latlng.lat)
    emit('update:lng', e.latlng.lng)
    placeMarker(e.latlng.lat, e.latlng.lng)
  })
})

onUnmounted(() => { if (map) map.remove() })

function placeMarker(lat, lng) {
  if (marker) map.removeLayer(marker)
  const icon = L.divIcon({
    className: 'center-marker',
    html: '<div class="center-dot"></div>',
    iconSize: [20, 20],
    iconAnchor: [10, 10]
  })
  marker = L.marker([lat, lng], { icon, draggable: true }).addTo(map)
  marker.on('drag', (e) => {
    const pos = e.target.getLatLng()
    emit('update:lat', pos.lat)
    emit('update:lng', pos.lng)
  })
  map.panTo([lat, lng])
}

watch(() => [props.lat, props.lng], ([lat, lng]) => {
  if (lat && lng && map) placeMarker(parseFloat(lat), parseFloat(lng))
})
</script>

<style>
.center-picker-wrap {
  border-radius: 10px;
  overflow: hidden;
  border: 1px solid rgba(255,255,255,0.1);
}
.center-picker-map { width: 100%; height: 200px; }
.center-picker-info {
  padding: 8px 12px;
  background: rgba(0,0,0,0.4);
  font-size: 12px;
  font-family: 'JetBrains Mono', monospace;
  color: #a5b4fc;
  text-align: center;
}
.center-marker { background: none !important; border: none !important; }
.center-dot {
  width: 20px; height: 20px;
  background: #6366f1;
  border: 3px solid white;
  border-radius: 50%;
  box-shadow: 0 0 10px rgba(99,102,241,0.6);
  cursor: grab;
}
</style>
