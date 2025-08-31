-- Практические упражнения для Модуля 1
-- Выполняйте упражнения по мере изучения материала

-- ========================================
-- Упражнения к Теме 1: Теория баз данных
-- ========================================

-- Упражнение 1.1: Анализ ненормализованной таблицы
-- Проанализируйте следующую таблицу и найдите проблемы:

/*
Таблица: orders_bad_design
+----+----------+----------+----------+----------+----------+
| id | customer | products | prices   | address  | phone    |
+----+----------+----------+----------+----------+----------+
| 1  | Иванов   | Хлеб,Молоко,Масло | 30,60,120 | ул.Мира,1| 123-45-67|
| 2  | Петров   | Хлеб,Сыр | 30,200   | ул.Ленина,5| 234-56-78|
+----+----------+----------+----------+----------+----------+

Проблемы:
1. Нарушение 1НФ - в одном поле несколько значений
2. Избыточность данных
3. Сложность обновления
4. Невозможность эффективного поиска
*/

-- Упражнение 1.2: Нормализация таблицы
-- Приведите таблицу выше к 3НФ, создав правильную структуру:

CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(200),
    phone VARCHAR(20)
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(8,2) NOT NULL
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(id),
    order_date DATE DEFAULT CURRENT_DATE
);

CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id),
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER DEFAULT 1,
    price DECIMAL(8,2) NOT NULL
);

-- ========================================
-- Упражнения к Теме 2: Архитектура PostgreSQL
-- ========================================

-- Упражнение 2.1: Исследование системных таблиц
-- Посмотрите информацию о текущей сессии
SELECT 
    current_database(),
    current_user,
    current_timestamp,
    version();

-- Упражнение 2.2: Анализ активности сервера
-- Посмотрите активные подключения
SELECT 
    pid,
    usename,
    application_name,
    client_addr,
    state,
    query_start
FROM pg_stat_activity
WHERE state = 'active';

-- Упражнение 2.3: Информация о базах данных
SELECT 
    datname,
    pg_size_pretty(pg_database_size(datname)) as size
FROM pg_database
ORDER BY pg_database_size(datname) DESC;

-- ========================================
-- Упражнения к Теме 3: Консольный клиент psql
-- ========================================

-- Упражнение 3.1: Работа с метакомандами
-- Выполните следующие команды в psql:

/*
\l                    -- список баз данных
\d                    -- список таблиц
\dt                   -- только таблицы
\dv                   -- представления
\df                   -- функции
\du                   -- пользователи
\timing               -- включить показ времени
\x                    -- расширенный вывод
*/

-- Упражнение 3.2: Создание и использование переменных
-- В psql выполните:
/*
\set mydb 'test_database'
\set myuser 'postgres'
\echo :mydb
\echo :myuser
*/

-- ========================================
-- Упражнения к Теме 4: pgAdmin
-- ========================================

-- Упражнение 4.1: Создание объектов через интерфейс
-- Создайте через pgAdmin:
-- 1. База данных: practice_db
-- 2. Таблица: employees с полями (id, name, position, salary, hire_date)
-- 3. Добавьте 5 записей через интерфейс

-- Упражнение 4.2: Экспорт/импорт данных
-- 1. Экспортируйте созданную таблицу в CSV
-- 2. Создайте новую таблицу employees_backup
-- 3. Импортируйте данные из CSV

-- ========================================
-- Упражнения к Теме 5: Основы SQL
-- ========================================

-- Упражнение 5.1: Создание учебной базы данных
CREATE DATABASE bookstore;
-- Подключитесь к базе: \c bookstore

-- Упражнение 5.2: Создание таблиц с различными типами данных
CREATE TABLE authors (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_date DATE,
    nationality VARCHAR(50),
    biography TEXT,
    is_alive BOOLEAN DEFAULT TRUE
);

CREATE TABLE genres (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT
);

CREATE TABLE books (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    author_id INTEGER REFERENCES authors(id),
    genre_id INTEGER REFERENCES genres(id),
    isbn VARCHAR(13) UNIQUE,
    publication_date DATE,
    pages INTEGER CHECK (pages > 0),
    price DECIMAL(8,2) CHECK (price >= 0),
    in_stock INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    registration_date DATE DEFAULT CURRENT_DATE,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(id),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'pending' 
        CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);

CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id),
    book_id INTEGER REFERENCES books(id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(8,2) NOT NULL,
    total_price DECIMAL(10,2) GENERATED ALWAYS AS (quantity * unit_price) STORED
);

-- Упражнение 5.3: Заполнение таблиц тестовыми данными
INSERT INTO authors (first_name, last_name, birth_date, nationality) VALUES
('Лев', 'Толстой', '1828-09-09', 'Русский'),
('Федор', 'Достоевский', '1821-11-11', 'Русский'),
('Александр', 'Пушкин', '1799-06-06', 'Русский'),
('Антон', 'Чехов', '1860-01-29', 'Русский'),
('Иван', 'Тургенев', '1818-11-09', 'Русский');

INSERT INTO genres (name, description) VALUES
('Роман', 'Большая форма эпической прозы'),
('Повесть', 'Средняя форма эпической прозы'),
('Рассказ', 'Малая форма эпической прозы'),
('Драма', 'Произведения для театральной постановки'),
('Поэзия', 'Стихотворные произведения');

INSERT INTO books (title, author_id, genre_id, isbn, publication_date, pages, price, in_stock) VALUES
('Война и мир', 1, 1, '9785170123456', '1869-01-01', 1300, 850.00, 15),
('Анна Каренина', 1, 1, '9785170123457', '1877-01-01', 900, 750.00, 8),
('Преступление и наказание', 2, 1, '9785170123458', '1866-01-01', 600, 650.00, 12),
('Идиот', 2, 1, '9785170123459', '1869-01-01', 700, 680.00, 6),
('Евгений Онегин', 3, 5, '9785170123460', '1833-01-01', 400, 450.00, 20),
('Капитанская дочка', 3, 2, '9785170123461', '1836-01-01', 300, 380.00, 10),
('Вишневый сад', 4, 4, '9785170123462', '1904-01-01', 200, 320.00, 5),
('Отцы и дети', 5, 1, '9785170123463', '1862-01-01', 350, 420.00, 7);

INSERT INTO customers (first_name, last_name, email, phone, address) VALUES
('Анна', 'Иванова', 'anna.ivanova@email.com', '+7-900-111-1111', 'Москва, ул. Тверская, 1'),
('Петр', 'Петров', 'petr.petrov@email.com', '+7-900-222-2222', 'СПб, Невский пр., 50'),
('Мария', 'Сидорова', 'maria.sidorova@email.com', '+7-900-333-3333', 'Екатеринбург, ул. Ленина, 10'),
('Алексей', 'Козлов', 'alexey.kozlov@email.com', '+7-900-444-4444', 'Новосибирск, ул. Красный пр., 25'),
('Елена', 'Морозова', 'elena.morozova@email.com', '+7-900-555-5555', 'Казань, ул. Баумана, 15');

-- Упражнение 5.4: Базовые SELECT запросы
-- 1. Выберите всех авторов
SELECT * FROM authors;

-- 2. Выберите названия и цены книг
SELECT title, price FROM books;

-- 3. Выберите книги дороже 500 рублей
SELECT title, price FROM books WHERE price > 500;

-- 4. Выберите книги, отсортированные по цене (по убыванию)
SELECT title, price FROM books ORDER BY price DESC;

-- 5. Выберите первые 3 самые дорогие книги
SELECT title, price FROM books ORDER BY price DESC LIMIT 3;

-- 6. Выберите авторов, родившихся в 19 веке
SELECT first_name, last_name, birth_date 
FROM authors 
WHERE birth_date >= '1801-01-01' AND birth_date <= '1900-12-31';

-- 7. Выберите книги с количеством страниц от 300 до 700
SELECT title, pages FROM books WHERE pages BETWEEN 300 AND 700;

-- 8. Найдите книги, в названии которых есть слово "и"
SELECT title FROM books WHERE title ILIKE '%и%';

-- Упражнение 5.5: Запросы с соединениями
-- 1. Выберите книги с именами авторов
SELECT 
    b.title,
    a.first_name || ' ' || a.last_name AS author_name,
    b.price
FROM books b
JOIN authors a ON b.author_id = a.id;

