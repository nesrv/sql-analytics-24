# Рекурсивные запросы 

Вот как можно посчитать **факториал** и **числа Фибоначчи** в PostgreSQL с помощью `WITH RECURSIVE` и `UNION ALL`.

---

## 🧮 1. Факториал (например, до 10!)

```sql
WITH RECURSIVE factorial(n, fact) AS (
    ...
)
SELECT * FROM factorial;
```

### 🔍 Что делает:

* `n` — число от 1 до 10;
* `fact` — значение `n!`.

---

## 🌀 2. Числа Фибоначчи (первые 15 чисел)

```sql
WITH RECURSIVE fib(n, a, b) AS (
    ...
)
SELECT n, a AS fib_n FROM fib;
```

### 🔍 Что делает:

* `a` — это `Fₙ`;
* `b` — это `Fₙ₊₁`;
* На каждой итерации `a` сдвигается на `b`, `b` на `a + b`.

---


* 1 Сумму всех Фибоначчи до N?
* 2 Найти `F(n)` через рекурсивную функцию?
* 3 Вывести факториалы в одной строке через `string_agg`?






## ✅ 1. Сумма всех чисел Фибоначчи до `N` (например, N = 15)

```sql
WITH RECURSIVE fib(n, a, b) AS (
    ...
)
SELECT SUM(a) AS fib_sum
FROM fib;
```

> 👉 `a` — это Fₙ на каждой итерации. Суммируем `a` до `F(14)` (всего 15 чисел от `F(0)` до `F(14)`).

---

## ✅ 2. Рекурсивная **функция** для вычисления `F(n)`

```sql
CREATE OR REPLACE FUNCTION fib_rec(n INTEGER)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
BEGIN   
    IF n = 0 THEN
        RETURN 0;
    ...
END;
$$;
```

### ▶ Пример вызова:

```sql
SELECT fib_rec(10);  -- → 55
```

⚠️ Но: эта функция **медленная для больших `n`**, потому что она не использует кеширование. Лучше использовать `WITH RECURSIVE` для итеративного подхода.

---

## ✅ 3. Вывести факториалы `1! ... 10!` в одну строку через `string_agg`

```sql
WITH RECURSIVE factorial(n, fact) AS (
    ...
SELECT ... AS result
FROM factorial;
```

### ▶ Пример вывода:

```
1! = 1
2! = 2
3! = 6
...
10! = 3628800
```


