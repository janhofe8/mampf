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
