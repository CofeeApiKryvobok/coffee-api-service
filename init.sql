CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    payment DECIMAL(10, 2) NOT NULL,
    coffee_type VARCHAR(50) NOT NULL
);
