/*
Task 1

Scenario A
Emma's final balance: 500.00 James's final balance: 300.00

Scenario B
Concert tickets available: 95

Scenario C:
Does Sophie exist in the table? - No
If yes, what is her balance? -----

---------------------------------------------------------------------------------

Task 2
2.1 What value does User A see at T2? - 100
2.2 What value does User A see at T6? - 90
2.3 If User A used SERIALIZABLE instead of READ COMMITTED, what would User A see at
T6? - 100
2.4 What type of read phenomenon occurred in the READ COMMITTED scenario? - Non-Repeatable Read

---------------------------------------------------------------------------------

Task 3
3.1 After COMMIT, even if the power goes out, the data changes are preserved when the system
restarts.
Answer: D
3.2 A transaction transferring money ensures the total amount in all accounts remains the same (no
money created or lost).
Answer: B
3.3 If a transaction fails halfway through, none of its changes are applied to the database.
Answer: A
3.4 Two transactions running at the same time don't interfere with each other's operations.
Answer: C
 */

---------------------------------------------------------------------------------

--Task 4
BEGIN;
UPDATE wallets SET balance = balance - 75.00
    WHERE user_name = 'Emma';
SAVEPOINT after_payment;
UPDATE tickets SET available = available - 1
    WHERE event = 'Theater';
COMMIT;