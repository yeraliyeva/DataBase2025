
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
    ('Bob', 500.00),
    ('Wally', 750.00);

INSERT INTO products (shop, product, price) VALUES
    ('Joe''s Shop', 'Coke', 2.50),
    ('Joe''s Shop', 'Pepsi', 3.00);


SELECT * FROM accounts;
SELECT * FROM products;


BEGIN;
    
    UPDATE accounts SET balance = balance - 100.00 
    WHERE name = 'Alice';

    
    UPDATE accounts SET balance = balance + 100.00 
    WHERE name = 'Bob';
COMMIT;

SELECT * FROM accounts;

/* 3.1
a)
   Alice: 900.00
   Bob: 600.00

b) 
   To ensure ATOMICITY. If money is taken from Alice, it MUST be given to Bob. 
   If the operations are not grouped, a failure after the first update but before 
   the second would result in money simply disappearing from the system.

c) 
   If not in a transaction (autocommit mode), Alice's balance would be reduced to 900.00 
   and saved to the database. The system would crash before crediting Bob. 
   Bob would still have 500.00. The total money in the system would decrease by 100.00, 
   violating data integrity.
*/



BEGIN;
    
    UPDATE accounts SET balance = balance - 500.00 
    WHERE name = 'Alice';

    
    SELECT * FROM accounts WHERE name = 'Alice'; 
   
ROLLBACK;

SELECT * FROM accounts WHERE name = 'Alice';

/* 3.2
a) 
   400.00 (visible only within the current transaction session).

b) 
   900.00 (The state reverts to exactly how it was before BEGIN).

c) 
   1. Error handling: If an error occurs (e.g., insufficient funds, division by zero) during a series of steps.
   2. Logic Checks: If a business rule fails (e.g., user tries to transfer more money than the daily limit).
   3. User Cancellation: If a user cancels a multi-step wizard process before final confirmation.
*/




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

SELECT * FROM accounts;

/* 3.3
a) 
   Alice: 800.00
   Bob:   600.00 (Unchanged from start of Task 3)
   Wally: 850.00

b) 
   Temporarily, yes (within the transaction scope), but in the final state: NO. 
   The `ROLLBACK TO my_savepoint` undid the operation that credited Bob.

c) 
   It allows you to partially handle errors without losing all work done in the transaction. 
   In this case, we kept the deduction from Alice (done before the savepoint) 
   but corrected the destination of the funds without having to restart the debit from Alice.
*/


/* 
NOTE: The following cannot be executed sequentially in a single script to demonstrate effects.
It describes the behavior based on running two Terminals (T1 and T2).
*/


-- T1: BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- T1: SELECT * FROM products WHERE shop = 'Joe''s Shop'; 
--     (T1 sees 2 items: Coke, Pepsi)

-- T2: BEGIN;
-- T2: DELETE FROM products WHERE shop = 'Joe''s Shop';
-- T2: INSERT INTO products VALUES (..., 'Joe''s Shop', 'Fanta', 3.50);
-- T2: COMMIT; 
--     (Changes are now permanently saved to DB)

-- T1: SELECT * FROM products WHERE shop = 'Joe''s Shop';
--     (T1 sees the NEW data: Fanta only. Coke and Pepsi are gone).
-- T1: COMMIT;

-- Scenario B: SERIALIZABLE

-- T1: BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- T1: SELECT * FROM products WHERE shop = 'Joe''s Shop';
--     (T1 sees initial snapshot)

-- T2: BEGIN;
-- T2: DELETE...; INSERT...;
-- T2: COMMIT;

-- T1: SELECT * FROM products WHERE shop = 'Joe''s Shop';
--     (T1 sees OLD data or execution blocks/fails depending on DB engine. 
--      In PostgreSQL Serializable: T1 sees the old data (Snapshot), 
--      but if T1 tries to update this data, it will get a Serialization Error).

