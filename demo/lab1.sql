-- 1. Аудитория уже занята в это время
-- expect: error unique
INSERT INTO schedule_entries
(group_id, discipline_id, teacher_id, room_id, pair_slot_id, lesson_date)
VALUES
(2, 2, 3, 1, 1, '2026-10-12');

-- 2. Недопустимый номер курса
-- expect: error check
INSERT INTO student_groups (name, course)
VALUES ('Б9999-09.03.03', 8);

-- 3. Несуществующий преподаватель
-- expect: error fk
INSERT INTO schedule_entries
(group_id, discipline_id, teacher_id, room_id, pair_slot_id, lesson_date)
VALUES
(1, 1, 999, 10, 6, '2026-10-16');