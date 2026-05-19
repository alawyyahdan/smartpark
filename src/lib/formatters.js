/**
 * Shared formatting utilities (locale: id-ID).
 *
 * All date/time helpers accept Date | ISO string | null and render '—' for
 * null/undefined input so views can safely interpolate optional timestamps.
 */

function toDate(input) {
  if (input == null || input === '') return null
  return input instanceof Date ? input : new Date(input)
}

export function getStatusLabel(status) {
  const labels = {
    active: 'Aktif',
    parked: 'Parkir',
    exiting: 'Proses Keluar',
    done: 'Selesai',
    expired: 'Expired'
  }
  return labels[status] || status
}

export function formatDateTime(input) {
  const d = toDate(input)
  if (!d) return '—'
  return d.toLocaleString('id-ID', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

export function formatTime(input) {
  const d = toDate(input)
  if (!d) return '—'
  return d.toLocaleTimeString('id-ID', {
    hour: '2-digit',
    minute: '2-digit'
  })
}

export function formatTimeWithSeconds(input) {
  const d = toDate(input)
  if (!d) return '—'
  return d.toLocaleTimeString('id-ID', {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  })
}

export function formatDateLong(input) {
  const d = toDate(input)
  if (!d) return '—'
  return d.toLocaleDateString('id-ID', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric'
  })
}

export function formatDateShort(input) {
  const d = toDate(input)
  if (!d) return '—'
  return d.toLocaleDateString('id-ID', {
    day: '2-digit',
    month: 'long',
    year: 'numeric'
  })
}

export function formatNumber(num) {
  return new Intl.NumberFormat('id-ID').format(num)
}

export function formatCurrency(amount) {
  return new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    minimumFractionDigits: 0
  }).format(amount)
}

export function getUnitLabel(unit) {
  const labels = {
    second: 'detik',
    minute: 'menit',
    hour: 'jam'
  }
  return labels[unit] || 'menit'
}
