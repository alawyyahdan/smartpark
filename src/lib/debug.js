/**
 * Dev-only logger. No-op in production builds (import.meta.env.PROD === true).
 *
 * Usage:
 *   import { debug } from '@/lib/debug.js'
 *   debug('LOCK', 'slot acquired:', slot.id)
 *
 * The first argument is a tag (rendered as `[TAG]`). Remaining args are forwarded to console.log.
 * Use this instead of bare console.log so production bundles stay quiet without manual guards.
 */
export function debug(tag, ...args) {
  if (!import.meta.env.DEV) return
  console.log(`[${tag}]`, ...args)
}
