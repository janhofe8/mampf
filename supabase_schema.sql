-- MAMPF Supabase Schema
-- Run this in the Supabase SQL Editor to set up the database

-- Create restaurants table
CREATE TABLE restaurants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    cuisine_type TEXT NOT NULL,
    neighborhood TEXT NOT NULL,
    price_range TEXT NOT NULL,
    address TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    opening_hours TEXT NOT NULL,
    is_closed BOOLEAN NOT NULL DEFAULT FALSE,
    notes TEXT NOT NULL DEFAULT '',
    image_url TEXT,
    personal_rating DOUBLE PRECISION,
    google_rating DOUBLE PRECISION,
    google_review_count INTEGER,
    google_place_id TEXT,
    google_maps_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security (public read-only)
ALTER TABLE restaurants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read access" ON restaurants
    FOR SELECT USING (true);

-- Create storage bucket for restaurant images (run separately in dashboard or via API)
-- Bucket name: restaurant-images, public access enabled

-- ============================================================================
-- restaurant_suggestions: user-submitted spots awaiting curation
-- ============================================================================
CREATE TABLE restaurant_suggestions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    google_url TEXT,
    name TEXT,
    location_hint TEXT,
    reason TEXT,
    rating REAL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    device_id TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT suggestion_has_identifier CHECK (
        (google_url IS NOT NULL AND length(trim(google_url)) > 0)
        OR (name IS NOT NULL AND length(trim(name)) > 0)
    ),
    CONSTRAINT rating_range CHECK (
        rating IS NULL OR (rating >= 1 AND rating <= 10)
    )
);

CREATE INDEX restaurant_suggestions_status_idx ON restaurant_suggestions (status, created_at DESC);

ALTER TABLE restaurant_suggestions ENABLE ROW LEVEL SECURITY;

-- Anon users may insert under their own device_id (user_id must be NULL).
CREATE POLICY "anon submit suggestion"
    ON restaurant_suggestions
    FOR INSERT TO anon
    WITH CHECK (user_id IS NULL);

-- Authenticated users may insert under their own user_id.
CREATE POLICY "auth submit suggestion"
    ON restaurant_suggestions
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

-- No SELECT/UPDATE/DELETE policies — curation happens via service-role key in the dashboard.
