-- ==========================================
-- MOCK MASTER V0 — SCHEMA ADDITIONS
-- Run this in your Supabase SQL Editor AFTER running SUPABASE_SCHEMA.sql
-- ==========================================

-- Add is_admin column to users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

-- Add user_answers and question_ids columns to history table
ALTER TABLE public.history ADD COLUMN IF NOT EXISTS user_answers JSONB DEFAULT '{}';
ALTER TABLE public.history ADD COLUMN IF NOT EXISTS question_ids JSONB DEFAULT '[]';

-- Create SRS Cards table
CREATE TABLE IF NOT EXISTS public.srs_cards (
    card_id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    question_id INTEGER NOT NULL,
    subject_id TEXT NOT NULL,
    chapter_id TEXT NOT NULL,
    ease_factor NUMERIC DEFAULT 2.5,
    interval INTEGER DEFAULT 1,
    repetitions INTEGER DEFAULT 0,
    next_review_date DATE NOT NULL,
    last_review_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- SRS RLS policies
ALTER TABLE public.srs_cards ENABLE ROW LEVEL SECURITY;
CREATE POLICY "srs_cards_select" ON public.srs_cards FOR SELECT USING (auth.uid()::text = user_id);
CREATE POLICY "srs_cards_insert" ON public.srs_cards FOR INSERT WITH CHECK (auth.uid()::text = user_id);
CREATE POLICY "srs_cards_update" ON public.srs_cards FOR UPDATE USING (auth.uid()::text = user_id);
CREATE POLICY "srs_cards_delete" ON public.srs_cards FOR DELETE USING (auth.uid()::text = user_id);

-- Question Reports table
CREATE TABLE IF NOT EXISTS public.question_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL,
    subject_id TEXT NOT NULL,
    chapter_id TEXT NOT NULL,
    question_id INTEGER NOT NULL,
    reason TEXT NOT NULL CHECK (reason IN ('wrong_answer','unclear','typo','outdated','other')),
    details TEXT DEFAULT '',
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending','reviewed','fixed','dismissed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Question Reports RLS
ALTER TABLE public.question_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "reports_insert" ON public.question_reports
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);
CREATE POLICY "reports_read_own" ON public.question_reports
    FOR SELECT USING (auth.uid()::text = user_id);
CREATE POLICY "admin_manage_reports" ON public.question_reports
    FOR ALL USING (
        (SELECT is_admin FROM public.users WHERE uid = auth.uid()::text) = TRUE
    );

-- Leaderboard table
CREATE TABLE IF NOT EXISTS public.leaderboard (
    user_id TEXT PRIMARY KEY,
    display_name TEXT NOT NULL DEFAULT 'Anonymous',
    total_correct INTEGER DEFAULT 0,
    total_attempted INTEGER DEFAULT 0,
    current_streak INTEGER DEFAULT 0,
    best_streak INTEGER DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Leaderboard RLS
ALTER TABLE public.leaderboard ENABLE ROW LEVEL SECURITY;
CREATE POLICY "leaderboard_read_all" ON public.leaderboard FOR SELECT USING (true);
CREATE POLICY "leaderboard_write_own" ON public.leaderboard
    FOR ALL USING (auth.uid()::text = user_id);

-- Update Admin RLS policies (more restrictive than before)
-- Drop old policies first
DROP POLICY IF EXISTS "Allow insert manifest for authenticated" ON public.admin_manifest;
DROP POLICY IF EXISTS "Allow update manifest for authenticated" ON public.admin_manifest;
DROP POLICY IF EXISTS "Allow delete manifest for authenticated" ON public.admin_manifest;
DROP POLICY IF EXISTS "Allow insert chapter data for authenticated" ON public.admin_chapters_data;
DROP POLICY IF EXISTS "Allow update chapter data for authenticated" ON public.admin_chapters_data;
DROP POLICY IF EXISTS "Allow delete chapter data for authenticated" ON public.admin_chapters_data;

-- Admin-only manifest policies
CREATE POLICY "admin_insert_manifest" ON public.admin_manifest
    FOR INSERT WITH CHECK (
        (SELECT is_admin FROM public.users WHERE uid = auth.uid()::text) = TRUE
    );
CREATE POLICY "admin_update_manifest" ON public.admin_manifest
    FOR UPDATE USING (
        (SELECT is_admin FROM public.users WHERE uid = auth.uid()::text) = TRUE
    );
CREATE POLICY "admin_delete_manifest" ON public.admin_manifest
    FOR DELETE USING (
        (SELECT is_admin FROM public.users WHERE uid = auth.uid()::text) = TRUE
    );

-- Admin-only chapter data policies
CREATE POLICY "admin_insert_chapter_data" ON public.admin_chapters_data
    FOR INSERT WITH CHECK (
        (SELECT is_admin FROM public.users WHERE uid = auth.uid()::text) = TRUE
    );
CREATE POLICY "admin_update_chapter_data" ON public.admin_chapters_data
    FOR UPDATE USING (
        (SELECT is_admin FROM public.users WHERE uid = auth.uid()::text) = TRUE
    );
CREATE POLICY "admin_delete_chapter_data" ON public.admin_chapters_data
    FOR DELETE USING (
        (SELECT is_admin FROM public.users WHERE uid = auth.uid()::text) = TRUE
    );

-- Set initial admin (replace with your Supabase user ID)
-- UPDATE public.users SET is_admin = TRUE WHERE uid = '<YOUR_SUPABASE_USER_ID>';
