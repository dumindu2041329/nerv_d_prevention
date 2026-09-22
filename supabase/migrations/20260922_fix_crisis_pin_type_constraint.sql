-- ============================================================================
-- Fix: crisis_pins.type CHECK conflict
-- ----------------------------------------------------------------------------
-- 20260624_initial_schema.sql created an inline CHECK allowing 'relief_supply'
-- (crisis_pins_type_check). 20260624_01_reference_data_and_constraints.sql
-- added a second CHECK allowing 'reliefSupply' (crisis_pins_type_chk).
-- Postgres enforces every CHECK, so the effective domain was the intersection
-- and the deployed `crisis-pins` Edge Function returned a 500 for every
-- 'relief_supply' insert (see VALID_TYPES in supabase/functions/crisis-pins).
--
-- Standardize both constraints on the snake_case spelling used by the initial
-- schema and the deployed function.
-- ============================================================================

alter table public.crisis_pins
  drop constraint crisis_pins_type_chk;

alter table public.crisis_pins
  add constraint crisis_pins_type_chk
  check (type in ('shelter', 'water', 'toilet', 'road', 'waste', 'relief_supply'));