/* 3.4
a) 
   Before T2 Commit: Old data (Coke, Pepsi).
   After T2 Commit: New data (Fanta).
   Why: Read Committed reads the latest committed data at the exact moment the SELECT statement runs.

b)
   It typically sees the data as it existed at the start of the transaction (Coke, Pepsi), 
   ignoring T2's changes even after T2 commits.

c) 
   READ COMMITTED offers lower isolation; a query within the transaction sees changes 
   committed by others immediately (Non-Repeatable Reads allowed).
   SERIALIZABLE creates a strict isolation view. It ensures the outcome is as if 
   transactions ran one after another. It prevents Non-Repeatable Reads and Phantoms.
*/




-- T1: BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- T1: SELECT count(*) FROM products; (Say count is 5)

-- T2: INSERT INTO products ... 'Sprite';
-- T2: COMMIT;

-- T1: SELECT count(*) FROM products;

/* 3.5
a) 
   No. In REPEATABLE READ, the transaction holds a snapshot of the data from the 
   first read (or start of transaction in some DBs). The new row ('Sprite') is hidden.

b)
   A phantom read occurs when a transaction executes a query returning a set of rows 
   that satisfy a search condition, but a second transaction inserts/deletes rows 
   that match that condition, causing the first transaction to see a different 
   set of rows if it repeats the query.

c) 
   Strictly speaking, SERIALIZABLE prevents phantoms. 
   (Note: PostgreSQL's implementation of REPEATABLE READ also prevents phantoms, 
   but the SQL standard only strictly requires Serializable to prevent them).
*/




-- T1: BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- T2: UPDATE products SET price = 99.99 ...; (No Commit yet)
-- T1: SELECT * FROM products;

/* 3.6
a) 
   Yes (if the DB supports true Read Uncommitted).
   It is problematic because T2 might ROLLBACK later. T1 is making decisions 
   (calculations, logic) based on a price (99.99) that strictly speaking "never existed".

b)
   Reading data that has been written by another transaction but not yet committed.

c) 
   It compromises data integrity severely. Reports generated might be incorrect, 
   and decisions made on dirty data can lead to financial loss or logical errors 
   if the originating transaction is rolled back.
*/


-- 4. INDEPENDENT EXERCISES

-- Exercise 1: Conditional Transfer (Bob -> Wally $200)
-- Note: Standard SQL requires procedural code (DO block) for IF logic.
-- Logic: Check Bob's balance. If >= 200, update both. Else raise notice.

DO $$
DECLARE
    bob_balance NUMERIC;
BEGIN
   
    SELECT balance INTO bob_balance FROM accounts WHERE name = 'Bob';

    IF bob_balance >= 200.00 THEN
        UPDATE accounts SET balance = balance - 200.00 WHERE name = 'Bob';
        UPDATE accounts SET balance = balance + 200.00 WHERE name = 'Wally';
        RAISE NOTICE 'Transfer successful.';
    ELSE
        RAISE NOTICE 'Insufficient funds. Transfer aborted.';
    END IF;
END $$;



-- Exercise 2: Multiple Savepoints


BEGIN;
    
    INSERT INTO products (shop, product, price) VALUES ('MyStore', 'Tablet', 300.00);
    
    SAVEPOINT sp_inserted;


    UPDATE products SET price = 350.00 WHERE product = 'Tablet';

    SAVEPOINT sp_updated;

   
    DELETE FROM products WHERE product = 'Tablet';


    ROLLBACK TO sp_inserted;

COMMIT;


SELECT * FROM products WHERE product = 'Tablet';

-- Exercise 3: Banking Scenario (Design)

/*
Scenario: Two users (Session A and Session B) try to withdraw $100 from an account 
that has $150.

PROBLEM (Lost Update / Race Condition):
1. A reads balance: 150.
2. B reads balance: 150.
3. A computes 150 - 100 = 50. Updates balance to 50.
4. B computes 150 - 100 = 50. Updates balance to 50.
RESULT: Both withdrew $100 ($200 total), but balance is 50. Bank loses $50.

SOLUTION USING ISOLATION LEVELS:

Method 1: SERIALIZABLE
Sets the isolation level strictly. If B tries to update a row A modified, 
the database throws a serialization error. B must retry the transaction.

Method 2: SELECT FOR UPDATE (Locking)
*/

