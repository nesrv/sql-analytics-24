![1748584162189](image/md/1748584162189.png)


# Секционирование (партиционирование) таблиц в PostgreSQL

## Введение
Секционирование (партиционирование) — это механизм разделения одной большой таблицы на меньшие, более управляемые части, называемые секциями или партициями. Это мощная функциональность PostgreSQL, которая помогает улучшить производительность и упростить управление большими объемами данных.

## 1. Задачи, решаемые с помощью секционирования

### 1.1 Улучшение производительности
- **Ускорение запросов**: Запросы могут обрабатывать только нужные секции благодаря "partition pruning"
- **Параллельный доступ**: Разные секции могут обрабатываться параллельно
- **Эффективное использование индексов**: Индексы становятся меньше и эффективнее

### 1.2 Упрощение управления данными
- **Удаление старых данных**: Можно быстро удалять целые секции вместо DELETE по строкам
- **Архивирование данных**: Старые секции можно перемещать на более медленные хранилища
- **Резервное копирование**: Можно бэкапить отдельные секции

### 1.3 Оптимизация хранилища
- Размещение разных секций на разных физических носителях
- Использование разных параметров хранения для разных секций

## 2. Виды секционирования в PostgreSQL

### 2.1 Range Partitioning (Диапазонное секционирование)

**Range Partitioning** (диапазонное секционирование) — это способ разделения таблицы на части (секции) по диапазонам значений одного или нескольких столбцов.

**Пример:** разделить таблицу заказов по годам (`order_date < 2025-01-01`, `order_date >= 2025-01-01 AND < 2023-01-01` и т.д.).

### Зачем использовать Partitioning?

* 📈 Повышает производительность запросов (особенно с фильтрацией).
* 📉 Уменьшает нагрузку на индексы.
* 🧹 Упрощает архивацию и удаление старых данных.

Отлично, вы хотите пример секционирования **без `PRIMARY KEY`** на родительской таблице. Это допустимо и даже удобно в случаях, когда:

* Уникальность `id` не требуется глобально
* Вы хотите создавать уникальные ключи на **отдельных партициях**
* Или обойти ограничение, связанное с обязательным включением секционирующего столбца в ключ

---

## 📘 Урок: Range Partitioning без `PRIMARY KEY` в PostgreSQL 16

### ✅ Шаг 1: Создаём родительскую таблицу

```sql
CREATE TABLE orders (
    id int,
    customer_name text,
    order_date date NOT NULL
) PARTITION BY RANGE (order_date);
```

> ❗ Здесь **нет `PRIMARY KEY`** — это допустимо, но значит, что PostgreSQL **не будет контролировать уникальность `id` или других полей** на уровне всей таблицы.

---

### ✅ Шаг 2: Создание партиций

```sql
CREATE TABLE orders_2022 PARTITION OF orders
    FOR VALUES FROM ('2022-01-01') TO ('2023-01-01');

CREATE TABLE orders_2023 PARTITION OF orders
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

CREATE TABLE orders_2024 PARTITION OF orders
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
```

---

---

### ✅ Шаг 3: Вставка данных

```sql
INSERT INTO orders (id, customer_name, order_date)
VALUES
  (1, 'Иванов', '2022-06-01'),
  (2, 'Петров', '2023-08-15'),
  (3, 'Сидоров', '2024-01-10');
```

---

### ✅ Шаг 4: Проверка выборки и плана

```sql
EXPLAIN ANALYZE
SELECT * FROM orders WHERE order_date >= '2023-01-01' AND order_date < '2024-01-01';
```

Ожидаем: **Partition Pruning** — только нужная партиция будет участвовать.

---



# 📘 Практика: Range Partitioning в PostgreSQL 16

## ✅ Задание 1: Добавить партицию по умолчанию

**Цель:** обработка "выпадающих" дат

```sql
CREATE TABLE orders_default PARTITION OF orders DEFAULT;
```

**Проверка:**

```sql
INSERT INTO orders VALUES (100, 'Алексеев', '2025-06-01');
SELECT * FROM orders_default;
```

🧠 *Объяснение:* `DEFAULT`-партиция принимает все значения, которые не попали ни в одну другую.

---

## ✅ Задание 2: Индекс по `customer_name` в каждой партиции

**Цель:** ускорить поиск по имени

```sql
CREATE INDEX ON orders_2022 (customer_name);
CREATE INDEX ON orders_2023 (customer_name);
CREATE INDEX ON orders_2024 (customer_name);
```

**Проверка производительности:**

```sql
EXPLAIN ANALYZE
SELECT * FROM orders WHERE customer_name = 'Иванов';
```

🧠 *Объяснение:* индексы нужно создавать отдельно для каждой партиции — глобальных индексов нет.

---

## ✅ Задание 3: Удалить все заказы 2022 года

```sql
DROP TABLE orders_2022;
```

🧠 *Объяснение:* это безопасный и быстрый способ удалить партицию целиком — намного быстрее, чем `DELETE`.

---

## ✅ Задание 4: Представление `orders_summary`

**Цель:** агрегировать количество заказов по годам

