-- 3.1 Setup: Create Test Database

DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;

CREATE TABLE accounts (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  balance DECIMAL(10, 2) DEFAULT 0.00
);

CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  shop VARCHAR(100) NOT NULL,
  product VARCHAR(100) NOT NULL,
  price DECIMAL(10, 2) NOT NULL
);

INSERT INTO accounts (name, balance) VALUES
 ('Alice', 1000.00),
 ('Bob',   500.00),
 ('Wally', 750.00);

INSERT INTO products (shop, product, price) VALUES
 ('Joe''s Shop', 'Coke',  2.50),
 ('Joe''s Shop', 'Pepsi', 3.00);

-- 3.2 Task 1: Basic Transaction with COMMIT
-- Transfer 100 from Alice to Bob

-- (опционально сброс балансов перед задачей)
UPDATE accounts SET balance = 1000.00 WHERE name = 'Alice';
UPDATE accounts SET balance = 500.00  WHERE name = 'Bob';
UPDATE accounts SET balance = 750.00  WHERE name = 'Wally';

BEGIN;
UPDATE accounts SET balance = balance - 100.00
 WHERE name = 'Alice';
UPDATE accounts SET balance = balance + 100.00
 WHERE name = 'Bob';
COMMIT;

-- Проверка результата:
SELECT * FROM accounts WHERE name IN ('Alice','Bob');

-- Ответы:
-- a) Balances: Alice = 900.00, Bob = 600.00
-- b) Обе операции должны быть атомарны: либо оба UPDATE, либо ни один.
-- c) Без транзакции возможна ситуация, когда деньги списались у Alice, но не дошли до Bob.


-- 3.3 Task 2: Using ROLLBACK


-- Сброс к исходным значениям для наглядности
UPDATE accounts SET balance = 1000.00 WHERE name = 'Alice';
UPDATE accounts SET balance = 500.00  WHERE name = 'Bob';
UPDATE accounts SET balance = 750.00  WHERE name = 'Wally';

BEGIN;
UPDATE accounts SET balance = balance - 500.00
 WHERE name = 'Alice';

SELECT * FROM accounts WHERE name = 'Alice';  -- после UPDATE

ROLLBACK;

SELECT * FROM accounts WHERE name = 'Alice';  -- после ROLLBACK

-- Ответы:
-- a) После UPDATE (до ROLLBACK) баланс Alice = 500.00.
-- b) После ROLLBACK баланс Alice снова = 1000.00.
-- c) ROLLBACK используется при ошибках (неверная сумма, сбой логики, исключения).


-- 3.4 Task 3: Working with SAVEPOINTs

-- Сброс
UPDATE accounts SET balance = 1000.00 WHERE name = 'Alice';
UPDATE accounts SET balance = 500.00  WHERE name = 'Bob';
UPDATE accounts SET balance = 750.00  WHERE name = 'Wally';

BEGIN;
UPDATE accounts SET balance = balance - 100.00
 WHERE name = 'Alice';

SAVEPOINT my_savepoint;

UPDATE accounts SET balance = balance + 100.00
 WHERE name = 'Bob';

ROLLBACK TO my_savepoint;

UPDATE accounts SET balance = balance + 100.00
 WHERE name = 'Wally';

COMMIT;

SELECT * FROM accounts ORDER BY name;

-- Ответы:
-- a) Итог: Alice = 900.00, Bob = 500.00, Wally = 850.00.
-- b) Bob временно был зачислен, но ROLLBACK TO my_savepoint откатил это изменение.
-- c) SAVEPOINT позволяет откатывать часть транзакции, не теряя уже выполненные шаги.

------------------------------------------------------------
-- 3.5 Task 4: Isolation Level Demonstration
-- Сценарии для двух терминалов
------------------------------------------------------------

-- SCENARIO A: READ COMMITTED
-- Terminal 1:
-- BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- -- подождать Terminal 2
-- SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- COMMIT;

-- Terminal 2:
-- BEGIN;
-- DELETE FROM products WHERE shop = 'Joe''s Shop';
-- INSERT INTO products (shop, product, price)
--   VALUES ('Joe''s Shop', 'Fanta', 3.50);
-- COMMIT;

