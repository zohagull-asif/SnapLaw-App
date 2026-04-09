-- ============================================
-- SnapLaw RAG: Supabase Database Migration
-- Run this in the Supabase SQL Editor
-- ============================================

-- Enable pgvector extension for vector embeddings
CREATE EXTENSION IF NOT EXISTS vector;

-- Company policies table
CREATE TABLE IF NOT EXISTS company_policies (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL,
  policy_name TEXT NOT NULL,
  original_text TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Policy chunks with LegalBERT embeddings (768 dimensions)
CREATE TABLE IF NOT EXISTS policy_chunks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  policy_id UUID REFERENCES company_policies(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  chunk_text TEXT NOT NULL,
  chunk_index INT DEFAULT 0,
  embedding VECTOR(768),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_policy_chunks_user_id ON policy_chunks(user_id);
CREATE INDEX IF NOT EXISTS idx_policy_chunks_policy_id ON policy_chunks(policy_id);
CREATE INDEX IF NOT EXISTS idx_company_policies_user_id ON company_policies(user_id);

-- RLS (Row Level Security) policies
ALTER TABLE company_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE policy_chunks ENABLE ROW LEVEL SECURITY;

-- Allow users to manage their own policies
CREATE POLICY "Users can view own policies"
  ON company_policies FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own policies"
  ON company_policies FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own policies"
  ON company_policies FOR DELETE
  USING (auth.uid() = user_id);

-- Allow users to manage their own policy chunks
CREATE POLICY "Users can view own chunks"
  ON policy_chunks FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own chunks"
  ON policy_chunks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own chunks"
  ON policy_chunks FOR DELETE
  USING (auth.uid() = user_id);

-- Service role bypass for backend operations
-- Note: The Python backend uses the anon key, so we need to allow
-- service-level access. For production, use the service role key.
-- For FYP demo, we can temporarily disable RLS:
-- ALTER TABLE company_policies DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE policy_chunks DISABLE ROW LEVEL SECURITY;
