-- 002_create_farmer_profiles.sql
CREATE TABLE IF NOT EXISTS public.farmer_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT,
    preferred_language TEXT DEFAULT 'ta' CHECK (preferred_language IN ('ta', 'en')),
    district TEXT,
    state TEXT DEFAULT 'Tamil Nadu',
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    farm_size_acres NUMERIC,
    soil_type TEXT,
    water_source TEXT,
    primary_crops TEXT[],
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id)
);

-- Enable RLS
ALTER TABLE public.farmer_profiles ENABLE ROW LEVEL SECURITY;

-- Profiles are viewable by the user who created them
CREATE POLICY "Users can view own profile" 
    ON public.farmer_profiles FOR SELECT 
    USING (auth.uid() = user_id);

-- Profiles are insertable by the user who created them
CREATE POLICY "Users can insert own profile" 
    ON public.farmer_profiles FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- Profiles are updatable by the user who created them
CREATE POLICY "Users can update own profile" 
    ON public.farmer_profiles FOR UPDATE 
    USING (auth.uid() = user_id);
