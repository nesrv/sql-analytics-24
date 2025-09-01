-- Домашнее задание по Модулю 1
-- Выполните все задания по порядку

-- ========================================
-- Задание 1: Создание базы данных
-- ========================================

-- 1.1 Создайте базу данных course_management
CREATE DATABASE course_management;

-- 1.2 Подключитесь к созданной базе данных
\c course_management;

-- ========================================
-- Задание 2: Создание таблиц
-- ========================================

-- 2.1 Создайте таблицу instructors (преподаватели)
CREATE TABLE instructors (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    hire_date DATE DEFAULT CURRENT_DATE,
    salary DECIMAL(10,2)
);

-- 2.2 Создайте таблицу courses (курсы)
CREATE TABLE courses (
    id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    duration_hours INTEGER NOT NULL,
    price DECIMAL(8,2) NOT NULL,
    instructor_id INTEGER REFERENCES instructors(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2.3 Создайте таблицу students (студенты)
CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    birth_date DATE,
    registration_date DATE DEFAULT CURRENT_DATE
);

-- 2.4 Создайте таблицу enrollments (записи на курсы)
CREATE TABLE enrollments (
    id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES students(id),
    course_id INTEGER REFERENCES courses(id),
    enrollment_date DATE DEFAULT CURRENT_DATE,
    completion_date DATE,
    grade INTEGER CHECK (grade >= 1 AND grade <= 5),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'dropped'))
);

-- ========================================
-- Задание 3: Заполнение таблиц данными
-- ========================================

-- 3.1 Добавьте преподавателей
INSERT INTO instructors (first_name, last_name, email, phone, salary) VALUES
('Иван', 'Петров', 'ivan.petrov@email.com', '+7-900-123-4567', 80000.00),
('Мария', 'Сидорова', 'maria.sidorova@email.com', '+7-900-234-5678', 75000.00),
('Алексей', 'Козлов', 'alexey.kozlov@email.com', '+7-900-345-6789', 90000.00),
('Елена', 'Морозова', 'elena.morozova@email.com', '+7-900-456-7890', 85000.00);

-- 3.2 Добавьте курсы
INSERT INTO courses (title, description, duration_hours, price, instructor_id) VALUES
('Основы SQL', 'Изучение основ языка SQL и работы с базами данных', 40, 25000.00, 1),
('Python для начинающих', 'Введение в программирование на Python', 60, 35000.00, 2),
('Веб-разработка', 'HTML, CSS, JavaScript для создания веб-сайтов', 80, 45000.00, 3),
('Анализ данных', 'Анализ данных с помощью Python и SQL', 50, 40000.00, 4),
('Машинное обучение', 'Основы машинного обучения и нейронных сетей', 70, 55000.00, 2);

-- 3.3 Добавьте студентов
INSERT INTO students (first_name, last_name, email, phone, birth_date) VALUES
('Анна', 'Иванова', 'anna.ivanova@email.com', '+7-911-111-1111', '1995-03-15'),
('Петр', 'Смирнов', 'petr.smirnov@email.com', '+7-911-222-2222', '1992-07-22'),
('Ольга', 'Кузнецова', 'olga.kuznetsova@email.com', '+7-911-333-3333', '1998-11-08'),
('Дмитрий', 'Волков', 'dmitry.volkov@email.com', '+7-911-444-4444', '1990-01-30'),
('Светлана', 'Попова', 'svetlana.popova@email.com', '+7-911-555-5555', '1996-09-12'),
('Михаил', 'Лебедев', 'mikhail.lebedev@email.com', '+7-911-666-6666', '1993-05-18'),
('Татьяна', 'Новикова', 'tatyana.novikova@email.com', '+7-911-777-7777', '1997-12-03');

-- 3.4 Добавьте записи на курсы
INSERT INTO enrollments (student_id, course_id, grade, status) VALUES
(1, 1, 5, 'completed'),
(1, 2, NULL, 'active'),
(2, 1, 4, 'completed'),
(2, 3, NULL, 'active'),
(3, 2, 5, 'completed'),
(3, 4, NULL, 'active'),
(4, 1, 3, 'completed'),
(4, 5, NULL, 'active'),
(5, 3, 4, 'completed'),
(6, 2, NULL, 'active'),
(7, 4, NULL, 'active');

-- ========================================
-- Задание 4: Запросы на выборку данных
-- ========================================

-- 4.1 Выберите всех преподавателей
SELECT * FROM instructors;

-- 4.2 Выберите названия и цены всех курсов
SELECT title, price FROM courses;

-- 4.3 Выберите студентов, родившихся после 1995 года
SELECT first_name, last_name, birth_date 
FROM students 
WHERE birth_date > '1995-01-01';

