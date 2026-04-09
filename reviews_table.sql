-- SnapLaw: Reviews & Ratings Table
-- Run this in your Supabase SQL Editor

CREATE TABLE IF NOT EXISTS reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL,
  lawyer_id UUID NOT NULL,
  case_id UUID,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  review_text TEXT,
  case_type TEXT DEFAULT 'General',
  client_name TEXT DEFAULT 'Anonymous',
  is_anonymous BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Prevent duplicate reviews: one review per client per lawyer per case
CREATE UNIQUE INDEX IF NOT EXISTS reviews_unique_idx
  ON reviews (client_id, lawyer_id, COALESCE(case_id, '00000000-0000-0000-0000-000000000000'::UUID));

-- Enable Row Level Security
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- Clients can insert their own reviews
CREATE POLICY "Clients can insert reviews"
  ON reviews FOR INSERT
  WITH CHECK (auth.uid() = client_id);

-- Anyone authenticated can read reviews
CREATE POLICY "Anyone can read reviews"
  ON reviews FOR SELECT
  USING (auth.role() = 'authenticated');

-- Clients can update their own reviews
CREATE POLICY "Clients can update own reviews"
  ON reviews FOR UPDATE
  USING (auth.uid() = client_id);

-- Clients can delete their own reviews
CREATE POLICY "Clients can delete own reviews"
  ON reviews FOR DELETE
  USING (auth.uid() = client_id);

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE reviews;

-- Helpful view: lawyer rating aggregates
CREATE OR REPLACE VIEW lawyer_ratings AS
SELECT
  lawyer_id,
  COUNT(*)::INTEGER           AS review_count,
  ROUND(AVG(rating)::NUMERIC, 1) AS average_rating,
  COUNT(CASE WHEN rating = 5 THEN 1 END)::INTEGER AS five_star,
  COUNT(CASE WHEN rating = 4 THEN 1 END)::INTEGER AS four_star,
  COUNT(CASE WHEN rating = 3 THEN 1 END)::INTEGER AS three_star,
  COUNT(CASE WHEN rating = 2 THEN 1 END)::INTEGER AS two_star,
  COUNT(CASE WHEN rating = 1 THEN 1 END)::INTEGER AS one_star
FROM reviews
GROUP BY lawyer_id;
