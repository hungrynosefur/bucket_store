-- 기존 테이블 삭제
DROP TABLE IF EXISTS Product;
DROP TABLE IF EXISTS Brand;
DROP TABLE IF EXISTS Inventory;
DROP TABLE IF EXISTS `Order`;
DROP TABLE IF EXISTS product_user;
DROP TABLE IF EXISTS OrderDetail;

show tables;

-- 회원 테이블
CREATE TABLE product_user (
    user_id VARCHAR(50) PRIMARY KEY,
    username VARCHAR(100),
    password VARCHAR(255),
    email VARCHAR(100),
    phone VARCHAR(20),
    address VARCHAR(255)
);

-- 브랜드 테이블
CREATE TABLE Brand (
    brand_id VARCHAR(50) PRIMARY KEY,
    brand_name VARCHAR(100),
    shipping_fee DECIMAL(10, 2)
);

-- 상품 테이블
CREATE TABLE Product (
    product_code VARCHAR(50) PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    color VARCHAR(50),
    brand_id varchar(50),
    product_option VARCHAR(100),
    size VARCHAR(10),
    price DECIMAL(10, 2),
    FOREIGN KEY (brand_id) REFERENCES Brand(brand_id)
);

-- 재고 테이블
CREATE TABLE Inventory (
    inventory_id INT AUTO_INCREMENT PRIMARY KEY,
    product_code VARCHAR(50),
    stock_quantity INT,
    FOREIGN KEY (product_code) REFERENCES Product(product_code)
);

-- 주문 테이블
CREATE TABLE `Order` (
    order_id varchar(50) PRIMARY KEY,
    user_id VARCHAR(50),
    order_date DATETIME,
    shipping_address VARCHAR(255),
    order_status VARCHAR(50),
    order_amount DECIMAL(10, 2),
    discount_amount DECIMAL(10, 2),
    shipping_fee DECIMAL(10, 2),
    FOREIGN KEY (user_id) REFERENCES product_user(user_id)
);

-- 주문 상세 테이블
CREATE TABLE OrderDetail (
    order_detail_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id varchar(50),
    product_code VARCHAR(50),
    quantity INT,
    unit_price DECIMAL(10, 2),
    FOREIGN KEY (order_id) REFERENCES `Order`(order_id),
    FOREIGN KEY (product_code) REFERENCES Product(product_code)
);


select * from product_user limit 5;
select * from `order` limit 5;


select * from product;
select * from brand;
select * from `order`;
select * from inventory;
select * from orderdetail;
select * from product_user;

show tables;


-- 3번의 a
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    COUNT(DISTINCT user_id) AS num_users,
    COUNT(order_id) AS num_orders,
    SUM(order_amount) AS total_order_amount,
    SUM(discount_amount) AS total_discount_amount,
    SUM(shipping_fee) AS total_shipping_fee
FROM
    `Order`
GROUP BY
    DATE_FORMAT(order_date, '%Y-%m');

-- 3번의 b
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    COUNT(DISTINCT user_id) AS num_users
FROM
    `Order`
GROUP BY
    DATE_FORMAT(order_date, '%Y-%m')
HAVING
    COUNT(order_id) >= 1;
    
-- 3번의 b-i
SELECT
    COUNT(*) AS num_users
FROM (
    SELECT
        user_id,
        AVG(monthly_order_amount) AS avg_last_3_months
    FROM (
        SELECT
            user_id,
            DATE_FORMAT(order_date, '%Y-%m') AS month,
            SUM(order_amount) AS monthly_order_amount
        FROM
            `Order`
        WHERE
            order_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
        GROUP BY
            user_id,
            DATE_FORMAT(order_date, '%Y-%m')
    ) AS monthly_orders
    GROUP BY
        user_id
) AS avg_orders
WHERE
    avg_last_3_months > 1000000;

-- 3번의 c
SELECT
    COUNT(DISTINCT o.user_id) AS num_users,
    COUNT(o.order_id) AS num_orders,
    SUM(o.order_amount) AS total_order_amount,
    SUM(o.discount_amount) AS total_discount_amount,
    SUM(o.shipping_fee) AS total_shipping_fee
FROM
    `Order` o
JOIN
    OrderDetail od ON o.order_id = od.order_id
JOIN
    Product p ON od.product_code = p.product_code
WHERE
    p.brand_id = 'A'
    AND MONTH(o.order_date) = 3
    AND o.user_id IN (
        SELECT
            user_id
        FROM
            `Order` o2
        JOIN
            OrderDetail od2 ON o2.order_id = od2.order_id
        JOIN
            Product p2 ON od2.product_code = p2.product_code
        WHERE
            p2.brand_id = 'A'
            AND MONTH(o2.order_date) = 3
        GROUP BY
            user_id
        HAVING
            MIN(o2.order_date) = MIN(o2.order_date)
    );
    
    
-- 3번의 d
-- 세션 테이블 생성
CREATE TABLE UserSession (
    session_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(50),
    session_start TIMESTAMP,
    session_end TIMESTAMP,
    page_count INT,
    unique_page_count INT
);

-- 세션 데이터 삽입 (예제 데이터 기반으로 생성)
INSERT INTO UserSession (user_id, session_start, session_end, page_count, unique_page_count)
SELECT
    user_id,
    MIN(access_timestamp) AS session_start,
    MAX(access_timestamp) AS session_end,
    COUNT(*) AS page_count,
    COUNT(DISTINCT page) AS unique_page_count
FROM (
    SELECT
        user_id,
        access_timestamp,
        page,
        IF(TIMESTAMPDIFF(MINUTE, LAG(access_timestamp) OVER (PARTITION BY user_id ORDER BY access_timestamp), access_timestamp) > 30 OR LAG(access_timestamp) OVER (PARTITION BY user_id ORDER BY access_timestamp) IS NULL, 1, 0) AS is_new_session
    FROM
        PageViewLog
) AS session_data
GROUP BY
    user_id,
    is_new_session;

-- 지표 1: 일별 세션 수
SELECT
    DATE(session_start) AS day,
    COUNT(session_id) AS num_sessions
FROM
    UserSession
GROUP BY
    DATE(session_start);

-- 지표 2: 월별 평균 세션 유지 시간
SELECT
    DATE_FORMAT(session_start, '%Y-%m') AS month,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, session_start, session_end)), 2) AS avg_session_duration_minutes
FROM
    UserSession
WHERE
    TIMESTAMPDIFF(MINUTE, session_start, session_end) > 0
GROUP BY
    DATE_FORMAT(session_start, '%Y-%m');

-- 지표 3: 세션별 평균 총 페이지 수 및 유니크 페이지 수
SELECT
    ROUND(AVG(page_count), 2) AS avg_page_count,
    ROUND(AVG(unique_page_count), 2) AS avg_unique_page_count
FROM
    UserSession;




