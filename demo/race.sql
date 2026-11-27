-- [setup] Подготовка двух пар с пересекающимся временем
DELETE FROM schedule_entries
WHERE lesson_date = DATE '2026-12-03'
  AND room_id = 1
  AND pair_slot_id IN (9, 10);

UPDATE pair_slots
SET starts_at = TIME '19:30',
    ends_at = TIME '20:50'
WHERE pair_number = 10;


-- [A] Первый пользователь добавляет занятие
BEGIN;

INSERT INTO schedule_entries (
    group_id,
    discipline_id,
    teacher_id,
    room_id,
    pair_slot_id,
    lesson_date
)
VALUES (1, 1, 1, 1, 9, DATE '2026-12-03');


-- [B] Второй пользователь одновременно добавляет занятие
BEGIN;

INSERT INTO schedule_entries (
    group_id,
    discipline_id,
    teacher_id,
    room_id,
    pair_slot_id,
    lesson_date
)
VALUES (2, 2, 2, 1, 10, DATE '2026-12-03');


-- [A] Первый пользователь сохраняет изменения
COMMIT;


-- [B] Второй пользователь сохраняет изменения
COMMIT;


-- [check] Нет ли пересекающихся занятий в одной аудитории?
-- expect: false
SELECT NOT EXISTS (
    SELECT 1
    FROM schedule_entries a
    JOIN schedule_entries b
        ON a.id < b.id
       AND a.room_id = b.room_id
       AND a.lesson_date = b.lesson_date
    JOIN pair_slots pa ON pa.id = a.pair_slot_id
    JOIN pair_slots pb ON pb.id = b.pair_slot_id
    WHERE a.room_id = 1
      AND a.lesson_date = DATE '2026-12-03'
      AND pa.starts_at < pb.ends_at
      AND pb.starts_at < pa.ends_at
) AS no_conflicts;


-- [cleanup] Удаление тестовых занятий и восстановление времени
DELETE FROM schedule_entries
WHERE lesson_date = DATE '2026-12-03'
  AND room_id = 1
  AND pair_slot_id IN (9, 10);

UPDATE pair_slots
SET starts_at = TIME '20:30',
    ends_at = TIME '21:50'
WHERE pair_number = 10;