/**
 * Pure pricing helpers shared by views (ExitGate, Visitor, Admin previews).
 *
 * Settings are passed explicitly so the functions stay testable and free of
 * Vue refs / module-level state. Caller is responsible for awaiting the
 * settings fetch before invoking these.
 *
 * Settings shape (all values are strings as stored in the `settings` table):
 *   pricing_mode              'per_minute' | 'per_hour'
 *   price_per_minute          numeric string
 *   price_first_hour          numeric string
 *   price_after_first_hour    numeric string
 *   special_price_enabled     'true' | 'false'
 *   price_threshold           numeric string
 *   threshold_unit            'second' | 'minute' | 'hour'
 *   free_parking_enabled      'true' | 'false'
 *   free_duration             numeric string
 *   free_duration_unit        'second' | 'minute' | 'hour'
 */

function elapsedMinutes(createdAt) {
  return Math.floor((Date.now() - new Date(createdAt).getTime()) / 60000)
}

export function calcDuration(createdAt) {
  const mins = elapsedMinutes(createdAt)
  const h = Math.floor(mins / 60)
  const m = mins % 60
  if (h > 0) return `${h} jam ${m} menit`
  return `${m} menit`
}

export function calcPrice(createdAt, settings = {}) {
  const mins = elapsedMinutes(createdAt)
  const mode = settings.pricing_mode || 'per_hour'
  const specialEnabled = settings.special_price_enabled === 'true'
  const freeEnabled = settings.free_parking_enabled === 'true'

  let chargeableMins = mins

  if (freeEnabled) {
    let freeMins = parseInt(settings.free_duration || 0)
    const freeUnit = settings.free_duration_unit || 'minute'
    if (freeUnit === 'hour') freeMins *= 60
    else if (freeUnit === 'second') freeMins /= 60
    if (chargeableMins <= freeMins) return 0
    chargeableMins -= freeMins
  }

  if (mode === 'per_minute') {
    const rate = parseInt(settings.price_per_minute || 0)
    if (specialEnabled) {
      let threshold = parseInt(settings.price_threshold || 60)
      const unit = settings.threshold_unit || 'minute'
      if (unit === 'hour') threshold *= 60
      else if (unit === 'second') threshold /= 60
      if (chargeableMins > threshold) {
        const afterRate = parseInt(settings.price_after_first_hour || 0)
        return (threshold * rate) + ((chargeableMins - threshold) * afterRate)
      }
    }
    return chargeableMins * rate
  }

  if (mode === 'per_hour') {
    const hours = Math.ceil(chargeableMins / 60)
    const rate = parseInt(settings.price_first_hour || 0)
    if (specialEnabled) {
      let threshold = parseInt(settings.price_threshold || 1)
      const unit = settings.threshold_unit || 'hour'
      if (unit === 'minute') threshold = Math.ceil(threshold / 60)
      else if (unit === 'second') threshold = Math.ceil(threshold / 3600)
      if (hours > threshold) {
        const afterRate = parseInt(settings.price_after_first_hour || 0)
        return (threshold * rate) + ((hours - threshold) * afterRate)
      }
    }
    return hours * rate
  }

  return 0
}
