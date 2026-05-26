alter table public.students
  add column if not exists slug text;

update public.students
set slug = case id
  when '21111111-1111-4111-8111-111111111111' then 'han-minseo'
  when '22222222-2222-4222-8222-222222222222' then 'kim-daniel'
  when '23333333-3333-4333-8333-333333333333' then 'choi-yuna'
  when '24444444-4444-4444-8444-444444444444' then 'lee-eden'
  when '25555555-5555-4555-8555-555555555555' then 'jung-sora'
  when '26666666-6666-4666-8666-666666666666' then 'baek-noah'
  else 'student-' || left(id::text, 8)
end
where slug is null or btrim(slug) = '';

alter table public.students
  alter column slug set not null;

alter table public.students
  drop constraint if exists students_slug_format_check;

alter table public.students
  add constraint students_slug_format_check
  check (slug ~ '^[a-z0-9][a-z0-9-]*$');

create unique index if not exists students_instructor_slug_idx
  on public.students (instructor_id, slug);
