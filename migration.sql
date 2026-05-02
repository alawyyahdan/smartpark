-- ============================================================
-- SmartPark Database Migration
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard
-- ============================================================

-- 1. Tickets table
CREATE TABLE IF NOT EXISTS public.tickets (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_code   VARCHAR(30) UNIQUE NOT NULL,
  qr_data       TEXT NOT NULL DEFAULT '',
  vehicle_image TEXT,
  status        VARCHAR(20) NOT NULL DEFAULT 'active'
                CHECK (status IN ('active', 'parked', 'exiting', 'done', 'expired')),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  parked_at     TIMESTAMPTZ,
  exited_at     TIMESTAMPTZ
);

-- 2. Parking areas table
CREATE TABLE IF NOT EXISTS public.parking_areas (
  id           SERIAL PRIMARY KEY,
  name         VARCHAR(50) NOT NULL,
  description  TEXT,
  floor        VARCHAR(20),
  mqtt_prefix  VARCHAR(100),
  total_slots  INT DEFAULT 0,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Parking slots table
CREATE TABLE IF NOT EXISTS public.parking_slots (
  id           SERIAL PRIMARY KEY,
  name         VARCHAR(10) NOT NULL,
  status       VARCHAR(20) NOT NULL DEFAULT 'available'
               CHECK (status IN ('available', 'occupied')),
  area_id      INT REFERENCES public.parking_areas(id) ON DELETE CASCADE,
  lat          DECIMAL(10, 8),
  lng          DECIMAL(11, 8),
  rotation     INT DEFAULT 0,
  slot_width   DECIMAL(4, 1) DEFAULT 3,
  slot_height  DECIMAL(4, 1) DEFAULT 5,
  mqtt_topic   VARCHAR(100),
  locked_by    UUID REFERENCES public.tickets(id) ON DELETE SET NULL,
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Sessions table
CREATE TABLE IF NOT EXISTS public.sessions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id         UUID REFERENCES public.tickets(id) ON DELETE CASCADE,
  slot_id           INT  REFERENCES public.parking_slots(id),
  entry_time        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  exit_time         TIMESTAMPTZ,
  duration_minutes  INT,
  cost_rupiah       INT
);

-- 5. Exit Gates table
CREATE TABLE IF NOT EXISTS public.exit_gates (
  id           SERIAL PRIMARY KEY,
  gate_number  INT UNIQUE NOT NULL,
  name         VARCHAR(50) NOT NULL,
  lat          DECIMAL(10, 8),
  lng          DECIMAL(11, 8),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. Gate Accounts table
CREATE TABLE IF NOT EXISTS public.gate_accounts (
  id           SERIAL PRIMARY KEY,
  username     VARCHAR(50) UNIQUE NOT NULL,
  password     VARCHAR(100) NOT NULL,
  current_gate INT REFERENCES public.exit_gates(id) ON DELETE SET NULL,
  is_online    BOOLEAN DEFAULT false,
  last_active  TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. MQTT Logs table
CREATE TABLE IF NOT EXISTS public.mqtt_logs (
  id          SERIAL PRIMARY KEY,
  type        VARCHAR(20) NOT NULL DEFAULT 'info',
  message     TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. Settings table
CREATE TABLE IF NOT EXISTS public.settings (
  id          SERIAL PRIMARY KEY,
  key         VARCHAR(50) UNIQUE NOT NULL,
  value       TEXT NOT NULL,
  description TEXT,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. Seed default settings
INSERT INTO public.settings (key, value, description) VALUES
  ('pricing_mode', 'per_hour', 'Mode harga: per_minute, per_hour'),
  ('price_per_minute', '500', 'Harga per menit (Rp)'),
  ('price_first_hour', '5000', 'Harga per jam (Rp)'),
  ('price_after_first_hour', '3000', 'Harga khusus setelah threshold (Rp)'),
  ('price_threshold', '1', 'Threshold untuk harga khusus'),
  ('threshold_unit', 'hour', 'Unit threshold: hour, minute, second'),
  ('special_price_enabled', 'false', 'Enable harga khusus'),
  ('free_parking_enabled', 'false', 'Enable bebas biaya'),
  ('free_duration', '15', 'Durasi bebas biaya'),
  ('free_duration_unit', 'minute', 'Unit durasi bebas: hour, minute, second'),
  ('app_name', 'SmartPark', 'Nama aplikasi'),
  ('app_favicon', '', 'URL favicon'),
  ('ticket_prefix', 'SP', 'Prefix kode tiket'),
  ('idle_timeout', '20', 'Timeout idle lock slot (menit)'),
  ('default_lat', '-7.2650876', 'Default latitude peta'),
  ('default_lng', '112.783217', 'Default longitude peta'),
  ('exit_cooldown', '5', 'Cooldown menit sebelum bisa keluar parkir'),
  ('debug_mode', 'false', 'Enable debug mode'),
  ('map_engine', 'maplibre', 'Map engine: maplibre, leaflet'),
  ('nav_line_color', '#4285F4', 'Warna garis navigasi'),
  ('app_url', 'http://localhost:5173', 'URL website (untuk QR code dll)'),
  ('mqtt_broker', '', 'MQTT broker URL'),
  ('mqtt_username', '', 'MQTT username'),
  ('mqtt_password', '', 'MQTT password'),
  ('mqtt_enabled', 'false', 'MQTT bridge on/off'),
  ('mqtt_connected_at', '', 'Waktu MQTT bridge connect'),
  ('mqtt_status', 'offline', 'Status MQTT bridge'),
  ('mqtt_messages', '0', 'Total pesan MQTT')
ON CONFLICT (key) DO NOTHING;

-- 9. Enable Row Level Security (RLS)
ALTER TABLE public.tickets       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parking_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parking_areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exit_gates    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mqtt_logs     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gate_accounts ENABLE ROW LEVEL SECURITY;

-- 8. RLS Policies

-- Tickets: allow both authenticated & anon
CREATE POLICY "Allow authenticated on tickets" ON public.tickets
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon on tickets" ON public.tickets
  FOR ALL TO anon USING (true) WITH CHECK (true);

-- Parking Slots: allow both
CREATE POLICY "Allow authenticated on parking_slots" ON public.parking_slots
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon on parking_slots" ON public.parking_slots
  FOR ALL TO anon USING (true) WITH CHECK (true);

-- Parking Areas: allow both
CREATE POLICY "Allow authenticated on parking_areas" ON public.parking_areas
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon on parking_areas" ON public.parking_areas
  FOR ALL TO anon USING (true) WITH CHECK (true);

-- Sessions: allow both
CREATE POLICY "Allow authenticated on sessions" ON public.sessions
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon on sessions" ON public.sessions
  FOR ALL TO anon USING (true) WITH CHECK (true);

-- Settings: allow both
CREATE POLICY "Allow authenticated on settings" ON public.settings
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon on settings" ON public.settings
  FOR ALL TO anon USING (true) WITH CHECK (true);

-- Exit Gates: allow both
CREATE POLICY "Allow authenticated on exit_gates" ON public.exit_gates
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon on exit_gates" ON public.exit_gates
  FOR ALL TO anon USING (true) WITH CHECK (true);

-- Gate Accounts: allow both
CREATE POLICY "Allow authenticated on gate_accounts" ON public.gate_accounts
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon on gate_accounts" ON public.gate_accounts
  FOR ALL TO anon USING (true) WITH CHECK (true);

-- MQTT Logs: allow both
CREATE POLICY "Allow authenticated on mqtt_logs" ON public.mqtt_logs
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon on mqtt_logs" ON public.mqtt_logs
  FOR ALL TO anon USING (true) WITH CHECK (true);

-- 11. Create Storage Bucket for vehicle images
INSERT INTO storage.buckets (id, name, public)
VALUES ('vehicle-images', 'vehicle-images', true)
ON CONFLICT (id) DO NOTHING;

-- 10. Storage Policies
CREATE POLICY "Allow public upload" ON storage.objects
  FOR INSERT TO anon WITH CHECK (bucket_id = 'vehicle-images');
CREATE POLICY "Allow public read" ON storage.objects
  FOR SELECT TO anon USING (bucket_id = 'vehicle-images');
CREATE POLICY "Allow public update" ON storage.objects
  FOR UPDATE TO anon USING (bucket_id = 'vehicle-images');
CREATE POLICY "Allow public delete" ON storage.objects
  FOR DELETE TO anon USING (bucket_id = 'vehicle-images');

-- ============================================================
-- CATATAN: Slot parkir TIDAK di-seed otomatis
-- Admin harus menambahkan area dan slot via Admin Panel
-- ============================================================
