CREATE OR REPLACE FUNCTION add_schedule_lesson_safe(
    p_group_id integer,
    p_discipline_id integer,
    p_teacher_id integer,
    p_room_id integer,
    p_pair_slot_id integer,
    p_lesson_date date
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_entry_id integer;
BEGIN
    PERFORM 1
    FROM rooms
    WHERE id = p_room_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Аудитория с id % не найдена', p_room_id;
    END IF;

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