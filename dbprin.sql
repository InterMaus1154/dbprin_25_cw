CREATE TABLE cities (
    city_id SERIAL PRIMARY KEY,
    city_name VARCHAR(50) NOT NULL
);

CREATE TABLE suppliers (
    sup_id SERIAL PRIMARY KEY,
    sup_name VARCHAR(100) NOT NULL,
    sup_contact_name VARCHAR(60),
    sup_contact_phone CHAR(15),
    sup_company_phone CHAR(15) NOT NULL,
    sup_address_first VARCHAR(100) NOT NULL,
    sup_address_second VARCHAR(100),
    sup_postcode CHAR(8) NOT NULL,
    sup_city INT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (sup_city) REFERENCES cities(city_id)
);

CREATE INDEX idx_supplier_name ON suppliers (sup_name);

CREATE INDEX idx_supplier_location ON suppliers (sup_postcode, sup_city);

CREATE INDEX idx_supplier_city ON suppliers (sup_city);

CREATE TABLE part_categories (
    part_cat_id SERIAL PRIMARY KEY,
    part_cat_name VARCHAR(50) NOT NULL
);

CREATE TABLE parts (
    part_id SERIAL PRIMARY KEY,
    part_cat_id INT NOT NULL,
    part_name VARCHAR(100) NOT NULL,
    part_description TEXT,
    part_price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (part_cat_id) REFERENCES part_categories(part_cat_id)
);

CREATE INDEX idx_part_cat ON parts (part_cat_id);

CREATE INDEX idx_part_name ON parts (part_name);

CREATE TABLE part_suppliers (
    sup_id INT NOT NULL,
    part_id INT NOT NULL,
    unit_cost DECIMAL(10, 2) NOT NULL,
    min_order_quantity SMALLINT CHECK (min_order_quantity > 0),
    FOREIGN KEY (sup_id) REFERENCES suppliers(sup_id),
    FOREIGN KEY (part_id) REFERENCES parts(part_id),
    PRIMARY KEY (part_id, sup_id)
);

CREATE INDEX idx_part_unit_cost_supplier ON part_suppliers (part_id, unit_cost);

CREATE INDEX idx_parts_supplied_by_supplier ON part_suppliers (sup_id);

