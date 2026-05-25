with ranked_focus_items as (
  select
    id,
    row_number() over (
      partition by instructor_id, student_id
      order by observed_on desc, updated_at desc, created_at desc, id desc
    ) as focus_rank
  from public.progress_items
  where current_focus
)
update public.progress_items
set
  current_focus = false,
  updated_at = now()
from ranked_focus_items
where progress_items.id = ranked_focus_items.id
  and ranked_focus_items.focus_rank > 1;

create unique index if not exists progress_items_one_current_focus_idx
  on public.progress_items (instructor_id, student_id)
  where current_focus;

alter table public.students
  drop column if exists current_focus;
