-- Location: supabase/migrations/20260113193808_add_authentication_system.sql
-- Schema Analysis: user_profiles table and handle_new_user function already exist
-- Integration Type: extension
-- Dependencies: user_profiles, user_role enum, handle_new_user function

-- =====================================================
-- AUTHENTICATION SYSTEM EXTENSION
-- =====================================================
-- This migration adds authentication capabilities to existing user_profiles table
-- Existing: user_profiles table, user_role enum, handle_new_user function
-- New: Trigger linkage, auth policies, mock users for testing

-- =====================================================
-- TRIGGER SETUP
-- =====================================================

-- Link handle_new_user function to auth.users table
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- ADDITIONAL RLS POLICIES
-- =====================================================

-- Ensure users can read their own profile data
DROP POLICY IF EXISTS "users_read_own_profile" ON public.user_profiles;

CREATE POLICY "users_read_own_profile"
  ON public.user_profiles
  FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- =====================================================
-- MOCK AUTHENTICATION DATA FOR TESTING
-- =====================================================

DO $$
DECLARE
  admin_id UUID := gen_random_uuid();
  caja_id UUID := gen_random_uuid();
  mesero_id UUID := gen_random_uuid();
  cocina_id UUID := gen_random_uuid();
BEGIN
  -- Insert test users into auth.users with complete field structure
  INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
    created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
    is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
    recovery_token, recovery_sent_at, email_change_token_new, email_change,
    email_change_sent_at, email_change_token_current, email_change_confirm_status,
    reauthentication_token, reauthentication_sent_at, phone, phone_change,
    phone_change_token, phone_change_sent_at
  ) VALUES
    -- Admin User
    (
      admin_id, 
      '00000000-0000-0000-0000-000000000000', 
      'authenticated', 
      'authenticated',
      'admin@cafepos.com', 
      crypt('admin123', gen_salt('bf', 10)), 
      now(), 
      now(), 
      now(),
      jsonb_build_object('full_name', 'Administrador POS', 'role', 'admin', 'phone', '70123456', 'pin_code', '1234'),
      jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
      false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
    ),
    -- Caja User
    (
      caja_id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      'cajero@cafepos.com',
      crypt('cajero123', gen_salt('bf', 10)),
      now(),
      now(),
      now(),
      jsonb_build_object('full_name', 'Usuario Caja', 'role', 'cashier', 'phone', '71234567', 'pin_code', '5678'),
      jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
      false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
    ),
    -- Mesero User
    (
      mesero_id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      'mesero@cafepos.com',
      crypt('mesero123', gen_salt('bf', 10)),
      now(),
      now(),
      now(),
      jsonb_build_object('full_name', 'Usuario Mesero', 'role', 'waiter', 'phone', '72345678', 'pin_code', '9012'),
      jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
      false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
    ),
    -- Cocina User
    (
      cocina_id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      'cocina@cafepos.com',
      crypt('cocina123', gen_salt('bf', 10)),
      now(),
      now(),
      now(),
      jsonb_build_object('full_name', 'Usuario Cocina', 'role', 'kitchen', 'phone', '73456789', 'pin_code', '3456'),
      jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
      false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
    );

  RAISE NOTICE 'Authentication system configured successfully';
  RAISE NOTICE 'Test users created - check login screen for credentials';

EXCEPTION
  WHEN unique_violation THEN
    RAISE NOTICE 'Test users already exist';
  WHEN OTHERS THEN
    RAISE NOTICE 'Error creating test users: %', SQLERRM;
END $$;