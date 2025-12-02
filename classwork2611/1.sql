CREATE OR REPLACE FUNCTION calculate_dynamic_discount(order_total NUMERIC, loyalty_points INTEGER)
RETURNS NUMERIC AS $$
DECLARE
       base_discount NUMERIC := 0;
       loyalty_discount NUMERIC := LEAST (loyalty_points / 1000, 10);
BEGIN
    IF order_total > 500000 THEN
       base_discount = 10;
    ELSIF order_total > 100000 THEN
        base_discount = 5;
    END IF;

RETURN order_total * (base_discount + loyalty_discount) / 100;
END;
$$ LANGUAGE plpgsql;

SELECT calculate_dynamic_discount(150000, 500);
SELECT calculate_dynamic_discount(600000, 2500);
SELECT calculate_dynamic_discount(80000, 1000);

CREATE OR REPLACE FUNCTION calculate_shipping_cost(order_total NUMERIC, city VARCHAR DEFAULT 'Almaty')
RETURNS NUMERIC AS $$
BEGIN
    IF order_total >= 50000 THEN
        RETURN 0;
    ELSIF city IN ('Almaty', 'Astana') THEN
        RETURN 2000;
    ELSE
        RETURN 3500;
    END IF;
END
$$ LANGUAGE plpgsql;

SELECT calculate_shipping_cost(30000, 'Almaty');
SELECT calculate_shipping_cost(60000, 'Shymkent');
SELECT calculate_shipping_cost(25000, 'Karaganda');


CREATE OR REPLACE FUNCTION
customer_purchase_stats(p_customer_id INTEGER)
RETURNS TABLE(
       total_orders INTEGER,
       total_spent NUMERIC,
       avg_order_value NUMERIC,
       loyalty_tier VARCHAR
) AS $$
BEGIN
    SELECT
        COUNT(o.order_id),
        SUM(o.total_amount - o.discount_amount),
        AVG(o.total_amount - o.discount_amount),
        CASE
            WHEN SUM(o.total_amount - o.discount_amount) < 500000 THEN 'Bronze'
            WHEN SUM(o.total_amount - o.discount_amount) BETWEEN 500000 AND 1000000 THEN 'Silver'
            WHEN SUM(o.total_amount - o.discount_amount) BETWEEN 1000000 AND 2000000 THEN 'Gold'
            ELSE 'Platinum'
        END
    INTO total_orders, total_spent, avg_order_value, loyalty_tier
    FROM orders o
    WHERE o.customer_id = p.customer_id;

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM customer_purchase_stats(1);
SELECT * FROM customer_purchase_stats(5);

CREATE OR RAPLACE FUNCTION product_performance(p_product_id INTEGER)
       RETURNS TABLE (
            total_sold INTEGER,
            revenue NUMERIC,
            avg_rating NUMERIC,
            review_count INTEGER,
            current_stock INTEGER,
       )AS $$
BEGIN
    SELECT
        SUM(oi.quantity),
        SUM(oi.quantity * oi.price_at_purchase),
        AVG(r.rating),
        COUNT(r.review_id),
        p.stock_quantity
    INTO total_sold, revenue, avg_rating, review_count, current_stock
    FROM order.items oi
    JOIN reviews r ON r.product_id = p_product_id
    JOIN products p ON p.product_id = p_product_id
    WHERE oi.product_id = p_product_id;
 return next;
