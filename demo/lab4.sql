-- 1. Сколько тестовых аудиторий существует до транзакции?
-- expect: value 0
SELECT COUNT(*)
FROM rooms
WHERE building = 'L4'
  AND room_number = '401';


-- 2. Что произойдёт, если в середине транзакции нарушить CHECK?
-- expect: error check
BEGIN;

INSERT INTO rooms (building, room_number, capacity)
VALUES ('L4', '401', 20);

INSERT INTO rooms (building, room_number, capacity)
VALUES ('L4', '402', -5);

COMMIT;


-- 3. Остались ли изменения после ошибки?
-- expect: same 1
SELECT COUNT(*)
FROM rooms
WHERE building = 'L4'
  AND room_number = '401';


-- 4. Может ли app_reader просматривать расписание?
-- expect: rows
SET ROLE app_reader;

SELECT *
FROM v_schedule_details
LIMIT 5;

RESET ROLE;


-- 5. Может ли app_reader читать таблицу напрямую?
-- expect: error permission
SET ROLE app_reader;

SELECT *
FROM schedule_entries
LIMIT 5;

RESET ROLE;


-- 6. Может ли app_writer самостоятельно добавлять записи в таблицу?
-- expect: error permission
SET ROLE app_writer;

INSERT INTO rooms (building, room_number, capacity)
VALUES ('L4', '403', 30);

RESET ROLE;


-- 7. Может ли app_writer добавить занятие через безопасную функцию?
-- expect: rows
BEGIN;

SET ROLE app_writer;

SELECT add_schedule_lesson_safe(
    1, 1, 1, 1, 1, DATE '2026-12-02'
) AS new_entry_id;


-- 8. Появилось ли добавленное занятие в расписании?
-- expect: rows
SELECT entry_id, lesson_date, group_name, room_number
FROM v_schedule_details
WHERE lesson_date = DATE '2026-12-02'
  AND group_id = 1;


-- 9. Осталось ли тестовое занятие после отката?
-- expect: value 0
RESET ROLE;

ROLLBACK;

SELECT COUNT(*)
FROM schedule_entries
WHERE lesson_date = DATE '2026-12-02'
  AND group_id = 1;