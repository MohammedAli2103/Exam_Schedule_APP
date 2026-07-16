-- Migration to alter public.app_config table safely without recreating it

-- 1. Remove force_update column
ALTER TABLE public.app_config 
DROP COLUMN IF EXISTS force_update;

-- 2. Add minimum_supported_version column (non-nullable with default value '1.0.0')
ALTER TABLE public.app_config 
ADD COLUMN IF NOT EXISTS minimum_supported_version TEXT NOT NULL DEFAULT '1.0.0';

-- 3. (Optional / Safe-keeping) Ensure updated_at column exists
ALTER TABLE public.app_config 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW());
