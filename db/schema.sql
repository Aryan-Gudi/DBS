CREATE DATABASE p2p_electricity;
USE p2p_electricity;

-- =========================
-- 1. USER MANAGEMENT
-- =========================

CREATE TABLE roles (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(50) UNIQUE NOT NULL,
    description VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    role_id INT NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    is_active TINYINT(1) DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES roles(role_id)
);

CREATE TABLE user_profiles (
    profile_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNIQUE NOT NULL,
    dob DATE,
    gender VARCHAR(10),
    kyc_verified TINYINT(1) DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE user_addresses (
    address_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    address TEXT,
    city VARCHAR(50),
    state VARCHAR(50),
    pincode VARCHAR(10),
    zone_id INT,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- =========================
-- 2. LOCATION & GRID
-- =========================

CREATE TABLE regions (
    region_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE grid_zones (
    zone_id INT AUTO_INCREMENT PRIMARY KEY,
    region_id INT NOT NULL,
    zone_name VARCHAR(100),
    FOREIGN KEY (region_id) REFERENCES regions(region_id)
);

-- =========================
-- 3. DEVICE MANAGEMENT
-- =========================

CREATE TABLE renewable_sources (
    source_id INT AUTO_INCREMENT PRIMARY KEY,
    source_name VARCHAR(50) UNIQUE
);

CREATE TABLE smart_meters (
    meter_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    zone_id INT,
    serial_number VARCHAR(100) UNIQUE,
    installed_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (zone_id) REFERENCES grid_zones(zone_id)
);

CREATE TABLE energy_sources (
    energy_source_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    source_id INT,
    capacity_kw DECIMAL(10,2),
    installed_date DATE,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (source_id) REFERENCES renewable_sources(source_id)
);

CREATE TABLE energy_storage (
    storage_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    capacity_kwh DECIMAL(10,2),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- =========================
-- 4. ENERGY MANAGEMENT
-- =========================

CREATE TABLE time_slots (
    slot_id INT AUTO_INCREMENT PRIMARY KEY,
    slot_name VARCHAR(50),
    start_time TIME,
    end_time TIME
);

CREATE TABLE energy_production_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    meter_id INT,
    units_generated DECIMAL(10,4),
    log_timestamp DATETIME,
    FOREIGN KEY (meter_id) REFERENCES smart_meters(meter_id)
);

CREATE TABLE energy_consumption_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    meter_id INT,
    units_consumed DECIMAL(10,4),
    log_timestamp DATETIME,
    FOREIGN KEY (meter_id) REFERENCES smart_meters(meter_id)
);

CREATE TABLE demand_forecasts (
    forecast_id INT AUTO_INCREMENT PRIMARY KEY,
    zone_id INT,
    slot_id INT,
    predicted_demand DECIMAL(10,4),
    forecast_date DATE,
    FOREIGN KEY (zone_id) REFERENCES grid_zones(zone_id),
    FOREIGN KEY (slot_id) REFERENCES time_slots(slot_id)
);

-- =========================
-- 5. PRICING
-- =========================

CREATE TABLE tariff_plans (
    tariff_id INT AUTO_INCREMENT PRIMARY KEY,
    zone_id INT,
    base_rate DECIMAL(8,4),
    peak_multiplier DECIMAL(5,2),
    FOREIGN KEY (zone_id) REFERENCES grid_zones(zone_id)
);

-- =========================
-- 6. TRADING SYSTEM
-- =========================

CREATE TABLE energy_listings (
    listing_id INT AUTO_INCREMENT PRIMARY KEY,
    seller_id INT,
    zone_id INT,
    slot_id INT,
    units_available_kwh DECIMAL(10,4) CHECK (units_available_kwh > 0),
    price_per_kwh DECIMAL(8,4),
    status ENUM('active','partially_sold','sold','expired','cancelled') DEFAULT 'active',
    FOREIGN KEY (seller_id) REFERENCES users(user_id),
    FOREIGN KEY (zone_id) REFERENCES grid_zones(zone_id),
    FOREIGN KEY (slot_id) REFERENCES time_slots(slot_id)
);

CREATE TABLE purchase_orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    buyer_id INT,
    listing_id INT,
    units_requested DECIMAL(10,4),
    status ENUM('pending','confirmed','cancelled'),
    FOREIGN KEY (buyer_id) REFERENCES users(user_id),
    FOREIGN KEY (listing_id) REFERENCES energy_listings(listing_id)
);

CREATE TABLE trade_matches (
    match_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    listing_id INT,
    buyer_id INT,
    seller_id INT,
    units_matched_kwh DECIMAL(10,4),
    agreed_price_per_kwh DECIMAL(8,4),
    status ENUM('pending','confirmed','completed','failed'),
    FOREIGN KEY (order_id) REFERENCES purchase_orders(order_id),
    FOREIGN KEY (buyer_id) REFERENCES users(user_id),
    FOREIGN KEY (seller_id) REFERENCES users(user_id)
);

CREATE TABLE contracts (
    contract_id INT AUTO_INCREMENT PRIMARY KEY,
    buyer_id INT,
    seller_id INT,
    start_date DATE,
    end_date DATE,
    terms TEXT,
    FOREIGN KEY (buyer_id) REFERENCES users(user_id),
    FOREIGN KEY (seller_id) REFERENCES users(user_id)
);

CREATE TABLE energy_transfer_logs (
    transfer_id INT AUTO_INCREMENT PRIMARY KEY,
    match_id INT,
    units_transferred DECIMAL(10,4),
    transfer_time DATETIME,
    FOREIGN KEY (match_id) REFERENCES trade_matches(match_id)
);

-- =========================
-- 7. PAYMENT SYSTEM
-- =========================

CREATE TABLE wallets (
    wallet_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNIQUE,
    balance DECIMAL(12,4) DEFAULT 0 CHECK (balance >= 0),
    currency VARCHAR(10) DEFAULT 'INR',
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    match_id INT,
    buyer_id INT,
    seller_id INT,
    amount DECIMAL(12,4),
    platform_fee DECIMAL(8,4),
    tax_amount DECIMAL(8,4),
    net_seller_amount DECIMAL(12,4),
    status ENUM('pending','processing','completed','failed','refunded'),
    FOREIGN KEY (match_id) REFERENCES trade_matches(match_id)
);

CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id INT,
    wallet_id INT,
    amount DECIMAL(12,4),
    type ENUM('debit','credit'),
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id),
    FOREIGN KEY (wallet_id) REFERENCES wallets(wallet_id)
);

