-- Migration: Create road_reports, road_report_media, and road_report_verifications
-- Date: 2026-11-08

-- 1. Ensure PostGIS is enabled in extensions schema
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;

-- 2. Create road_reports table
CREATE TABLE IF NOT EXISTS public.road_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    issue_type TEXT NOT NULL CHECK (issue_type IN ('pothole', 'marked_speedbreaker', 'unmarked_speedbreaker', 'unpaved_road', 'longitudinal_crack', 'other')),
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    location extensions.geography(Point, 4326) GENERATED ALWAYS AS (extensions.ST_SetSRID(extensions.ST_MakePoint(longitude, latitude), 4326)::extensions.geography) STORED,
    location_accuracy DOUBLE PRECISION,
    severity TEXT CHECK (severity IS NULL OR severity IN ('low', 'moderate', 'high')),
    description TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'disputed', 'resolved', 'archived')),
    source_trip_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Create road_report_media table
CREATE TABLE IF NOT EXISTS public.road_report_media (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES public.road_reports(id) ON DELETE CASCADE,
    storage_path TEXT NOT NULL,
    media_type TEXT NOT NULL DEFAULT 'image/jpeg',
    captured_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. Create road_report_verifications table
CREATE TABLE IF NOT EXISTS public.road_report_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES public.road_reports(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL,
    verdict TEXT NOT NULL CHECK (verdict IN ('present', 'repaired', 'incorrect')),
    description TEXT,
    evidence_storage_path TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_report_user_verification UNIQUE (report_id, user_id)
);

-- 5. Indexes for spatial queries, foreign keys, and filtering
CREATE INDEX IF NOT EXISTS idx_road_reports_location ON public.road_reports USING GIST (location);
CREATE INDEX IF NOT EXISTS idx_road_reports_user_id ON public.road_reports(user_id);
CREATE INDEX IF NOT EXISTS idx_road_reports_status ON public.road_reports(status);
CREATE INDEX IF NOT EXISTS idx_road_reports_issue_type ON public.road_reports(issue_type);
CREATE INDEX IF NOT EXISTS idx_road_reports_created_at ON public.road_reports(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_road_report_media_report_id ON public.road_report_media(report_id);
CREATE INDEX IF NOT EXISTS idx_road_report_verifications_report_id ON public.road_report_verifications(report_id);
CREATE INDEX IF NOT EXISTS idx_road_report_verifications_user_id ON public.road_report_verifications(user_id);

-- 6. Verification Status Transition Trigger
CREATE OR REPLACE FUNCTION public.trig_update_road_report_status()
RETURNS TRIGGER AS $$
DECLARE
    v_report_id UUID;
    v_current_status TEXT;
    v_present_count INT := 0;
    v_repaired_count INT := 0;
    v_incorrect_count INT := 0;
    v_new_status TEXT;
BEGIN
    IF (TG_OP = 'DELETE') THEN
        v_report_id := OLD.report_id;
    ELSE
        v_report_id := NEW.report_id;
    END IF;

    -- Fetch current status
    SELECT status INTO v_current_status FROM public.road_reports WHERE id = v_report_id;
    IF NOT FOUND OR v_current_status = 'archived' THEN
        RETURN NEW;
    END IF;

    -- Tally verification verdicts
    SELECT
        COUNT(*) FILTER (WHERE verdict = 'present'),
        COUNT(*) FILTER (WHERE verdict = 'repaired'),
        COUNT(*) FILTER (WHERE verdict = 'incorrect')
    INTO
        v_present_count,
        v_repaired_count,
        v_incorrect_count
    FROM public.road_report_verifications
    WHERE report_id = v_report_id;

    -- Verification lifecycle policy:
    -- Threshold 2:
    -- If repaired >= 2 and repaired > present -> resolved
    -- If incorrect >= 2 and incorrect > present -> disputed
    -- If present >= 1 (or 2) and status was pending -> confirmed
    -- If no verifications exist -> pending
    IF v_repaired_count >= 2 AND v_repaired_count > v_present_count THEN
        v_new_status := 'resolved';
    ELSIF v_incorrect_count >= 2 AND v_incorrect_count > v_present_count THEN
        v_new_status := 'disputed';
    ELSIF v_present_count >= 2 THEN
        v_new_status := 'confirmed';
    ELSIF v_present_count = 1 AND v_current_status = 'pending' THEN
        v_new_status := 'confirmed';
    ELSE
        v_new_status := v_current_status;
    END IF;

    IF v_new_status != v_current_status THEN
        UPDATE public.road_reports
        SET status = v_new_status, updated_at = now()
        WHERE id = v_report_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_road_report_verification_status ON public.road_report_verifications;
CREATE TRIGGER trg_road_report_verification_status
AFTER INSERT OR UPDATE OR DELETE ON public.road_report_verifications
FOR EACH ROW EXECUTE FUNCTION public.trig_update_road_report_status();

-- 7. Geographic Query RPC: get_nearby_road_reports
CREATE OR REPLACE FUNCTION public.get_nearby_road_reports(
    user_lat DOUBLE PRECISION,
    user_lon DOUBLE PRECISION,
    radius_meters DOUBLE PRECISION DEFAULT 2000,
    category_filter TEXT DEFAULT NULL,
    status_filter TEXT DEFAULT NULL,
    current_user_id TEXT DEFAULT NULL,
    limit_count INT DEFAULT 100,
    offset_count INT DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    user_id TEXT,
    issue_type TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    location_accuracy DOUBLE PRECISION,
    severity TEXT,
    description TEXT,
    status TEXT,
    source_trip_id TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    distance_meters DOUBLE PRECISION,
    media_storage_paths TEXT[],
    verification_counts JSONB,
    user_verdict TEXT,
    is_own_report BOOLEAN
) AS $$
DECLARE
    user_pt extensions.geography := extensions.ST_SetSRID(extensions.ST_MakePoint(user_lon, user_lat), 4326)::extensions.geography;
BEGIN
    RETURN QUERY
    SELECT
        r.id,
        r.user_id,
        r.issue_type,
        r.latitude,
        r.longitude,
        r.location_accuracy,
        r.severity,
        r.description,
        r.status,
        r.source_trip_id,
        r.created_at,
        r.updated_at,
        extensions.ST_Distance(r.location, user_pt) AS distance_meters,
        COALESCE(
            ARRAY(
                SELECT m.storage_path
                FROM public.road_report_media m
                WHERE m.report_id = r.id
                ORDER BY m.created_at ASC
            ),
            '{}'::TEXT[]
        ) AS media_storage_paths,
        (
            SELECT jsonb_build_object(
                'present', COUNT(*) FILTER (WHERE v.verdict = 'present'),
                'repaired', COUNT(*) FILTER (WHERE v.verdict = 'repaired'),
                'incorrect', COUNT(*) FILTER (WHERE v.verdict = 'incorrect')
            )
            FROM public.road_report_verifications v
            WHERE v.report_id = r.id
        ) AS verification_counts,
        (
            SELECT v.verdict
            FROM public.road_report_verifications v
            WHERE v.report_id = r.id AND current_user_id IS NOT NULL AND v.user_id = current_user_id
            LIMIT 1
        ) AS user_verdict,
        (current_user_id IS NOT NULL AND r.user_id = current_user_id) AS is_own_report
    FROM public.road_reports r
    WHERE
        r.status != 'archived'
        AND extensions.ST_DWithin(r.location, user_pt, radius_meters)
        AND (category_filter IS NULL OR r.issue_type = category_filter)
        AND (status_filter IS NULL OR r.status = status_filter)
    ORDER BY distance_meters ASC
    LIMIT limit_count
    OFFSET offset_count;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 8. Contribution Statistics RPC: get_user_contribution_stats
CREATE OR REPLACE FUNCTION public.get_user_contribution_stats(target_user_id TEXT)
RETURNS TABLE (
    reported_count BIGINT,
    verified_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        (SELECT COUNT(*) FROM public.road_reports WHERE user_id = target_user_id AND status != 'archived'),
        (SELECT COUNT(*) FROM public.road_report_verifications WHERE user_id = target_user_id);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 9. Row Level Security on road_reports, road_report_media, road_report_verifications
ALTER TABLE public.road_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.road_report_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.road_report_verifications ENABLE ROW LEVEL SECURITY;

-- Policies for road_reports
DROP POLICY IF EXISTS "Allow authenticated users to read active road reports" ON public.road_reports;
CREATE POLICY "Allow authenticated users to read active road reports"
ON public.road_reports
FOR SELECT
USING (
    status != 'archived'
    OR (
        (auth.jwt() ->> 'sub'::text) IS NOT NULL
        AND user_id = (auth.jwt() ->> 'sub'::text)
    )
);

DROP POLICY IF EXISTS "Allow users to create their own road reports" ON public.road_reports;
CREATE POLICY "Allow users to create their own road reports"
ON public.road_reports
FOR INSERT
WITH CHECK (
    (auth.jwt() ->> 'sub'::text) IS NOT NULL
    AND user_id = (auth.jwt() ->> 'sub'::text)
    AND status = 'pending'
);

DROP POLICY IF EXISTS "Allow users to update their own road reports" ON public.road_reports;
CREATE POLICY "Allow users to update their own road reports"
ON public.road_reports
FOR UPDATE
USING (
    (auth.jwt() ->> 'sub'::text) IS NOT NULL
    AND user_id = (auth.jwt() ->> 'sub'::text)
)
WITH CHECK (
    (auth.jwt() ->> 'sub'::text) IS NOT NULL
    AND user_id = (auth.jwt() ->> 'sub'::text)
);

DROP POLICY IF EXISTS "Allow users to delete their own road reports" ON public.road_reports;
CREATE POLICY "Allow users to delete their own road reports"
ON public.road_reports
FOR DELETE
USING (
    (auth.jwt() ->> 'sub'::text) IS NOT NULL
    AND user_id = (auth.jwt() ->> 'sub'::text)
);

-- Policies for road_report_media
DROP POLICY IF EXISTS "Allow authenticated users to read road report media" ON public.road_report_media;
CREATE POLICY "Allow authenticated users to read road report media"
ON public.road_report_media
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.road_reports r
        WHERE r.id = road_report_media.report_id
        AND (r.status != 'archived' OR r.user_id = (auth.jwt() ->> 'sub'::text))
    )
);

DROP POLICY IF EXISTS "Allow users to add media to their own reports" ON public.road_report_media;
CREATE POLICY "Allow users to add media to their own reports"
ON public.road_report_media
FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.road_reports r
        WHERE r.id = road_report_media.report_id
        AND r.user_id = (auth.jwt() ->> 'sub'::text)
    )
);

