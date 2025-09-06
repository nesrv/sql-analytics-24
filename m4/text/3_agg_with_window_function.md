# Конструкции вида "SUM (*) / AVG (*) / MIN(*) / MAX(*) OVER (PARTITION BY * ORDER BY)"

Вот практические задачи с решениями на оконные агрегатные функции PostgreSQL (`SUM()`, `AVG()`, `MIN()`, `MAX()` с `OVER (PARTITION BY ... ORDER BY ...)`) — как раз под твой курс.


## 🔧 Подготовка: таблица продаж

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
('Олег', '2024-01-12', 300),
('Олег', '2024-02-12', 400),
('Олег', '2024-02-08', 200);

```

---

## ✅ ЗАДАЧА 1: Посчитать накопительный итог продаж по каждому продавцу

**Цель:** Накапливающее `SUM()` по дате.

```sql
SELECT
    seller,
    sale_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY seller ORDER BY sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM sales;


SELECT
    seller,
    sale_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY seller ORDER BY sale_date
    ) AS running_total
FROM sales;

```

📌 `ROWS BETWEEN` указывает, что сумма идёт "с начала до текущей строки".

---

## ✅ ЗАДАЧА 2: Средняя сумма продаж до каждой даты включительно

**Цель:** Накопительная `AVG()` — средний чек со временем.

```sql
SELECT
    seller,
    sale_date,
    amount,
    AVG(amount) OVER (
        PARTITION BY seller ORDER BY sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_avg
FROM sales;



SELECT
    seller,
    sale_date,
    amount,
    AVG(amount) OVER (
        PARTITION BY seller ORDER BY sale_date
    ) AS running_avg
FROM sales;
```

---

## ✅ ЗАДАЧА 3: Минимальная сумма продажи **до текущей даты**

```sql
SELECT
    seller,
    sale_date,
    amount,
    MIN(amount) OVER (
        PARTITION BY seller ORDER BY sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS min_so_far
FROM sales;



SELECT
    seller,
    sale_date,
    amount,
    MIN(amount) OVER (
        PARTITION BY seller ORDER BY sale_date
    ) AS min_so_far
FROM sales;

```

---

## ✅ ЗАДАЧА 4: Максимальная продажа **вплоть до текущей строки**

```sql
SELECT
    seller,
    sale_date,
    amount,
    MAX(amount) OVER (
        PARTITION BY seller ORDER BY sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS max_so_far
FROM sales;

SELECT
    seller,
    sale_date,
    amount,
    MAX(amount) OVER (
        PARTITION BY seller ORDER BY sale_date
    ) AS max_so_far
FROM sales;

```

---

## ✅ ЗАДАЧА 5: Посчитать прирост по сравнению с минимальной продажей

```sql
SELECT
    seller,
    sale_date,
    amount,
    amount - MIN(amount) OVER (
        PARTITION BY seller ORDER BY sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS diff_from_min
FROM sales;

SELECT
    seller,
    sale_date,
    amount,
    amount - MIN(amount) OVER (
        PARTITION BY seller ORDER BY sale_date
    ) AS diff_from_min
FROM sales;

```

---

## ✅ ЗАДАЧА 6: Процент текущей продажи от накопительной суммы

```sql
SELECT
    seller,
    sale_date,
    amount,
    ROUND(
        amount * 100.0 / SUM(amount) OVER (
            PARTITION BY seller ORDER BY sale_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS percent_of_running_total
FROM sales;


SELECT
    seller,
    sale_date,
    amount,
    ROUND(
        amount * 100.0 / SUM(amount) OVER (
            PARTITION BY seller ORDER BY sale_date
        ),
        2
    ) AS percent_of_running_total
FROM sales;


```

---

## 🧠 Задачи:

* Вывести сделки, у которых сумма выше накопительного среднего.
* Показать все дни, когда текущая сумма равна максимальной в окне.
* Рассчитать "разницу между текущей и средней продажей до этой даты".

