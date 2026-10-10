WITH generated AS (
    SELECT
        n,
        ((n - 1) % 10) + 1 AS group_id,
        (((n - 1) / 10) % 6) + 1 AS pair_slot_id,
        DATE '2026-11-01' + ((n - 1) / 60)::integer AS lesson_date
    FROM generate_series(1, 1000) AS g(n)
)
INSERT INTO schedule_entries
    (group_id, discipline_id, teacher_id, room_id, pair_slot_id, lesson_date)
SELECT
    group_id,
    group_id,
    group_id,
    group_id,
    pair_slot_id,
    lesson_date
FROM generated;