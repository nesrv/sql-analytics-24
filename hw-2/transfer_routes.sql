-- База данных для построения трансферных маршрутов
-- 
-- Описание: Система управления трансферными перевозками между городами
-- Включает: 4 связанные таблицы, 10 городов, различные типы транспорта
-- Функционал: построение маршрутов, управление расписанием, бронирование мест
--
-- Структура:
-- cities - справочник городов (id, название, страна, координаты)
-- vehicles - транспортные средства (тип, вместимость, номер)
-- routes - маршруты между городами (расстояние, время, цена)
-- transfers - конкретные поездки (расписание, доступные места, статус)
--
-- Связи:
-- routes.from_city_id → cities.id
-- routes.to_city_id → cities.id  
-- transfers.route_id → routes.id
-- transfers.vehicle_id → vehicles.id

-- Таблица городов
CREATE TABLE cities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    country VARCHAR(50) NOT NULL,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8)
);

-- Таблица транспортных средств
CREATE TABLE vehicles (
    id SERIAL PRIMARY KEY,
    type VARCHAR(50) NOT NULL, -- bus, car, minivan
    capacity INTEGER NOT NULL,
    license_plate VARCHAR(20) UNIQUE NOT NULL
);

-- Таблица маршрутов между городами
CREATE TABLE routes (
    id SERIAL PRIMARY KEY,
    from_city_id INTEGER REFERENCES cities(id),
    to_city_id INTEGER REFERENCES cities(id),
    distance_km INTEGER NOT NULL,
    duration_minutes INTEGER NOT NULL,
    price DECIMAL(10,2) NOT NULL
);

-- Таблица трансферов (конкретные поездки)
CREATE TABLE transfers (
    id SERIAL PRIMARY KEY,
    route_id INTEGER REFERENCES routes(id),
    vehicle_id INTEGER REFERENCES vehicles(id),
    departure_time TIMESTAMP NOT NULL,
    available_seats INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'active' -- active, completed, cancelled
);

-- Вставка данных: города
INSERT INTO cities (name, country, latitude, longitude) VALUES
('Москва', 'Россия', 55.7558, 37.6176),
('Санкт-Петербург', 'Россия', 59.9311, 30.3609),
('Казань', 'Россия', 55.8304, 49.0661),
('Нижний Новгород', 'Россия', 56.2965, 43.9361),
('Екатеринбург', 'Россия', 56.8431, 60.6454),
('Новосибирск', 'Россия', 55.0084, 82.9357),
('Краснодар', 'Россия', 45.0355, 38.9753),
('Воронеж', 'Россия', 51.6720, 39.1843),
('Самара', 'Россия', 53.2001, 50.1500),
('Ростов-на-Дону', 'Россия', 47.2357, 39.7015);

-- Вставка данных: транспорт
INSERT INTO vehicles (type, capacity, license_plate) VALUES
('minivan', 8, 'А123БВ777'),
('bus', 20, 'В456ГД777'),
('car', 4, 'Е789ЖЗ777'),
('bus', 30, 'И012КЛ777'),
('minivan', 6, 'М345НО777');

-- Вставка данных: маршруты
INSERT INTO routes (from_city_id, to_city_id, distance_km, duration_minutes, price) VALUES
(1, 2, 635, 480, 2500.00), -- Москва - СПб
(1, 3, 719, 540, 2800.00), -- Москва - Казань
(1, 4, 411, 300, 1800.00), -- Москва - Н.Новгород
(2, 3, 1143, 720, 3500.00), -- СПб - Казань
(3, 5, 1057, 660, 3200.00), -- Казань - Екатеринбург
(1, 7, 1160, 780, 3800.00), -- Москва - Краснодар
(4, 9, 430, 320, 2000.00), -- Н.Новгород - Самара
(7, 10, 270, 180, 1200.00), -- Краснодар - Ростов
(2, 1, 635, 480, 2500.00), -- СПб - Москва
(5, 3, 1057, 660, 3200.00); -- Екатеринбург - Казань

-- Вставка данных: трансферы
INSERT INTO transfers (route_id, vehicle_id, departure_time, available_seats) VALUES
(1, 2, CURRENT_DATE + INTERVAL '1 day' + TIME '08:00:00', 18),
(2, 1, CURRENT_DATE + INTERVAL '2 days' + TIME '10:30:00', 6),
(3, 3, CURRENT_DATE + INTERVAL '3 days' + TIME '14:00:00', 3),
(4, 4, CURRENT_DATE + INTERVAL '1 day' + TIME '09:00:00', 25),
(5, 2, CURRENT_DATE + INTERVAL '2 days' + TIME '11:00:00', 15),
(6, 3, CURRENT_DATE + INTERVAL '3 days' + TIME '16:30:00', 2),
(7, 1, CURRENT_DATE + INTERVAL '1 day' + TIME '12:15:00', 4),
(8, 4, CURRENT_DATE + INTERVAL '2 days' + TIME '07:45:00', 28);