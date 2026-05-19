/**
 * Translate raw backend errors into user-friendly Indonesian messages.
 *
 * Falls back to err.message untouched when the error pattern is unknown,
 * so existing behaviour is preserved for non-recognized errors.
 *
 * Postgres error codes used:
 *   23505 - unique_violation
 *   23503 - foreign_key_violation
 *   23502 - not_null_violation
 */

const CONSTRAINT_LABELS = {
  gate_accounts_username_key: 'Username',
  gate_accounts_email_key: 'Email',
  parking_slots_name_key: 'Nama slot',
  parking_slots_mqtt_topic_key: 'Topic MQTT slot',
  areas_name_key: 'Nama area',
  exit_gates_name_key: 'Nama gate',
  exit_gates_gate_number_key: 'Nomor gate',
  settings_key_key: 'Key pengaturan',
  tickets_ticket_code_key: 'Kode tiket',
}

function labelFromConstraint(constraint) {
  if (!constraint) return null
  if (CONSTRAINT_LABELS[constraint]) return CONSTRAINT_LABELS[constraint]

  // Generic fallback: strip leading table name and trailing `_key`,
  // turn snake_case into a capitalized phrase.
  const stripped = constraint.replace(/_key$/, '')
  const parts = stripped.split('_')
  if (parts.length <= 1) return null
  const tail = parts.slice(-2).join(' ')
  return tail.charAt(0).toUpperCase() + tail.slice(1)
}

function isUniqueViolation(err, msg) {
  if (err?.code === '23505') return true
  return msg.includes('duplicate key value') || msg.includes('unique constraint')
}

function isForeignKeyViolation(err, msg) {
  if (err?.code === '23503') return true
  return msg.includes('foreign key constraint')
}

function isNotNullViolation(err, msg) {
  if (err?.code === '23502') return true
  return msg.includes('null value in column')
}

export function friendlyError(err) {
  if (!err) return 'Terjadi kesalahan tidak diketahui'
  const msg = err.message || String(err)

  if (isUniqueViolation(err, msg)) {
    const match = msg.match(/(?:unique constraint|index)\s+"([^"]+)"/)
    const label = labelFromConstraint(match?.[1])
    return label
      ? `${label} sudah dipakai. Silakan pilih yang lain.`
      : 'Data ini sudah ada. Silakan pilih nilai yang berbeda.'
  }

  if (isForeignKeyViolation(err, msg)) {
    return 'Data ini masih dipakai oleh data lain. Hapus relasinya dulu.'
  }

  if (isNotNullViolation(err, msg)) {
    const match = msg.match(/null value in column "([^"]+)"/)
    const column = match?.[1]
    return column
      ? `Field "${column}" wajib diisi.`
      : 'Ada field wajib yang belum diisi.'
  }

  return msg
}
