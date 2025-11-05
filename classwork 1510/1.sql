CREATE TABLE restaurant_tables(
    table_id SERIAL PRIMARY KEY,
    table_number TEXT NOT NULL UNIQUE,
    seating_capacity INTEGER NOT NULL  CHECK (seating_capacity BETWEEN 2 AND 12),
    location TEXT NOT NULL CHECK (location IN ('indoor', 'outdoor', 'patio', 'private')),
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    notes TEXT

);

INSERT INTO restaurant_table values
(101, 'caesr salad', 'apperzier', 9.50, NULL, TRUE, 10, 350),

CREATE TABLE menu_items(
    item_id INTEGER PRIMARY KEY,
    item_name TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('', '', '', '')),
    base_price NUMERIC(10, 2) NOT NULL CHECK ( base_price BETWEEN 5 AND 120),
    special_price NUMERIC(10, 2),
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    preparation_time INTEGER CHECK ( preparation_time BETWEEN 5 AND 120),
    calories INTEGER CHECK ( calories BETWEEN 0 AND 5000),
    CONSTRAINT uq_item_cat UNIQUE (item_name, category),
    CONSTRAINT ch
)


INSERT INTO menu_items values
(101, 'caesr salad', 'apperzier', 9.50, NULL, TRUE, 10, 350),