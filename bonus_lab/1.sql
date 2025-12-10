/*
  Bonus Lab - Advanced DB
  Student: Bektemissov Iskander
  ID: 24B031706
 */

/* Task 1: Transaction Management */
CREATE OR REPLACE FUNCTION process_transfer(
       from_account_number VARCHAR,
       to_account_number VARCHAR,
       amount NUMERIC,
       currency VARCHAR,
       description TEXT
) RETURNS TEXT AS $$

DECLARE
       from_account_balance NUMERIC;
       to_account_balance NUMERIC;
       exchange_rate NUMERIC;
       daily_limit NUMERIC;
       daily_total NUMERIC;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM accounts WHERE account_number = from_account_number AND is_active = TRUE) THEN
       RETURN 'Sender account not found or inactive';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM accounts WHERE account_number = to_account_number AND is_active = TRUE) THEN
       RETURN 'Recipient account not found or inactive';
    END IF;

    IF (SELECT status FROM customers WHERE customer_id = (SELECT customer_id FROM accounts WHERE account_number = from_account_number)) <> 'active' THEN
        RETURN 'Sender account is not active';
    END IF;

    SELECT balance INTO from_account_balance FROM accounts WHERE account_number = from_account_number;
    IF from_account_balance < amount THEN
        RETURN 'Insufficient balance';
    END IF;

    SELECT daily_limit_kzt INTO daily_limit FROM customers WHERE customer_id = (SELECT customer_id FROM accounts WHERE account_number = from_account_number);
    SELECT COALESCE(SUM(amount_kzt), 0) INTO daily_total
    FROM transactions
    WHERE from_account_id = (SELECT account_id FROM accounts WHERE account_number = from_account_number)
    AND DATE(created_at) = CURRENT_DATE;

    IF daily_total + amount > daily_limit THEN
       RETURN 'Exceeds daily transaction limit';
    END IF;

    IF currency != 'KZT' THEN
       SELECT rate INTO exchange_rate FROM exchange_rates WHERE from_currency = currency AND to_currency = 'KZT' AND valid_from <= CURRENT_DATE AND valid_to >= CURRENT_DATE;
       IF exchange_rate IS NULL THEN
          RETURN 'Currency conversion rate not available';
       END IF;
       amount := amount * exchange_rate;
    END IF;

BEGIN
    SELECT balance INTO from_account_balance FROM accounts WHERE account_number = from_account_number FOR UPDATE;
    SELECT balance INTO to_account_balance FROM accounts WHERE account_number = to_account_number FOR UPDATE;

    UPDATE accounts SET balance = balance - amount WHERE account_number = from_account_number;
    UPDATE accounts SET balance = balance + amount WHERE account_number = to_account_number;

    INSERT INTO transactions (from_account_id, to_account_id, amount, currency, exchange_rate, amount_kzt, type, status, created_at, description)
    VALUES ((SELECT account_id FROM accounts WHERE account_number = from_account_number),
            (SELECT account_id FROM accounts WHERE account_number = to_account_number),
            amount,
            currency,
            exchange_rate,
            amount,
            'transfer',
            'completed',
            CURRENT_TIMESTAMP,
            description
    );

COMMIT;
        RETURN 'Transfer completed successfully';
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RETURN 'Transaction failed';
    END;
END;
$$ LANGUAGE plpgsql;

-- Test the procedure
SELECT process_transfer('KZT1234567890', 'KZT0987654321', 50000, 'KZT', 'Payment for services');

/* Task 2: Views for Reporting */
CREATE OR REPLACE VIEW customer_balance_summary AS
SELECT c.customer_id,
       c.full_name,
       a.account_number,
       a.currency,
       a.balance,
       COALESCE((a.balance / e.rate), a.balance) AS balance_kzt,
       c.daily_limit_kzt,
       ROUND((a.balance / c.daily_limit_kzt) * 100, 2) AS daily_limit_utilization
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
LEFT JOIN exchange_rates e ON a.currency = e.from_currency AND e.to_currency = 'KZT'
WHERE a.is_active = TRUE;