```sql
CREATE VIEW orders_summary AS
SELECT
    EXTRACT(YEAR FROM order_date) AS year,
    COUNT(*) AS total_orders
FROM orders
GROUP BY 1
ORDER BY 1;
```

**Проверка:**

```sql
SELECT * FROM orders_summary;
```

🧠 *Объяснение:* представление агрегирует по дате из всех партиций — PostgreSQL сам обходит их.

---

## ✅ Задание 5: Обновить клиента `'Иванов'` на `'Иванов И.И.'`

```sql
UPDATE orders
SET customer_name = 'Иванов И.И.'
WHERE customer_name = 'Иванов';
```

🧠 *Объяснение:* обновление выполняется внутри каждой партиции, где есть такие строки. PostgreSQL применяет **partition-wise UPDATE** при возможности.

---



## ✅ Задание 6: Использование `MERGE`


```sql
MERGE INTO orders AS o
USING (VALUES
    (2, 'Петров П.П.', DATE '2023-01-12'),
    (4, 'Смирнов',     DATE '2023-01-13')
) AS incoming(id, customer_name, order_date)
ON o.id = incoming.id
WHEN MATCHED THEN
    UPDATE SET customer_name = incoming.customer_name
WHEN NOT MATCHED THEN
    INSERT (id, customer_name, order_date)
    VALUES (incoming.id, incoming.customer_name, incoming.order_date);

```


```sql
MERGE INTO orders AS o
USING (VALUES (4, 'Смирнов', '2023-04-10')) AS v(id, name, date)
ON o.id = v.id AND o.order_date = v.date
WHEN MATCHED THEN
    UPDATE SET customer_name = v.name
WHEN NOT MATCHED THEN
    INSERT VALUES (v.id, v.name, v.date);
```

🧠 *Объяснение:* `MERGE` выполняет UPSERT на секционированной таблице. PostgreSQL 16 полностью поддерживает это.

---

## ✅ Задание 7: Узнать, в какой партиции заказ

```sql
SELECT id, customer_name, order_date, tableoid::regclass AS partition
FROM orders
WHERE id = 4;
```

🧠 *Объяснение:* `tableoid::regclass` показывает фактическое имя партиции, в которой хранится строка.

---


## ✅ Задание 7: 🎓 Материализованные представления в PostgreSQL


**Материализованное представление (Materialized View)** — это объект базы данных, который хранит **результат SQL-запроса физически**, в отличие от обычных представлений (`VIEW`), которые формируются на лету.

```sql

CREATE MATERIALIZED VIEW monthly_sales AS
SELECT
    DATE_TRUNC('month', order_date) AS month,
    count(customer_name) AS total_customer
FROM orders
GROUP BY month
ORDER BY month;

SELECT * FROM monthly_sales;

INSERT INTO orders (customer_name, order_date)
VALUES ('Тестов', '2024-02-10');

INSERT INTO orders (customer_name, order_date)
VALUES ('Тестов-2', '2024-02-10');


REFRESH MATERIALIZED VIEW monthly_sales;

```


---

## ✅ Преимущества:

* Ускоряет выполнение сложных запросов.
* Используется для отчетов, дашбордов и агрегации данных.

## ⚠️ Недостатки:

* Данные **не обновляются автоматически**, их нужно **обновлять вручную**.
* Занимают дополнительное место на диске.

---

## 🔧 Синтаксис

```sql
CREATE MATERIALIZED VIEW имя_представления AS
SELECT ...
WITH [NO] DATA;
```

* `WITH DATA` (по умолчанию) — сохраняет результат сразу.
* `WITH NO DATA` — создает представление, но без заполнения.

Обновление данных:

```sql
REFRESH MATERIALIZED VIEW имя_представления;
```



## 🧠 Заключение

| Сравнение вариантов                 | С `PRIMARY KEY`    | Без `PRIMARY KEY`       |
| ----------------------------------- | ------------------ | ----------------------- |
| Проверка уникальности               | Глобальная (везде) | Только вручную/локально |
| Необходимость включать `order_date` | Да                 | Нет                     |
| Простота разработки                 | Чуть сложнее       | Проще                   |

---





### 2.2 List Partitioning (Списочное секционирование)

**List Partitioning** — это способ разделить таблицу на части (партиции), где каждая партиция содержит строки с **конкретным значением** одного из столбцов.
Например, можно создать отдельные партиции по странам, регионам, статусам и т.д.

---

## 📦 Пример: Секционирование заказов по статусу

---

### 1. Создаём родительскую таблицу

```sql
CREATE TABLE orders (
    id serial,
    customer_name text,
    status text NOT NULL
) PARTITION BY LIST (status);
```

---

### 2. Создаём партиции

```sql
CREATE TABLE orders_new PARTITION OF orders
    FOR VALUES IN ('new');

CREATE TABLE orders_processing PARTITION OF orders
    FOR VALUES IN ('processing');

CREATE TABLE orders_done PARTITION OF orders
    FOR VALUES IN ('done');
```

---

### 3. (Необязательно) Партиция по умолчанию

```sql
CREATE TABLE orders_other PARTITION OF orders DEFAULT;
```

