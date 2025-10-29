CREATE TABLE cities (
    city_id SERIAL PRIMARY KEY,
    city_name VARCHAR(50) NOT NULL
);

CREATE TABLE suppliers (
    sup_id SERIAL PRIMARY KEY,
    sup_name VARCHAR(100),
    sup_contact_name VARCHAR(60),
    sup_contact_phone CHAR(15),
    sup_address_first VARCHAR(100),
    sup_address_second VARCHAR(100),
    sup_postcode CHAR(8),
    sup_city INTEGER NOT NULL,
    FOREIGN KEY (sup_city) REFERENCES cities(city_id) 
    is_active BOOLEAN
);

CREATE TABLE part_categories (
    part_cat_id SERIAL PRIMARY KEY,
    part_cat_name VARCHAR(50)
);

CREATE TABLE parts (
    part_id SERIAL PRIMARY KEY,
    part_cat_id INTEGER NOT NULL,
    part_name VARCHAR(100),
    part_description TEXT,
    part_price DECIMAL(10,2)
    FOREIGN KEY (part_cat_id) 
    REFERENCES part_categories(part_cat_id)
);

CREATE TABLE part_suppliers (
    part_id INT REFERENCES parts(part_id),
    sup_id INT REFERENCES suppliers(sup_id),
    unit_cost DECIMAL(10,2) NOT NULL,
    min_order_quantity SMALLINT NOT NULL,
    PRIMARY KEY (part_id, sup_id)
);

CREATE TABLE packages (
    pkg_id SERIAL PRIMARY KEY,
    pkg_name VARCHAR(200) NOT NULL,
    pkg_desc TEXT,
    is_active BOOLEAN
);


CREATE TABLE services (
    serv_id SERIAL PRIMARY KEY,
    serv_name VARCHAR(200) NOT NULL,
    serv_desc TEXT,
    serv_price DECIMAL(10,2) NOT NULL
);

CREATE TABLE package_services (
    pkg_id INT REFERENCES packages(pkg_id), 
    serv_id INT REFERENCES services(serv_id), 
    PRIMARY KEY (pkg_id, serv_id)
);

CREATE TABLE service_discounts (
    disc_id SERIAL PRIMARY KEY,
    serv_id INT REFERENCES services(serv_id),
    disc_amount DECIMAL(6,2) NOT NULL,
    disc_from DATE NOT NULL,
    disc_to DATE NOT NULL,
    is_active BOOLEAN
    )

CREATE TYPE pay_period AS ENUM ('weekly', 'monthly', 'yearly');

CREATE TABLE memberships (
    mship_id SERIAL PRIMARY KEY,
    mship_name VARCHAR(30) NOT NULL,
    mship_description TEXT,
    mship_price DECIMAL(8,2) NOT NULL,
    mship_duration_days SMALLINT NOT NULL,
    mship_pay_period pay_period NOT NULL
);

CREATE TYPE discount_type AS ENUM ('percentage', 'fixed');

CREATE TABLE membership_services (
    mship_id INT REFERENCES memberships(mship_id),
    serv_id INT REFERENCES services(serv_id),
    discount_type discount_type NOT NULL,
    discount_value DECIMAL(6,2) NOT NULL,
    PRIMARY KEY (mship_id, serv_id)
);

CREATE TABLE customers (
    cust_id SERIAL PRIMARY KEY,
    mship_id INT REFERENCES memberships(mship_id),
    mship_start_date DATE,
    mship_end_date DATE,
    mship_auto_renew BOOLEAN,
    cust_fname VARCHAR(50) NOT NULL,
    cust_lname VARCHAR(50) NOT NULL,
    cust_email VARCHAR(150) UNIQUE NOT NULL,
    cust_contact_num CHAR(15),
    cust_address_first VARCHAR(100) NOT NULL,
    cust_address_second VARCHAR(100),
    cust_city INT REFERENCES cities(city_id),
    cust_postcode CHAR(8)
)

CREATE TYPE emg_type AS ENUM ('family', 'friend', 'colleague', 'other');

CREATE TABLE emergency_contacts (
    emg_id SERIAL PRIMARY KEY,
    cust_id INT REFERENCES customers(cust_id),
    emg_type emg_type NOT NULL,
    emg_contact VARCHAR(200) NOT NULL
)

CREATE TABLE vehicle_brands (
    vec_brand_id SERIAL PRIMARY KEY,
    vec_brand_name VARCHAR(50) NOT NULL    
);

CREATE TYPE fuel_type AS ENUM ('petrol', 'diesel', 'electric', 'hybrid', 'other');

