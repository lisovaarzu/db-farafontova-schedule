-- 1. Какие занятия видит пользователь первой группы?
-- expect: rows
SET ROLE schedule_group_1;

SELECT id, group_id, lesson_date, room_id
FROM schedule_entries
ORDER BY id
LIMIT 5;

RESET ROLE;


-- 2. Видит ли первый пользователь занятия других групп?
-- expect: value 0
SET ROLE schedule_group_1;

SELECT COUNT(*) AS other_groups
FROM schedule_entries
WHERE group_id <> 1;

RESET ROLE;


-- 3. Какие занятия видит пользователь второй группы?
-- expect: rows
SET ROLE schedule_group_2;

SELECT id, group_id, lesson_date, room_id
FROM schedule_entries
ORDER BY id
LIMIT 5;

RESET ROLE;


-- 4. Видит ли второй пользователь занятия других групп?
-- expect: value 0
SET ROLE schedule_group_2;

SELECT COUNT(*) AS other_groups
FROM schedule_entries
WHERE group_id <> 2;

RESET ROLE;


-- 5. Видит ли администратор занятия обеих групп?
-- expect: value 2
SELECT COUNT(DISTINCT group_id) AS visible_groups
FROM schedule_entries
WHERE group_id IN (1, 2);