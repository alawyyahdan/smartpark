import { createRouter, createWebHistory } from 'vue-router'
import TicketView from '../views/TicketView.vue'
import VisitorView from '../views/VisitorView.vue'
import AdminView from '../views/AdminView.vue'
import LoginView from '../views/LoginView.vue'
import ExitGateView from '../views/ExitGateView.vue'
import { supabase } from '../lib/supabase.js'

const adminPath = import.meta.env.VITE_ADMIN_PATH || '/admin'

const routes = [
  {
    path: '/',
    redirect: '/ticket'
  },
  {
    path: '/ticket',
    name: 'ticket',
    component: TicketView,
    meta: { titleSuffix: '— Gate Operator' }
  },
  {
    path: '/visitor',
    name: 'visitor',
    component: VisitorView,
    meta: { titleSuffix: '— Panduan Parkir' }
  },
  {
    path: '/keluar',
    name: 'exit-gate',
    component: ExitGateView,
    meta: { titleSuffix: '— Gate Keluar' }
  },
  {
    path: `${adminPath}/login`,
    name: 'login',
    component: LoginView,
    meta: { titleSuffix: '— Login Admin' }
  },
  {
    path: adminPath,
    name: 'admin',
    component: AdminView,
    meta: { titleSuffix: '— Admin Panel', requiresAuth: true }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// Cache branding agar tidak fetch ulang setiap navigasi
let cachedAppName = null
let cachedFavicon = null

async function applyBranding(titleSuffix) {
  // Fetch dari DB sekali lalu cache
  if (!cachedAppName) {
    const { data } = await supabase
      .from('settings')
      .select('key, value')
      .in('key', ['app_name', 'app_favicon'])
    if (data) {
      data.forEach(s => {
        if (s.key === 'app_name') cachedAppName = s.value || 'SmartPark'
        if (s.key === 'app_favicon') cachedFavicon = s.value || null
      })
    }
    if (!cachedAppName) cachedAppName = 'SmartPark'
  }

  // Apply title
  document.title = titleSuffix
    ? `${cachedAppName} ${titleSuffix}`
    : cachedAppName

  // Apply favicon
  if (cachedFavicon) {
    let link = document.querySelector("link[rel~='icon']")
    if (!link) {
      link = document.createElement('link')
      link.rel = 'icon'
      document.head.appendChild(link)
    }
    link.href = cachedFavicon
  }
}

// Dipanggil dari AdminView.saveSettings() setelah settings disimpan
export function invalidateBrandingCache() {
  cachedAppName = null
  cachedFavicon = null
}

router.beforeEach(async (to) => {
  try {
    await applyBranding(to.meta.titleSuffix || '')
  } catch (err) {
    console.warn('Branding fetch failed:', err.message)
  }

  // Check auth for protected routes
  if (to.meta.requiresAuth) {
    const { data: { session } } = await supabase.auth.getSession()
    if (!session) {
      return `${adminPath}/login`
    }
  }
})

export default router