CREATE TABLE packages (
    pkg_id SERIAL PRIMARY KEY,
    pkg_name VARCHAR(200) NOT NULL,
    pkg_desc TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX idx_package_name ON packages (pkg_name);

CREATE TABLE services (
    service_id SERIAL PRIMARY KEY,
    service_name VARCHAR(200) NOT NULL,
    service_desc TEXT,
    service_price DECIMAL(10, 2) NOT NULL
);

CREATE INDEX idx_service_name ON services (service_name);

CREATE TABLE package_services(
    pkg_id INT NOT NULL,
    service_id INT NOT NULL,
    FOREIGN KEY (pkg_id) REFERENCES packages(pkg_id),
    FOREIGN KEY (service_id) REFERENCES services(service_id),
    PRIMARY KEY (pkg_id, service_id)
);

CREATE TABLE service_discounts (
    disc_id SERIAL PRIMARY KEY,
    service_id INT NOT NULL,
    disc_amount DECIMAL(6, 2) NOT NULL,
    disc_from DATE NOT NULL,
    disc_to DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (service_id) REFERENCES services(service_id)
);

CREATE INDEX idx_service_discount_for_period ON service_discounts (disc_from, disc_to);

CREATE INDEX idx_service_discount_for_service_period ON service_discounts (service_id, disc_from, disc_to);

CREATE TYPE membership_pay_period AS ENUM ('YEARLY', 'MONTHLY', 'WEEKLY');

CREATE TABLE memberships (
    mship_id SERIAL PRIMARY KEY,
    mship_name VARCHAR(30) NOT NULL,
    mship_description TEXT NOT NULL,
    mship_price DECIMAL(8, 2) NOT NULL,
    mship_duration_days SMALLINT NOT NULL,
    mship_pay_period membership_pay_period NOT NULL
);

CREATE INDEX idx_customer_membership_duration ON memberships(mship_price, mship_duration_days);

CREATE TYPE membership_discount_type AS ENUM ('FIXED', 'PERCENT');

CREATE TABLE membership_services (
    mship_id INT NOT NULL,
    service_id INT NOT NULL,
    discount_type membership_discount_type NOT NULL,
    discount_value DECIMAL(6, 2) NOT NULL,
    FOREIGN KEY (mship_id) REFERENCES memberships(mship_id),
    FOREIGN KEY (service_id) REFERENCES services(service_id),
    PRIMARY KEY (mship_id, service_id)
);

CREATE TABLE customers (
    cust_id SERIAL PRIMARY KEY,
    mship_id INT,
    mship_start_date DATE,
    mship_end_date DATE,
    mship_auto_renew BOOLEAN,
    cust_fname VARCHAR(50) NOT NULL,
    cust_lname VARCHAR(50) NOT NULL,
    cust_email VARCHAR(150) NOT NULL UNIQUE,
    cust_contact_num CHAR(15) NOT NULL UNIQUE,
    cust_address_first VARCHAR(100) NOT NULL,
    cust_address_second VARCHAR(100),
    cust_city INT NOT NULL,
    cust_postcode CHAR(8) NOT NULL,
    FOREIGN KEY (mship_id) REFERENCES memberships(mship_id),
    FOREIGN KEY (cust_city) REFERENCES cities(city_id)
);

CREATE INDEX idx_customer_name ON customers (cust_lname, cust_fname);

CREATE INDEX idx_customer_email ON customers (cust_email);

CREATE INDEX idx_customer_postcode_lastname ON customers (cust_postcode, cust_lname);

CREATE TYPE emergency_contact_type AS ENUM ('LANDLINE', 'MOBILE', 'EMAIL');

CREATE TABLE customer_emergency_contacts (
    emg_id SERIAL PRIMARY KEY,
    cust_id INT NOT NULL,
    emg_type emergency_contact_type NOT NULL,
    emg_contact VARCHAR(200) NOT NULL,
    FOREIGN KEY (cust_id) REFERENCES customers(cust_id)
);

CREATE INDEX idx_emergency_contact_customer_id ON customer_emergency_contacts (cust_id);

CREATE TABLE vehicle_brands (
    vec_brand_id SERIAL PRIMARY KEY,
    vec_brand_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TYPE vehicle_fuel_types AS ENUM ('PETROL', 'DIESEL', 'HYBRID', 'ELECTRIC');

CREATE TABLE vehicles (
    vec_id SERIAL PRIMARY KEY,
    vec_brand_id INT NOT NULL,
    cust_id INT NOT NULL,
    vec_model VARCHAR(50) NOT NULL,
    vec_reg CHAR(7) NOT NULL UNIQUE,
    vec_year SMALLINT NOT NULL,
    vec_colour VARCHAR(10),
    vec_vin CHAR(17) NOT NULL UNIQUE,
    vec_fuel_type vehicle_fuel_types NOT NULL,
    FOREIGN KEY (vec_brand_id) REFERENCES vehicle_brands(vec_brand_id),
    FOREIGN KEY (cust_id) REFERENCES customers(cust_id)
);

CREATE INDEX idx_vehicle_customer ON vehicles (cust_id);

CREATE INDEX idx_vehicle_registration_number ON vehicles (vec_reg);

CREATE INDEX idx_vehicle_vin ON vehicles (vec_vin);

CREATE TABLE branches (
    branch_id SERIAL PRIMARY KEY,
    branch_code CHAR(7) NOT NULL UNIQUE,
    branch_name VARCHAR(100) NOT NULL UNIQUE,
    branch_phone CHAR(15) NOT NULL,
    branch_email VARCHAR(200) NOT NULL UNIQUE,
    branch_address_first VARCHAR(100) NOT NULL,
    branch_address_second VARCHAR(100),
    branch_postcode CHAR(8) NOT NULL,
    branch_city INT NOT NULL,
    FOREIGN KEY (branch_city) REFERENCES cities(city_id)
);

CREATE INDEX idx_branch_code ON branches (branch_code);

CREATE INDEX idx_branch_location ON branches (branch_city, branch_postcode);

CREATE INDEX idx_branch_postcode ON branches (branch_postcode);

CREATE TYPE bay_status AS ENUM (
    'AVAILABLE',
    'OCCUPIED',
    'UNDER_MAINTENANCE',
    'RESERVED',
    'INACTIVE'
);

CREATE TABLE bays (
    bay_id SERIAL PRIMARY KEY,
    branch_id INT NOT NULL,
    bay_name VARCHAR(50) NOT NULL,
    bay_status bay_status DEFAULT 'AVAILABLE',
    bay_capacity SMALLINT NOT NULL CHECK (bay_capacity > 0),
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
);

CREATE INDEX idx_branch_bay_status ON bays (branch_id, bay_status);

CREATE TABLE staff (
    staff_id SERIAL PRIMARY KEY,
    branch_id INT NOT NULL,
    staff_code CHAR(11) NOT NULL UNIQUE,
    staff_fname VARCHAR(50) NOT NULL,
    staff_lname VARCHAR(50) NOT NULL,
    staff_email VARCHAR(200) NOT NULL UNIQUE,
    staff_work_email VARCHAR(200) NOT NULL UNIQUE,
    staff_mobile CHAR(15) NOT NULL UNIQUE,
    staff_work_phone CHAR(15) UNIQUE,
    staff_address_first VARCHAR(100) NOT NULL,
    staff_address_second VARCHAR(100),
    staff_city INT NOT NULL,
    staff_postcode CHAR(8) NOT NULL,
    hired_at DATE NOT NULL,
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id),
    FOREIGN KEY (staff_city) REFERENCES cities(city_id)
);

CREATE INDEX idx_staff_branch ON staff (branch_id);

CREATE INDEX idx_staff_code ON staff (staff_code);

CREATE INDEX idx_staff_name ON staff (staff_fname, staff_lname);

CREATE INDEX idx_staff_location ON staff (staff_city, staff_postcode);

CREATE TYPE staff_schedule_day AS ENUM (
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY'
);

CREATE TABLE staff_schedule (
    schedule_id SERIAL PRIMARY KEY,
    staff_id INT NOT NULL,
    schedule_day staff_schedule_day NOT NULL,
    schedule_start_time TIME NOT NULL,
    schedule_end_time TIME NOT NULL,
    CHECK (schedule_start_time < schedule_end_time),
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
);

CREATE TYPE staff_certification_level AS ENUM (
    'TRAINEE',
    'LEVEL_1',
    'LEVEL_2',
    'LEVEL_3',
    'MASTER_TECHNICIAN'
);

CREATE TABLE staff_certifications (
    staff_cert_id SERIAL PRIMARY KEY,
    staff_id INT NOT NULL,
    cert_level staff_certification_level NOT NULL,
    cert_name VARCHAR(100) NOT NULL,
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
);

CREATE TABLE branch_managers (
    branch_man_id SERIAL PRIMARY KEY,
    branch_id INT NOT NULL,
    staff_id INT NOT NULL,
    assigned_at DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id),
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
);