CREATE TABLE wallet_recharge_logs (
    recharge_id INT AUTO_INCREMENT PRIMARY KEY,
    wallet_id INT,
    amount DECIMAL(12,4),
    recharge_time DATETIME,
    FOREIGN KEY (wallet_id) REFERENCES wallets(wallet_id)
);

-- =========================
-- 8. RATINGS
-- =========================

CREATE TABLE ratings (
    rating_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id INT,
    rater_id INT,
    rated_id INT,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    review TEXT,
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id)
);

-- =========================
-- 9. NOTIFICATIONS
-- =========================

CREATE TABLE notification_types (
    type_id INT AUTO_INCREMENT PRIMARY KEY,
    type_name VARCHAR(100)
);

CREATE TABLE notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    type_id INT,
    message TEXT,
    is_read TINYINT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (type_id) REFERENCES notification_types(type_id)
);

-- =========================
-- 10. DISPUTES
-- =========================

CREATE TABLE disputes (
    dispute_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id INT,
    user_id INT,
    status ENUM('open','under_review','resolved'),
    resolution TEXT,
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id)
);

-- =========================
-- 11. MONITORING
-- =========================

CREATE TABLE audit_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action TEXT,
    old_data JSON,
    new_data JSON,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE api_request_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    endpoint VARCHAR(255),
    request_payload JSON,
    response_time_ms INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE system_config (
    config_id INT AUTO_INCREMENT PRIMARY KEY,
    config_key VARCHAR(100),
    config_value VARCHAR(255)
);

-- =========================
-- INDEXES
-- =========================

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_listings_status ON energy_listings(status);
CREATE INDEX idx_transactions_buyer ON transactions(buyer_id);

-- =========================
-- TRIGGER
-- =========================

DELIMITER $$

CREATE TRIGGER after_user_insert
AFTER INSERT ON users
FOR EACH ROW
BEGIN
    INSERT INTO wallets(user_id, balance)
    VALUES (NEW.user_id, 0.00);
END$$

DELIMITER ;

-- =========================
-- STORED PROCEDURE
-- =========================

DELIMITER $$

CREATE PROCEDURE ProcessPayment(
    IN p_transaction_id INT,
    IN p_buyer_wallet INT,
    IN p_seller_wallet INT,
    IN p_amount DECIMAL(12,4)
)
BEGIN
    DECLARE buyer_balance DECIMAL(12,4);

    START TRANSACTION;

    SELECT balance INTO buyer_balance
    FROM wallets
    WHERE wallet_id = p_buyer_wallet FOR UPDATE;

    IF buyer_balance >= p_amount THEN
        UPDATE wallets SET balance = balance - p_amount
        WHERE wallet_id = p_buyer_wallet;

        UPDATE wallets SET balance = balance + p_amount
        WHERE wallet_id = p_seller_wallet;

        UPDATE transactions SET status = 'completed'
        WHERE transaction_id = p_transaction_id;

        COMMIT;
    ELSE
        UPDATE transactions SET status = 'failed'
        WHERE transaction_id = p_transaction_id;

        ROLLBACK;
    END IF;

END$$

DELIMITER ;
