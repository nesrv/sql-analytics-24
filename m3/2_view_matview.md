# 🎓 Представления в PostgreSQL

## 📌 Обычные представления (VIEW)

**Представление (View)** — это виртуальная таблица, которая представляет результат SQL-запроса. Данные не хранятся физически, а формируются на лету при каждом обращении.

### Синтаксис создания представления

```sql
CREATE VIEW имя_представления AS
SELECT ...
```

### Пример с обычными представлениями

Создадим базовые таблицы:

```sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_name TEXT,
    amount NUMERIC,
    order_date DATE
);

INSERT INTO orders (customer_name, amount, order_date)
VALUES
('Иванов', 1000, '2024-01-10'),
('Петров', 2000, '2024-01-15'),
('Сидоров', 1500, '2024-02-05');
```

Создаем обычное представление:

```sql
CREATE VIEW customer_summary AS
SELECT 
    customer_name,
    COUNT(*) as order_count,
    SUM(amount) as total_amount,
    AVG(amount) as avg_amount
FROM orders
GROUP BY customer_name;
```

Использование представления:

```sql
SELECT * FROM customer_summary;
SELECT * FROM customer_summary WHERE total_amount > 1500;
```

### Преимущества обычных представлений

- **Актуальные данные**: всегда показывают текущее состояние
- **Безопасность**: можно ограничить доступ к определенным столбцам
- **Упрощение**: скрывают сложность запросов
- **Не занимают место**: данные не дублируются

### Недостатки обычных представлений

- **Производительность**: запрос выполняется каждый раз заново
- **Сложные вычисления**: могут быть медленными для больших данных

### Управление представлениями

```sql
-- Просмотр всех представлений
SELECT * FROM information_schema.views WHERE table_schema = 'public';

-- Изменение представления
CREATE OR REPLACE VIEW customer_summary AS
SELECT 
    customer_name,
    COUNT(*) as order_count,
    SUM(amount) as total_amount
FROM orders
GROUP BY customer_name;

-- Удаление представления
DROP VIEW customer_summary;
```

---

## 📌 Материализованные представления (MATERIALIZED VIEW)

**Материализованное представление (Materialized View)** — это объект базы данных, который хранит **результат SQL-запроса физически**, в отличие от обычных представлений (`VIEW`), которые формируются на лету.

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

---

## 📘 Пример

Создадим базу с заказами:

```sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_name TEXT,
    amount NUMERIC,
    order_date DATE
);

INSERT INTO orders (customer_name, amount, order_date)
VALUES
('Иванов', 1000, '2024-01-10'),
('Петров', 2000, '2024-01-15'),
('Сидоров', 1500, '2024-02-05');
```

Создаем материализованное представление:

```sql
CREATE MATERIALIZED VIEW monthly_sales AS
SELECT
    DATE_TRUNC('month', order_date) AS month,
    SUM(amount) AS total_sales
FROM orders
GROUP BY month
ORDER BY month;
```

Смотрим данные:

```sql
SELECT * FROM monthly_sales;
```

После добавления новых заказов:

```sql
INSERT INTO orders (customer_name, amount, order_date)
VALUES ('Тестов', 3000, '2024-02-10');
```

Представление **не обновится автоматически**. Нужно:

```sql
REFRESH MATERIALIZED VIEW monthly_sales;
```

---

## 💡 Дополнительно: Индексы на материализованных представлениях

```sql
CREATE INDEX idx_sales_month ON monthly_sales(month);
```

Это увеличит скорость выборки по дате.

---

## 🧠 Практика

### 🧪 Задание 1:

Создайте материализованное представление, показывающее общее количество заказов и общую сумму по каждому клиенту.

**Ожидаемый результат:**

| customer\_name | total\_orders | total\_amount |
| -------------- | ------------- | ------------- |
| Иванов         | 1             | 1000          |

🔧 *Решение:*

```sql
CREATE MATERIALIZED VIEW customer_stats AS
SELECT
    customer_name,
    COUNT(*) AS total_orders,
    SUM(amount) AS total_amount
FROM orders
GROUP BY customer_name;
```

---

### 🧪 Задание 2:

Добавьте новый заказ. Проверьте, обновится ли представление `customer_stats`. Затем обновите его.

🔧 *Решение:*

```sql
-- Добавляем заказ
INSERT INTO orders (customer_name, amount, order_date)
VALUES ('Иванов', 500, '2024-02-15');

-- Проверяем (будет старое значение)
SELECT * FROM customer_stats;

-- Обновляем
REFRESH MATERIALIZED VIEW customer_stats;

-- Снова проверяем
SELECT * FROM customer_stats;
```

---

## 🎯 Итог

| Функция                    | Материализованное представление |
| -------------------------- | ------------------------------- |
| Хранит данные физически?   | ✅ Да                            |
| Обновляется автоматически? | ❌ Нет                           |
|                            |                                 |
