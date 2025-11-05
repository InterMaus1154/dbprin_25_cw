CREATE TYPE pay_period AS ENUM ('weekly', 'monthly', 'yearly');
CREATE TYPE discount_type AS ENUM ('percentage', 'fixed');
CREATE TYPE emg_type AS ENUM ('family', 'friend', 'colleague', 'other');
CREATE TYPE fuel_type AS ENUM ('petrol', 'diesel', 'electric', 'hybrid', 'other');
CREATE TYPE schedule_day AS ENUM ('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday');
CREATE TYPE cert_level AS ENUM ('beginner', 'intermediate', 'advanced', 'expert');
CREATE TYPE ins_status AS ENUM ('passed', 'failed', 'pending', 'in_progress');
CREATE TYPE inst_status AS ENUM ('pending', 'paid', 'overdue', 'cancelled');
CREATE TYPE work_status AS ENUM ('assigned', 'in_progress', 'completed', 'cancelled');
CREATE TYPE mot_result_enum AS ENUM ('PASS', 'FAIL', 'ADVISORY');


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

CREATE TABLE part_categories (
    part_cat_id SERIAL PRIMARY KEY,
    part_cat_name VARCHAR(50) NOT NULL
);

CREATE TABLE parts (
    part_id SERIAL PRIMARY KEY,
    part_cat_id INT NOT NULL,
    part_name VARCHAR(100) NOT NULL,
    part_description TEXT,
    part_price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (part_cat_id) REFERENCES part_categories(part_cat_id)
);

CREATE TABLE part_suppliers (
    sup_id INT NOT NULL,
    part_id INT NOT NULL,
    unit_cost DECIMAL(10,2) NOT NULL,
    min_order_quantity SMALLINT CHECK (min_order_quantity > 0),
    FOREIGN KEY (sup_id) REFERENCES suppliers(sup_id),
    FOREIGN KEY (part_id) REFERENCES parts(part_id),
    PRIMARY KEY (part_id, sup_id)
);

CREATE TABLE packages (
    pkg_id SERIAL PRIMARY KEY,
    pkg_name VARCHAR(200) NOT NULL,
    pkg_desc TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE services (
    service_id SERIAL PRIMARY KEY,
    service_name VARCHAR(200) NOT NULL,
    service_desc TEXT,
    service_price DECIMAL(10,2) NOT NULL
);

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
    disc_amount DECIMAL(6,2) NOT NULL,
    disc_from DATE NOT NULL,
    disc_to DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (service_id) REFERENCES services(service_id)
);


CREATE TYPE membership_pay_period AS ENUM ('YEARLY', 'MONTHLY', 'WEEKLY');
CREATE TABLE memberships (
    mship_id SERIAL PRIMARY KEY,
    mship_name VARCHAR(30) NOT NULL,
    mship_description TEXT NOT NULL,
    mship_price DECIMAL(8,2) NOT NULL,
    mship_duration_days SMALLINT NOT NULL,
    mship_pay_period membership_pay_period NOT NULL
);

