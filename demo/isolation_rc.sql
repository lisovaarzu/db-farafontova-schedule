-- [setup] Начальная вместимость аудитории
UPDATE rooms
SET capacity = 30
WHERE building = 'A'
  AND room_number = '101';


-- [A] Первое чтение на уровне READ COMMITTED
-- expect: value 30
BEGIN ISOLATION LEVEL READ COMMITTED;

SELECT capacity
FROM rooms
WHERE building = 'A'
  AND room_number = '101';


-- [B] Другой пользователь изменяет вместимость
BEGIN;

UPDATE rooms
SET capacity = 35
WHERE building = 'A'
  AND room_number = '101';

COMMIT;


-- [A] Повторное чтение той же аудитории
-- expect: value 35
SELECT capacity
FROM rooms
WHERE building = 'A'
  AND room_number = '101';

COMMIT;


-- [cleanup] Восстановление исходной вместимости
UPDATE rooms
SET capacity = 30
WHERE building = 'A'
  AND room_number = '101';