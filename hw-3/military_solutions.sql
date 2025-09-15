-- Решения SQL заданий для базы данных военных изделий (PostgreSQL 16)

-- SQL-функции (1-3)

-- 1. Функция для расчета объема изделия по его размерам
CREATE OR REPLACE FUNCTION calculate_volume(
    IN dim dimension,
    OUT volume_m3 NUMERIC,
    OUT volume_cm3 NUMERIC
) AS $$
    SELECT 
        ROUND((dim.length_mm * dim.width_mm * dim.height_mm)::NUMERIC / 1000000000, 3),
        ROUND((dim.length_mm * dim.width_mm * dim.height_mm)::NUMERIC / 1000, 3);
$$ LANGUAGE SQL;

-- Пример вызова:
-- SELECT * FROM calculate_volume(ROW(1000, 500, 200));

-- 2. Функция для определения возраста производителя
CREATE OR REPLACE FUNCTION get_manufacturer_age(
    IN manufacturer_id INTEGER,
    OUT age_years INTEGER,
    OUT founded_year INTEGER,
    OUT company_name VARCHAR
) AS $$
    SELECT 
        EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER - founded_year,
        founded_year,
        name::VARCHAR
    FROM manufacturers 
    WHERE id = manufacturer_id;
$$ LANGUAGE SQL;

-- Пример вызова:
-- SELECT * FROM get_manufacturer_age(1);

-- 3. Функция для подсчета количества испытаний по типу
CREATE OR REPLACE FUNCTION count_tests_by_type(
    IN test_type_param VARCHAR,
    OUT total_tests INTEGER,
    OUT passed_tests INTEGER,
    OUT failed_tests INTEGER,
    OUT success_rate NUMERIC,
    OUT failure_rate NUMERIC,
    OUT avg_test_date DATE,
    OUT products_tested INTEGER
) AS $$
    SELECT 
        COUNT(*)::INTEGER,
        COUNT(*) FILTER (WHERE passed = true)::INTEGER,
        COUNT(*) FILTER (WHERE passed = false)::INTEGER,
        ROUND(COUNT(*) FILTER (WHERE passed = true) * 100.0 / COUNT(*), 3),
        ROUND(COUNT(*) FILTER (WHERE passed = false) * 100.0 / COUNT(*), 3),
        (MIN(test_date) + (MAX(test_date) - MIN(test_date)) / 2)::DATE,
        COUNT(DISTINCT product_id)::INTEGER
    FROM tests 
    WHERE test_type = test_type_param;
$$ LANGUAGE SQL;

-- Пример вызова:
-- SELECT * FROM count_tests_by_type('Полигонные испытания');

-- SQL-функции с RETURNS TABLE (4-6)

-- 4. Функция, возвращающая таблицу изделий по категории
CREATE OR REPLACE FUNCTION get_products_by_category(
    IN category_name VARCHAR
)
RETURNS TABLE(product_name VARCHAR, model VARCHAR, weight_kg NUMERIC, search_count INTEGER) AS $$
    SELECT 
        mp.name::VARCHAR, 
        mp.model::VARCHAR, 
        mp.weight_kg,
        COUNT(*) OVER()::INTEGER
    FROM military_products mp
    JOIN categories c ON mp.category_id = c.id
    WHERE c.name = category_name;
$$ LANGUAGE SQL;

-- Пример вызова:
-- SELECT * FROM get_products_by_category('Стрелковое оружие');

-- 5. Функция для получения статистики испытаний по изделию
CREATE OR REPLACE FUNCTION get_product_test_stats(
    IN product_id INTEGER,
    OUT total_tests INTEGER,
    OUT passed_tests INTEGER, 
    OUT success_rate NUMERIC,
    OUT product_name VARCHAR
) AS $$
    SELECT 
        COUNT(*)::INTEGER,
        COUNT(*) FILTER (WHERE passed = true)::INTEGER,
        ROUND(COUNT(*) FILTER (WHERE passed = true) * 100.0 / COUNT(*), 3),
        MAX(mp.name)::VARCHAR
    FROM tests t
    JOIN military_products mp ON t.product_id = mp.id
    WHERE t.product_id = get_product_test_stats.product_id;
$$ LANGUAGE SQL;

-- Пример вызова:
-- SELECT * FROM get_product_test_stats(1);

-- 6. Функция для поиска изделий в диапазоне веса
CREATE OR REPLACE FUNCTION get_products_by_weight_range(
    IN min_weight NUMERIC,
    IN max_weight NUMERIC
)
RETURNS TABLE(name VARCHAR, weight_kg NUMERIC, category_name VARCHAR, corrected_min NUMERIC, corrected_max NUMERIC) AS $$
    SELECT 
        mp.name::VARCHAR, 
        mp.weight_kg, 
        c.name::VARCHAR,
        CASE WHEN min_weight > max_weight THEN max_weight ELSE min_weight END,
        CASE WHEN min_weight > max_weight THEN min_weight ELSE max_weight END
    FROM military_products mp
    JOIN categories c ON mp.category_id = c.id
    WHERE mp.weight_kg BETWEEN 
        CASE WHEN min_weight > max_weight THEN max_weight ELSE min_weight END AND
        CASE WHEN min_weight > max_weight THEN min_weight ELSE max_weight END;
