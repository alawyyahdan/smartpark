import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// Helper: apply app branding (favicon + title) from settings
export async function applyAppBranding(pageSuffix = '') {
  const { data } = await supabase
    .from('settings')
    .select('key, value')
    .in('key', ['app_name', 'app_favicon'])
  
  if (data) {
    data.forEach(s => {
      if (s.key === 'app_name' && s.value) {
        document.title = pageSuffix ? `${s.value} — ${pageSuffix}` : s.value
      }
      if (s.key === 'app_favicon' && s.value) {
        let link = document.querySelector("link[rel~='icon']")
        if (!link) { link = document.createElement('link'); link.rel = 'icon'; document.head.appendChild(link) }
        link.href = s.value
      }
    })
  }
}
