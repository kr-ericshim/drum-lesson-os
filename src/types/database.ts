export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

export type Database = {
  public: {
    Tables: {
      instructors: {
        Row: {
          id: string;
          display_name: string;
          studio_name: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id: string;
          display_name: string;
          studio_name?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          display_name?: string;
          studio_name?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Relationships: [];
      };
      students: {
        Row: {
          id: string;
          instructor_id: string;
          slug: string;
          name: string;
          profile_cue: string;
          primary_weak_point: string;
          active: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          instructor_id: string;
          slug?: string;
          name: string;
          profile_cue: string;
          primary_weak_point: string;
          active?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          instructor_id?: string;
          slug?: string;
          name?: string;
          profile_cue?: string;
          primary_weak_point?: string;
          active?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Relationships: [];
      };
      progress_items: {
        Row: {
          id: string;
          instructor_id: string;
          student_id: string;
          category: string;
          status: string;
          title: string;
          current_focus: boolean;
          observed_on: string;
          detail: string;
          tempo_note: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          instructor_id: string;
          student_id: string;
          category: string;
          status: string;
          title: string;
          current_focus?: boolean;
          observed_on?: string;
          detail: string;
          tempo_note?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          instructor_id?: string;
          student_id?: string;
          category?: string;
          status?: string;
          title?: string;
          current_focus?: boolean;
          observed_on?: string;
          detail?: string;
          tempo_note?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Relationships: [];
      };
      student_traits: {
        Row: {
          id: string;
          instructor_id: string;
          student_id: string;
          trait_type: string;
          label: string;
          detail: string;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          instructor_id: string;
          student_id: string;
          trait_type: string;
          label: string;
          detail: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          instructor_id?: string;
          student_id?: string;
          trait_type?: string;
          label?: string;
          detail?: string;
          created_at?: string;
          updated_at?: string;
        };
        Relationships: [];
      };
      lesson_notes: {
        Row: {
          id: string;
          instructor_id: string;
          student_id: string;
          lesson_date: string;
          covered_material: string;
          observations: string;
          practice_assigned: string;
          next_step_hint: string;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          instructor_id: string;
          student_id: string;
          lesson_date: string;
          covered_material: string;
          observations: string;
          practice_assigned: string;
          next_step_hint: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          instructor_id?: string;
          student_id?: string;
          lesson_date?: string;
          covered_material?: string;
          observations?: string;
          practice_assigned?: string;
          next_step_hint?: string;
          created_at?: string;
          updated_at?: string;
        };
        Relationships: [];
      };
      assignments: {
        Row: {
          id: string;
          instructor_id: string;
          student_id: string;
          title: string;
          status: string;
          due_date: string | null;
          detail: string;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          instructor_id: string;
          student_id: string;
          title: string;
          status: string;
          due_date?: string | null;
          detail: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          instructor_id?: string;
          student_id?: string;
          title?: string;
          status?: string;
          due_date?: string | null;
          detail?: string;
          created_at?: string;
          updated_at?: string;
        };
        Relationships: [];
      };
      next_lesson_plans: {
        Row: {
          id: string;
          instructor_id: string;
          student_id: string;
          planned_for: string | null;
          priority: string;
          next_action: string;
          detail: string;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          instructor_id: string;
          student_id: string;
          planned_for?: string | null;
          priority: string;
          next_action: string;
          detail: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          instructor_id?: string;
          student_id?: string;
          planned_for?: string | null;
          priority?: string;
          next_action?: string;
          detail?: string;
          created_at?: string;
          updated_at?: string;
        };
        Relationships: [];
      };
    };
    Views: Record<string, never>;
    Functions: Record<string, never>;
  };
};

// Regenerate from Supabase later with:
// npx supabase gen types typescript --project-id <project-id> --schema public > src/types/database.ts