CREATE INDEX idx_branch_manager_branch_active ON branch_managers (branch_id, is_active);

CREATE TABLE roles (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL
);

CREATE TABLE staff_roles (
    role_id INT NOT NULL,
    staff_id INT NOT NULL,
    FOREIGN KEY (role_id) REFERENCES roles(role_id),
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id),
    PRIMARY KEY (role_id, staff_id)
);

CREATE TYPE bay_inspection_status AS ENUM (
    'PENDING',
    'IN_PROGRESS',
    'PASSED',
    'FAILED',
    'REINSPECTION_DUE',
    'CANCELLED'
);

CREATE TABLE bay_inspections (
    inspection_id SERIAL PRIMARY KEY,
    bay_id INT NOT NULL,
    inspected_by INT NOT NULL,
    inspection_date DATE NOT NULL,
    inspection_status bay_inspection_status NOT NULL,
    inspection_next_due_date DATE NOT NULL,
    inspection_remarks TEXT NOT NULL,
    FOREIGN KEY (bay_id) REFERENCES bays(bay_id),
    FOREIGN KEY (inspected_by) REFERENCES staff(staff_id)
);

CREATE INDEX idx_bay_inspection_bay_status ON bay_inspections (bay_id, inspection_status);

CREATE INDEX idx_bay_inspection_bay_next_inspection ON bay_inspections (bay_id, inspection_next_due_date);

CREATE TABLE bookings (
    booking_id SERIAL PRIMARY KEY,
    vec_id INT NOT NULL,
    booking_date DATE NOT NULL,
    booking_time TIME NOT NULL,
    booking_comments TEXT,
    FOREIGN KEY (vec_id) REFERENCES vehicles(vec_id)
);

