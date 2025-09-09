-- Решения SQL заданий для базы данных трансферных маршрутов

-- СРЕДНИЙ УРОВЕНЬ (1-10)

-- 1. Найти все маршруты из Москвы с указанием названий городов назначения
SELECT r.id, c1.name AS from_city, c2.name AS to_city, r.distance_km, r.price
FROM routes r
JOIN cities c1 ON r.from_city_id = c1.id
JOIN cities c2 ON r.to_city_id = c2.id
WHERE c1.name = 'Москва';

-- 2. Показать топ-3 самых дорогих маршрута с названиями городов
SELECT c1.name AS from_city, c2.name AS to_city, r.price
FROM routes r
JOIN cities c1 ON r.from_city_id = c1.id
JOIN cities c2 ON r.to_city_id = c2.id
ORDER BY r.price DESC
LIMIT 3;

-- 3. Найти все трансферы на завтра с информацией о маршруте и транспорте
SELECT t.id, c1.name AS from_city, c2.name AS to_city, 
       v.type, v.license_plate, t.departure_time, t.available_seats
FROM transfers t
JOIN routes r ON t.route_id = r.id
JOIN cities c1 ON r.from_city_id = c1.id
JOIN cities c2 ON r.to_city_id = c2.id
JOIN vehicles v ON t.vehicle_id = v.id
WHERE DATE(t.departure_time) = CURRENT_DATE + INTERVAL '1 day';

-- 4. Подсчитать общее количество доступных мест по каждому типу транспорта
SELECT v.type, SUM(t.available_seats) AS total_available_seats
FROM transfers t
JOIN vehicles v ON t.vehicle_id = v.id
WHERE t.status = 'active'
GROUP BY v.type;

-- 5. Найти города, в которые нет прямых маршрутов из Москвы
SELECT c.name
FROM cities c
WHERE c.id NOT IN (
    SELECT r.to_city_id
    FROM routes r
    JOIN cities c1 ON r.from_city_id = c1.id
    WHERE c1.name = 'Москва'
) AND c.name != 'Москва';

-- 6. Показать среднюю стоимость маршрута по каждому городу отправления
SELECT c.name AS from_city, AVG(r.price) AS avg_price
FROM routes r
JOIN cities c ON r.from_city_id = c.id
GROUP BY c.name;

-- 7. Найти все маршруты длительностью более 8 часов
SELECT c1.name AS from_city, c2.name AS to_city, 
       r.duration_minutes, r.duration_minutes/60.0 AS hours
FROM routes r
JOIN cities c1 ON r.from_city_id = c1.id
JOIN cities c2 ON r.to_city_id = c2.id
WHERE r.duration_minutes > 480;

-- 8. Показать загруженность каждого транспортного средства (занятые места)
SELECT v.license_plate, v.type, v.capacity,
       CONCAT(c1.name, ' - ', c2.name) AS route_name,
       v.capacity - t.available_seats AS occupied_seats,
       ROUND((v.capacity - t.available_seats) * 100.0 / v.capacity, 2) AS occupancy_percent
FROM transfers t
JOIN vehicles v ON t.vehicle_id = v.id
JOIN routes r ON t.route_id = r.id
JOIN cities c1 ON r.from_city_id = c1.id
JOIN cities c2 ON r.to_city_id = c2.id
WHERE t.status = 'active';

-- 9. Найти ТОП-3 маршруты с самой высокой стоимостью за километр
SELECT c1.name AS from_city, c2.name AS to_city,
       r.price, r.distance_km,
       ROUND(r.price / r.distance_km, 2) AS price_per_km
FROM routes r
JOIN cities c1 ON r.from_city_id = c1.id
JOIN cities c2 ON r.to_city_id = c2.id
ORDER BY price_per_km DESC;

-- 10. Показать все трансферы, отправляющиеся в ближайшие 36 часов
SELECT t.id, c1.name AS from_city, c2.name AS to_city,
       t.departure_time, v.type, t.available_seats
FROM transfers t
JOIN routes r ON t.route_id = r.id
JOIN cities c1 ON r.from_city_id = c1.id
JOIN cities c2 ON r.to_city_id = c2.id
JOIN vehicles v ON t.vehicle_id = v.id
WHERE t.departure_time BETWEEN NOW() AND NOW() + INTERVAL '24 hours'
  AND t.status = 'active';

