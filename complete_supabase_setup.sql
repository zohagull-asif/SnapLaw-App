-- ========================================
-- COMPLETE SUPABASE SETUP FOR SNAPLAW
-- Run this in Supabase SQL Editor (new project)
-- ========================================

-- ========================================
-- 1. PROFILES TABLE
-- ========================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  phone_number TEXT,
  avatar_url TEXT,
  role TEXT NOT NULL CHECK (role IN ('client', 'lawyer', 'admin')) DEFAULT 'client',
  is_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all profiles" ON public.profiles
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE TO authenticated USING (auth.uid() = id);

-- ========================================
-- 2. LAWYER PROFILES TABLE
-- ========================================
CREATE TABLE IF NOT EXISTS public.lawyer_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  bar_number TEXT,
  specialization TEXT,
  years_of_experience INTEGER DEFAULT 0,
  bio TEXT,
  hourly_rate NUMERIC DEFAULT 0,
  rating NUMERIC DEFAULT 0,
  total_cases INTEGER DEFAULT 0,
  is_available BOOLEAN DEFAULT TRUE,
  certifications TEXT[],
  office_address TEXT,
  is_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

ALTER TABLE public.lawyer_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view lawyer profiles" ON public.lawyer_profiles
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Lawyers can insert own profile" ON public.lawyer_profiles
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Lawyers can update own profile" ON public.lawyer_profiles
  FOR UPDATE TO authenticated USING (auth.uid() = user_id);

-- ========================================
-- 3. CASES TABLE
-- ========================================
CREATE TABLE IF NOT EXISTS public.cases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  lawyer_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL DEFAULT 'other',
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'assigned', 'in_progress', 'resolved', 'closed')),
  is_urgent BOOLEAN DEFAULT FALSE,
  document_urls TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.cases ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Clients can view own cases" ON public.cases
  FOR SELECT TO authenticated
  USING (auth.uid() = client_id OR auth.uid() = lawyer_id);

CREATE POLICY "Clients can create cases" ON public.cases
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = client_id);

CREATE POLICY "Case parties can update" ON public.cases
  FOR UPDATE TO authenticated
  USING (auth.uid() = client_id OR auth.uid() = lawyer_id);



-- Allow lawyers to see all open/unassigned cases
CREATE POLICY "Lawyers can view open cases" ON public.cases
  FOR SELECT TO authenticated
  USING (status = 'open');

-- ========================================
-- 4. MESSAGES TABLE
-- ========================================
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id UUID NOT NULL REFERENCES public.cases(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sender_name TEXT NOT NULL,
  sender_role TEXT NOT NULL CHECK (sender_role IN ('client', 'lawyer', 'admin')),
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their messages" ON public.messages
  FOR SELECT TO authenticated
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can send messages" ON public.messages
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can mark messages as read" ON public.messages
  FOR UPDATE TO authenticated
  USING (auth.uid() = receiver_id);

-- ========================================
-- 5. INDEXES
-- ========================================
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_cases_client_id ON public.cases(client_id);
CREATE INDEX IF NOT EXISTS idx_cases_lawyer_id ON public.cases(lawyer_id);
CREATE INDEX IF NOT EXISTS idx_cases_status ON public.cases(status);
CREATE INDEX IF NOT EXISTS idx_messages_case_id ON public.messages(case_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON public.messages(receiver_id);

-- ========================================
-- 6. STORAGE BUCKET FOR DOCUMENTS
-- ========================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
CREATE POLICY "Authenticated users can upload documents" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'documents');

CREATE POLICY "Public documents are viewable" ON storage.objects
  FOR SELECT TO public USING (bucket_id = 'documents');

CREATE POLICY "Users can delete own documents" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ========================================
-- DONE!
-- ========================================
DO $$
BEGIN
  RAISE NOTICE 'SnapLaw database setup complete!';
  RAISE NOTICE 'Tables created: profiles, lawyer_profiles, cases, messages';
  RAISE NOTICE 'Storage bucket: documents';
END $$;
