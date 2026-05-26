export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

export type Database = {
  public: {
    Tables: {
      instructors: {
        Row: {
          id: string;
          auth_user_id: string | null;
          display_name: string;
          studio_name: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id: string;
          auth_user_id?: string | null;
          display_name: string;
          studio_name?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          auth_user_id?: string | null;
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
    Functions: {
      closeout_lesson: {
        Args: {
          target_student_id: string;
          closeout_lesson_date: string;
          closeout_covered_material: string;
          closeout_observations: string;
          closeout_practice_assigned: string;
          closeout_next_step_hint: string;
          target_next_plan_id: string | null;
          closeout_next_action: string;
          closeout_next_plan_detail: string;
          closeout_planned_for: string | null;
          closeout_priority: string;
          target_assignment_id: string | null;
          closeout_assignment_title: string;
          closeout_assignment_status: string | null;
          closeout_assignment_due_date: string | null;
          closeout_assignment_detail: string;
          target_progress_item_id: string | null;
          closeout_progress_status: string | null;
          closeout_progress_current_focus: boolean;
        };
        Returns: undefined;
      };
    };
  };
};

// Regenerate from Supabase later with:
// npx supabase gen types typescript --project-id <project-id> --schema public > src/types/database.ts