🧠 Эта партиция будет принимать строки с любым статусом, не указанным в других партициях.

---

### 4. Вставка данных

```sql
INSERT INTO orders (customer_name, status) VALUES
('Иванов', 'new'),
('Петров', 'processing'),
('Сидоров', 'done'),
('Михайлов', 'canceled');  -- попадёт в orders_other
```

---

### 5. Проверка данных

```sql
SELECT * FROM orders_new;
SELECT * FROM orders_other;
```

---

## 🧠 Как это работает?

* PostgreSQL сам направляет строку в нужную партицию
* Запросы к `orders` прозрачно работают с партициями
* Можно использовать **partition pruning** — если в WHERE есть `status`, Postgres обойдёт только нужные партиции

---

## 🔍 EXPLAIN: проверка pruning

```sql
EXPLAIN SELECT * FROM orders WHERE status = 'processing';
```

✅ В плане будет видно, что читается **только нужная партиция** (`orders_processing`).

---

## ✅ Практические задачи

### Задание 1: Добавить ещё одну партицию

Создай партицию `orders_canceled` для статуса `'canceled'`.

```sql
CREATE TABLE orders_canceled PARTITION OF orders
    FOR VALUES IN ('canceled');
```

---

### Задание 2: Найти, в какой партиции заказ

```sql
SELECT id, customer_name, status, tableoid::regclass AS partition
FROM orders;
```

---

### Задание 3: Удалить строки с `status = 'done'`

```sql
DELETE FROM orders WHERE status = 'done';
```

🧠 Выполнится только в `orders_done`.

---

### Задание 4: Удалить партицию `orders_other`

```sql
DROP TABLE orders_other;
```

---

## ⚠️ Ограничения и особенности

* Все `UNIQUE` и `PRIMARY KEY` ограничения должны включать секционирующий столбец (`status`)
* Нет глобальных индексов — нужно создавать индексы **в каждой партиции**
* Нельзя вставить строку с `status`, не соответствующим ни одной партиции, если нет `DEFAULT`-партиции — получите ошибку

---

## 📌 Заключение

List Partitioning удобно использовать, если:

* У вас есть фиксированный список значений (`'new'`, `'done'`, `'processing'`, …)
* Данные логически хорошо группируются по этим значениям
* Вы хотите упростить очистку/архивацию данных (например, просто удалить партицию)



### 2.4 Комбинированные методы
PostgreSQL поддерживает многоуровневое секционирование (подсекционирование).
В PostgreSQL 16 секционирование стало более производительным и удобным, но **обслуживание секций (партиций)** всё ещё требует внимания. Вот подробный разбор:

---

# 🛠 Обслуживание секций (партиций) в PostgreSQL 16

---

## 🔹 1. Зачем обслуживать партиции?

Партиции — это обычные таблицы под капотом. Они нуждаются в:

* **архивации** или **удалении устаревших данных**
* **переиндексации** и **анализе статистики**
* **добавлении/удалении** партиций по мере роста данных
* **мониторинге** производительности

---

## 🔹 2. Обновление статистики

```sql
ANALYZE orders;
```

🔍 Выполняет `ANALYZE` на всех дочерних таблицах. Можно отдельно:

```sql
ANALYZE orders_2023;
```

---

## 🔹 3. Индексация

Индексы нужно создавать **на каждой партиции отдельно**:

```sql
CREATE INDEX ON orders_2022 (customer_name);
```

💡 В PostgreSQL 16 пока **нет глобальных индексов**, как в некоторых других СУБД.

---

## 🔹 4. Проверка распределения строк

```sql
SELECT
    relname AS partition,
    reltuples::bigint AS estimated_rows
FROM pg_class
WHERE relname LIKE 'orders_%';
```

---

## 🔹 5. Очистка/удаление устаревших партиций

Удаление партиции — очень быстро:

```sql
DROP TABLE orders_2022;
```

📌 Это намного эффективнее, чем `DELETE FROM`.

---

## 🔹 6. Добавление новых партиций

Пример:

```sql
CREATE TABLE orders_2025 PARTITION OF orders
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
```

💡 Обычно используется **скрипт автоматизации**, который добавляет новые партиции в начале месяца/года.

---

## 🔹 7. Проверка наличия "выпадающих" строк

Если вы не используете `DEFAULT`-партицию, убедитесь, что все значения попадают в диапазоны:

```sql
-- пример для RANGE секционирования
SELECT * FROM orders
WHERE order_date < '2022-01-01' OR order_date >= '2025-01-01';
```

---

## 🔹 8. Проверка, какая партиция используется

```sql
SELECT id, tableoid::regclass AS partition
FROM orders
LIMIT 10;
```

---

## 🔹 9. VACUUM по партициям

```sql
VACUUM ANALYZE orders_2023;
```

Можно написать скрипт, который пробегается по всем партициям.

---

## 🔹 10. Мониторинг partition pruning

Проверка, насколько эффективно Postgres отсекает ненужные партиции:

```sql
EXPLAIN ANALYZE
SELECT * FROM orders WHERE order_date = '2023-05-01';
```

⏱ Если pruning работает, Postgres ссылается только на нужную партицию (`orders_2023`).


