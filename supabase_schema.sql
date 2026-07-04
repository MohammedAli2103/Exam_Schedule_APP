-- Database Schema for Exam Preparation Application
-- Run this in your Supabase SQL Editor to set up the tables, Row Level Security (RLS), and triggers.

-- Enable UUID extension if not enabled
create extension if not exists "uuid-ossp";

---------------------------------------------------------
-- 1. PROFILES TABLE
---------------------------------------------------------
create table public.profiles (
    id uuid references auth.users on delete cascade primary key,
    email text not null,
    full_name text,
    streak_count integer default 0 not null,
    last_study_date date,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS for Profiles
alter table public.profiles enable row level security;

create policy "Users can view their own profile" 
    on public.profiles for select 
    using (auth.uid() = id);

create policy "Users can update their own profile" 
    on public.profiles for update 
    using (auth.uid() = id);

-- Trigger to automatically create a profile when a new user signs up
create or replace function public.handle_new_user()
returns trigger as $$
begin
    insert into public.profiles (id, email, full_name)
    values (new.id, new.email, new.raw_user_meta_data->>'full_name');
    return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_auth_user_created
    after insert on auth.users
    for each row execute procedure public.handle_new_user();

---------------------------------------------------------
-- 2. SUBJECTS TABLE
---------------------------------------------------------
create table public.subjects (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references auth.users on delete cascade default auth.uid() not null,
    name text not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    
    constraint subjects_name_length check (char_length(name) >= 1)
);

-- Enable RLS for Subjects
alter table public.subjects enable row level security;

create policy "Users can perform all operations on their own subjects"
    on public.subjects for all
    using (auth.uid() = user_id);

---------------------------------------------------------
-- 3. CHAPTERS TABLE
---------------------------------------------------------
create table public.chapters (
    id uuid primary key default gen_random_uuid(),
    subject_id uuid references public.subjects on delete cascade not null,
    name text not null,
    is_completed boolean default false not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    
    constraint chapters_name_length check (char_length(name) >= 1)
);

-- Enable RLS for Chapters (through subject relationship or helper function)
alter table public.chapters enable row level security;

create policy "Users can perform all operations on chapters of their subjects"
    on public.chapters for all
    using (
        exists (
            select 1 from public.subjects 
            where public.subjects.id = public.chapters.subject_id 
            and public.subjects.user_id = auth.uid()
        )
    );

---------------------------------------------------------
-- 4. NOTES TABLE
---------------------------------------------------------
create table public.notes (
    id uuid primary key default gen_random_uuid(),
    chapter_id uuid references public.chapters on delete cascade not null,
    name text not null,
    file_url text not null,
    file_path text not null, -- Supabase Storage file path
    file_size bigint,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS for Notes
alter table public.notes enable row level security;

create policy "Users can perform all operations on notes of their chapters"
    on public.notes for all
    using (
        exists (
            select 1 from public.chapters
            join public.subjects on public.subjects.id = public.chapters.subject_id
            where public.chapters.id = public.notes.chapter_id
            and public.subjects.user_id = auth.uid()
        )
    );

---------------------------------------------------------
-- 5. STUDY SESSIONS TABLE
---------------------------------------------------------
create table public.study_sessions (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references auth.users on delete cascade default auth.uid() not null,
    subject_id uuid references public.subjects on delete cascade not null,
    study_type text not null, -- 'Learning', 'Revision', 'Practice Questions', 'Mock Test'
    notes text,
    start_time timestamp with time zone not null,
    end_time timestamp with time zone not null,
    is_completed boolean default false not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    
    constraint study_sessions_time_check check (start_time < end_time)
);

-- Enable RLS for Study Sessions
alter table public.study_sessions enable row level security;

create policy "Users can perform all operations on their study sessions"
    on public.study_sessions for all
    using (auth.uid() = user_id);

---------------------------------------------------------
-- 6. STUDY SESSION CHAPTERS (Junction Table)
---------------------------------------------------------
create table public.study_session_chapters (
    study_session_id uuid references public.study_sessions on delete cascade not null,
    chapter_id uuid references public.chapters on delete cascade not null,
    primary key (study_session_id, chapter_id)
);

-- Enable RLS for Study Session Chapters
alter table public.study_session_chapters enable row level security;

create policy "Users can manage chapters for their study sessions"
    on public.study_session_chapters for all
    using (
        exists (
            select 1 from public.study_sessions
            where public.study_sessions.id = public.study_session_chapters.study_session_id
            and public.study_sessions.user_id = auth.uid()
        )
    );

---------------------------------------------------------
-- 7. PROGRESS TRACKING & STREAKS
---------------------------------------------------------
-- Function to automatically update streaks when a study session is marked complete
create or replace function public.update_streak_on_session_complete()
returns trigger as $$
declare
    session_user_id uuid;
    session_date date;
    last_date date;
    current_streak integer;
begin
    -- Get session details
    if (new.is_completed = true and (old.is_completed = false or old.is_completed is null)) then
        session_user_id := new.user_id;
        session_date := date(new.end_time at time zone 'utc');
        
        -- Get current streak details
        select streak_count, last_study_date into current_streak, last_date
        from public.profiles
        where id = session_user_id;
        
        if last_date is null then
            -- First study session ever
            update public.profiles
            set streak_count = 1, last_study_date = session_date
            where id = session_user_id;
        elsif session_date = last_date then
            -- Already studied today, streak stays the same
            null;
        elsif session_date = last_date + interval '1 day' then
            -- Studied on consecutive day, increment streak
            update public.profiles
            set streak_count = current_streak + 1, last_study_date = session_date
            where id = session_user_id;
        else
            -- Streak broken, reset to 1
            update public.profiles
            set streak_count = 1, last_study_date = session_date
            where id = session_user_id;
        end if;
    end if;
    return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_study_session_completed
    after update on public.study_sessions
    for each row execute procedure public.update_streak_on_session_complete();

---------------------------------------------------------
-- 8. INDEXES FOR PERFORMANCE & SEARCH
---------------------------------------------------------
create index if not exists subjects_user_id_idx on public.subjects(user_id);
create index if not exists subjects_name_idx on public.subjects(name);
create index if not exists chapters_subject_id_idx on public.chapters(subject_id);
create index if not exists chapters_name_idx on public.chapters(name);
create index if not exists notes_chapter_id_idx on public.notes(chapter_id);
create index if not exists notes_name_idx on public.notes(name);
create index if not exists study_sessions_user_id_idx on public.study_sessions(user_id);
create index if not exists study_sessions_time_idx on public.study_sessions(start_time, end_time);

---------------------------------------------------------
-- 9. STORAGE BUCKET CONFIGURATION & POLICIES
---------------------------------------------------------
-- Create a public bucket named "notes" if it doesn't exist
insert into storage.buckets (id, name, public)
values ('notes', 'notes', true)
on conflict (id) do update set public = true;

-- Policies for the "notes" bucket:

-- 1. Allow public read access to anyone (needed for external browser/apps to view the files via getPublicUrl)
create policy "Allow public read access on notes"
    on storage.objects for select
    using (bucket_id = 'notes');

-- 2. Allow authenticated users to upload files to their own user directory
create policy "Allow authenticated users to upload notes"
    on storage.objects for insert
    to authenticated
    with check (
        bucket_id = 'notes'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

-- 3. Allow users to update files in their own user directory
create policy "Allow users to update their own notes"
    on storage.objects for update
    to authenticated
    using (
        bucket_id = 'notes'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

-- 4. Allow users to delete files in their own user directory
create policy "Allow users to delete their own notes"
    on storage.objects for delete
    to authenticated
    using (
        bucket_id = 'notes'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

