import QRCode from 'qrcode'
import { jsPDF } from 'jspdf'

/**
 * Generate a unique ticket code
 * Format: PREFIX-YYYYMMDD-XXX-RRRR (e.g. SP-20250424-001-a3f2)
 * @param {number} sequence
 * @param {string} prefix - dari settings (default 'SP')
 */
export function generateTicketCode(sequence, prefix = 'SP') {
  const now = new Date()
  const dateStr = now.toISOString().slice(0, 10).replace(/-/g, '')
  const seq = String(sequence).padStart(3, '0')
  const rand = Math.random().toString(36).substring(2, 6)
  return `${prefix}-${dateStr}-${seq}-${rand}`
}

/**
 * Generate QR code data URL from ticket UUID
 * @param {string} ticketId
 * @param {string} appUrl - URL website dari settings
 */
export async function generateQRDataUrl(ticketId, appUrl = 'http://localhost:5173') {
  const url = `${appUrl}/visitor?t=${ticketId}`
  return await QRCode.toDataURL(url, {
    width: 300,
    margin: 2,
    color: { dark: '#0f172a', light: '#ffffff' },
    errorCorrectionLevel: 'M'
  })
}

/**
 * Generate and download thermal PDF (80mm width ≈ 226px / ~302pt)
 * @param {object} ticket
 * @param {string} appName - Nama aplikasi dari settings
 */
export async function printThermalPDF(ticket, appUrl = 'http://localhost:5173', appName = 'SmartPark') {
  const doc = new jsPDF({
    unit: 'mm',
    format: [80, 120], // 80mm width, 120mm height
    orientation: 'portrait'
  })

  const qrDataUrl = await generateQRDataUrl(ticket.id, appUrl)
  const now = new Date(ticket.created_at)
  const dateStr = now.toLocaleDateString('id-ID', {
    day: '2-digit', month: 'long', year: 'numeric'
  })
  const timeStr = now.toLocaleTimeString('id-ID', {
    hour: '2-digit', minute: '2-digit'
  })

  // Header
  doc.setFillColor(15, 23, 42)
  doc.rect(0, 0, 80, 22, 'F')

  doc.setTextColor(255, 255, 255)
  doc.setFontSize(14)
  doc.setFont('helvetica', 'bold')
  doc.text(appName, 40, 10, { align: 'center' })

  doc.setFontSize(7)
  doc.setFont('helvetica', 'normal')
  doc.text('Sistem Parkir Cerdas', 40, 16, { align: 'center' })

  // Divider
  doc.setDrawColor(99, 102, 241)
  doc.setLineWidth(0.5)
  doc.line(5, 23, 75, 23)

  // Ticket Code
  doc.setTextColor(15, 23, 42)
  doc.setFontSize(7)
  doc.setFont('helvetica', 'normal')
  doc.text('Nomor Tiket', 40, 30, { align: 'center' })

  doc.setFontSize(11)
  doc.setFont('helvetica', 'bold')
  doc.text(ticket.ticket_code, 40, 37, { align: 'center' })

  // Date & Time
  doc.setFontSize(7)
  doc.setFont('helvetica', 'normal')
  doc.setTextColor(100, 116, 139)
  doc.text(`${dateStr}  ${timeStr}`, 40, 43, { align: 'center' })

  // QR Code
  doc.addImage(qrDataUrl, 'PNG', 20, 54, 40, 40)

  // Instruction
  doc.setFontSize(6.5)
  doc.setFont('helvetica', 'normal')
  doc.setTextColor(100, 116, 139)
  doc.text('Scan QR untuk panduan parkir', 40, 98, { align: 'center' })

  // Footer
  doc.setFillColor(248, 250, 252)
  doc.rect(0, 102, 80, 18, 'F')
  doc.setFontSize(6)
  doc.setTextColor(148, 163, 184)
  doc.text('Simpan tiket ini hingga kendaraan keluar', 40, 109, { align: 'center' })
  doc.text('smartpark.local', 40, 115, { align: 'center' })

  // Save
  doc.save(`tiket-${ticket.ticket_code}.pdf`)
}
