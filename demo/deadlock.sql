-- [A] Пользователь A блокирует первую аудиторию
BEGIN;

SELECT id
FROM rooms
WHERE id = 1
FOR UPDATE;


-- [B] Пользователь B блокирует вторую аудиторию
BEGIN;

SELECT id
FROM rooms
WHERE id = 2
FOR UPDATE;


-- [A] Пользователь A пытается заблокировать вторую аудиторию
-- expect: blocked
SELECT id
FROM rooms
WHERE id = 2
FOR UPDATE;


-- [B] Пользователь B пытается заблокировать первую аудиторию
-- expect: error deadlock
SELECT id
FROM rooms
WHERE id = 1
FOR UPDATE;


-- [A] Завершение первой транзакции
COMMIT;


-- [B] Отмена второй транзакции
ROLLBACK;