-- Migration: Populate PIN codes for existing users
-- Purpose: Add missing PIN codes to user_profiles to enable PIN authentication
-- Timestamp: 20260113200634

-- Update user profiles with PIN codes matching the demo credentials
UPDATE user_profiles
SET pin_code = '1234'
WHERE email = 'admin@cafepos.com';

UPDATE user_profiles
SET pin_code = '5678'
WHERE email = 'cajero@cafepos.com';

UPDATE user_profiles
SET pin_code = '9012'
WHERE email = 'mesero@cafepos.com';

UPDATE user_profiles
SET pin_code = '3456'
WHERE email = 'cocina@cafepos.com';

-- Add check constraint to ensure PIN codes are exactly 4 digits (optional but recommended)
ALTER TABLE user_profiles
ADD CONSTRAINT check_pin_code_format CHECK (
    pin_code IS NULL OR (pin_code ~ '^\d{4}$')
);

-- Create index on pin_code for faster PIN-based authentication
CREATE INDEX IF NOT EXISTS idx_user_profiles_pin_code ON user_profiles(pin_code)
WHERE pin_code IS NOT NULL;

-- Add comment explaining PIN code format
COMMENT ON COLUMN user_profiles.pin_code IS 'User PIN code for quick login - must be exactly 4 digits';