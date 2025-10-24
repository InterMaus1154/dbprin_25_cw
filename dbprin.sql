CREATE TABLE cities; (
    city_id SERIAL PRIMARY KEY,
    city_name VARCHAR(50) NOT NULL
);

CREATE TABLE suppliers;

CREATE TABLE part_categories;

CREATE TABLE parts;

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