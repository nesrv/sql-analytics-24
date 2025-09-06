# Конструкции вида 

"SUM (*) / AVG (*) / MIN(*) / MAX(*) OVER (PARTITION BY * ORDER BY)"


## 🔧 Подготовка: таблица продаж

```sql
CREATE TABLE sales (
    id SERIAL PRIMARY KEY,
    seller TEXT,
    sale_date DATE,
    amount NUMERIC
);

INSERT INTO sales (seller, sale_date, amount) VALUES
('Alice', '2024-01-01', 100),
('Alice', '2024-01-03', 200),
('Alice', '2024-01-05', 300),
('Bob',   '2024-01-02', 150),
('Bob',   '2024-01-04', 350),
('Bob',   '2024-01-06', 100);
```

---

## ✅ ЗАДАЧА 1: Посчитать накопительный итог продаж по каждому продавцу

**Цель:** Накапливающее `SUM()` по дате.

```sql
SELECT
    seller,
    sale_date,
    amount,
   ...
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
   ...
FROM sales;
```

---

## ✅ ЗАДАЧА 3: Минимальная сумма продажи **до текущей даты**

```sql


SELECT
    seller,
    sale_date,
    amount,
  ...
FROM sales;

```

---

## ✅ ЗАДАЧА 4: Максимальная продажа **вплоть до текущей строки**

```sql

SELECT
    seller,
    sale_date,
    amount,
    ...
FROM sales;

```

---

## ✅ ЗАДАЧА 5: Посчитать прирост по сравнению с минимальной продажей

```sql
SELECT
    seller,
    sale_date,
    amount,
    ...
FROM sales;

```


## ✅ ЗАДАЧА 6: Процент текущей продажи от накопительной суммы

```sql
SELECT
    seller,
    sale_date,
    amount,
    ...     AS percent_of_running_total
FROM sales;


SELECT
    seller,
    sale_date,
    amount,
    ... AS percent_of_running_total
FROM sales;


```

---

## 🧠 Задачи:

* Вывести сделки, у которых сумма выше накопительного среднего.
* Показать все дни, когда текущая сумма равна максимальной в окне.
* Рассчитать "разницу между текущей и средней продажей до этой даты".

