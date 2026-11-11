-- 1. Какие дисциплины изучает каждая учебная группа?
-- expect: rows
SELECT sg.name AS student_group, d.name AS discipline
FROM student_groups sg
JOIN group_disciplines gd ON gd.group_id = sg.id
JOIN disciplines d ON d.id = gd.discipline_id
ORDER BY sg.name, d.name;


-- 2. Кто ведёт занятия у учебных групп 12 октября 2026 года?
-- expect: rows
SELECT sg.name AS student_group, t.full_name AS teacher,
       se.lesson_date
FROM schedule_entries se
JOIN student_groups sg ON sg.id = se.group_id
JOIN teachers t ON t.id = se.teacher_id
WHERE se.lesson_date = '2026-10-12'
ORDER BY sg.name, t.full_name;


-- 3. В каких аудиториях проходят занятия 13 октября 2026 года?
-- expect: rows
SELECT se.lesson_date, r.building, r.room_number,
       ps.pair_number, ps.starts_at
FROM schedule_entries se
JOIN rooms r ON r.id = se.room_id
JOIN pair_slots ps ON ps.id = se.pair_slot_id
WHERE se.lesson_date = '2026-10-13'
ORDER BY ps.pair_number, r.building, r.room_number;


-- 4. Сколько занятий у каждой учебной группы?
-- expect: rows
SELECT sg.name AS student_group,
       COUNT(se.id) AS lesson_count
FROM student_groups sg
JOIN schedule_entries se ON se.group_id = sg.id
GROUP BY sg.id, sg.name
ORDER BY lesson_count DESC, sg.name;


-- 5. Какие преподаватели проводят больше 100 занятий?
-- expect: rows
SELECT t.full_name AS teacher,
       COUNT(se.id) AS lesson_count
FROM teachers t
JOIN schedule_entries se ON se.teacher_id = t.id
GROUP BY t.id, t.full_name
HAVING COUNT(se.id) > 100
ORDER BY lesson_count DESC, t.full_name;


-- 6. Какие номера пар свободны 13 октября 2026 года?
-- expect: rows
SELECT ps.pair_number, ps.starts_at, ps.ends_at
FROM pair_slots ps
LEFT JOIN schedule_entries se
    ON se.pair_slot_id = ps.id
    AND se.lesson_date = '2026-10-13'
WHERE se.id IS NULL
ORDER BY ps.pair_number;


-- 7. Какие учебные группы изучают дисциплину «Базы данных»?
-- expect: rows
SELECT sg.name AS student_group
FROM student_groups sg
WHERE sg.id IN (
    SELECT gd.group_id
    FROM group_disciplines gd
    JOIN disciplines d ON d.id = gd.discipline_id
    WHERE d.name = 'Базы данных'
)
ORDER BY sg.name;


-- 8. Какие аудитории имеют вместимость выше средней?
-- expect: rows
SELECT building, room_number, capacity
FROM rooms
WHERE capacity > (
    SELECT AVG(capacity)
    FROM rooms
)
ORDER BY capacity DESC, building, room_number;


-- 9. Какие пять занятий являются последними по дате?
-- expect: rows
SELECT se.lesson_date, sg.name AS student_group,
       d.name AS discipline, ps.pair_number
FROM schedule_entries se
JOIN student_groups sg ON sg.id = se.group_id
JOIN disciplines d ON d.id = se.discipline_id
JOIN pair_slots ps ON ps.id = se.pair_slot_id
ORDER BY se.lesson_date DESC, se.id DESC
LIMIT 5;


-- 10. Как добавить новую аудиторию и проверить её появление?
-- expect: rows
BEGIN;

SELECT COUNT(*) AS before_count
FROM rooms
WHERE building = 'Z' AND room_number = '901';

INSERT INTO rooms (building, room_number, capacity)
VALUES ('Z', '901', 20);

SELECT building, room_number, capacity
FROM rooms
WHERE building = 'Z' AND room_number = '901';

ROLLBACK;


-- 11. Как изменить вместимость аудитории A-101 с 30 до 35 мест?
-- expect: rows
BEGIN;

SELECT building, room_number, capacity
FROM rooms
WHERE building = 'A' AND room_number = '101';

UPDATE rooms
SET capacity = 35
WHERE building = 'A' AND room_number = '101';

SELECT building, room_number, capacity
FROM rooms
WHERE building = 'A' AND room_number = '101';

ROLLBACK;


-- 12. Как удалить тестовую аудиторию и проверить результат?
-- expect: value 0
BEGIN;

INSERT INTO rooms (building, room_number, capacity)
VALUES ('Z', '902', 20);

SELECT building, room_number, capacity
FROM rooms
WHERE building = 'Z' AND room_number = '902';

DELETE FROM rooms
WHERE building = 'Z' AND room_number = '902';

SELECT COUNT(*) AS remaining_rooms
FROM rooms
WHERE building = 'Z' AND room_number = '902';

ROLLBACK;


-- 13. Какие три аудитории наиболее загружены в каждом корпусе?
-- expect: rows
WITH room_load AS (
    SELECT r.building, r.room_number,
           COUNT(se.id) AS lesson_count
    FROM rooms r
    LEFT JOIN schedule_entries se ON se.room_id = r.id
    GROUP BY r.id, r.building, r.room_number
),
ranked AS (
    SELECT building, room_number, lesson_count,
           ROW_NUMBER() OVER (
               PARTITION BY building
               ORDER BY lesson_count DESC, room_number
           ) AS place
    FROM room_load
)
SELECT building, room_number, lesson_count, place
FROM ranked
WHERE place <= 3
ORDER BY building, place;


-- 14. Как изменяется количество занятий по месяцам в процентах?
-- expect: rows
WITH monthly_counts AS (
    SELECT DATE_TRUNC('month', lesson_date)::date AS month,
           COUNT(*) AS lesson_count
    FROM schedule_entries
    GROUP BY DATE_TRUNC('month', lesson_date)::date
),
monthly_changes AS (
    SELECT month, lesson_count,
           LAG(lesson_count) OVER (
               ORDER BY month
           ) AS previous_month_count
    FROM monthly_counts
)
SELECT month, lesson_count, previous_month_count,
       ROUND(
           100.0 * (lesson_count - previous_month_count)
           / NULLIF(previous_month_count, 0), 1
       ) AS change_percent
FROM monthly_changes
ORDER BY month;


-- 15. Сколько занятий проводится каждый день, сколько из них утренних и дневных, и каков процент утренних?
-- expect: rows
WITH RECURSIVE calendar(day) AS (
    SELECT MIN(lesson_date)
    FROM schedule_entries

    UNION ALL

    SELECT day + 1
    FROM calendar
    WHERE day < (
        SELECT MAX(lesson_date)
        FROM schedule_entries
    )
)
SELECT c.day AS lesson_date,
       COUNT(se.id) AS total_lessons,
       COUNT(*) FILTER (
           WHERE ps.starts_at < TIME '12:00'
       ) AS morning_lessons,
       COUNT(*) FILTER (
           WHERE ps.starts_at >= TIME '12:00'
       ) AS afternoon_lessons,
       COALESCE(
           ROUND(
               100.0 * COUNT(*) FILTER (
                   WHERE ps.starts_at < TIME '12:00'
               ) / NULLIF(COUNT(se.id), 0), 1
           ), 0
       ) AS morning_percent
FROM calendar c
LEFT JOIN schedule_entries se ON se.lesson_date = c.day
LEFT JOIN pair_slots ps ON ps.id = se.pair_slot_id
GROUP BY c.day
ORDER BY c.day;