DROP POLICY IF EXISTS "Allow users to delete media of their own reports" ON public.road_report_media;
CREATE POLICY "Allow users to delete media of their own reports"
ON public.road_report_media
FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM public.road_reports r
        WHERE r.id = road_report_media.report_id
        AND r.user_id = (auth.jwt() ->> 'sub'::text)
    )
);

-- Policies for road_report_verifications
DROP POLICY IF EXISTS "Allow authenticated users to read verifications" ON public.road_report_verifications;
CREATE POLICY "Allow authenticated users to read verifications"
ON public.road_report_verifications
FOR SELECT
USING (true);

DROP POLICY IF EXISTS "Allow users to verify reports from other users" ON public.road_report_verifications;
CREATE POLICY "Allow users to verify reports from other users"
ON public.road_report_verifications
FOR INSERT
WITH CHECK (
    (auth.jwt() ->> 'sub'::text) IS NOT NULL
    AND user_id = (auth.jwt() ->> 'sub'::text)
    AND NOT EXISTS (
        SELECT 1 FROM public.road_reports r
        WHERE r.id = road_report_verifications.report_id
        AND r.user_id = (auth.jwt() ->> 'sub'::text)
    )
    AND EXISTS (
        SELECT 1 FROM public.road_reports r
        WHERE r.id = road_report_verifications.report_id
        AND r.status != 'archived'
    )
);

