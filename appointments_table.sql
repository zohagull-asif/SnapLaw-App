-- Appointments table for booking system
-- Run this in Supabase SQL Editor

CREATE TABLE IF NOT EXISTS appointments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  client_id UUID NOT NULL REFERENCES auth.users(id),
  lawyer_id UUID NOT NULL REFERENCES auth.users(id),
  lawyer_name TEXT NOT NULL,
  client_name TEXT NOT NULL,
  case_title TEXT,
  appointment_date DATE NOT NULL,
  time_slot TEXT NOT NULL,  -- e.g. '09:00 AM', '02:00 PM'
  consultation_type TEXT NOT NULL DEFAULT 'in-person',  -- in-person, video, phone
  status TEXT NOT NULL DEFAULT 'pending',  -- pending, confirmed, cancelled, completed
  duration INT NOT NULL DEFAULT 60,  -- in minutes
  notes TEXT,
  location TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_appointments_client_id ON appointments(client_id);
CREATE INDEX idx_appointments_lawyer_id ON appointments(lawyer_id);
CREATE INDEX idx_appointments_date ON appointments(appointment_date);
CREATE INDEX idx_appointments_status ON appointments(status);

-- RLS policies
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

-- Clients can create appointments
CREATE POLICY "Clients can create appointments"
  ON appointments FOR INSERT TO authenticated
  WITH CHECK (client_id = auth.uid());

-- Clients can view their own appointments
CREATE POLICY "Clients can view their appointments"
  ON appointments FOR SELECT TO authenticated
  USING (client_id = auth.uid() OR lawyer_id = auth.uid());

-- Lawyers can update appointments (confirm/cancel/complete)
CREATE POLICY "Lawyers can update their appointments"
  ON appointments FOR UPDATE TO authenticated
  USING (lawyer_id = auth.uid() OR client_id = auth.uid());

-- Clients can cancel (delete) their own appointments
CREATE POLICY "Users can delete their appointments"
  ON appointments FOR DELETE TO authenticated
  USING (client_id = auth.uid() OR lawyer_id = auth.uid());

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE appointments;
