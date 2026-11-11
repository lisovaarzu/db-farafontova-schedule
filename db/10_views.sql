CREATE OR REPLACE VIEW v_schedule_details AS
SELECT
    se.id AS entry_id,
    se.lesson_date,
    ps.pair_number,
    ps.starts_at,
    ps.ends_at,
    sg.id AS group_id,
    sg.name AS group_name,
    d.name AS discipline_name,
    t.id AS teacher_id,
    t.full_name AS teacher_name,
    r.id AS room_id,
    r.building,
    r.room_number
FROM schedule_entries se
JOIN student_groups sg ON sg.id = se.group_id
JOIN disciplines d ON d.id = se.discipline_id
JOIN teachers t ON t.id = se.teacher_id
JOIN rooms r ON r.id = se.room_id
JOIN pair_slots ps ON ps.id = se.pair_slot_id;


CREATE OR REPLACE VIEW v_teacher_load AS
SELECT
    t.id AS teacher_id,
    t.full_name AS teacher_name,
    COUNT(se.id) AS lesson_count
FROM teachers t
LEFT JOIN schedule_entries se ON se.teacher_id = t.id
GROUP BY t.id, t.full_name;


CREATE MATERIALIZED VIEW mv_monthly_schedule AS
SELECT
    DATE_TRUNC('month', lesson_date)::date AS month,
    COUNT(*) AS lesson_count
FROM schedule_entries
GROUP BY DATE_TRUNC('month', lesson_date)::date;