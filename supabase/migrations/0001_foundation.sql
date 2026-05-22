create extension if not exists pgcrypto;

create table if not exists public.instructors (
  id uuid primary key,
  display_name text not null,
  studio_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  instructor_id uuid not null references public.instructors(id) on delete cascade,
  name text not null,
  profile_cue text not null,
  current_focus text not null,
  primary_weak_point text not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, instructor_id)
);

create table if not exists public.progress_items (
  id uuid primary key default gen_random_uuid(),
  instructor_id uuid not null references public.instructors(id) on delete cascade,
  student_id uuid not null,
  category text not null check (category in ('book', 'song', 'rudiment', 'genre', 'technique', 'session', 'assignment')),
  status text not null check (status in ('new', 'in_progress', 'needs_review', 'steady', 'complete')),
  title text not null,
  current_focus boolean not null default false,
  observed_on date not null default current_date,
  detail text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (student_id, instructor_id) references public.students(id, instructor_id) on delete cascade
);

create table if not exists public.student_traits (
  id uuid primary key default gen_random_uuid(),
  instructor_id uuid not null references public.instructors(id) on delete cascade,
  student_id uuid not null,
  trait_type text not null check (trait_type in ('strength', 'weak_point', 'practice_habit', 'learning_style', 'musical_preference', 'caution')),
  label text not null,
  detail text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (student_id, instructor_id) references public.students(id, instructor_id) on delete cascade
);

create table if not exists public.lesson_notes (
  id uuid primary key default gen_random_uuid(),
  instructor_id uuid not null references public.instructors(id) on delete cascade,
  student_id uuid not null,
  lesson_date date not null,
  covered_material text not null,
  observations text not null,
  practice_assigned text not null,
  next_step_hint text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (student_id, instructor_id) references public.students(id, instructor_id) on delete cascade
);

create table if not exists public.assignments (
  id uuid primary key default gen_random_uuid(),
  instructor_id uuid not null references public.instructors(id) on delete cascade,
  student_id uuid not null,
  title text not null,
  status text not null check (status in ('not_started', 'in_progress', 'needs_review', 'complete', 'paused')),
  due_date date,
  detail text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (student_id, instructor_id) references public.students(id, instructor_id) on delete cascade
);

create table if not exists public.next_lesson_plans (
  id uuid primary key default gen_random_uuid(),
  instructor_id uuid not null references public.instructors(id) on delete cascade,
  student_id uuid not null,
  planned_for date,
  priority text not null check (priority in ('low', 'normal', 'high')),
  next_action text not null,
  detail text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (student_id, instructor_id) references public.students(id, instructor_id) on delete cascade
);

create index if not exists students_instructor_active_idx on public.students (instructor_id, active, name);
create index if not exists progress_items_student_focus_idx on public.progress_items (instructor_id, student_id, current_focus, observed_on desc);
create index if not exists student_traits_student_type_idx on public.student_traits (instructor_id, student_id, trait_type);
create index if not exists lesson_notes_student_date_idx on public.lesson_notes (instructor_id, student_id, lesson_date desc);
create index if not exists assignments_student_status_idx on public.assignments (instructor_id, student_id, status);
create index if not exists next_lesson_plans_student_priority_idx on public.next_lesson_plans (instructor_id, student_id, priority);

alter table public.instructors enable row level security;
alter table public.students enable row level security;
alter table public.progress_items enable row level security;
alter table public.student_traits enable row level security;
alter table public.lesson_notes enable row level security;
alter table public.assignments enable row level security;
alter table public.next_lesson_plans enable row level security;

create policy "instructors_select_own" on public.instructors
  for select to authenticated using (id = auth.uid());
create policy "instructors_insert_own" on public.instructors
  for insert to authenticated with check (id = auth.uid());
create policy "instructors_update_own" on public.instructors
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy "instructors_delete_own" on public.instructors
  for delete to authenticated using (id = auth.uid());

create policy "students_select_own" on public.students
  for select to authenticated using (instructor_id = auth.uid());
create policy "students_insert_own" on public.students
  for insert to authenticated with check (instructor_id = auth.uid());
create policy "students_update_own" on public.students
  for update to authenticated using (instructor_id = auth.uid()) with check (instructor_id = auth.uid());
create policy "students_delete_own" on public.students
  for delete to authenticated using (instructor_id = auth.uid());

create policy "progress_items_select_own" on public.progress_items
  for select to authenticated using (instructor_id = auth.uid());
create policy "progress_items_insert_own" on public.progress_items
  for insert to authenticated with check (instructor_id = auth.uid());
create policy "progress_items_update_own" on public.progress_items
  for update to authenticated using (instructor_id = auth.uid()) with check (instructor_id = auth.uid());
create policy "progress_items_delete_own" on public.progress_items
  for delete to authenticated using (instructor_id = auth.uid());

create policy "student_traits_select_own" on public.student_traits
  for select to authenticated using (instructor_id = auth.uid());
create policy "student_traits_insert_own" on public.student_traits
  for insert to authenticated with check (instructor_id = auth.uid());
create policy "student_traits_update_own" on public.student_traits
  for update to authenticated using (instructor_id = auth.uid()) with check (instructor_id = auth.uid());
create policy "student_traits_delete_own" on public.student_traits
  for delete to authenticated using (instructor_id = auth.uid());

create policy "lesson_notes_select_own" on public.lesson_notes
  for select to authenticated using (instructor_id = auth.uid());
create policy "lesson_notes_insert_own" on public.lesson_notes
  for insert to authenticated with check (instructor_id = auth.uid());
create policy "lesson_notes_update_own" on public.lesson_notes
  for update to authenticated using (instructor_id = auth.uid()) with check (instructor_id = auth.uid());
create policy "lesson_notes_delete_own" on public.lesson_notes
  for delete to authenticated using (instructor_id = auth.uid());

create policy "assignments_select_own" on public.assignments
  for select to authenticated using (instructor_id = auth.uid());
create policy "assignments_insert_own" on public.assignments
  for insert to authenticated with check (instructor_id = auth.uid());
create policy "assignments_update_own" on public.assignments
  for update to authenticated using (instructor_id = auth.uid()) with check (instructor_id = auth.uid());
create policy "assignments_delete_own" on public.assignments
  for delete to authenticated using (instructor_id = auth.uid());

create policy "next_lesson_plans_select_own" on public.next_lesson_plans
  for select to authenticated using (instructor_id = auth.uid());
create policy "next_lesson_plans_insert_own" on public.next_lesson_plans
  for insert to authenticated with check (instructor_id = auth.uid());
create policy "next_lesson_plans_update_own" on public.next_lesson_plans
  for update to authenticated using (instructor_id = auth.uid()) with check (instructor_id = auth.uid());
create policy "next_lesson_plans_delete_own" on public.next_lesson_plans
  for delete to authenticated using (instructor_id = auth.uid());