CREATE INDEX idx_booking_vehicle ON bookings (vec_id);

CREATE INDEX idx_booking_date ON bookings (booking_date);

CREATE TABLE booking_packages(
    booking_id INT NOT NULL,
    pkg_id INT NOT NULL,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
    FOREIGN KEY (pkg_id) REFERENCES packages(pkg_id)
);

CREATE TYPE payment_status AS ENUM ('PAID', 'OVERDUE', 'PENDING');

CREATE TABLE invoices (
    inv_id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL,
    inv_number CHAR(16) UNIQUE NOT NULL,
    -- INV-POGS01-00001
    inv_issue_date DATE NOT NULL,
    inv_due_date DATE NOT NULL,
    inv_total DECIMAL(10, 2),
    inv_discount DECIMAL(10, 2),
    inv_final DECIMAL(10, 2),
    CHECK (inv_issue_date <= inv_due_date),
    CHECK (inv_total > 0),
    CHECK (inv_final > 0),
    CHECK (inv_discount >= 0),
    CHECK (inv_final <= inv_total - inv_discount),
    FOREIGN KEY (booking_id) REFERENCES bookings (booking_id)
);

ALTER TABLE
    invoices
ADD
    COLUMN IF NOT EXISTS inv_status payment_status NOT NULL DEFAULT 'PENDING';

CREATE INDEX idx_invoice_status ON invoices (inv_status);

CREATE INDEX idx_invoice_booking ON invoices (booking_id);

CREATE INDEX idx_invoice_due_date ON invoices (inv_due_date);

CREATE TYPE installment_payment_status AS ENUM ('PAID', 'OVERDUE', 'PENDING', 'CANCELLED');

CREATE TABLE installments (
    inst_id SERIAL PRIMARY KEY,
    inv_id INT NOT NULL,
    inst_number SMALLINT NOT NULL,
    inst_due_date DATE NOT NULL,
    inst_paid_date DATE,
    inst_status installment_payment_status NOT NULL DEFAULT 'PENDING',
    CHECK (inst_number > 0),
    UNIQUE (inv_id, inst_number),
    -- an invoice can't have same installment numbers
    FOREIGN KEY (inv_id) REFERENCES invoices(inv_id)
);

CREATE INDEX idx_installment_status ON installments (inst_status);

CREATE TABLE refunds (
    refund_id SERIAL PRIMARY KEY,
    inv_id INT NOT NULL,
    refunded_by INT NOT NULL,
    refund_amount DECIMAL(10, 2) NOT NULL,
    refund_reason TEXT,
    CHECK (refund_amount > 0),
    FOREIGN KEY (inv_id) REFERENCES invoices (inv_id),
    FOREIGN KEY (refunded_by) REFERENCES staff(stafF_id)
);

CREATE INDEX idx_refund_invoice ON refunds (inv_id);

CREATE TABLE booking_services (
    booking_service_id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL,
    service_id INT NOT NULL,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
    FOREIGN KEY (service_id) REFERENCES services(service_id),
    UNIQUE (booking_id, service_id) -- a booking cant have the same service twice
);

CREATE TYPE job_status AS ENUM (
    'SCHEDULED',
    'IN_PROGRESS',
    'ON_HOLD',
    'COMPLETED',
    'CANCELLED',
    'FAILED'
);

CREATE TABLE jobs (
    job_id SERIAL PRIMARY KEY,
    staff_id INT NOT NULL,
    booking_service_id INT NOT NULL,
    bay_id INT NOT NULL,
    job_assigned_at DATE NOT NULL,
    job_due_at DATE NOT NULL,
    job_start TIMESTAMP,
    job_end TIMESTAMP,
    job_status job_status NOT NULL DEFAULT 'SCHEDULED',
    job_notes TEXT,
    CHECK (job_start < job_end),
    CHECK (job_assigned_at <= job_due_at),
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id),
    FOREIGN KEY (booking_service_id) REFERENCES booking_services(booking_service_id),
    FOREIGN KEY (bay_id) REFERENCES bays (bay_id)
);

CREATE INDEX idx_job_staff_due ON jobs (staff_id, job_due_at);

