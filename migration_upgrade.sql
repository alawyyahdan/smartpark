-- ============================================================
-- SmartPark Database UPGRADE Migration
-- Untuk database yang SUDAH menjalankan migration.sql versi lama
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard
-- ============================================================

-- ============================================================
-- STEP 1: Enable pgcrypto extension (untuk password hashing)
-- ============================================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================
-- STEP 2: Rename kolom password → password_hash + hash existing data
-- ============================================================
ALTER TABLE public.gate_accounts 
  RENAME COLUMN password TO password_hash;

ALTER TABLE public.gate_accounts 
  ALTER COLUMN password_hash TYPE VARCHAR(255);

-- Hash semua password plaintext yang sudah ada
-- (bcrypt hash selalu dimulai dengan $2, jadi kita skip yang sudah di-hash)
UPDATE public.gate_accounts
SET password_hash = crypt(password_hash, gen_salt('bf'))
WHERE password_hash NOT LIKE '$2%';

-- ============================================================
-- STEP 3: Buat RPC functions untuk login & create account
-- ============================================================

-- RPC: verify gate account password (aman, hash tidak pernah dikirim ke client)
CREATE OR REPLACE FUNCTION public.verify_gate_login(p_username TEXT, p_password TEXT)
RETURNS TABLE(id INT, username VARCHAR, current_gate INT, is_online BOOLEAN) AS $$
BEGIN
  RETURN QUERY
    SELECT ga.id, ga.username, ga.current_gate, ga.is_online
    FROM public.gate_accounts ga
    WHERE ga.username = p_username
      AND ga.password_hash = crypt(p_password, ga.password_hash);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: create gate account with hashed password
CREATE OR REPLACE FUNCTION public.create_gate_account(p_username TEXT, p_password TEXT)
RETURNS void AS $$
BEGIN
  INSERT INTO public.gate_accounts (username, password_hash)
  VALUES (p_username, crypt(p_password, gen_salt('bf')));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- STEP 4: Drop old RLS policies (yang terlalu permisif)
-- ============================================================

-- Tickets
DROP POLICY IF EXISTS "Allow anon on tickets" ON public.tickets;

-- Parking Slots
DROP POLICY IF EXISTS "Allow anon on parking_slots" ON public.parking_slots;

-- Parking Areas
DROP POLICY IF EXISTS "Allow anon on parking_areas" ON public.parking_areas;

-- Sessions
DROP POLICY IF EXISTS "Allow anon on sessions" ON public.sessions;

-- Settings
DROP POLICY IF EXISTS "Allow anon on settings" ON public.settings;

-- Exit Gates
DROP POLICY IF EXISTS "Allow anon on exit_gates" ON public.exit_gates;

-- Gate Accounts
DROP POLICY IF EXISTS "Allow anon on gate_accounts" ON public.gate_accounts;

-- MQTT Logs
DROP POLICY IF EXISTS "Allow anon on mqtt_logs" ON public.mqtt_logs;

-- ============================================================
-- STEP 5: Buat RLS policies baru yang restricted
-- ============================================================

-- Tickets: anon bisa read + insert + update (visitor flow)
CREATE POLICY "Allow anon select on tickets" ON public.tickets
  FOR SELECT TO anon USING (true);
CREATE POLICY "Allow anon insert on tickets" ON public.tickets
  FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Allow anon update on tickets" ON public.tickets
  FOR UPDATE TO anon USING (true) WITH CHECK (true);

-- Parking Slots: anon bisa read + update (lock/unlock)
CREATE POLICY "Allow anon select on parking_slots" ON public.parking_slots
  FOR SELECT TO anon USING (true);
CREATE POLICY "Allow anon update on parking_slots" ON public.parking_slots
  FOR UPDATE TO anon USING (true) WITH CHECK (true);

-- Parking Areas: anon read-only
CREATE POLICY "Allow anon select on parking_areas" ON public.parking_areas
  FOR SELECT TO anon USING (true);

-- Sessions: anon bisa read + insert + update (visitor creates/updates session)
CREATE POLICY "Allow anon select on sessions" ON public.sessions
  FOR SELECT TO anon USING (true);
CREATE POLICY "Allow anon insert on sessions" ON public.sessions
  FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Allow anon update on sessions" ON public.sessions
  FOR UPDATE TO anon USING (true) WITH CHECK (true);

-- Settings: anon read-only
CREATE POLICY "Allow anon select on settings" ON public.settings
  FOR SELECT TO anon USING (true);

-- Exit Gates: anon read-only
CREATE POLICY "Allow anon select on exit_gates" ON public.exit_gates
  FOR SELECT TO anon USING (true);

-- Gate Accounts: anon bisa read + update (login/heartbeat)
CREATE POLICY "Allow anon select on gate_accounts" ON public.gate_accounts
  FOR SELECT TO anon USING (true);
CREATE POLICY "Allow anon update on gate_accounts" ON public.gate_accounts
  FOR UPDATE TO anon USING (true) WITH CHECK (true);

-- MQTT Logs: anon read-only
CREATE POLICY "Allow anon select on mqtt_logs" ON public.mqtt_logs
  FOR SELECT TO anon USING (true);

-- ============================================================
-- STEP 6: Fix Storage Policies untuk vehicle-images bucket
-- ============================================================

-- Pastikan bucket ada
INSERT INTO storage.buckets (id, name, public)
VALUES ('vehicle-images', 'vehicle-images', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Drop old storage policies (kalau ada) lalu buat ulang
DROP POLICY IF EXISTS "Allow public upload" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read" ON storage.objects;
DROP POLICY IF EXISTS "Allow public update" ON storage.objects;
DROP POLICY IF EXISTS "Allow public delete" ON storage.objects;

CREATE POLICY "Allow public upload" ON storage.objects
  FOR INSERT TO anon WITH CHECK (bucket_id = 'vehicle-images');
CREATE POLICY "Allow public read" ON storage.objects
  FOR SELECT TO anon USING (bucket_id = 'vehicle-images');
CREATE POLICY "Allow public update" ON storage.objects
  FOR UPDATE TO anon USING (bucket_id = 'vehicle-images');
CREATE POLICY "Allow public delete" ON storage.objects
  FOR DELETE TO anon USING (bucket_id = 'vehicle-images');

-- Juga allow authenticated (admin)
CREATE POLICY "Allow authenticated upload" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'vehicle-images');
CREATE POLICY "Allow authenticated read" ON storage.objects
  FOR SELECT TO authenticated USING (bucket_id = 'vehicle-images');
CREATE POLICY "Allow authenticated update" ON storage.objects
  FOR UPDATE TO authenticated USING (bucket_id = 'vehicle-images');
CREATE POLICY "Allow authenticated delete" ON storage.objects
  FOR DELETE TO authenticated USING (bucket_id = 'vehicle-images');

-- ============================================================
-- DONE! Verifikasi:
-- 1. Cek gate_accounts: SELECT id, username, password_hash FROM gate_accounts;
--    → password_hash harus dimulai dengan $2b$ (bcrypt)
-- 2. Test login via app
-- 3. Test create akun baru via admin panel
-- 4. Test ambil tiket dengan kamera → foto harus tersimpan
-- ============================================================