CREATE TYPE membership_discount_type AS ENUM ('FIXED', 'PERCENT');
CREATE TABLE membership_services (
    mship_id INT NOT NULL,
    service_id INT NOT NULL,
    discount_type membership_discount_type NOT NULL,
    discount_value DECIMAL(6,2) NOT NULL,
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


CREATE TYPE emergency_contact_type AS ENUM ('LANDLINE', 'MOBILE', 'EMAIL');
CREATE TABLE emergency_contacts (
    emg_id SERIAL PRIMARY KEY,
    cust_id INT NOT NULL,
    emg_type emergency_contact_type NOT NULL,
    emg_contact VARCHAR(200) NOT NULL,
    FOREIGN KEY (cust_id) REFERENCES customers(cust_id)
);

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

CREATE TYPE bay_status AS ENUM ('AVAILABLE', 'OCCUPIED', 'UNDER_MAINTENANCE', 'RESERVED', 'INACTIVE');
CREATE TABLE bays (
    bay_id SERIAL PRIMARY KEY,
    branch_id INT NOT NULL,
    bay_name VARCHAR(50) NOT NULL,
    bay_status bay_status DEFAULT 'AVAILABLE',
    bay_capacity SMALLINT NOT NULL CHECK (bay_capacity > 0),
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
);

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

CREATE TYPE staff_schedule_day AS ENUM ('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY');
CREATE TABLE staff_schedule (
    schedule_id SERIAL PRIMARY KEY,
    staff_id INT NOT NULL,
    schedule_day staff_schedule_day NOT NULL,
    schedule_start_time TIME NOT NULL,
    schedule_end_time TIME NOT NULL,
    CHECK (schedule_start_time < schedule_end_time),
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
);

CREATE TYPE staff_certification_level AS ENUM ('TRAINEE', 'LEVEL_1', 'LEVEL_2', 'LEVEL_3', 'MASTER_TECHNICIAN');
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

CREATE TYPE bay_inspection_status AS ENUM ('PENDING', 'IN_PROGRESS', 'PASSED', 'FAILED', 'REINSPECTION_DUE', 'CANCELLED');
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

CREATE TABLE bookings (
    booking_id SERIAL PRIMARY KEY,
    vec_id INT NOT NULL,
    booking_date DATE NOT NULL,
    booking_time TIME NOT NULL,
    booking_comments TEXT,
    FOREIGN KEY (vec_id) REFERENCES vehicles(vec_id)
);

CREATE TABLE invoices (
    inv_id SERIAL PRIMARY KEY,
    booking_id INT REFERENCES bookings(booking_id),
    inv_number VARCHAR(10) UNIQUE NOT NULL,
    inv_issue_date DATE NOT NULL,
    inv_due_date DATE NOT NULL,
    inv_total DECIMAL(10,2) NOT NULL,
    inv_discount DECIMAL(10,2),
    inv_final DECIMAL(10,2) NOT NULL
);

CREATE TABLE installments (
    inst_id SERIAL PRIMARY KEY,
    inv_id INT REFERENCES invoices(inv_id),
    inst_number SMALLINT NOT NULL,
    inst_due_date DATE NOT NULL,
    inst_paid_date DATE,
    inst_status inst_status
);

CREATE TABLE refunds (
    refund_id SERIAL PRIMARY KEY,
    inv_id INT REFERENCES invoices(inv_id),
    refunded_by INT REFERENCES staff(staff_id),
    refund_amount DECIMAL(10,2) NOT NULL,
    refund_reason TEXT
);

CREATE TABLE booking_services (
    booking_serv_id SERIAL PRIMARY KEY,
    booking_id INT REFERENCES bookings(booking_id),
    serv_id INT REFERENCES services(serv_id)
);

CREATE TABLE jobs (
    job_id SERIAL PRIMARY KEY,
    staff_id INT REFERENCES staff(staff_id),
    booking_serv_id INT REFERENCES booking_services(booking_serv_id),
    bay_id INT REFERENCES bays(bay_id),
    assigned_at DATE NOT NULL,
    work_start TIMESTAMP,
    work_end TIMESTAMP,
    work_status work_status
);

CREATE TABLE additional_services (
    job_id INT REFERENCES jobs(job_id),
    serv_id INT REFERENCES services(serv_id),
    note TEXT,
    PRIMARY KEY (job_id, serv_id)
);

CREATE TABLE branch_parts (
    branch_id INT REFERENCES branches(branch_id),
    part_id INT REFERENCES parts(part_id),
    quantity SMALLINT,
    PRIMARY KEY (branch_id, part_id)
);

CREATE TABLE part_usage (
    job_id INT REFERENCES jobs(job_id),
    part_id INT REFERENCES parts(part_id),
    quantity INT,
    PRIMARY KEY (job_id, part_id)
);

CREATE TABLE part_transfers (
    transfer_id SERIAL PRIMARY KEY,
    part_id INT REFERENCES parts(part_id),
    from_branch_id INT REFERENCES branches(branch_id),
    to_branch_id INT REFERENCES branches(branch_id),
    requested_by INT REFERENCES staff(staff_id),
    approved_by INT REFERENCES staff(staff_id),
    quantity INT,
    transfer_date DATE
);

CREATE TABLE mot_results (
    mot_res_id SERIAL PRIMARY KEY,
    booking_id INT REFERENCES bookings(booking_id),
    vec_id INT REFERENCES vehicles(vec_id),
    staff_id INT REFERENCES staff(staff_id),
    test_date DATE,
    expiry_date DATE,
    result mot_result_enum,
    mileage_reading INT,
    comments TEXT
);

CREATE TABLE customer_feedback (
    cust_fb_id SERIAL PRIMARY KEY,
    cust_id INT REFERENCES customers(cust_id),
    booking_id INT REFERENCES bookings(booking_id),
    cust_fb_content TEXT
);

CREATE TABLE feedback_replies (
    reply_id SERIAL PRIMARY KEY,
    cust_fb_id INT REFERENCES customer_feedback(cust_fb_id),
    staff_id INT REFERENCES staff(staff_id),
    cust_id INT REFERENCES customers(cust_id),
    reply_to INT REFERENCES feedback_replies(reply_id),
    reply_content TEXT
);

