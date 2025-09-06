# Урок: Функция LAG() в PostgreSQL

## Подготовка данных

```sql
CREATE TABLE sales (
    id SERIAL PRIMARY KEY,
    seller TEXT,
    sale_date DATE,
    amount NUMERIC
);

INSERT INTO sales (seller, sale_date, amount) VALUES
('Дмитрий', '2024-01-01', 100),
('Дмитрий', '2024-01-05', 200),
('Дмитрий', '2024-01-10', 300),
('Катерина', '2024-01-02', 400),
('Катерина', '2024-01-07', 100),
('Катерина', '2024-01-08', 600),
('Олег', '2024-01-03', 300),
('Олег', '2024-01-10', 300),
('Олег', '2024-01-12', 300);
```

## Пример 1: LAG() без ORDER BY ❌

```sql
SELECT seller, amount, LAG(amount) OVER (PARTITION BY seller)
FROM sales;
```

**Проблема:** Без `ORDER BY` порядок строк непредсказуем.

**Вывод:** Всегда используйте `ORDER BY` с оконными функциями!

## Пример 2: LAG() с ORDER BY ✅

```sql
SELECT seller, amount, LAG(amount) OVER (PARTITION BY seller ORDER BY sale_date)
FROM sales;
```

**Объяснение:**
- `PARTITION BY seller` — группируем по продавцам
- `ORDER BY sale_date` — сортируем по дате
- `LAG(amount)` — берем значение из предыдущей строки

## Пример 3: LAG() с параметрами

```sql
SELECT seller, amount, LAG(amount, 1, 0) OVER (PARTITION BY seller ORDER BY sale_date)
FROM sales;
```

**Параметры LAG():**
1. `amount` — столбец для получения значения
2. `1` — смещение (на сколько строк назад)
3. `0` — значение по умолчанию вместо NULL

## Пример 4: Полный запрос

```sql
SELECT
    seller,
    sale_date,
    amount,
    LAG(amount) OVER (PARTITION BY seller ORDER BY sale_date) AS previous_amount
FROM sales;
```

## Практическое применение

### Вычисление изменения продаж

```sql
SELECT
    seller,
    sale_date,
    amount,
    amount - LAG(amount) OVER (PARTITION BY seller ORDER BY sale_date) AS change
FROM sales;
```

### Процент роста (исправленная версия)

```sql
SELECT
    seller,
    sale_date,
    amount,
    ROUND(
        (amount - previous_amount) * 100.0 / previous_amount, 
        2
    ) AS growth_percent
FROM (
    SELECT
        seller,
        sale_date,
        amount,
        LAG(amount) OVER (PARTITION BY seller ORDER BY sale_date) AS previous_amount
    FROM sales
) t
WHERE previous_amount IS NOT NULL;
```

**Важно:** Оконные функции нельзя использовать в WHERE. Используйте подзапрос.

## Ключевые моменты

1. **Всегда используйте ORDER BY**
2. **PARTITION BY** разделяет данные на группы
3. **Оконные функции в WHERE запрещены** — используйте подзапрос
4. **NULL в первой строке** каждой группы
5. **Третий параметр** заменяет NULL значением по умолчанию