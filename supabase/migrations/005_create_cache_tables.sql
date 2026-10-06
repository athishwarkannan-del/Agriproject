-- 005_create_cache_tables.sql

CREATE TABLE IF NOT EXISTS public.crop_information (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name_en TEXT NOT NULL,
    name_ta TEXT NOT NULL,
    category TEXT,
    season TEXT,
    soil_type TEXT,
    water_requirement TEXT,
    growing_period_days INTEGER,
    description_en TEXT,
    description_ta TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.crop_information ENABLE ROW LEVEL SECURITY;

-- Reference table: anyone authenticated can read
CREATE POLICY "Anyone can read crop information" 
    ON public.crop_information FOR SELECT 
    USING (auth.role() = 'authenticated');
