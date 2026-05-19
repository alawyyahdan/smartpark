/**
 * Shared geo utilities for parking slot geometry and heading calculation
 */

// 1 meter ≈ 0.000009 degrees latitude (private to this module)
const METER_TO_DEG = 0.000009

export const DEFAULT_LAT = -7.2650876
export const DEFAULT_LNG = 112.783217

/**
 * Compute rotated rectangle corners for a parking slot (Leaflet order: [lat, lng])
 */
export function computeSlotCorners(lat, lng, rotation, widthM, heightM) {
  const w = (widthM / 2) * METER_TO_DEG
  const h = (heightM / 2) * METER_TO_DEG
  const rad = (rotation * Math.PI) / 180

  return [[-h, -w], [-h, w], [h, w], [h, -w]].map(([dy, dx]) => {
    const ry = dy * Math.cos(rad) - dx * Math.sin(rad)
    const rx = dy * Math.sin(rad) + dx * Math.cos(rad)
    return [lat + ry, lng + rx]
  })
}

/**
 * Compute rotated rectangle corners for GeoJSON (MapLibre order: [lng, lat])
 * Closes the polygon by repeating the first point
 */
export function computeSlotCornersGeoJSON(lat, lng, rotation, widthM, heightM) {
  const w = (widthM / 2) * METER_TO_DEG
  const h = (heightM / 2) * METER_TO_DEG
  const rad = (rotation * Math.PI) / 180

  return [[-h, -w], [-h, w], [h, w], [h, -w], [-h, -w]].map(([dy, dx]) => {
    const ry = dy * Math.cos(rad) - dx * Math.sin(rad)
    const rx = dy * Math.sin(rad) + dx * Math.cos(rad)
    return [lng + rx, lat + ry]
  })
}

/**
 * Calculate heading (bearing) between two points in degrees (0-360)
 */
export function calcHeading(lat1, lng1, lat2, lng2) {
  const dLng = (lng2 - lng1) * Math.PI / 180
  const y = Math.sin(dLng) * Math.cos(lat2 * Math.PI / 180)
  const x = Math.cos(lat1 * Math.PI / 180) * Math.sin(lat2 * Math.PI / 180) -
            Math.sin(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.cos(dLng)
  return ((Math.atan2(y, x) * 180 / Math.PI) + 360) % 360
}