$$ LANGUAGE SQL;

-- Пример вызова:
-- SELECT * FROM get_products_by_weight_range(1000, 100);

-- SQL-процедуры (7-9)

-- 7. Процедура и функция для добавления нового испытания
CREATE OR REPLACE FUNCTION add_test(
    IN product_id INTEGER,
    IN test_type VARCHAR,
    IN test_date DATE
)
RETURNS TABLE(test_id INTEGER, product_id INTEGER, test_type VARCHAR, test_date DATE) AS $$
    INSERT INTO tests (product_id, test_type, test_date, test_location, conditions, results, participants)
    VALUES (product_id, test_type, test_date, ROW(0, 0), '{}', '{}', ARRAY[]::TEXT[])
    RETURNING id, add_test.product_id, add_test.test_type, add_test.test_date;
$$ LANGUAGE SQL;


CREATE OR REPLACE PROCEDURE pro_add_test(
    IN product_id INTEGER,
    IN test_type VARCHAR,
    IN test_date DATE,
    OUT test_id INTEGER,
    OUT message TEXT
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO tests (product_id, test_type, test_date, test_location, conditions, results, participants)
    VALUES (product_id, test_type, test_date, ROW(0, 0), '{}', '{}', ARRAY[]::TEXT[])
    RETURNING id INTO test_id;
    
    message := 'Испытание успешно добавлено. ID: ' || test_id;
END;
$$;

-- Пример вызова:
-- CALL add_test(1, 'Новое испытание', '2024-01-01', NULL, NULL);

-- 8. Процедура для обновления статуса изделия
CREATE OR REPLACE PROCEDURE update_product_status(
    IN product_id INTEGER,
    IN new_status VARCHAR
)
LANGUAGE SQL AS $$
    UPDATE military_products 
    SET status = new_status 
    WHERE id = product_id
    RETURNING id, name, status;
$$;

-- Пример вызова:
-- CALL update_product_status(1, 'inactive');

-- 9. Процедура для архивации старых испытаний
CREATE OR REPLACE PROCEDURE archive_old_tests(
    IN cutoff_date DATE
)
LANGUAGE SQL AS $$
    UPDATE tests 
    SET test_type = 'АРХИВНЫЙ - ' || test_type 
    WHERE test_date < cutoff_date
    RETURNING id, test_type, test_date;
$$;

-- Пример вызова:
-- CALL archive_old_tests('2023-01-01');


-- Работа с JSON и JSONB (11-12)


-- 10.  Найти все изделия с определенным калибром в характеристиках


SELECT name, model, characteristics
FROM military_products
WHERE characteristics->>'калибр' = '5.45x39';



-- 11. Найти все изделия с калибром больше 6 в характеристиках
SELECT name, model, characteristics->>'калибр' AS caliber
FROM military_products
WHERE CAST(SPLIT_PART(characteristics->>'калибр', 'x', 1) AS NUMERIC) > 6;


-- 12. Обновить техническую характеристику в JSONB поле
UPDATE military_products 
SET technical_specs = technical_specs || '{"часы_обслуживания": 100}'
WHERE category_id = (SELECT id FROM categories WHERE name = 'Стрелковое оружие');

-- Window функции (13)

-- 13. Ранжировать изделия по весу внутри каждой категории
SELECT 
    mp.name,
    c.name AS category,
    mp.weight_kg,
    ROW_NUMBER() OVER (PARTITION BY c.name ORDER BY mp.weight_kg) AS row_num,
    RANK() OVER (PARTITION BY c.name ORDER BY mp.weight_kg) AS rank_num,
    DENSE_RANK() OVER (PARTITION BY c.name ORDER BY mp.weight_kg) AS dense_rank_num
FROM military_products mp
JOIN categories c ON mp.category_id = c.id
ORDER BY c.name, mp.weight_kg;

-- GROUPING SETS, CUBE и ROLLUP (14-15)

-- 14. Отчет по количеству изделий с использованием ROLLUP
SELECT 
    m.country,
    c.name AS category,
    COUNT(mp.id) AS product_count,
    GROUPING(m.country) AS country_grouping,
    GROUPING(c.name) AS category_grouping
FROM military_products mp
JOIN manufacturers m ON mp.manufacturer_id = m.id
JOIN categories c ON mp.category_id = c.id
GROUP BY ROLLUP(m.country, c.name)
ORDER BY m.country NULLS LAST, c.name NULLS LAST;

-- 15. Сводный отчет по испытаниям с использованием CUBE
SELECT 
    test_type,
    passed,
    COUNT(*) AS test_count,
    GROUPING(test_type) AS type_grouping,
    GROUPING(passed) AS passed_grouping
FROM tests
GROUP BY CUBE(test_type, passed)
ORDER BY test_type NULLS LAST, passed NULLS LAST;