insert into public.instructors (id, display_name, studio_name)
values ('11111111-1111-4111-8111-111111111111', 'Jin Park', 'Studio Groove')
on conflict (id) do update set
  display_name = excluded.display_name,
  studio_name = excluded.studio_name,
  updated_at = now();

insert into public.students (id, instructor_id, name, profile_cue, primary_weak_point, active)
values
  ('21111111-1111-4111-8111-111111111111', '11111111-1111-4111-8111-111111111111', 'Minseo Han', 'Complete beginner, counts aloud well', 'Rushes the last two counts when the fill appears', true),
  ('22222222-2222-4222-8222-222222222222', '11111111-1111-4111-8111-111111111111', 'Daniel Kim', 'Hobby adult, wants to play band songs', 'Practice is uneven after work-heavy weeks', true),
  ('23333333-3333-4333-8333-333333333333', '11111111-1111-4111-8111-111111111111', 'Yuna Choi', 'Practical-music audition prep', 'Fill entrances get tense above 92 bpm', true),
  ('24444444-4444-4444-8444-444444444444', '11111111-1111-4111-8111-111111111111', 'Ethan Lee', 'Learns fastest by watching first', 'Needs demonstration before verbal correction lands', true),
  ('25555555-5555-4555-8555-555555555555', '11111111-1111-4111-8111-111111111111', 'Sora Jung', 'Intermediate student, strong groove feel', 'Weak fills: hands speed up before the downbeat', true),
  ('26666666-6666-4666-8666-666666666666', '11111111-1111-4111-8111-111111111111', 'Noah Baek', 'Middle school student, loves pop punk', 'Assignment follow-through drops without a small checklist', true)
on conflict (id) do update set
  name = excluded.name,
  profile_cue = excluded.profile_cue,
  primary_weak_point = excluded.primary_weak_point,
  active = excluded.active,
  updated_at = now();

insert into public.progress_items (instructor_id, student_id, category, status, title, current_focus, observed_on, detail, tempo_note)
values
  ('11111111-1111-4111-8111-111111111111', '21111111-1111-4111-8111-111111111111', 'technique', 'in_progress', 'Basic 8-beat coordination', true, '2026-05-12', 'Can place kick and snare cleanly at slow tempo; needs count-aloud habit for fills.', 'Comfortable at 62 with counting aloud.'),
  ('11111111-1111-4111-8111-111111111111', '22222222-2222-4222-8222-222222222222', 'song', 'needs_review', 'Song groove: Come As You Are-style pattern', true, '2026-05-13', 'Groove is musical when relaxed, but tempo drops after missed entrances.', 'Clean around 82; drops after missed entrances.'),
  ('11111111-1111-4111-8111-111111111111', '23333333-3333-4333-8333-333333333333', 'genre', 'in_progress', 'Funk ghost-note comping', true, '2026-05-15', 'Audition prep focus: keep left-hand ghost notes lower than backbeat.', 'Clean at 84, tense at 96.'),
  ('11111111-1111-4111-8111-111111111111', '24444444-4444-4444-8444-444444444444', 'rudiment', 'steady', 'Paradiddle orchestration', true, '2026-05-16', 'After watching a two-bar demo, can mirror accent shapes around toms.', null),
  ('11111111-1111-4111-8111-111111111111', '25555555-5555-4555-8555-555555555555', 'technique', 'needs_review', 'Two-bar fill timing', true, '2026-05-18', 'Weak fills show up when moving from snare to floor tom; downbeat crash lands early.', 'Rushes above 88 when moving to floor tom.'),
  ('11111111-1111-4111-8111-111111111111', '26666666-6666-4666-8666-666666666666', 'assignment', 'in_progress', 'Hi-hat opening checklist', true, '2026-05-19', 'Small checklist improves consistency more than a long practice note.', null)
on conflict do nothing;

insert into public.student_traits (instructor_id, student_id, trait_type, label, detail)
values
  ('11111111-1111-4111-8111-111111111111', '21111111-1111-4111-8111-111111111111', 'learning_style', 'Counts aloud', 'Beginner confidence improves when every exercise starts with spoken counting.'),
  ('11111111-1111-4111-8111-111111111111', '22222222-2222-4222-8222-222222222222', 'practice_habit', 'Inconsistent practice', 'Work schedule creates uneven practice weeks; assign one short groove target.'),
  ('11111111-1111-4111-8111-111111111111', '23333333-3333-4333-8333-333333333333', 'strength', 'Audition focus', 'Prepared and detail-oriented; responds well to exact tempo targets.'),
  ('11111111-1111-4111-8111-111111111111', '24444444-4444-4444-8444-444444444444', 'learning_style', 'Demonstration-friendly learning', 'Needs to see the motion once before verbal explanation becomes useful.'),
  ('11111111-1111-4111-8111-111111111111', '25555555-5555-4555-8555-555555555555', 'weak_point', 'Weak fills', 'Fills speed up during tom movement; isolate last two sixteenth-note groups.'),
  ('11111111-1111-4111-8111-111111111111', '26666666-6666-4666-8666-666666666666', 'musical_preference', 'Pop punk energy', 'Motivated by fast chorus grooves and recognizable song sections.')
