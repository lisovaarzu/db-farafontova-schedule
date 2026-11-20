
-- 1. Как выглядит полное расписание с группами, дисциплинами и аудиториями?
-- expect: rows
SELECT *
FROM v_schedule_details
ORDER BY lesson_date, pair_number
LIMIT 5;


-- 2. Сколько занятий проводит каждый преподаватель?
-- expect: rows
SELECT *
FROM v_teacher_load
ORDER BY lesson_count DESC, teacher_name
LIMIT 10;


-- 3. Сколько занятий у преподавателя с id = 1?
-- expect: rows
SELECT teacher_lesson_count(1) AS lesson_count;


-- 4. Как найти расписание группы по дате через функцию с фильтрами?
-- expect: rows
SELECT *
FROM find_schedule(
    p_group_id => 1,
    p_lesson_date => DATE '2026-10-12'
);


-- 5. Есть ли занятия 1 декабря 2026 года до добавления новой записи?
-- expect: value 0
BEGIN;

SELECT COUNT(*) AS before_count
FROM schedule_entries
WHERE lesson_date = DATE '2026-12-01';


-- 6. Как добавить занятие одной командой и увидеть его в расписании?
-- expect: rows
SELECT add_schedule_lesson(
    1, 1, 1, 1, 1, DATE '2026-12-01'
) AS new_entry_id;

SELECT entry_id, lesson_date, group_name,
       discipline_name, teacher_name, building, room_number
FROM v_schedule_details
WHERE lesson_date = DATE '2026-12-01'
  AND group_id = 1;


-- 7. Как обновить материализованный отчёт после добавления занятия?
-- expect: rows
SELECT COUNT(*) AS december_before_refresh
FROM mv_monthly_schedule
WHERE month = DATE '2026-12-01';

REFRESH MATERIALIZED VIEW mv_monthly_schedule;

SELECT month, lesson_count
FROM mv_monthly_schedule
WHERE month = DATE '2026-12-01';


-- 8. Обновится ли updated_at при изменении преподавателя занятия?
-- expect: rows
UPDATE schedule_entries
SET teacher_id = 2
WHERE lesson_date = DATE '2026-12-01'
  AND group_id = 1
  AND pair_slot_id = 1;

SELECT
    h.schedule_entry_id,
    (h.old_row->>'updated_at')::timestamptz AS updated_before,
    (h.new_row->>'updated_at')::timestamptz AS updated_after,
    (h.old_row->>'updated_at')::timestamptz <
        (h.new_row->>'updated_at')::timestamptz AS timestamp_changed
FROM schedule_entries_history h
WHERE h.operation = 'UPDATE'
  AND h.new_row->>'lesson_date' = '2026-12-01'
ORDER BY h.id DESC
LIMIT 1;


-- 9. Сохранились ли добавление и изменение занятия в журнале?
-- expect: rows
SELECT
    h.operation,
    h.old_row->>'teacher_id' AS teacher_before,
    h.new_row->>'teacher_id' AS teacher_after,
    h.changed_by,
    h.changed_at
FROM schedule_entries_history h
WHERE h.schedule_entry_id = (
    SELECT id
    FROM schedule_entries
    WHERE lesson_date = DATE '2026-12-01'
      AND group_id = 1
      AND pair_slot_id = 1
)
ORDER BY h.id;


-- 10. Можно ли удалить тестовое занятие?
-- expect: rows
DELETE FROM schedule_entries
WHERE lesson_date = DATE '2026-12-01'
  AND group_id = 1
  AND pair_slot_id = 1
RETURNING id;


-- 11. Каким было состояние занятия при добавлении, изменении и удалении?
-- expect: rows
WITH target AS (
    SELECT schedule_entry_id
    FROM schedule_entries_history
    WHERE operation = 'INSERT'
      AND new_row->>'lesson_date' = '2026-12-01'
      AND new_row->>'group_id' = '1'
    ORDER BY id DESC
    LIMIT 1
)
SELECT
    h.operation,
    h.changed_at,
    h.changed_by,
    h.old_row IS NOT NULL AS has_old,
    h.new_row IS NOT NULL AS has_new,
    schedule_entry_at(
        h.schedule_entry_id, h.changed_at
    ) AS state_at_time
FROM schedule_entries_history h
JOIN target t ON t.schedule_entry_id = h.schedule_entry_id
WHERE h.operation IN ('INSERT', 'UPDATE', 'DELETE')
ORDER BY h.id;


-- 12. Что произойдёт, если назначить занятие в уже занятую аудиторию?
-- expect: error "уже занята"
UPDATE pair_slots
SET starts_at = TIME '07:30',
    ends_at = TIME '08:50'
WHERE pair_number = 10;

INSERT INTO schedule_entries (
    group_id, discipline_id, teacher_id,
    room_id, pair_slot_id, lesson_date
)
VALUES (6, 6, 6, 1, 10, DATE '2026-10-12');


-- 13. Остались ли тестовые изменения после отката транзакции?
-- expect: value 0
ROLLBACK;

SELECT COUNT(*) AS remaining_test_lessons
FROM schedule_entries
WHERE lesson_date = DATE '2026-12-01';
