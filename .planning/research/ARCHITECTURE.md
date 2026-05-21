# Architecture Research: Drum Lesson OS

## Suggested Components

### Dashboard

Shows the student roster and compact indicators: current focus, last lesson date, assignment status, weak points, and next action.

### Student Detail

Holds the working memory for one student: profile, traits, progress items, recent lesson notes, assignments, and next lesson plan.

### Progress Model

Progress should support flexible categories rather than a rigid syllabus only:

- Books
- Songs
- Rudiments
- Genres
- Techniques
- Lesson sessions
- Assignments

### Lesson Note Model

Each lesson note should capture date, summary, what was covered, observations, assigned practice, and next-step hints.

### Traits/Weak Points

Keep these easy to edit and scan. Early MVP can use structured tags plus freeform notes instead of forcing every detail into a strict taxonomy.

## Data Flow

1. Instructor opens dashboard.
2. Dashboard lists students with latest progress and warnings.
3. Instructor opens one student.
4. Student detail shows current progress, traits, recent notes, assignment status, and next plan.
5. Instructor updates notes/progress during or after the lesson.
6. Dashboard reflects the updated next action.

## Build Order

1. Establish app shell, database schema, and sample data.
2. Build roster dashboard and student detail read views.
3. Add create/edit flows for students, progress, traits, notes, and assignments.
4. Add next-lesson summary and dashboard indicators.

## Integration Notes

Keep the MVP single-instructor. If hosted accounts are added later, all student records should belong to an instructor workspace/user.