-- SQL Demonstration (Conceptual Code):
BEGIN;
    
    SELECT balance FROM accounts WHERE name = 'Alice' FOR UPDATE;
    
COMMIT;


-- Exercise 4: The Sally (MAX < MIN) Paradox

/*
Problem: Sally runs two queries:
1. SELECT MAX(price) FROM products; (Result: say 100)
   -- Meanwhile, Joe inserts a new product with price 200 --
2. SELECT MIN(price) FROM products; (Result: 200, because of Joe's insert)

Result: Sally sees MAX (100) < MIN (200). This violates logic.

Fix: Use Transaction Isolation.
If Sally uses SERIALIZABLE or REPEATABLE READ:
1. MAX is 100.
2. Joe inserts 200 (Committed).
3. Sally requests MIN. Because of isolation snapshot, she does NOT see the 200.
   She sees the MIN calculated from the snapshot taken at step 1.
*/


BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    SELECT MAX(price) FROM products;

    SELECT MIN(price) FROM products;
COMMIT;



-- 5. ANSWERS TO SELF-ASSESSMENT QUESTIONS

/*
1. Explain each ACID property with a practical example.
   - Atomic: Transferring money. Either debit and credit both happen, or neither happens.
   - Consistent: Valid database states. You cannot create a bank account with a NULL name if the schema forbids it.
   - Isolated: Two people buying the last plane ticket simultaneously. They shouldn't both be told "Success". One processes, the other waits.
   - Durable: Once the database says "Transaction Saved", if the power plug is pulled 1 second later, the data is still there upon reboot.

2. What is the difference between COMMIT and ROLLBACK?
   - COMMIT: Saves all changes made in the current transaction permanently to the database.
   - ROLLBACK: Discards all changes made in the current transaction (or up to a savepoint) and reverts to the previous state.

3. When would you use a SAVEPOINT instead of a full ROLLBACK?
   - When you have a long, complex transaction and you want to handle a specific error (like a constraint violation on one record) without losing the successful processing of previous records in the same batch.

4. Compare and contrast the four SQL isolation levels.
   - Read Uncommitted: Lowest. Fast, but dangerous (Dirty reads).
   - Read Committed: Default for most DBs. No dirty reads, but data can change between queries.
   - Repeatable Read: Consistent snapshot within transaction. No fuzzy reads.
   - Serializable: Highest. Strict serial execution simulation. Slowest, most errors to handle.

5. What is a dirty read and which isolation level allows it?
   - Reading uncommitted data from another transaction. Allowed by READ UNCOMMITTED.

6. What is a non-repeatable read? Give an example.
   - You read a row (Price = 10). Someone else updates it (Price = 15) and commits. You read it again and get 15. The read was not "repeatable".

7. What is a phantom read? Which isolation levels prevent it?
   - You query for "Items > $100" and get 5 items. Someone inserts a new item costing $200. You query again and get 6 items. The new row is the phantom.
   - Prevented by SERIALIZABLE (and strictly speaking, often handled by Snapshots in Repeatable Read in engines like Postgres).

8. Why might you choose READ COMMITTED over SERIALIZABLE in a high-traffic application?
   - Performance and Concurrency. Serializable locks more resources or causes more transaction failures (serialization anomalies) requiring retries. Read Committed allows more users to work simultaneously with fewer blockages.

9. Explain how transactions help maintain database consistency during concurrent access.
   - They ensure that intermediate, invalid states (like money deducted but not credited) are never visible to other users. They serialize access to critical resources using locks or versioning.

10. What happens to uncommitted changes if the database system crashes?
    - They are lost. Upon restart, the database recovery process (WAL/Undo logs) rolls back any transaction that did not successfully write a COMMIT record to disk before the crash.
*/