CREATE TABLE vehicles (
    vec_id SERIAL PRIMARY KEY,
    vec_brand_id INT REFERENCES vehicle_brands(vec_brand_id),
    cust_id INT REFERENCES customers(cust_id),
    vec_model VARCHAR(50) NOT NULL,
    vec_reg CHAR(7) UNIQUE NOT NULL,
    vec_year SMALLINT,
    vec_colour VARCHAR(10),
    vec_vin CHAR(17) UNIQUE,
    vec_fuel_type fuel_type NOT NULL
);

CREATE TABLE branches (
    branch_id SERIAL PRIMARY KEY,
    branch_name VARCHAR(100) NOT NULL,
    branch_phone CHAR(15),
    branch_email VARCHAR(200),
    branch_address_first VARCHAR(100) NOT NULL,
    branch_address_second VARCHAR(100),
    branch_postcode CHAR(8),
    branch_city INT REFERENCES cities(city_id)
);

CREATE TYPE bay_status AS ENUM ('available', 'occupied', 'maintenance', 'closed');

CREATE TABLE bays (
    bay_id SERIAL PRIMARY KEY,
    branch_id INT REFERENCES branches(branch_id) ON DELETE CASCADE,
    bay_name VARCHAR(50) NOT NULL,
    bay_status bay_status DEFAULT 'available',
    bay_capacity SMALLINT NOT NULL
);

CREATE TABLE staff (
    staff_id SERIAL PRIMARY KEY,
    branch_id INT REFERENCES branches(branch_id),
    staff_fname VARCHAR(50) NOT NULL,
    staff_lname VARCHAR(50) NOT NULL,
    staff_email VARCHAR(200) UNIQUE,
    staff_work_email VARCHAR(200) UNIQUE,
    staff_mobile CHAR(15),
    staff_work_phone CHAR(15),
    staff_address_first VARCHAR(100) NOT NULL,
    staff_address_second VARCHAR(100),
    staff_city INT REFERENCES cities(city_id),
    staff_postcode CHAR(8),
    hired_at DATE NOT NULL
);

CREATE TYPE schedule_day AS ENUM (
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
);

CREATE TABLE staff_schedule (
    schedule_id SERIAL PRIMARY KEY,
    staff_id INT REFERENCES staff(staff_id),
    schedule_day schedule_day NOT NULL,
    schedule_start_time TIME NOT NULL,
    schedule_end_time TIME NOT NULL
);
-- can change to something different if this dont sound right lol --
CREATE TYPE cert_level AS ENUM ('beginner', 'intermediate', 'advanced', 'expert');

CREATE TABLE staff_certifications (
    staff_cert_id SERIAL PRIMARY KEY,
    staff_id INT REFERENCES staff(staff_id),
    cert_level cert_level NOT NULL,
    cert_name VARCHAR(100) NOT NULL
);
 
CREATE TABLE branch_managers (
        branch_man_id SERIAL PRIMARY KEY,
    branch_id INT REFERENCES branches(branch_id) ON DELETE SET NULL,
    staff_id INT REFERENCES staff(staff_id) ON DELETE SET NULL,
    assigned_at DATE,
    is_active BOOLEAN
);


CREATE TABLE roles (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL
);

CREATE TABLE staff_roles (
    role_id INT REFERENCES roles(role_id),
    staff_id INT REFERENCES staff(staff_id),
    PRIMARY KEY (role_id, staff_id)
);

CREATE TYPE ins_status AS ENUM ('passed', 'failed', 'pending', 'in_progress');

CREATE TABLE bay_inspections (
    ins_id SERIAL PRIMARY KEY,
    bay_id INT REFERENCES bays(bay_id),
    inspected_by INT REFERENCES staff(staff_id),
    ins_date DATE NOT NULL,
    ins_status ins_status NOT NULL,
    ins_next_due_date DATE,
    ins_remarks TEXT
);

CREATE TABLE bookings (
    booking_id SERIAL PRIMARY KEY,
    vec_id INT REFERENCES vehicles(vec_id),
    booking_date DATE NOT NULL,
    booking_time TIME NOT NULL,
    booking_comments TEXT
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

CREATE TYPE inst_status AS ENUM ('pending', 'paid', 'overdue', 'cancelled');

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

CREATE TYPE work_status AS ENUM ('assigned', 'in_progress', 'completed', 'cancelled');

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

CREATE TYPE mot_result_enum AS ENUM ('PASS', 'FAIL', 'ADVISORY');

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

CREATE TABLE customer_feedbacks (
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