-- SCENARIO B: SERIALIZABLE
-- Terminal 1:
-- BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- -- подождать Terminal 2
-- SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- COMMIT;

-- Terminal 2: те же DELETE/INSERT/COMMIT (как выше),
-- но возможен конфликт с SERIALIZABLE (ошибка сериализации).

-- Ответы:
-- a) READ COMMITTED: сначала старые строки (Coke, Pepsi), после COMMIT во 2-м терминале – новые (только Fanta).
-- b) SERIALIZABLE: T1 либо видит старое состояние до конца своей транзакции,
--    либо одна из транзакций откатывается с ошибкой сериализации.
-- c) READ COMMITTED допускает «перечитывание» изменённых данных;
--    SERIALIZABLE ведёт себя как последовательное выполнение транзакций.

------------------------------------------------------------
-- 3.6 Task 5: Phantom Read Demonstration (REPEATABLE READ)
------------------------------------------------------------

-- Terminal 1:
-- BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- SELECT MAX(price), MIN(price)
--   FROM products
--  WHERE shop = 'Joe''s Shop';
-- -- подождать Terminal 2
-- SELECT MAX(price), MIN(price)
--   FROM products
--  WHERE shop = 'Joe''s Shop';
-- COMMIT;

-- Terminal 2:
-- BEGIN;
-- INSERT INTO products (shop, product, price)
--   VALUES ('Joe''s Shop', 'Sprite', 4.00);
-- COMMIT;

-- Ответы:
-- a) В REPEATABLE READ Terminal 1 НЕ увидит новую строку Sprite (та же выборка, что и в первый раз).
-- b) Phantom read – когда повторный запрос с теми же условиями возвращает дополнительные (новые) строки.
-- c) Фантомы предотвращает уровень SERIALIZABLE.

------------------------------------------------------------
-- 3.7 Task 6: Dirty Read Demonstration (READ UNCOMMITTED)
------------------------------------------------------------

-- В PostgreSQL READ UNCOMMITTED фактически ведёт себя как READ COMMITTED,
-- но логика примера такая (теоретически):

-- Terminal 1:
-- BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- -- подождать Terminal 2 UPDATE (без COMMIT)
-- SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- -- подождать ROLLBACK во 2-м терминале
-- SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- COMMIT;

-- Terminal 2:
-- BEGIN;
-- UPDATE products SET price = 99.99
--  WHERE product = 'Fanta';
-- -- подождать, не коммитить
-- ROLLBACK;

-- Ответы:
-- a) При реальном READ UNCOMMITTED T1 может увидеть 99.99,
--    хотя изменение потом откатится (это опасно).
-- b) Dirty read – чтение данных, которые ещё не зафиксированы и могут быть отменены.
-- c) READ UNCOMMITTED почти всегда следует избегать: риск неконсистентных данных.

------------------------------------------------------------
-- 4. Independent Exercise 1
-- Transfer $200 from Bob to Wally, only if Bob has enough funds
------------------------------------------------------------

-- Предположим исходные значения:
UPDATE accounts SET balance = 1000.00 WHERE name = 'Alice';
UPDATE accounts SET balance = 500.00  WHERE name = 'Bob';
UPDATE accounts SET balance = 750.00  WHERE name = 'Wally';

DO $$
DECLARE
  bob_balance DECIMAL(10,2);
BEGIN
  BEGIN
    SELECT balance INTO bob_balance
    FROM accounts
    WHERE name = 'Bob'
    FOR UPDATE;

    IF bob_balance < 200 THEN
      RAISE EXCEPTION 'Insufficient funds for Bob. Current balance: %', bob_balance;
    END IF;

    UPDATE accounts
      SET balance = balance - 200
      WHERE name = 'Bob';

    UPDATE accounts
      SET balance = balance + 200
      WHERE name = 'Wally';

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RAISE;
  END;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM accounts WHERE name IN ('Bob','Wally');

