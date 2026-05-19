/**
 * Shared formatting utilities
 */

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

export function formatDateTime(isoStr) {
  if (!isoStr) return '—'
  return new Date(isoStr).toLocaleString('id-ID', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

export function formatNumber(num) {
  return new Intl.NumberFormat('id-ID').format(num)
}

export function getUnitLabel(unit) {
  const labels = {
    second: 'detik',
    minute: 'menit',
    hour: 'jam'
  }
  return labels[unit] || 'menit'
}
