/**
 * Shared branding helpers used by every view that needs to react to
 * `settings.app_name` and `settings.app_favicon` changes.
 *
 * The router holds the cached values (lib/router has its own cache
 * via applyBranding/invalidateBrandingCache) — these helpers simply do the
 * idempotent DOM mutations so individual views don't have to repeat the
 * favicon-injection dance everywhere.
 */

export function applyFavicon(href) {
  if (!href) return
  let link = document.querySelector("link[rel~='icon']")
  if (!link) {
    link = document.createElement('link')
    link.rel = 'icon'
    document.head.appendChild(link)
  }
  link.href = href
}

export function applyTitle(appName, suffix = '') {
  if (!appName) return
  document.title = suffix ? `${appName} ${suffix}` : appName
}
