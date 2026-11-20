ALTER TABLE schedule_entries
ADD COLUMN updated_at timestamptz NOT NULL DEFAULT now();


CREATE OR REPLACE FUNCTION check_room_occupancy()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_start time;
    v_end time;
    v_building text;
    v_room_number text;
BEGIN
    SELECT ps.starts_at, ps.ends_at,
           r.building, r.room_number
    INTO v_start, v_end, v_building, v_room_number
    FROM pair_slots ps
    CROSS JOIN rooms r
    WHERE ps.id = NEW.pair_slot_id
      AND r.id = NEW.room_id;

    IF NOT FOUND THEN
        RETURN NEW;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM schedule_entries se
        JOIN pair_slots ps ON ps.id = se.pair_slot_id
        WHERE se.room_id = NEW.room_id
          AND se.lesson_date = NEW.lesson_date
          AND se.id IS DISTINCT FROM NEW.id
          AND se.pair_slot_id <> NEW.pair_slot_id
          AND ps.starts_at < v_end
          AND ps.ends_at > v_start
    ) THEN
        RAISE EXCEPTION
            'Аудитория %-% уже занята % с % до %',
            v_building, v_room_number,
            NEW.lesson_date, v_start, v_end;
    END IF;

    RETURN NEW;
END;
$$;


CREATE TRIGGER trg_check_room_occupancy
BEFORE INSERT OR UPDATE ON schedule_entries
FOR EACH ROW
EXECUTE FUNCTION check_room_occupancy();


CREATE OR REPLACE FUNCTION set_schedule_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := clock_timestamp();
    RETURN NEW;
END;
$$;


CREATE TRIGGER trg_schedule_updated_at
BEFORE UPDATE ON schedule_entries
FOR EACH ROW
EXECUTE FUNCTION set_schedule_updated_at();


CREATE TABLE schedule_entries_history (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    schedule_entry_id integer NOT NULL,
    operation text NOT NULL
        CHECK (operation IN ('SNAPSHOT', 'INSERT', 'UPDATE', 'DELETE')),
    old_row jsonb,
    new_row jsonb,
    changed_by text NOT NULL DEFAULT session_user,
    changed_at timestamptz NOT NULL DEFAULT clock_timestamp()
);


CREATE INDEX idx_schedule_history_entry_time
ON schedule_entries_history (
    schedule_entry_id,
    changed_at DESC,
    id DESC
);


INSERT INTO schedule_entries_history (
    schedule_entry_id, operation, old_row, new_row
)
SELECT
    se.id, 'SNAPSHOT', NULL, to_jsonb(se)
FROM schedule_entries se;


CREATE OR REPLACE FUNCTION log_schedule_changes()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO schedule_entries_history (
            schedule_entry_id, operation, old_row, new_row
        )
        VALUES (
            NEW.id, TG_OP, NULL, to_jsonb(NEW)
        );

    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO schedule_entries_history (
            schedule_entry_id, operation, old_row, new_row
        )
        VALUES (
            NEW.id, TG_OP, to_jsonb(OLD), to_jsonb(NEW)
        );

    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO schedule_entries_history (
            schedule_entry_id, operation, old_row, new_row
        )
        VALUES (
            OLD.id, TG_OP, to_jsonb(OLD), NULL
        );
    END IF;

    RETURN NULL;
END;
$$;


CREATE TRIGGER trg_log_schedule_changes
AFTER INSERT OR UPDATE OR DELETE ON schedule_entries
FOR EACH ROW
EXECUTE FUNCTION log_schedule_changes();


CREATE OR REPLACE FUNCTION schedule_entry_at(
    p_entry_id integer,
    p_moment timestamptz
)
RETURNS jsonb
LANGUAGE sql
STABLE
AS $$
    SELECT h.new_row
    FROM schedule_entries_history h
    WHERE h.schedule_entry_id = p_entry_id
      AND h.changed_at <= p_moment
    ORDER BY h.changed_at DESC, h.id DESC
    LIMIT 1;
$$;