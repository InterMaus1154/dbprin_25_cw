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

CREATE TABLE part_suppliers;

CREATE TABLE packages;

CREATE TABLE services;

CREATE TABLE package_services;

CREATE TABLE service_discounts;

CREATE TABLE memberships;

CREATE TABLE membership_services;

CREATE TABLE customers;

CREATE TABLE emergency_contacts;

CREATE TABLE vehicle_brands;

CREATE TABLE vehicles;

CREATE TABLE branches;

CREATE TABLE bays;

CREATE TABLE staff;

CREATE TABLE staff_schedule;

CREATE TABLE staff_certifications;

CREATE TABLE branch_managers;

CREATE TABLE roles;

CREATE TABLE staff_roles;

CREATE TABLE bay_inspections;

CREATE TABLE bookings;

CREATE TABLE invoices;

CREATE TABLE installments;

CREATE TABLE refunds;

CREATE TABLE booking_services;

CREATE TABLE jobs;

CREATE TABLE additional_services;

CREATE TABLE branch_parts;

CREATE TABLE part_usage;

CREATE TABLE part_transfers;

CREATE TABLE mot_results;

CREATE TABLE customer_feedbacks;

CREATE TABLE feedback_replies;