CREATE INDEX idx_job_staff_status_due ON jobs (staff_id, job_status, job_due_at);

CREATE TABLE additional_services (
    job_id INT NOT NULL,
    service_id INT NOT NULL,
    note TEXT NOT NULL,
    FOREIGN KEY (job_id) REFERENCES jobs(job_id),
    FOREIGN KEY (service_id) REFERENCES services(service_id),
    PRIMARY KEY (job_id, service_id)
);

CREATE TABLE branch_parts (
    branch_id INT NOT NULL,
    part_id INT NOT NULL,
    quantity SMALLINT NOT NULL,
    CHECK (quantity >= 0),
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id),
    FOREIGN KEY (part_id) REFERENCES parts(part_id),
    PRIMARY KEY (branch_id, part_id)
);

CREATE TABLE part_usage (
    job_id INT NOT NULL,
    part_id INT NOT NULL,
    quantity SMALLINT NOT NULL,
    CHECK (quantity > 0),
    FOREIGN KEY (job_id) REFERENCES jobs(job_id),
    FOREIGN KEY (part_id) REFERENCES parts(part_id),
    PRIMARY KEY (job_id, part_id)
);

CREATE TYPE transfer_status AS ENUM (
    'REQUESTED',
    'IN_PROGRESS',
    'COMPLETED',
    'CANCELLED',
    'REJECTED'
);

CREATE TABLE part_transfers (
    transfer_id SERIAL PRIMARY KEY,
    part_id INT NOT NULL,
    from_branch_id INT NOT NULL,
    to_branch_id INT NOT NULL,
    requested_by INT NOT NULL,
    -- staff
    requested_at DATE NOT NULL,
    approved_by INT NOT NULL,
    -- staff
    quantity SMALLINT NOT NULL,
    transfer_date DATE NOT NULL,
    transfer_status transfer_status NOT NULL DEFAULT 'REQUESTED',
    transfer_note TEXT,
    CHECK (from_branch_id <> to_branch_id),
    CHECK (quantity > 0),
    CHECK (requested_at <= transfer_date),
    FOREIGN KEY (part_id) REFERENCES parts(part_id),
    FOREIGN KEY (from_branch_id) REFERENCES branches(branch_id),
    FOREIGN KEY (to_branch_id) REFERENCES branches(branch_id),
    FOREIGN KEY (requested_by) REFERENCES staff(staff_id),
    FOREIGN KEY (approved_by) REFERENCES staff(staff_id)
);

CREATE INDEX idx_part_transfer_status_to_branch ON part_transfers (to_branch_id, transfer_status);

CREATE INDEX idx_part_transfer_status_from_branch ON part_transfers (from_branch_id, transfer_status);

CREATE TYPE mot_result_status AS ENUM (
    'PASS',
    'FAIL',
    'PASS_WITH_DEFECTS',
    'FAIL_DANGEROUS'
);

CREATE TABLE mot_results (
    mot_res_id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL,
    vec_id INT NOT NULL,
    staff_id INT NOT NULL,
    test_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    result mot_result_status NOT NULL,
    mileage_reading INT NOT NULL,
    comments TEXT NOT NULL,
    CHECK (mileage_reading > 0),
    CHECK (test_date < expiry_date),
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
    FOREIGN KEY (vec_id) REFERENCES vehicles(vec_id),
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
);

CREATE INDEX idx_mot_result_vehicle_expiry_date ON mot_results (vec_id, expiry_date DESC);

CREATE INDEX idx_mot_result_test_date ON mot_results (test_date);

CREATE TABLE customer_feedbacks (
    cust_fb_id SERIAL PRIMARY KEY,
    cust_id INT NOT NULL,
    booking_id INT NOT NULL,
    cust_fb_content TEXT NOT NULL,
    FOREIGN KEY (cust_id) REFERENCES customers(cust_id),
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
);

CREATE INDEX idx_customer_feedback_booking ON customer_feedbacks (booking_id);

CREATE TABLE feedback_replies (
    reply_id SERIAL PRIMARY KEY,
    cust_fb_id INT NOT NULL,
    staff_id INT NOT NULL,
    cust_id INT NOT NULL,
    reply_to INT,
    reply_content TEXT NOT NULL,
    FOREIGN KEY (cust_fb_id) REFERENCES customer_feedbacks(cust_fb_id),
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id),
    FOREIGN KEY (cust_id) REFERENCES customers(cust_id),
    FOREIGN KEY (reply_to) REFERENCES feedback_replies(reply_id)
);

