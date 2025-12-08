
-- Cleanup
DROP MATERIALIZED VIEW IF EXISTS salary_batch_report;
DROP PROCEDURE IF EXISTS process_salary_batch;
DROP PROCEDURE IF EXISTS process_transfer;
DROP FUNCTION IF EXISTS get_exchange_rate;
DROP VIEW IF EXISTS suspicious_activity_view;
DROP VIEW IF EXISTS daily_transaction_report;
DROP VIEW IF EXISTS customer_balance_summary;
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS exchange_rates CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

-- 0: Database Schema

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    iin CHAR(12) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100),
    status VARCHAR(20) CHECK (status IN ('active', 'blocked', 'frozen')) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    daily_limit_kzt NUMERIC(15, 2) DEFAULT 1000000.00
);

CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    account_number VARCHAR(20) NOT NULL UNIQUE,
    currency VARCHAR(3) CHECK (currency IN ('KZT', 'USD', 'EUR', 'RUB')),
    balance NUMERIC(15, 2) DEFAULT 0.00 CHECK (balance >= 0),
    is_active BOOLEAN DEFAULT TRUE,
    opened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP
);

CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    from_account_id INT REFERENCES accounts(account_id),
    to_account_id INT REFERENCES accounts(account_id),
    amount NUMERIC(15, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    exchange_rate NUMERIC(10, 6) DEFAULT 1.0,
    amount_kzt NUMERIC(15, 2),
    type VARCHAR(20) CHECK (type IN ('transfer', 'deposit', 'withdrawal')),
    status VARCHAR(20) CHECK (status IN ('pending', 'completed', 'failed', 'reversed')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    description TEXT
);

CREATE TABLE exchange_rates (
    rate_id SERIAL PRIMARY KEY,
    from_currency VARCHAR(3) NOT NULL,
    to_currency VARCHAR(3) NOT NULL,
    rate NUMERIC(10, 6) NOT NULL,
    valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP
);

CREATE TABLE audit_log (
    log_id SERIAL PRIMARY KEY,
    table_name VARCHAR(50),
    record_id INT,
    action VARCHAR(10),
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(50) DEFAULT CURRENT_USER,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET
);


INSERT INTO customers (iin, full_name, email, status, daily_limit_kzt) VALUES
('111111111111', 'Aliya Nurtas', 'aliya@kbtu.kz', 'active', 500000),
('222222222222', 'Bob Smith', 'bob@kbtu.kz', 'active', 1000000),
('333333333333', 'Carol Danvers', 'carol@test.com', 'active', 1000000),
('444444444444', 'Darkhan Kim', 'darkhan@test.com', 'blocked', 0),
('555555555555', 'Elena Gilbert', 'elena@test.com', 'active', 2000000),
('666666666666', 'KazEnergy Corp', 'payroll@kazenergy.kz', 'active', 900000000),
('777777777777', 'Gennady Golovkin', 'ggg@box.kz', 'active', 5000000),
('888888888888', 'Harry Potter', 'harry@magic.com', 'frozen', 1000000),
('999999999999', 'Ivan Drago', 'ivan@test.com', 'active', 1000000),
('000000000001', 'John Wick', 'john@continental.com', 'active', 500000);

INSERT INTO accounts (customer_id, account_number, currency, balance) VALUES
(1, 'KZ010101', 'KZT', 150000),
(1, 'KZ010102', 'USD', 1000),
(2, 'KZ020201', 'KZT', 500000),
(2, 'KZ020202', 'EUR', 500),
(3, 'KZ030301', 'KZT', 10000),
(4, 'KZ040401', 'KZT', 5000),
(5, 'KZ050501', 'USD', 5000),
(6, 'KZ060601', 'KZT', 500000000),
(7, 'KZ070701', 'KZT', 75000),
(8, 'KZ080801', 'KZT', 200000),
(9, 'KZ090901', 'KZT', 300000),
(10, 'KZ101001', 'RUB', 50000);

INSERT INTO exchange_rates (from_currency, to_currency, rate, valid_to) VALUES
('USD', 'KZT', 485.00, NULL),
('KZT', 'USD', 0.00206, NULL),
('EUR', 'KZT', 510.00, NULL),
('KZT', 'EUR', 0.00196, NULL),
('RUB', 'KZT', 5.50, NULL),
('KZT', 'RUB', 0.18, NULL),
('KZT', 'KZT', 1.0, NULL),
('USD', 'USD', 1.0, NULL),
('EUR', 'EUR', 1.0, NULL),
('RUB', 'RUB', 1.0, NULL);

INSERT INTO transactions (from_account_id, to_account_id, amount, currency, amount_kzt, type, status, created_at) VALUES
(1, 2, 1000, 'KZT', 1000, 'transfer', 'completed', NOW() - INTERVAL '2 days'),
(3, 1, 5000, 'KZT', 5000, 'transfer', 'completed', NOW() - INTERVAL '1 day'),
(1, 3, 2000, 'KZT', 2000, 'transfer', 'completed', NOW()),
(2, 5, 100, 'USD', 48500, 'transfer', 'completed', NOW()),
(6, 1, 50000, 'KZT', 50000, 'deposit', 'completed', NOW() - INTERVAL '5 days'),
(1, 3, 100, 'KZT', 100, 'transfer', 'completed', NOW()),
(1, 3, 100, 'KZT', 100, 'transfer', 'completed', NOW() + INTERVAL '1 second'),
(1, 3, 100, 'KZT', 100, 'transfer', 'completed', NOW() + INTERVAL '2 seconds'),
(5, 2, 100000, 'USD', 48500000, 'transfer', 'failed', NOW()),
(9, 7, 15000, 'KZT', 15000, 'transfer', 'completed', NOW());

INSERT INTO audit_log (table_name, record_id, action, new_values) VALUES
('customers', 1, 'INSERT', '{"iin": "111111111111", "name": "Aliya"}'::jsonb);



CREATE OR REPLACE FUNCTION get_exchange_rate(p_from VARCHAR, p_to VARCHAR)
RETURNS NUMERIC AS $$
DECLARE
    v_rate NUMERIC;
BEGIN
    IF p_from = p_to THEN RETURN 1.0; END IF;

    SELECT rate INTO v_rate FROM exchange_rates
    WHERE from_currency = p_from AND to_currency = p_to
    AND (valid_to IS NULL OR valid_to > NOW())
    ORDER BY valid_from DESC LIMIT 1;

    RETURN COALESCE(v_rate, 0);
END;
$$ LANGUAGE plpgsql;

-- 1: Transaction Management

CREATE OR REPLACE PROCEDURE process_transfer(
    p_from_acc_num VARCHAR,
    p_to_acc_num VARCHAR,
    p_amount NUMERIC,
    p_currency VARCHAR,
    p_description TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_from_id INT; v_to_id INT;
    v_from_bal NUMERIC; v_from_curr VARCHAR;
    v_cust_status VARCHAR; v_daily_limit NUMERIC;
    v_rate_to_kzt NUMERIC; v_amount_kzt NUMERIC;
    v_debit_amt NUMERIC; v_credit_amt NUMERIC;
    v_to_curr VARCHAR; v_daily_spent NUMERIC;
    v_tx_id INT;
BEGIN
    IF p_amount <= 0 THEN RAISE EXCEPTION 'Amount must be positive'; END IF;

    
    SELECT a.account_id, a.balance, a.currency, c.status, c.daily_limit_kzt
    INTO v_from_id, v_from_bal, v_from_curr, v_cust_status, v_daily_limit
    FROM accounts a
    JOIN customers c ON a.customer_id = c.customer_id
    WHERE a.account_number = p_from_acc_num AND a.is_active = TRUE
    FOR UPDATE OF a;

    IF NOT FOUND THEN RAISE EXCEPTION 'Sender account invalid or inactive'; END IF;
    IF v_cust_status IN ('blocked', 'frozen') THEN RAISE EXCEPTION 'Sender is %', v_cust_status; END IF;

   
    SELECT account_id, currency INTO v_to_id, v_to_curr
    FROM accounts WHERE account_number = p_to_acc_num AND is_active = TRUE
    FOR UPDATE;

    IF NOT FOUND THEN RAISE EXCEPTION 'Receiver account invalid or inactive'; END IF;

    
    v_rate_to_kzt := get_exchange_rate(p_currency, 'KZT');
    v_amount_kzt := p_amount * v_rate_to_kzt;
    v_debit_amt := p_amount * get_exchange_rate(p_currency, v_from_curr);
    v_credit_amt := p_amount * get_exchange_rate(p_currency, v_to_curr);

    
    IF v_from_bal < v_debit_amt THEN
        INSERT INTO audit_log (table_name, action, old_values)
        VALUES ('transactions', 'FAIL', jsonb_build_object('reason', 'Insufficient Funds', 'acc', p_from_acc_num));
        RAISE EXCEPTION 'Insufficient funds';
    END IF;

    SELECT COALESCE(SUM(amount_kzt), 0) INTO v_daily_spent
    FROM transactions
    WHERE from_account_id = v_from_id AND type = 'transfer'
    AND status = 'completed' AND created_at::DATE = CURRENT_DATE;

    IF (v_daily_spent + v_amount_kzt) > v_daily_limit THEN
        INSERT INTO audit_log (table_name, action, old_values)
        VALUES ('transactions', 'FAIL', jsonb_build_object('reason', 'Limit Exceeded', 'acc', p_from_acc_num));
        RAISE EXCEPTION 'Daily limit exceeded';
    END IF;

  
    UPDATE accounts SET balance = balance - v_debit_amt WHERE account_id = v_from_id;
    UPDATE accounts SET balance = balance + v_credit_amt WHERE account_id = v_to_id;

    INSERT INTO transactions (from_account_id, to_account_id, amount, currency, amount_kzt, type, status, description, completed_at)
    VALUES (v_from_id, v_to_id, p_amount, p_currency, v_amount_kzt, 'transfer', 'completed', p_description, NOW())
    RETURNING transaction_id INTO v_tx_id;

    INSERT INTO audit_log (table_name, record_id, action, new_values)
    VALUES ('transactions', v_tx_id, 'INSERT', jsonb_build_object('amt', p_amount, 'status', 'success'));
END;
$$;

-- 2: Reporting Views

CREATE OR REPLACE VIEW customer_balance_summary AS
SELECT
    c.full_name,
    a.account_number,
    a.balance,
    a.currency,
    (a.balance * get_exchange_rate(a.currency, 'KZT')) AS total_kzt,
    RANK() OVER (ORDER BY (a.balance * get_exchange_rate(a.currency, 'KZT')) DESC) as wealth_rank,
    COALESCE((
        SELECT SUM(amount_kzt) FROM transactions t
        WHERE t.from_account_id = a.account_id AND t.created_at::DATE = CURRENT_DATE
    ), 0) / NULLIF(c.daily_limit_kzt, 0) * 100 as limit_utilization_pct
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
WHERE a.is_active = TRUE;

CREATE OR REPLACE VIEW daily_transaction_report AS
SELECT
    created_at::DATE as date,
    type,
    COUNT(*) as count,
    SUM(amount_kzt) as volume_kzt,
    SUM(SUM(amount_kzt)) OVER (PARTITION BY created_at::DATE ORDER BY type) as running_total,
    SUM(amount_kzt) - LAG(SUM(amount_kzt)) OVER (PARTITION BY type ORDER BY created_at::DATE) as growth_kzt
FROM transactions
WHERE status = 'completed'
GROUP BY created_at::DATE, type;

CREATE OR REPLACE VIEW suspicious_activity_view WITH (security_barrier = true) AS
SELECT
    t.transaction_id,
    c.full_name,
    t.amount_kzt,
    t.created_at,
    CASE
        WHEN t.amount_kzt > 5000000 THEN 'High Value'
        ELSE 'Rapid Frequency'
    END as flag_reason
FROM transactions t
JOIN accounts a ON t.from_account_id = a.account_id
JOIN customers c ON a.customer_id = c.customer_id
WHERE t.amount_kzt > 5000000
OR EXISTS (
    SELECT 1 FROM transactions t2
    WHERE t2.from_account_id = t.from_account_id
    AND t2.transaction_id != t.transaction_id
    AND ABS(EXTRACT(EPOCH FROM (t.created_at - t2.created_at))) < 60
);

-- 3: Indexing

-- B-Tree for frequent account lookups
CREATE INDEX idx_accounts_number ON accounts USING btree (account_number);

-- Hash for equality checks on type
CREATE INDEX idx_trans_type ON transactions USING hash (type);

-- GIN for querying JSONB audit logs
CREATE INDEX idx_audit_json ON audit_log USING gin (new_values);

-- Partial index for active customers
CREATE INDEX idx_active_customers ON customers (customer_id) WHERE status = 'active';

-- Composite covering index for daily limit checks
CREATE INDEX idx_daily_limit_check ON transactions (from_account_id, type, status, created_at);

-- Expression index for case-insensitive email search
CREATE INDEX idx_email_lower ON customers (LOWER(email));

-- 4: Batch Processing

CREATE OR REPLACE PROCEDURE process_salary_batch(
    p_comp_acc VARCHAR,
    p_batch_data JSONB,
    INOUT p_result JSONB DEFAULT '{}'
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_comp_id INT; v_comp_bal NUMERIC; v_comp_curr VARCHAR;
    v_total_req NUMERIC := 0;
    v_item JSONB; v_iin VARCHAR; v_amt NUMERIC; v_desc TEXT;
    v_emp_id INT; v_emp_curr VARCHAR;
    v_success INT := 0; v_failed INT := 0;
    v_fail_details JSONB[] := ARRAY[]::JSONB[];
    v_error_msg TEXT;
BEGIN
    
    IF NOT pg_try_advisory_xact_lock(hashtext(p_comp_acc)) THEN
        RAISE EXCEPTION 'Batch is already running for this company';
    END IF;

    SELECT account_id, balance, currency INTO v_comp_id, v_comp_bal, v_comp_curr
    FROM accounts WHERE account_number = p_comp_acc FOR UPDATE;

    IF NOT FOUND THEN RAISE EXCEPTION 'Company account not found'; END IF;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_batch_data) LOOP
        v_total_req := v_total_req + (v_item->>'amount')::NUMERIC;
    END LOOP;

    IF v_comp_bal < v_total_req THEN
        RAISE EXCEPTION 'Total batch amount % exceeds balance %', v_total_req, v_comp_bal;
    END IF;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_batch_data) LOOP
        v_iin := v_item->>'iin';
        v_amt := (v_item->>'amount')::NUMERIC;
        v_desc := v_item->>'description';

        BEGIN
            SELECT a.account_id, a.currency INTO v_emp_id, v_emp_curr
            FROM accounts a JOIN customers c ON a.customer_id = c.customer_id
            WHERE c.iin = v_iin AND a.is_active = TRUE LIMIT 1;

            IF v_emp_id IS NULL THEN RAISE EXCEPTION 'Employee not found'; END IF;

            UPDATE accounts SET balance = balance - v_amt WHERE account_id = v_comp_id;

            UPDATE accounts SET balance = balance + (v_amt * get_exchange_rate(v_comp_curr, v_emp_curr))
            WHERE account_id = v_emp_id;

            INSERT INTO transactions (from_account_id, to_account_id, amount, currency, amount_kzt, type, status, description)
            VALUES (v_comp_id, v_emp_id, v_amt, v_comp_curr, (v_amt * get_exchange_rate(v_comp_curr, 'KZT')),
                    'transfer', 'completed', 'SALARY: ' || v_desc);

            v_success := v_success + 1;

        EXCEPTION WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
            v_failed := v_failed + 1;
            v_fail_details := array_append(v_fail_details, jsonb_build_object('iin', v_iin, 'error', v_error_msg));

            INSERT INTO audit_log (table_name, action, new_values)
            VALUES ('batch', 'ERROR', jsonb_build_object('iin', v_iin, 'msg', v_error_msg));
        END;
    END LOOP;

    p_result := jsonb_build_object(
        'status', 'completed',
        'success', v_success,
        'failed', v_failed,
        'errors', to_jsonb(v_fail_details)
    );
END;
$$;

CREATE MATERIALIZED VIEW salary_batch_report AS
SELECT
    t.created_at::DATE as date,
    c.full_name as company,
    SUM(t.amount_kzt) as total_payout
FROM transactions t
JOIN accounts a ON t.from_account_id = a.account_id
JOIN customers c ON a.customer_id = c.customer_id
WHERE t.description LIKE 'SALARY:%'
GROUP BY t.created_at::DATE, c.full_name;



/*
-- Test Transfer
CALL process_transfer('KZ010101', 'KZ020201', 500, 'KZT', 'Lunch');

-- Test Batch
DO $$
DECLARE res JSONB;
BEGIN
    CALL process_salary_batch('KZ060601', '[{"iin":"111111111111", "amount":50000, "description":"Bonus"}]', res);
    RAISE NOTICE '%', res;
END $$;
*/