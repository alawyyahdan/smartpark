import L from 'leaflet'
import 'leaflet/dist/leaflet.css'

/**
 * Initialise a Leaflet map with the project's standard OSM tile layer plus a
 * ResizeObserver that calls invalidateSize() whenever the container's size
 * changes. Returns `{ map, observer }`. Caller is responsible for calling
 * `destroy()` from `onUnmounted`.
 *
 * Why centralised: ParkingMap, ParkingMap3D (no — uses MapLibre instead), AdminSlotMap,
 * SlotMapPicker and MapCenterPicker all need the same boilerplate (tile URL, zoom 22 max,
 * resize observer, post-mount invalidateSize tick). Drift between copies caused subtle
 * "grey-half-tile" bugs.
 */
export function createLeafletMap(container, {
  center,
  zoom = 18,
  zoomControl = true,
  attributionControl = true,
  invalidateAfterMs = 300
} = {}) {
  const map = L.map(container, { center, zoom, zoomControl, attributionControl })

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 22
  }).addTo(map)

  const observer = new ResizeObserver(() => {
    if (map) map.invalidateSize()
  })
  observer.observe(container)

  if (invalidateAfterMs > 0) {
    setTimeout(() => { try { map.invalidateSize() } catch {} }, invalidateAfterMs)
  }

  function destroy() {
    try { observer.disconnect() } catch {}
    try { map.remove() } catch {}
  }

  return { map, observer, destroy }
}