DROP POLICY IF EXISTS "Allow users to update their own verifications" ON public.road_report_verifications;
CREATE POLICY "Allow users to update their own verifications"
ON public.road_report_verifications
FOR UPDATE
USING (
    (auth.jwt() ->> 'sub'::text) IS NOT NULL
    AND user_id = (auth.jwt() ->> 'sub'::text)
)
WITH CHECK (
    (auth.jwt() ->> 'sub'::text) IS NOT NULL
    AND user_id = (auth.jwt() ->> 'sub'::text)
);

DROP POLICY IF EXISTS "Allow users to delete their own verifications" ON public.road_report_verifications;
CREATE POLICY "Allow users to delete their own verifications"
ON public.road_report_verifications
FOR DELETE
USING (
    (auth.jwt() ->> 'sub'::text) IS NOT NULL
    AND user_id = (auth.jwt() ->> 'sub'::text)
);

-- 10. Create road-report-media private storage bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'road-report-media',
    'road-report-media',
    false,
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic']
)
ON CONFLICT (id) DO UPDATE SET
    public = false,
    file_size_limit = 10485760,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic'];

-- 11. Storage Policies for road-report-media
DROP POLICY IF EXISTS "Users can upload their road report images" ON storage.objects;
CREATE POLICY "Users can upload their road report images"
ON storage.objects
FOR INSERT
WITH CHECK (
    bucket_id = 'road-report-media'
    AND (auth.jwt() ->> 'sub'::text) IS NOT NULL
    AND (storage.foldername(name))[1] = (auth.jwt() ->> 'sub'::text)
);

DROP POLICY IF EXISTS "Authenticated users can view road report media" ON storage.objects;
CREATE POLICY "Authenticated users can view road report media"
ON storage.objects
FOR SELECT
USING (
    bucket_id = 'road-report-media'
    AND (auth.jwt() ->> 'sub'::text) IS NOT NULL
);

DROP POLICY IF EXISTS "Users can delete their own road report images" ON storage.objects;
CREATE POLICY "Users can delete their own road report images"
ON storage.objects
FOR DELETE
USING (
    bucket_id = 'road-report-media'
    AND (auth.jwt() ->> 'sub'::text) IS NOT NULL
    AND (storage.foldername(name))[1] = (auth.jwt() ->> 'sub'::text)
);