SELECT * FROM customer_balance_summary;

CREATE OR REPLACE VIEW daily_transaction_report AS
SELECT DATE(created_at) AS transaction_date,
    type,
       COUNT(*) AS transaction_count,
       SUM(amount_kzt) AS total_volume,
       AVG(amount_kzt) AS avg_amount,
       SUM(amount_kzt) OVER (ORDER BY DATE(created_at)) AS running_total,
       (SUM(amount_kzt) - LAG(SUM(amount_kzt), 1, 0) OVER (ORDER BY DATE(created_at))) / LAG(SUM(amount_kzt), 1, 0) OVER (ORDER BY DATE(created_at)) * 100 AS day_over_day_growth
FROM transactions
WHERE DATE(created_at) = CURRENT_DATE
GROUP BY DATE(created_at), type;

SELECT * FROM daily_transaction_report;

CREATE OR REPLACE VIEW suspicious_activity_view
WITH (security_barrier=true) AS
SELECT t.transaction_id,
t.from_account_id,
t.to_account_id,
t.amount,
t.created_at
FROM transactions t
WHERE t.amount > 500000
   OR EXISTS (
       SELECT 1
       FROM transactions t2
       WHERE t2.from_account_id = t.from_account_id
       AND t2.created_at > t.created_at - INTERVAL '1 hour'
       HAVING COUNT(*) > 10
   )
   OR EXISTS (
       SELECT 1
       FROM transactions t3
       WHERE t3.from_account_id = t.from_account_id
       AND t3.created_at > t.created_at - INTERVAL '1 minute'
       ORDER BY t3.created_at
       LIMIT 2
   );

SELECT * FROM suspicious_activity_view;

CREATE INDEX accounts_account_number_idx ON accounts(account_number);

CREATE INDEX customers_iin_hash_idx ON customers USING HASH (iin);

CREATE INDEX accounts_customer_account_idx ON accounts(customer_id, account_number);

CREATE INDEX accounts_active_idx ON accounts(balance) WHERE is_active = TRUE;

CREATE INDEX audit_log_changes_idx ON audit_log USING GIN (old_values);

CREATE OR REPLACE FUNCTION process_salary_batch(
    company_account_number VARCHAR,
    payments JSONB
) RETURNS JSONB AS $$
DECLARE
       total_batch_amount NUMERIC;
    payment_record JSONB;
    failed_payments JSONB := '[]'::JSONB;
    success_count INT := 0;
    failure_count INT := 0;
BEGIN
    SELECT balance INTO total_batch_amount FROM accounts WHERE account_number = company_account_number FOR UPDATE;
    IF total_batch_amount < (SELECT SUM((payment->>'amount')::NUMERIC) FROM jsonb_array_elements(payments) AS payment) THEN
        RAISE EXCEPTION 'Insufficient funds for salary batch';
    END IF;

    FOR payment_record IN SELECT * FROM jsonb_array_elements(payments)
    LOOP
        BEGIN
            SELECT process_transfer(
                company_account_number,
                (payment_record->>'iin')::VARCHAR,
                (payment_record->>'amount')::NUMERIC,
                'KZT',
                (payment_record->>'description')::TEXT
            );
            success_count := success_count + 1;
        EXCEPTION
            WHEN OTHERS THEN
                failure_count := failure_count + 1;
                failed_payments := failed_payments || jsonb_build_object(
                    'iin', payment_record->>'iin',
                    'error', SQLERRM
                );
        END;
    END LOOP;

    RETURN jsonb_build_object(
        'successful_count', success_count,
        'failed_count', failure_count,
        'failed_details', failed_payments
    );
END;
$$ LANGUAGE plpgsql;

SELECT process_salary_batch(
    'KZT1234567890',
    '[{"iin": "123456789012", "amount": 50000, "description": "Salary for October"},
      {"iin": "234567890123", "amount": 40000, "description": "Salary for October"}]'
);