-- ============================================================================
-- PRODUCT IMAGES STORAGE SETUP
-- ============================================================================
-- Create public bucket for product images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'product-images',
    'product-images',
    true,  -- PUBLIC bucket - anyone can view
    10485760, -- 10MB file size limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
);

-- ============================================================================
-- RLS POLICIES FOR PRODUCT IMAGES
-- ============================================================================

-- Policy: Anyone can view product images (public read)
CREATE POLICY "public_read_product_images" ON storage.objects
FOR SELECT TO public
USING (bucket_id = 'product-images');

-- Policy: Authenticated users can upload product images
CREATE POLICY "authenticated_upload_product_images" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'product-images');

-- Policy: Users can update their own uploaded images
CREATE POLICY "authenticated_update_product_images" ON storage.objects
FOR UPDATE TO authenticated
USING (bucket_id = 'product-images' AND owner = auth.uid())
WITH CHECK (bucket_id = 'product-images' AND owner = auth.uid());

-- Policy: Users can delete their own uploaded images
CREATE POLICY "authenticated_delete_product_images" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'product-images' AND owner = auth.uid());