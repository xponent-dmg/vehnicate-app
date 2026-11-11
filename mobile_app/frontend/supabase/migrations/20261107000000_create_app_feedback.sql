-- Migration: Create app_feedback table and feedback-attachments storage bucket
-- Date: 2026-11-07

-- 1. Create app_feedback table
CREATE TABLE IF NOT EXISTS public.app_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT,
    category TEXT NOT NULL CHECK (category IN ('bug_report', 'feature_request', 'general')),
    description TEXT NOT NULL,
    attachment_urls TEXT[] NOT NULL DEFAULT '{}',
    app_version TEXT,
    build_number TEXT,
    device_model TEXT,
    os_version TEXT,
    status TEXT NOT NULL DEFAULT 'new',
    email_status TEXT NOT NULL DEFAULT 'pending',
    email_error TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Indexes for performance and querying
CREATE INDEX IF NOT EXISTS idx_app_feedback_user_id ON public.app_feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_app_feedback_created_at ON public.app_feedback(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_app_feedback_email_status ON public.app_feedback(email_status);

-- 3. Row Level Security on app_feedback
ALTER TABLE public.app_feedback ENABLE ROW LEVEL SECURITY;

-- Allow users to insert feedback with strict guardrails
DROP POLICY IF EXISTS "Allow users to submit feedback" ON public.app_feedback;
CREATE POLICY "Allow users to submit feedback"
ON public.app_feedback
FOR INSERT
WITH CHECK (
    status = 'new'
    AND email_status = 'pending'
    AND email_error IS NULL
    AND (
        ((auth.jwt() ->> 'sub') IS NOT NULL AND user_id = (auth.jwt() ->> 'sub'))
        OR
        ((auth.jwt() ->> 'sub') IS NULL AND user_id IS NULL)
    )
);

-- Allow authenticated users to view only their own feedback
DROP POLICY IF EXISTS "Allow users to read their own feedback" ON public.app_feedback;
CREATE POLICY "Allow users to read their own feedback"
ON public.app_feedback
FOR SELECT
USING (
    (auth.jwt() ->> 'sub') IS NOT NULL
    AND user_id = (auth.jwt() ->> 'sub')
);

-- Deny client UPDATE and DELETE by not creating policies for them
-- Service role key bypasses RLS and handles status/email_status updates.

-- 4. Create feedback-attachments storage bucket (private)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'feedback-attachments',
    'feedback-attachments',
    false,
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic']
)
ON CONFLICT (id) DO UPDATE SET
    public = false,
    file_size_limit = 10485760,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic'];

-- 5. Storage RLS Policies for feedback-attachments
DROP POLICY IF EXISTS "Users can upload their own feedback attachments" ON storage.objects;
CREATE POLICY "Users can upload their own feedback attachments"
ON storage.objects
FOR INSERT
WITH CHECK (
    bucket_id = 'feedback-attachments'
    AND (
        ((auth.jwt() ->> 'sub') IS NOT NULL AND (storage.foldername(name))[1] = (auth.jwt() ->> 'sub'))
        OR
        ((auth.jwt() ->> 'sub') IS NULL AND (storage.foldername(name))[1] = 'anon')
    )
);

DROP POLICY IF EXISTS "Users can view their own feedback attachments" ON storage.objects;
CREATE POLICY "Users can view their own feedback attachments"
ON storage.objects
FOR SELECT
USING (
    bucket_id = 'feedback-attachments'
    AND (auth.jwt() ->> 'sub') IS NOT NULL
    AND (storage.foldername(name))[1] = (auth.jwt() ->> 'sub')
);

DROP POLICY IF EXISTS "Users can delete their own feedback attachments" ON storage.objects;
CREATE POLICY "Users can delete their own feedback attachments"
ON storage.objects
FOR DELETE
USING (
    bucket_id = 'feedback-attachments'
    AND (auth.jwt() ->> 'sub') IS NOT NULL
    AND (storage.foldername(name))[1] = (auth.jwt() ->> 'sub')
);

