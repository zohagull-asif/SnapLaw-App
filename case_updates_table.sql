-- Case Updates table for real-time case progress tracking
-- Run this in Supabase SQL Editor

CREATE TABLE IF NOT EXISTS case_updates (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  case_id UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'general',  -- hearing, document, evidence, status, deadline, general
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  lawyer_name TEXT,
  next_action TEXT,
  next_hearing_date TIMESTAMPTZ,
  attachments TEXT[],  -- array of file names or URLs
  created_by UUID REFERENCES auth.users(id)
);

-- Index for fast lookup by case_id
CREATE INDEX idx_case_updates_case_id ON case_updates(case_id);
CREATE INDEX idx_case_updates_timestamp ON case_updates(timestamp DESC);

-- RLS policies
ALTER TABLE case_updates ENABLE ROW LEVEL SECURITY;

-- Lawyers can insert updates for their cases
CREATE POLICY "Lawyers can insert updates for their cases"
  ON case_updates FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = case_updates.case_id
      AND cases.lawyer_id = auth.uid()
    )
  );

-- Clients can read updates for their cases
CREATE POLICY "Clients can read updates for their cases"
  ON case_updates FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM cases
      WHERE cases.id = case_updates.case_id
      AND (cases.client_id = auth.uid() OR cases.lawyer_id = auth.uid())
    )
  );

-- Lawyers can update their own updates
CREATE POLICY "Lawyers can update their own updates"
  ON case_updates FOR UPDATE TO authenticated
  USING (created_by = auth.uid());

-- Lawyers can delete their own updates
CREATE POLICY "Lawyers can delete their own updates"
  ON case_updates FOR DELETE TO authenticated
  USING (created_by = auth.uid());

-- Enable realtime for this table
ALTER PUBLICATION supabase_realtime ADD TABLE case_updates;
