-- 006_create_storage_buckets.sql
-- Note: This is usually done via Supabase Dashboard or API, 
-- but this script serves as documentation for what needs to be created.

-- Ensure the extension exists
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- We need to create a bucket named 'crop-images'
-- INSERT INTO storage.buckets (id, name, public) VALUES ('crop-images', 'crop-images', false);

-- And add policies for storage
-- Allow authenticated users to upload to their own folder
-- CREATE POLICY "Users can upload their own images" ON storage.objects
--   FOR INSERT WITH CHECK (
--     bucket_id = 'crop-images' AND auth.uid()::text = (storage.foldername(name))[1]
--   );

-- Allow users to view their own images
-- CREATE POLICY "Users can view their own images" ON storage.objects
--   FOR SELECT USING (
--     bucket_id = 'crop-images' AND auth.uid()::text = (storage.foldername(name))[1]
--   );
SELECT 1;