------------------------------------------------------------
-- 4. Independent Exercise 2
-- Multi-savepoint product transaction
------------------------------------------------------------

-- Добавим новый продукт с несколькими SAVEPOINT
BEGIN;
INSERT INTO products (shop, product, price)
VALUES ('Joe''s Shop', 'TempProduct', 10.00);

SAVEPOINT sp1;

UPDATE products
SET price = 12.00
WHERE product = 'TempProduct';

SAVEPOINT sp2;

DELETE FROM products
WHERE product = 'TempProduct';

ROLLBACK TO sp1;

COMMIT;

SELECT * FROM products WHERE product = 'TempProduct';

-- Итог: продукт существует с ценой 12.00 (мы откатили только удаление).

------------------------------------------------------------
-- 4. Independent Exercise 3
-- Two users withdrawing from same account (outline)
------------------------------------------------------------

-- Предположим счёт:
UPDATE accounts SET balance = 500.00 WHERE name = 'Alice';

-- Terminal 1 (READ COMMITTED):
-- BEGIN;
-- SELECT balance FROM accounts WHERE name = 'Alice' FOR UPDATE;
-- -- проверка и UPDATE balance = balance - 300;
-- COMMIT;

-- Terminal 2 (READ COMMITTED):
-- BEGIN;
-- SELECT balance FROM accounts WHERE name = 'Alice' FOR UPDATE;
-- -- проверка и UPDATE balance = balance - 300;
-- COMMIT;

-- При правильном использовании FOR UPDATE один из терминалов подождёт другого,
-- и баланс не уйдёт в минус (сериализация по строке).

-- Для разных isolation level можно повторить эксперименты с READ COMMITTED / SERIALIZABLE.

------------------------------------------------------------
-- 4. Independent Exercise 4
-- Sells(shop, product, price): MAX < MIN example
------------------------------------------------------------

-- Аналогия с products:
-- Joe как-то так:
-- BEGIN;
-- UPDATE products SET price = 100 WHERE shop = 'Joe''s Shop' AND product = 'Coke';
-- -- ещё не COMMIT

-- Sally:
-- SELECT MAX(price), MIN(price) FROM products WHERE shop = 'Joe''s Shop';
-- -- может увидеть странное сочетание при несогласованных обновлениях без транзакций.

-- Правильный вариант: оба используют явные транзакции и нужный уровень изоляции,
-- тогда Sally увидит либо старые, либо новые данные, но не «смесь».

------------------------------------------------------------
-- 5. Questions for Self-Assessment (short answers)
------------------------------------------------------------

/*
1. ACID:
   A – атомарность: перевод денег либо полностью, либо нет;
   C – согласованность: не нарушаются ограничения (баланс не уходит в минус и т.п.);
   I – изоляция: параллельные транзакции не «видят» незаконченные изменения друг друга;
   D – долговечность: после COMMIT данные сохраняются даже при сбое.

2. COMMIT фиксирует изменения, ROLLBACK отменяет все изменения с начала транзакции.

3. SAVEPOINT используется, когда нужно откатить только часть действий в рамках одной транзакции.

4. READ UNCOMMITTED < READ COMMITTED < REPEATABLE READ < SERIALIZABLE
   по уровню защиты от грязных/повторных/фантомных чтений.

5. Dirty read – чтение незакоммиченных изменений; допускается на уровне READ UNCOMMITTED.

6. Non-repeatable read – повторное чтение той же строки даёт другой результат,
   если другая транзакция изменила и закоммитила эту строку между чтениями
   (READ COMMITTED это допускает).

7. Phantom read – при повторном запросе по тем же условиям появляются новые строки.
   Предотвращает SERIALIZABLE.

8. READ COMMITTED обычно выбирают в нагруженных системах, потому что
   он даёт меньше блокировок и конфликтов, чем SERIALIZABLE.

9. Транзакции позволяют «склеить» набор операций в одну логическую единицу
   и защитить данные от конфликтов при параллельном доступе.

10. Все незакоммиченные изменения откатываются (как ROLLBACK), коммитнутые – сохраняются.
*/