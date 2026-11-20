CREATE OR REPLACE FUNCTION teacher_lesson_count(p_teacher_id integer)
RETURNS bigint
LANGUAGE sql
STABLE
AS $$
    SELECT COUNT(*)
    FROM schedule_entries
    WHERE teacher_id = p_teacher_id;
$$;


CREATE OR REPLACE FUNCTION add_schedule_lesson(
    p_group_id integer,
    p_discipline_id integer,
    p_teacher_id integer,
    p_room_id integer,
    p_pair_slot_id integer,
    p_lesson_date date
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_entry_id integer;
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM group_disciplines
        WHERE group_id = p_group_id
          AND discipline_id = p_discipline_id
    ) THEN
        RAISE EXCEPTION
            'Группа % не изучает дисциплину %',
            p_group_id, p_discipline_id;
    END IF;

    INSERT INTO schedule_entries (
        group_id,
        discipline_id,
        teacher_id,
        room_id,
        pair_slot_id,
        lesson_date
    )
    VALUES (
        p_group_id,
        p_discipline_id,
        p_teacher_id,
        p_room_id,
        p_pair_slot_id,
        p_lesson_date
    )
    RETURNING id INTO v_entry_id;

    RETURN v_entry_id;
END;
$$;


CREATE OR REPLACE FUNCTION find_schedule(
    p_group_id integer DEFAULT NULL,
    p_teacher_id integer DEFAULT NULL,
    p_lesson_date date DEFAULT NULL,
    p_building text DEFAULT NULL
)
RETURNS TABLE (
    entry_id integer,
    lesson_date date,
    pair_number integer,
    group_name text,
    discipline_name text,
    teacher_name text,
    building text,
    room_number text
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        v.entry_id,
        v.lesson_date,
        v.pair_number,
        v.group_name,
        v.discipline_name,
        v.teacher_name,
        v.building,
        v.room_number
    FROM v_schedule_details v
    WHERE (p_group_id IS NULL OR v.group_id = p_group_id)
      AND (p_teacher_id IS NULL OR v.teacher_id = p_teacher_id)
      AND (p_lesson_date IS NULL OR v.lesson_date = p_lesson_date)
      AND (p_building IS NULL OR v.building = p_building)
    ORDER BY v.lesson_date, v.pair_number, v.group_name;
$$;