-- СЛОЖНЫЙ УРОВЕНЬ (11-20)

-- 11. Найти кратчайший путь между двумя городами через промежуточные остановки
WITH RECURSIVE route_paths AS (
    -- Прямые маршруты
    SELECT r.from_city_id, r.to_city_id, r.distance_km, 
           ARRAY[r.from_city_id, r.to_city_id] AS path, 1 AS hops
    FROM routes r
    
    UNION ALL
    
    -- Маршруты с пересадками
    SELECT rp.from_city_id, r.to_city_id, 
           rp.distance_km + r.distance_km,
           rp.path || r.to_city_id, rp.hops + 1
    FROM route_paths rp
    JOIN routes r ON rp.to_city_id = r.from_city_id
    WHERE r.to_city_id != ALL(rp.path) AND rp.hops < 3
)
SELECT c1.name AS from_city, c2.name AS to_city, 
       rp.distance_km, rp.hops,
       ARRAY_TO_STRING(ARRAY(
           SELECT cities.name 
           FROM unnest(rp.path) AS city_id 
           JOIN cities ON cities.id = city_id
       ), ' -> ') AS route_path
FROM route_paths rp
JOIN cities c1 ON rp.from_city_id = c1.id
JOIN cities c2 ON rp.to_city_id = c2.id
WHERE c1.name = 'Москва' AND c2.name = 'Екатеринбург'
ORDER BY rp.distance_km
LIMIT 3;