on conflict do nothing;

insert into public.lesson_notes (instructor_id, student_id, lesson_date, covered_material, observations, practice_assigned, next_step_hint)
values
  ('11111111-1111-4111-8111-111111111111', '21111111-1111-4111-8111-111111111111', '2026-05-12', 'Basic 8-beat and count-aloud drill', 'Stayed relaxed until adding a one-beat fill.', 'Four bars groove, one bar rest, count aloud every rep.', 'Start with clapping fill rhythm before kit.'),
  ('11111111-1111-4111-8111-111111111111', '22222222-2222-4222-8222-222222222222', '2026-05-13', 'Song groove and crash entrance', 'Good musical feel, practice gap showed in transitions.', 'Ten-minute song loop twice this week.', 'Review assignment honestly before adding a new section.'),
  ('11111111-1111-4111-8111-111111111111', '23333333-3333-4333-8333-333333333333', '2026-05-15', 'Ghost notes at audition tempo ladder', 'Clean at 84 bpm, tense at 96 bpm.', '84, 88, 92 bpm ladder with recorded self-check.', 'Keep tempo at 92 until left hand stays quiet.'),
  ('11111111-1111-4111-8111-111111111111', '24444444-4444-4444-8444-444444444444', '2026-05-16', 'Paradiddle accent movement', 'Mirrored demo quickly; verbal-only correction took longer.', 'Watch short demo clip, then play two-bar loop slowly.', 'Lead with visual demo next lesson.'),
  ('11111111-1111-4111-8111-111111111111', '25555555-5555-4555-8555-555555555555', '2026-05-18', 'Two-bar fills and crash landing', 'Groove is steady; fill hands rush before crash.', 'Loop last half-bar of fill into downbeat crash.', 'Use metronome accent on beat 1 only.'),
  ('11111111-1111-4111-8111-111111111111', '26666666-6666-4666-8666-666666666666', '2026-05-19', 'Hi-hat opening in chorus groove', 'Better focus with short checklist than paragraph instructions.', 'Three-item checklist: count, open, close.', 'Ask to show checklist before playing.')
on conflict do nothing;

insert into public.assignments (instructor_id, student_id, title, status, due_date, detail)
values
  ('11111111-1111-4111-8111-111111111111', '21111111-1111-4111-8111-111111111111', 'Count-aloud groove loop', 'in_progress', '2026-05-26', 'Keep the assignment short: four bars only, no speed goal yet.'),
  ('11111111-1111-4111-8111-111111111111', '22222222-2222-4222-8222-222222222222', 'Song section loop', 'needs_review', '2026-05-27', 'Review whether practice happened before adding chorus variation.'),
  ('11111111-1111-4111-8111-111111111111', '23333333-3333-4333-8333-333333333333', 'Ghost-note tempo ladder', 'in_progress', '2026-05-28', 'Record one take at 92 bpm for timing check.'),
  ('11111111-1111-4111-8111-111111111111', '24444444-4444-4444-8444-444444444444', 'Paradiddle accent demo loop', 'complete', '2026-05-29', 'Completed after watching demo clip and repeating slowly.'),
  ('11111111-1111-4111-8111-111111111111', '25555555-5555-4555-8555-555555555555', 'Fill landing isolation', 'needs_review', '2026-05-30', 'Bring attention to crash landing after tom movement.'),
  ('11111111-1111-4111-8111-111111111111', '26666666-6666-4666-8666-666666666666', 'Hi-hat checklist', 'in_progress', '2026-05-31', 'Student should bring the checklist and mark each practice day.')
on conflict do nothing;

insert into public.next_lesson_plans (instructor_id, student_id, planned_for, priority, next_action, detail)
values
  ('11111111-1111-4111-8111-111111111111', '21111111-1111-4111-8111-111111111111', '2026-05-26', 'normal', 'Clap the fill before playing it on the kit', 'Keep the beginner lesson calm and count-based.'),
  ('11111111-1111-4111-8111-111111111111', '22222222-2222-4222-8222-222222222222', '2026-05-27', 'high', 'Check practice consistency before adding a new song section', 'If practice was light, repeat the same groove with a smaller target.'),
  ('11111111-1111-4111-8111-111111111111', '23333333-3333-4333-8333-333333333333', '2026-05-28', 'high', 'Hold 92 bpm until ghost notes stay below the backbeat', 'Audition timeline matters, but tension will cost more than speed.'),
  ('11111111-1111-4111-8111-111111111111', '24444444-4444-4444-8444-444444444444', '2026-05-29', 'normal', 'Start with a visual demo of the full two-bar phrase', 'Use demonstration first, explanation second.'),
  ('11111111-1111-4111-8111-111111111111', '25555555-5555-4555-8555-555555555555', '2026-05-30', 'high', 'Isolate the last two beats of the weak fill', 'Do not add a harder fill until the crash lands on beat 1.'),
  ('11111111-1111-4111-8111-111111111111', '26666666-6666-4666-8666-666666666666', '2026-05-31', 'normal', 'Use the checklist before playing the chorus groove', 'The checklist is the lesson anchor.')
on conflict do nothing;
