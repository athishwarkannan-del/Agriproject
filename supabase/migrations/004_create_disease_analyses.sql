-- 004_create_disease_analyses.sql

CREATE TABLE IF NOT EXISTS public.disease_analyses (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    image_size_bytes INTEGER,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending','processing','completed','failed')),
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.disease_predictions (
    id UUID PRIMARY KEY,
    analysis_id UUID REFERENCES public.disease_analyses(id) ON DELETE CASCADE,
    crop TEXT,
    disease TEXT,
    confidence NUMERIC,
    status TEXT CHECK (status IN ('possible','uncertain','unidentified')),
    symptoms_en TEXT,
    symptoms_ta TEXT,
    recommendations_en TEXT[],
    recommendations_ta TEXT[],
    model_version TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.disease_analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.disease_predictions ENABLE ROW LEVEL SECURITY;

-- Analyses RLS
CREATE POLICY "Users can view own analyses" 
    ON public.disease_analyses FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own analyses" 
    ON public.disease_analyses FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- Predictions RLS
CREATE POLICY "Users can view predictions for own analyses" 
    ON public.disease_predictions FOR SELECT 
    USING (
        EXISTS (
            SELECT 1 FROM public.disease_analyses 
            WHERE disease_analyses.id = disease_predictions.analysis_id 
            AND disease_analyses.user_id = auth.uid()
        )
    );