CREATE INDEX idx_feedback_replies_feedback ON feedback_replies (cust_fb_id);

CREATE INDEX idx_feedback_replies_parent ON feedback_replies (reply_to);

-- query 1, to review customers spending, membership activity, avg spend per customer, etc 
SELECT
    -- Customer Info (cust email and name to send reminders abour mship)
    c.cust_id as id,
    c.cust_fname || ' ' || c.cust_lname as name,
    c.cust_email as email,
    -- Spend Metrics ( check avg price and overall price cust spends)
    COALESCE(SUM(i.inv_final), 0) as total_spend,
    COUNT(DISTINCT b.booking_id) as visits,
    ROUND(COALESCE(AVG(i.inv_final), 0), 2) as avg_invoice,
    -- Last Visit ( check frequency of how often cust comes)
    MAX(b.booking_date) as last_visit,
    CURRENT_DATE - MAX(b.booking_date) as days_ago,
    -- Membership (clear overview of who has one or not )
    CASE
        WHEN c.mship_id IS NOT NULL
        AND c.mship_end_date >= CURRENT_DATE THEN 'ACTIVE'
        WHEN c.mship_id IS NOT NULL
        AND c.mship_end_date < CURRENT_DATE THEN 'EXPIRED'
        ELSE 'NONE'
    END as mship_status,
    m.mship_name as mship_type,
    -- Tier (good for checking which customer is spending the most)
    CASE
        WHEN COALESCE(SUM(i.inv_final), 0) >= 2000 THEN 'PLATINUM'
        WHEN COALESCE(SUM(i.inv_final), 0) >= 1000 THEN 'GOLD'
        WHEN COALESCE(SUM(i.inv_final), 0) >= 500 THEN 'SILVER'
        ELSE 'BRONZE'
    END as tier,
    -- Status ( good for setting up email reminders when at risk or inactive)
    CASE
        WHEN MAX(b.booking_date) >= CURRENT_DATE - INTERVAL '90 days' THEN 'ACTIVE'
        WHEN MAX(b.booking_date) >= CURRENT_DATE - INTERVAL '180 days' THEN 'AT_RISK'
        WHEN MAX(b.booking_date) IS NOT NULL THEN 'INACTIVE'
        ELSE 'NEW'
    END as status,
    -- Upsell Opportunity (good for receptionists to know so they can sell to customer at appointment)
    CASE
        WHEN c.mship_id IS NULL
        AND COUNT(DISTINCT b.booking_id) >= 3
        AND COALESCE(SUM(i.inv_final), 0) >= 500 THEN 'YES'
        ELSE 'NO'
    END as upsell
FROM
    customers c
    LEFT JOIN vehicles v ON c.cust_id = v.cust_id
    LEFT JOIN bookings b ON v.vec_id = b.vec_id
    LEFT JOIN invoices i ON b.booking_id = i.booking_id
    LEFT JOIN memberships m ON c.mship_id = m.mship_id
GROUP BY
    c.cust_id,
    c.cust_fname,
    c.cust_lname,
    c.cust_email,
    c.cust_contact_num,
    c.mship_id,
    c.mship_end_date,
    m.mship_name
ORDER BY
    total_spend DESC;

-- Branch Level Workload
SELECT
    b.branch_name,
    COUNT(DISTINCT s.staff_id) as total_staff,
    COUNT(j.job_id) as total_jobs,
    ROUND(
        COUNT(j.job_id) :: NUMERIC / NULLIF(COUNT(DISTINCT s.staff_id), 0),
        1
    ) as avg_jobs_per_staff,
    COUNT(
        CASE
            WHEN j.job_status = 'SCHEDULED' THEN 1
        END
    ) as pending_jobs,
    COUNT(
        CASE
            WHEN j.job_status = 'IN_PROGRESS' THEN 1
        END
    ) as active_jobs
FROM
    branches b
    INNER JOIN staff s ON b.branch_id = s.branch_id
    LEFT JOIN jobs j ON s.staff_id = j.staff_id
GROUP BY
    b.branch_name
ORDER BY
    total_jobs DESC;