-- 11a. Простая PL/pgSQL функция поиска пути
CREATE OR REPLACE FUNCTION find_path(start_city TEXT, end_city TEXT)
RETURNS TABLE(distance INTEGER, path TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE paths AS (
        SELECT r.to_city_id, r.distance_km, c.name AS route
        FROM routes r
        JOIN cities c ON r.from_city_id = c.id
        WHERE c.name = start_city
        
        UNION ALL
        
        SELECT r.to_city_id, p.distance_km + r.distance_km, p.route || ' -> ' || c.name
        FROM paths p
        JOIN routes r ON p.to_city_id = r.from_city_id
        JOIN cities c ON r.to_city_id = c.id
        WHERE p.route NOT LIKE '%' || c.name || '%'
    )
    SELECT p.distance_km, p.route || ' -> ' || c.name
    FROM paths p
    JOIN cities c ON p.to_city_id = c.id
    WHERE c.name = end_city
    ORDER BY p.distance_km
    LIMIT 1;
END;
$$;

-- Использование
SELECT * FROM find_path('Москва', 'Екатеринбург');

-- 11b. SQL версия функции поиска кратчайшего пути
-- Параметры: start_city - город отправления, end_city - город назначения
-- Возвращает: расстояние и путь кратчайшего маршрута
CREATE OR REPLACE FUNCTION find_path_sql(start_city TEXT, end_city TEXT)
RETURNS TABLE(distance INTEGER, path TEXT)
LANGUAGE sql
AS $$
    WITH RECURSIVE paths AS (
        -- Базовый случай: начинаем с прямых маршрутов из стартового города
        SELECT 
            r.to_city_id,                    -- ID города назначения
            r.distance_km,                   -- Расстояние от старта
            c.name::TEXT AS route            -- Начальный путь (только стартовый город)
        FROM routes r
        JOIN cities c ON r.from_city_id = c.id
        WHERE c.name = start_city            -- Фильтруем по стартовому городу
        
        UNION ALL
        
        -- Рекурсивный случай: добавляем следующие сегменты маршрута
        SELECT 
            r.to_city_id,                                        -- Новый город назначения
            p.distance_km + r.distance_km,                      -- Общее расстояние (предыдущее + текущее)
            (p.route || ' -> ' || c.name)::TEXT                  -- Полный путь (старый + новый город)
        FROM paths p                                             -- Используем результаты предыдущей итерации
        JOIN routes r ON p.to_city_id = r.from_city_id           -- Находим маршруты из текущего города
        JOIN cities c ON r.to_city_id = c.id                    -- Получаем название следующего города
        WHERE p.route NOT LIKE '%' || c.name || '%'             -- Избегаем циклов (не возвращаемся в уже посещенные города)
    )
    -- Финальный запрос: находим пути до целевого города
    SELECT 
        p.distance_km,                                       -- Общее расстояние
        (p.route || ' -> ' || c.name)::TEXT                  -- Полный путь с конечным городом
    FROM paths p
    JOIN cities c ON p.to_city_id = c.id                    -- Получаем название конечного города
    WHERE c.name = end_city                                  -- Фильтруем по целевому городу
    ORDER BY p.distance_km                                   -- Сортируем по расстоянию (кратчайший первым)
    LIMIT 1;                                                 -- Возвращаем только кратчайший маршрут
$$;

-- Использование SQL версии
SELECT * FROM find_path_sql('Москва', 'Екатеринбург');


CREATE OR REPLACE FUNCTION find_path_sql(start_city TEXT, end_city TEXT)
RETURNS TABLE(distance INTEGER, path TEXT)
LANGUAGE sql
AS $$
    -- 1. Сначала выполняется рекурсивный CTE (Common Table Expression) paths
    WITH RECURSIVE paths AS (
        -- 2. Базовый запрос (нерекурсивная часть) - получаем начальную точку
        SELECT 
            r.to_city_id,           -- ID города назначения
            r.distance_km,          -- Дистанция до следующего города
            c.name::TEXT AS route   -- Начинаем формировать маршрут
        FROM routes r
        JOIN cities c ON r.from_city_id = c.id
        WHERE c.name = start_city   -- Ищем маршруты из начального города
        
        UNION ALL  -- Объединяем результаты рекурсивных итераций
        
        -- 3. Рекурсивная часть - на каждой итерации расширяем пути
        SELECT 
            r.to_city_id,                       -- ID следующего города
            p.distance_km + r.distance_km,      -- Суммируем дистанцию
            (p.route || ' -> ' || c.name)::TEXT -- Добавляем город к маршруту
        FROM paths p
        JOIN routes r ON p.to_city_id = r.from_city_id  -- Ищем маршруты из текущего города
        JOIN cities c ON r.to_city_id = c.id            -- Получаем название следующего города
        -- 4. Условие остановки: предотвращаем зацикливание
        WHERE p.route NOT LIKE '%' || c.name || '%'     -- Исключаем города, уже посещенные в маршруте
    )
    -- 5. После завершения рекурсии выбираем результат
    SELECT 
        p.distance_km,                      -- Итоговая дистанция
        (p.route || ' -> ' || c.name)::TEXT -- Завершаем маршрут конечным городом
    FROM paths p
    JOIN cities c ON p.to_city_id = c.id    -- Связываем с конечным городом
    WHERE c.name = end_city                 -- Фильтруем только нужный конечный город
    ORDER BY p.distance_km                  -- Сортируем по дистанции (кратчайший путь)
    LIMIT 1;                                -- Берем только самый короткий маршрут
$$;


-- **Пошаговый порядок выполнения:**

-- 1. **Инициализация**: Выполняется базовый запрос - находятся все маршруты из начального города
-- 2. **Рекурсивные итерации**: Для каждого найденного пути ищутся продолжения маршрута
-- 3. **Проверка циклов**: На каждой итерации исключаются города, уже посещенные в текущем маршруте
-- 4. **Завершение рекурсии**: Когда не остается новых допустимых путей для расширения
-- 5. **Финальный отбор**: Из всех найденных путей выбирается кратчайший до конечного города

-- **Особенности работы:**
-- - Функция находит ВСЕ возможные пути без циклов между городами
-- - Возвращает только самый короткий маршрут
-- - Использует рекурсивный SQL для обхода графа маршрутов
-- - Предотвращает зацикливание через проверку уже пройденных городов



-- 11c. Простой вариант без функции - прямой CTE запрос

WITH RECURSIVE paths AS (
    -- Начинаем с Москвы
    SELECT r.to_city_id, r.distance_km, c.name::TEXT AS route
    FROM routes r
    JOIN cities c ON r.from_city_id = c.id
    WHERE c.name = 'Москва'
    
    UNION ALL
    
    -- Добавляем следующие города
    SELECT r.to_city_id, p.distance_km + r.distance_km, (p.route || ' -> ' || c.name)::TEXT
    FROM paths p
    JOIN routes r ON p.to_city_id = r.from_city_id
    JOIN cities c ON r.to_city_id = c.id
    WHERE p.route NOT LIKE '%' || c.name || '%'
)
SELECT p.distance_km, (p.route || ' -> ' || c.name)::TEXT AS full_path
FROM paths p
JOIN cities c ON p.to_city_id = c.id
WHERE c.name = 'Екатеринбург'
ORDER BY p.distance_km
LIMIT 1;


-- ПОСЛЕДОВАТЕЛЬНОСТЬ ВЫПОЛНЕНИЯ:
WITH RECURSIVE paths AS (
    -- ШАГ 1: Базовый случай - находим все прямые маршруты из Москвы
    -- Результат: Москва -> СПб, Москва -> Казань, и т.д.
    SELECT r.to_city_id, r.distance_km, c.name::TEXT AS route
    FROM routes r
    JOIN cities c ON r.from_city_id = c.id
    WHERE c.name = 'Москва'
    
    UNION ALL
    
    -- ШАГ 2,3,4...: Рекурсивные итерации - для каждого найденного пути
    -- ищем следующие возможные маршруты
    -- Пример: Москва -> СПб -> Новгород, Москва -> Казань -> Пермь
    SELECT r.to_city_id, p.distance_km + r.distance_km, (p.route || ' -> ' || c.name)::TEXT
    FROM paths p                                    -- Берем результаты предыдущей итерации
    JOIN routes r ON p.to_city_id = r.from_city_id  -- Находим маршруты из конечного города
    JOIN cities c ON r.to_city_id = c.id            -- Получаем название нового города
    WHERE p.route NOT LIKE '%' || c.name || '%'     -- Проверяем: не были ли мы уже в этом городе
)
-- ШАГ ФИНАЛ: Из всех найденных путей выбираем только те,
-- которые заканчиваются в Екатеринбурге, и берем кратчайший
SELECT p.distance_km, (p.route || ' -> ' || c.name)::TEXT AS full_path
FROM paths p
JOIN cities c ON p.to_city_id = c.id
WHERE c.name = 'Екатеринбург'        -- Фильтруем по целевому городу
ORDER BY p.distance_km                              -- Сортируем по расстоянию
LIMIT 1;                                            -- Возвращаем только кратчайший

-- 12. Показать города с наибольшим количеством входящих и исходящих маршрутов
SELECT c.name, 
       COUNT(r1.id) AS outgoing_routes,
       COUNT(r2.id) AS incoming_routes,
       COUNT(r1.id) + COUNT(r2.id) AS total_routes
FROM cities c
LEFT JOIN routes r1 ON c.id = r1.from_city_id
LEFT JOIN routes r2 ON c.id = r2.to_city_id
GROUP BY c.id, c.name
ORDER BY total_routes DESC;



-- 13. Найти все возможные маршруты из Москвы в Екатеринбург с одной пересадкой
SELECT c1.name AS from_city, c2.name AS via_city, c3.name AS to_city,
       r1.distance_km + r2.distance_km AS total_distance,
       r1.price + r2.price AS total_price
FROM routes r1
JOIN routes r2 ON r1.to_city_id = r2.from_city_id
JOIN cities c1 ON r1.from_city_id = c1.id
JOIN cities c2 ON r1.to_city_id = c2.id
JOIN cities c3 ON r2.to_city_id = c3.id
WHERE c1.name = 'Москва' AND c3.name = 'Екатеринбург';

-- 14. Рассчитать среднюю заполненность транспорта по дням недели
SELECT EXTRACT(DOW FROM t.departure_time) AS day_of_week,
       TO_CHAR(t.departure_time, 'Day') AS day_name,
       AVG((v.capacity - t.available_seats) * 100.0 / v.capacity) AS avg_occupancy_percent
FROM transfers t
JOIN vehicles v ON t.vehicle_id = v.id
GROUP BY EXTRACT(DOW FROM t.departure_time), TO_CHAR(t.departure_time, 'Day')
ORDER BY day_of_week;

-- 15. Найти транспорт, который используется наиболее эффективно (высокая заполненность)
SELECT v.license_plate, v.type, v.capacity,
       AVG((v.capacity - t.available_seats) * 100.0 / v.capacity) AS avg_occupancy_percent
FROM vehicles v
JOIN transfers t ON v.id = t.vehicle_id
WHERE t.status = 'active'
GROUP BY v.id, v.license_plate, v.type, v.capacity
ORDER BY avg_occupancy_percent DESC;

-- 16. Показать топ-3 самых популярных направлений по количеству трансферов
SELECT c1.name AS from_city, c2.name AS to_city, COUNT(t.id) AS transfer_count
FROM transfers t
JOIN routes r ON t.route_id = r.id
JOIN cities c1 ON r.from_city_id = c1.id
JOIN cities c2 ON r.to_city_id = c2.id
GROUP BY r.id, c1.name, c2.name
ORDER BY transfer_count DESC
LIMIT 5;

-- 17. Найти города-хабы (через которые проходит больше всего маршрутов)
SELECT c.name, 
       COUNT(DISTINCT r1.id) + COUNT(DISTINCT r2.id) AS total_routes
FROM cities c
LEFT JOIN routes r1 ON c.id = r1.from_city_id
LEFT JOIN routes r2 ON c.id = r2.to_city_id
GROUP BY c.id, c.name
ORDER BY total_routes DESC;

-- 18. Рассчитать потенциальную выручку по каждому маршруту при полной загрузке
SELECT c1.name AS from_city, c2.name AS to_city,
       r.price AS price_per_person,
       ROUND(AVG(v.capacity), 2) AS avg_capacity,
       ROUND(r.price * AVG(v.capacity), 2) AS potential_revenue
FROM routes r
JOIN cities c1 ON r.from_city_id = c1.id
JOIN cities c2 ON r.to_city_id = c2.id
JOIN transfers t ON r.id = t.route_id
JOIN vehicles v ON t.vehicle_id = v.id
GROUP BY r.id, c1.name, c2.name, r.price
ORDER BY potential_revenue DESC;

-- 19. Найти оптимальные маршруты по соотношению цена/время для каждой пары городов
SELECT c1.name AS from_city, c2.name AS to_city,
       r.price, r.duration_minutes,
       ROUND(r.price / (r.duration_minutes / 60.0), 2) AS price_per_hour
FROM routes r
JOIN cities c1 ON r.from_city_id = c1.id
JOIN cities c2 ON r.to_city_id = c2.id
ORDER BY price_per_hour;

-- 20. Создать отчет по загруженности маршрутов с группировкой по месяцам
SELECT EXTRACT(YEAR FROM t.departure_time) AS year,
       TO_CHAR(t.departure_time, 'Month') AS month_name,
       c1.name AS from_city, c2.name AS to_city,
       COUNT(t.id) AS transfers_count,
       ROUND(AVG((v.capacity - t.available_seats) * 100.0 / v.capacity), 2) AS avg_occupancy
FROM transfers t
JOIN routes r ON t.route_id = r.id
JOIN cities c1 ON r.from_city_id = c1.id
JOIN cities c2 ON r.to_city_id = c2.id
JOIN vehicles v ON t.vehicle_id = v.id
GROUP BY EXTRACT(YEAR FROM t.departure_time), EXTRACT(MONTH FROM t.departure_time),
         TO_CHAR(t.departure_time, 'Month'), r.id, c1.name, c2.name
ORDER BY year, EXTRACT(MONTH FROM t.departure_time), transfers_count DESC;


-- 21 Создать материализованное представление для отображения актуальных маршрутов
CREATE MATERIALIZED VIEW active_routes AS
SELECT t.id AS transfer_id,
       c1.name AS from_city, c2.name AS to_city,
       t.departure_time, v.type AS vehicle_type,
       v.license_plate, t.available_seats,
       r.price, r.duration_minutes
FROM transfers t
JOIN routes r ON t.route_id = r.id
JOIN cities c1 ON r.from_city_id = c1.id
JOIN cities c2 ON r.to_city_id = c2.id
JOIN vehicles v ON t.vehicle_id = v.id
WHERE t.status = 'active' AND t.departure_time > NOW();

-- Как использовать материализованное представление:

-- 1. Запрос данных (как обычную таблицу)
SELECT * FROM active_routes;

-- 2. Обновление данных в представлении
REFRESH MATERIALIZED VIEW active_routes;

-- 3. Обновление с блокировкой (без блокировки чтения)
REFRESH MATERIALIZED VIEW CONCURRENTLY active_routes;

-- 4. Удаление представления
-- DROP MATERIALIZED VIEW active_routes;