-- 2. Выберите книги с жанрами
SELECT 
    b.title,
    g.name AS genre,
    b.price
FROM books b
JOIN genres g ON b.genre_id = g.id;

-- 3. Полная информация о книгах
SELECT 
    b.title,
    a.first_name || ' ' || a.last_name AS author,
    g.name AS genre,
    b.pages,
    b.price,
    b.in_stock
FROM books b
JOIN authors a ON b.author_id = a.id
JOIN genres g ON b.genre_id = g.id
ORDER BY b.title;

-- Упражнение 5.6: Агрегатные функции
-- 1. Подсчитайте общее количество книг
SELECT COUNT(*) AS total_books FROM books;

-- 2. Найдите среднюю цену книг
SELECT AVG(price) AS average_price FROM books;

-- 3. Найдите самую дорогую и самую дешевую книгу
SELECT 
    MAX(price) AS max_price,
    MIN(price) AS min_price
FROM books;

-- 4. Подсчитайте количество книг каждого автора
SELECT 
    a.first_name || ' ' || a.last_name AS author,
    COUNT(b.id) AS book_count
FROM authors a
LEFT JOIN books b ON a.id = b.author_id
GROUP BY a.id, a.first_name, a.last_name
ORDER BY book_count DESC;

-- 5. Найдите общую стоимость всех книг в наличии
SELECT SUM(price * in_stock) AS total_inventory_value FROM books;

-- Упражнение 5.7: Обновление и удаление данных
-- 1. Увеличьте цены всех книг на 10%
UPDATE books SET price = price * 1.1;

-- 2. Обновите количество в наличии для конкретной книги
UPDATE books SET in_stock = 25 WHERE title = 'Евгений Онегин';

-- 3. Добавьте новый жанр
INSERT INTO genres (name, description) VALUES 
('Фантастика', 'Произведения о будущем и невозможном');

-- 4. Удалите книги, которых нет в наличии
DELETE FROM books WHERE in_stock = 0;

-- Упражнение 5.8: Сложные запросы
-- 1. Найдите автора с наибольшим количеством книг
SELECT 
    a.first_name || ' ' || a.last_name AS author,
    COUNT(b.id) AS book_count
FROM authors a
JOIN books b ON a.id = b.author_id
GROUP BY a.id, a.first_name, a.last_name
ORDER BY book_count DESC
LIMIT 1;

-- 2. Найдите жанры, в которых нет книг
SELECT g.name 
FROM genres g
LEFT JOIN books b ON g.id = b.genre_id
WHERE b.id IS NULL;

-- 3. Найдите среднюю цену книг каждого жанра
SELECT 
    g.name AS genre,
    AVG(b.price) AS average_price,
    COUNT(b.id) AS book_count
FROM genres g
LEFT JOIN books b ON g.id = b.genre_id
GROUP BY g.id, g.name
HAVING COUNT(b.id) > 0
ORDER BY average_price DESC;

-- ========================================
-- Дополнительные упражнения
-- ========================================

-- Упражнение 6.1: Работа с датами
-- 1. Найдите возраст каждого автора (для живых)
SELECT 
    first_name || ' ' || last_name AS author,
    birth_date,
    EXTRACT(YEAR FROM AGE(birth_date)) AS age
FROM authors
WHERE is_alive = TRUE;

-- 2. Найдите книги, опубликованные в 19 веке
SELECT title, publication_date
FROM books
WHERE EXTRACT(YEAR FROM publication_date) BETWEEN 1801 AND 1900;

-- Упражнение 6.2: Условные выражения
-- 1. Классифицируйте книги по цене
SELECT 
    title,
    price,
    CASE 
        WHEN price < 400 THEN 'Дешевая'
        WHEN price BETWEEN 400 AND 600 THEN 'Средняя'
        ELSE 'Дорогая'
    END AS price_category
FROM books;

-- 2. Определите статус наличия
SELECT 
    title,
    in_stock,
    CASE 
        WHEN in_stock = 0 THEN 'Нет в наличии'
        WHEN in_stock < 5 THEN 'Мало'
        WHEN in_stock < 15 THEN 'Достаточно'
        ELSE 'Много'
    END AS stock_status
FROM books;

-- ========================================
-- КОНЕЦ УПРАЖНЕНИЙ
-- ========================================