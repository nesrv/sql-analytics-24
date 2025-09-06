## Практика оконные функции PostgreSQL:

`LEAD()`, `LAG()`, `FIRST_VALUE()`, `LAST_VALUE()`, `RANK()`, `DENSE_RANK()`, `ROW_NUMBER()`.

## 🗂️ Исходные данные:

Создадим таблицу продаж:

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
('Катерина',   '2024-01-02', 400),
('Катерина',   '2024-01-07', 100),
('Катерина',   '2024-01-08', 600),
('Олег', '2024-01-03', 300),
('Олег', '2024-01-10', 300),
('Олег', '2024-01-12', 300);
```

---

## 1️⃣ **`LAG()`** — Продажи и разница с предыдущей

### 📌 Задача: Показать разницу между текущей и предыдущей продажей для каждого продавца.

```sql
SELECT
    seller,
    sale_date,
    amount,
    ...
FROM sales;
```

---

## 2️⃣ **`LEAD()`** — Предсказание следующей суммы

### 📌 Задача: Посчитать, сколько заработает продавец в следующей сделке.

```sql
SELECT
    seller,
    sale_date,
    amount,
    ...
FROM sales;
```

---

## 3️⃣ **`FIRST_VALUE()`** — Первая продажа продавца

```sql
SELECT
    seller,
    sale_date,
    amount,
    ...
FROM sales;
```

---

## 4️⃣ **`LAST_VALUE()`** — Последняя продажа (в пределах окна)

⚠️ `LAST_VALUE()` может вернуть "неожиданный" результат без `RANGE BETWEEN ...`.

```sql
SELECT
    seller,
    sale_date,
    amount,
    ...
FROM sales;





```

---

## 5️⃣ **`ROW_NUMBER()`** — Нумерация сделок по дате

```sql
SELECT
    seller,
    sale_date,
    amount,
    ...
FROM sales;
```

---

## 6️⃣ **`RANK()`** — Рейтинг продавцов по продажам (с пропусками)

```sql
SELECT
    seller,
    amount,
   ...
FROM sales;
```

---

## 7️⃣ **`DENSE_RANK()`** — Тот же рейтинг, но без пропусков

```sql
SELECT
    seller,
    amount,
    ...
FROM sales;
```

### 📌 Практические задания:

1. **Найти дату самой первой и последней продажи каждого продавца.**
2. **Показать сделки, где разница между текущей и предыдущей продажей превышает 200.**
3. **Показать топ-1 продажу каждого продавца (по сумме) с `RANK()` и `ROW_NUMBER()`.**
4. **Отметить сделки, которые являются повторяющимися по сумме (используя `DENSE_RANK()`).**

## ✅ 1. Найти дату самой первой и последней продажи каждого продавца

```sql
SELECT DISTINCT seller,
       FIRST_VALUE(sale_date) ...,
       LAST_VALUE(sale_date) ...  AS last_sale
FROM sales;
```

📌 `DISTINCT` используется, чтобы получить по одной строке на продавца.

---

## ✅ 2. Показать сделки, где разница с предыдущей продажей > 200

```sql
SELECT seller, sale_date, amount,
       .... AS diff
FROM sales
WHERE ... OVER ... > 200;
```

📌 Используется `LAG()` и фильтрация по условию.

---

## ✅ 3. Показать топ-1 продажу каждого продавца с `RANK()` и `ROW_NUMBER()`

### 💡 Вариант с `RANK()`:

```sql
SELECT seller, amount, sale_date
FROM (
    SELECT *,
           ...
    FROM sales
) sub
WHERE rnk = 1;
```

### 💡 Вариант с `ROW_NUMBER()`:

```sql
SELECT seller, amount, sale_date
FROM (
    SELECT *,
           ... AS rn
    FROM sales
) sub
WHERE rn = 1;
```

🔎 Разница:

* `RANK()` допускает **несколько топ-1**, если суммы одинаковы.
* `ROW_NUMBER()` возвращает **строго одну строку**, даже при дубликатах.

---

## ✅ 4. Отметить повторяющиеся суммы продаж с помощью `DENSE_RANK()`

```sql
SELECT seller, amount, sale_date,
      ...
FROM sales;
```

📌 Сделки с одинаковой суммой получат одинаковый `dense_rank`. Это помогает выявлять повторяющиеся значения.
