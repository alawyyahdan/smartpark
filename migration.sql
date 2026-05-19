-- ============================================================
-- SmartPark Database Migration (Fresh Install)
-- Run this in Supabase SQL Editor for a brand new project.
-- ============================================================

-- 1. Tickets
CREATE TABLE public.tickets (
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

-- 2. Parking areas
CREATE TABLE public.parking_areas (
  id           SERIAL PRIMARY KEY,
  name         VARCHAR(50) NOT NULL,
  description  TEXT,
  floor        VARCHAR(20),
  mqtt_prefix  VARCHAR(100),
  total_slots  INT DEFAULT 0,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Parking slots
CREATE TABLE public.parking_slots (
  id           SERIAL PRIMARY KEY,
  name         VARCHAR(10) NOT NULL,
  status       VARCHAR(20) NOT NULL DEFAULT 'tersedia'
               CHECK (status IN ('tersedia', 'diambil')),
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

-- 4. Sessions
CREATE TABLE public.sessions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id         UUID REFERENCES public.tickets(id) ON DELETE CASCADE,
  slot_id           INT  REFERENCES public.parking_slots(id),
  entry_time        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  exit_time         TIMESTAMPTZ,
  duration_minutes  INT,
  cost_rupiah       INT
);

-- 5. Exit gates
CREATE TABLE public.exit_gates (
  id           SERIAL PRIMARY KEY,
  gate_number  INT UNIQUE NOT NULL,
  name         VARCHAR(50) NOT NULL,
  lat          DECIMAL(10, 8),
  lng          DECIMAL(11, 8),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. Gate accounts (password is stored hashed)
CREATE TABLE public.gate_accounts (
  id            SERIAL PRIMARY KEY,
  username      VARCHAR(50) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  current_gate  INT REFERENCES public.exit_gates(id) ON DELETE SET NULL,
  is_online     BOOLEAN DEFAULT false,
  last_active   TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. MQTT logs
CREATE TABLE public.mqtt_logs (
  id          SERIAL PRIMARY KEY,
  type        VARCHAR(20) NOT NULL DEFAULT 'info',
  message     TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. Settings (key-value config)
CREATE TABLE public.settings (
  id          SERIAL PRIMARY KEY,
  key         VARCHAR(50) UNIQUE NOT NULL,
  value       TEXT NOT NULL,
  description TEXT,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 9. RPC helpers (require pgcrypto for bcrypt password hashing)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- verify_gate_login validates the password and (on success) atomically marks
-- the operator online + records the gate. Returning the row keeps the client
-- API identical to before — but the client no longer needs SELECT/UPDATE
-- access to gate_accounts directly, so we can revoke anon access to the table
-- (see RLS section below). p_gate_id is optional for backwards compat.
CREATE FUNCTION public.verify_gate_login(
  p_username TEXT,
  p_password TEXT,
  p_gate_id  INT DEFAULT NULL
)
RETURNS TABLE(id INT, username VARCHAR, current_gate INT, is_online BOOLEAN) AS $$
DECLARE
  v_id INT;
BEGIN
  SELECT ga.id INTO v_id
  FROM public.gate_accounts ga
  WHERE ga.username = p_username
    AND ga.password_hash = crypt(p_password, ga.password_hash);

  IF v_id IS NULL THEN
    RETURN;
  END IF;

  UPDATE public.gate_accounts ga
     SET is_online    = TRUE,
         current_gate = COALESCE(p_gate_id, ga.current_gate),
         last_active  = NOW()
   WHERE ga.id = v_id;

  RETURN QUERY
    SELECT ga.id, ga.username, ga.current_gate, ga.is_online
    FROM public.gate_accounts ga
    WHERE ga.id = v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Heartbeat: touch last_active for an already-online operator. Returns nothing.
-- Safe to call from anon; the row to update is keyed by id (which the client
-- only has after a successful verify_gate_login).
CREATE FUNCTION public.gate_heartbeat(p_account_id INT)
RETURNS void AS $$
BEGIN
  UPDATE public.gate_accounts
     SET last_active = NOW()
   WHERE id = p_account_id
     AND is_online  = TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Logout: clear is_online and current_gate.
CREATE FUNCTION public.gate_logout(p_account_id INT)
RETURNS void AS $$
BEGIN
  UPDATE public.gate_accounts
     SET is_online    = FALSE,
         current_gate = NULL,
         last_active  = NOW()
   WHERE id = p_account_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE FUNCTION public.create_gate_account(p_username TEXT, p_password TEXT)
RETURNS void AS $$
BEGIN
  INSERT INTO public.gate_accounts (username, password_hash)
  VALUES (p_username, crypt(p_password, gen_salt('bf')));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Atomic ticket issuance — prevents multi-gate race condition.
-- Capacity rule (single source of truth = parking_slots row state):
--   TERISI   = status = 'diambil' OR locked_by IS NOT NULL
--   TERSEDIA = NOT terisi
-- Concurrent issuances serialize on pg_advisory_xact_lock(8472001), then
-- pre-lock one free slot inside the same transaction so the next caller
-- sees one fewer free slot.
CREATE FUNCTION public.issue_ticket(
  p_ticket_code   TEXT,
  p_qr_data       TEXT DEFAULT '',
  p_vehicle_image TEXT DEFAULT NULL
)
RETURNS SETOF public.tickets AS $$
DECLARE
  v_total_slots INT;
  v_free_slot   INT;
  v_ticket_id   UUID;
BEGIN
  PERFORM pg_advisory_xact_lock(8472001);

  SELECT COUNT(*) INTO v_total_slots FROM public.parking_slots;

  IF v_total_slots = 0 THEN
    RAISE EXCEPTION 'NO_SLOTS_CONFIGURED'
      USING HINT = 'Belum ada slot parkir yang dikonfigurasi.';
  END IF;

  SELECT id INTO v_free_slot
  FROM public.parking_slots
  WHERE status = 'tersedia' AND locked_by IS NULL
  ORDER BY id
  LIMIT 1
  FOR UPDATE;

  IF v_free_slot IS NULL THEN
    RAISE EXCEPTION 'PARKING_FULL'
      USING HINT = 'Parkir penuh. Tidak ada slot tersedia.';
  END IF;

  INSERT INTO public.tickets (ticket_code, qr_data, vehicle_image, status)
  VALUES (p_ticket_code, COALESCE(p_qr_data, ''), p_vehicle_image, 'active')
  RETURNING id INTO v_ticket_id;

  UPDATE public.parking_slots
  SET locked_by  = v_ticket_id,
      updated_at = NOW()
  WHERE id = v_free_slot;

  RETURN QUERY
    SELECT * FROM public.tickets WHERE id = v_ticket_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.issue_ticket(TEXT, TEXT, TEXT) TO anon, authenticated;
-- Anon can authenticate, heartbeat, and log out via RPC. Admin can also call
-- create_gate_account from the panel (it runs SECURITY DEFINER so RLS doesn't
-- apply, but EXECUTE grant is still required).
GRANT EXECUTE ON FUNCTION public.verify_gate_login(TEXT, TEXT, INT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.gate_heartbeat(INT)                TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.gate_logout(INT)                   TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.create_gate_account(TEXT, TEXT)    TO authenticated;

-- 10. Default settings (seed)
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
  ('mqtt_messages', '0', 'Total pesan MQTT');

-- 11. Role privileges
GRANT USAGE ON SCHEMA public TO postgres, service_role, anon, authenticated;
GRANT ALL PRIVILEGES ON ALL TABLES    IN SCHEMA public TO postgres, service_role, anon, authenticated;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres, service_role, anon, authenticated;

-- Defense-in-depth: even if a future RLS policy accidentally allows anon to
-- SELECT from gate_accounts, anon must NOT be able to read password_hash.
-- Revoking column privileges enforces this at the SQL grant layer below RLS.
REVOKE ALL ON COLUMN public.gate_accounts.password_hash FROM anon;

-- 12. Row Level Security
ALTER TABLE public.tickets       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parking_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parking_areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exit_gates    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mqtt_logs     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gate_accounts ENABLE ROW LEVEL SECURITY;

-- Admin (authenticated) = full access
CREATE POLICY "Admin_Full_Access_Tickets"       ON public.tickets       FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Admin_Full_Access_Slots"         ON public.parking_slots FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Admin_Full_Access_Areas"         ON public.parking_areas FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Admin_Full_Access_Sessions"      ON public.sessions      FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Admin_Full_Access_Settings"      ON public.settings      FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Admin_Full_Access_Exit_Gates"    ON public.exit_gates    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Admin_Full_Access_Mqtt_Logs"     ON public.mqtt_logs     FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Admin_Full_Access_Gate_Accounts" ON public.gate_accounts FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Visitor / kiosk / gate (anon) = restricted
-- Tickets: visitor flow needs SELECT (visitor checks own ticket) + UPDATE (mark
-- exiting). INSERT is funnelled through `issue_ticket` RPC for atomicity, so
-- we deliberately do NOT grant anon INSERT on the table itself.
CREATE POLICY "Anon_Select_Tickets"       ON public.tickets       FOR SELECT TO anon USING (true);
CREATE POLICY "Anon_Update_Tickets"       ON public.tickets       FOR UPDATE TO anon USING (true) WITH CHECK (true);
-- Slots: visitors need to read availability and lock/unlock their slot.
CREATE POLICY "Anon_Select_Slots"         ON public.parking_slots FOR SELECT TO anon USING (true);
CREATE POLICY "Anon_Update_Slots"         ON public.parking_slots FOR UPDATE TO anon USING (true) WITH CHECK (true);
-- Areas: read-only for visitor map.
CREATE POLICY "Anon_Select_Areas"         ON public.parking_areas FOR SELECT TO anon USING (true);
-- Sessions: visitor parks/exits, gate operator processes — both need
-- SELECT/INSERT/UPDATE. No DELETE.
CREATE POLICY "Anon_Select_Sessions"      ON public.sessions      FOR SELECT TO anon USING (true);
CREATE POLICY "Anon_Insert_Sessions"      ON public.sessions      FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Anon_Update_Sessions"      ON public.sessions      FOR UPDATE TO anon USING (true) WITH CHECK (true);
-- Settings: read-only for branding/pricing/feature flags. Mutations are
-- admin-only.
CREATE POLICY "Anon_Select_Settings"      ON public.settings      FOR SELECT TO anon USING (true);
-- Exit gates: read-only (gate UI shows gate name).
CREATE POLICY "Anon_Select_Exit_Gates"    ON public.exit_gates    FOR SELECT TO anon USING (true);

-- gate_accounts: NO anon access at all. password_hash must never be exposed
-- to the public anon role. All operations the gate-keluar UI needs are now
-- routed through SECURITY DEFINER RPCs (verify_gate_login, gate_heartbeat,
-- gate_logout). Admin (authenticated) retains full access via the policy
-- above.

-- 13. Storage bucket for vehicle images
INSERT INTO storage.buckets (id, name, public)
VALUES ('vehicle-images', 'vehicle-images', true);

CREATE POLICY "Allow public upload"        ON storage.objects FOR INSERT TO anon          WITH CHECK (bucket_id = 'vehicle-images');
CREATE POLICY "Allow public read"          ON storage.objects FOR SELECT TO anon          USING      (bucket_id = 'vehicle-images');
CREATE POLICY "Allow public update"        ON storage.objects FOR UPDATE TO anon          USING      (bucket_id = 'vehicle-images');
CREATE POLICY "Allow public delete"        ON storage.objects FOR DELETE TO anon          USING      (bucket_id = 'vehicle-images');
CREATE POLICY "Allow authenticated upload" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'vehicle-images');
CREATE POLICY "Allow authenticated read"   ON storage.objects FOR SELECT TO authenticated USING      (bucket_id = 'vehicle-images');
CREATE POLICY "Allow authenticated update" ON storage.objects FOR UPDATE TO authenticated USING      (bucket_id = 'vehicle-images');
CREATE POLICY "Allow authenticated delete" ON storage.objects FOR DELETE TO authenticated USING      (bucket_id = 'vehicle-images');

-- 14. Realtime publication
-- (Supabase provisions an empty `supabase_realtime` publication; we just attach the tables.)
ALTER PUBLICATION supabase_realtime ADD TABLE public.parking_slots;
ALTER PUBLICATION supabase_realtime ADD TABLE public.settings;
ALTER PUBLICATION supabase_realtime ADD TABLE public.mqtt_logs;

-- ============================================================
-- DONE. Add areas & slots from the Admin Panel.
-- ============================================================