-- 4.4 Выберите курсы дороже 30000 рублей, отсортированные по цене
SELECT title, price 
FROM courses 
WHERE price > 30000 
ORDER BY price;

-- 4.5 Выберите первых 3 студентов по алфавиту
SELECT first_name, last_name 
FROM students 
ORDER BY last_name, first_name 
LIMIT 3;

-- ========================================
-- Задание 5: Запросы с соединениями
-- ========================================

-- 5.1 Выберите курсы с именами преподавателей
SELECT 
    c.title,
    c.price,
    i.first_name || ' ' || i.last_name AS instructor_name
FROM courses c
JOIN instructors i ON c.instructor_id = i.id;

-- 5.2 Выберите активные записи студентов на курсы
SELECT 
    s.first_name || ' ' || s.last_name AS student_name,
    c.title AS course_title,
    e.enrollment_date
FROM enrollments e
JOIN students s ON e.student_id = s.id
JOIN courses c ON e.course_id = c.id
WHERE e.status = 'active';

-- 5.3 Выберите завершенные курсы с оценками
SELECT 
    s.first_name || ' ' || s.last_name AS student_name,
    c.title AS course_title,
    e.grade
FROM enrollments e
JOIN students s ON e.student_id = s.id
JOIN courses c ON e.course_id = c.id
WHERE e.status = 'completed' AND e.grade IS NOT NULL;

-- ========================================
-- Задание 6: Агрегатные функции
-- ========================================

-- 6.1 Подсчитайте количество студентов
SELECT COUNT(*) AS total_students FROM students;

-- 6.2 Найдите среднюю цену курсов
SELECT AVG(price) AS average_price FROM courses;

-- 6.3 Найдите максимальную и минимальную зарплату преподавателей
SELECT 
    MAX(salary) AS max_salary,
    MIN(salary) AS min_salary
FROM instructors;

-- 6.4 Подсчитайте количество записей на каждый курс
SELECT 
    c.title,
    COUNT(e.id) AS enrollment_count
FROM courses c
LEFT JOIN enrollments e ON c.id = e.course_id
GROUP BY c.id, c.title
ORDER BY enrollment_count DESC;

-- ========================================
-- Задание 7: Обновление и удаление данных
-- ========================================

-- 7.1 Обновите телефон студента с id = 1
UPDATE students 
SET phone = '+7-911-111-0000' 
WHERE id = 1;

-- 7.2 Увеличьте зарплату всех преподавателей на 10%
UPDATE instructors 
SET salary = salary * 1.1;

-- 7.3 Установите дату завершения для завершенных курсов
UPDATE enrollments 
SET completion_date = CURRENT_DATE 
WHERE status = 'completed' AND completion_date IS NULL;

-- ========================================
-- Задание 8: Дополнительные запросы
-- ========================================

-- 8.1 Найдите преподавателя с самой высокой зарплатой
SELECT first_name, last_name, salary 
FROM instructors 
WHERE salary = (SELECT MAX(salary) FROM instructors);

-- 8.2 Найдите студентов, которые не записаны ни на один курс
SELECT s.first_name, s.last_name 
FROM students s
LEFT JOIN enrollments e ON s.id = e.student_id
WHERE e.id IS NULL;

-- 8.3 Найдите курсы, на которые никто не записался
SELECT c.title 
FROM courses c
LEFT JOIN enrollments e ON c.id = e.course_id
WHERE e.id IS NULL;

-- 8.4 Вычислите средний возраст студентов
SELECT AVG(EXTRACT(YEAR FROM AGE(birth_date))) AS average_age 
FROM students 
WHERE birth_date IS NOT NULL;

-- ========================================
-- Задание 9: Проверка структуры
-- ========================================

-- 9.1 Посмотрите структуру всех созданных таблиц
\d instructors
\d courses  
\d students
\d enrollments

-- 9.2 Посмотрите список всех таблиц в базе данных
\dt

-- ========================================
-- Задание 10: Экспорт данных
-- ========================================

-- 10.1 Экспортируйте список всех студентов в CSV файл
\copy students TO 'students_export.csv' CSV HEADER;

-- 10.2 Экспортируйте отчет по записям на курсы
\copy (SELECT s.first_name || ' ' || s.last_name AS student, c.title AS course, e.status FROM enrollments e JOIN students s ON e.student_id = s.id JOIN courses c ON e.course_id = c.id) TO 'enrollments_report.csv' CSV HEADER;

-- ========================================
-- КОНЕЦ ДОМАШНЕГО ЗАДАНИЯ
-- ========================================

-- Сохраните все выполненные команды в файл homework_completed.sql
-- и отправьте преподавателю для проверки