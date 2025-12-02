-- roles and permissions
-- passwords are just placeholders, the important parts are roles and permisisons
-- super admin
CREATE USER admin WITH LOGIN SUPERUSER PASSWORD 'admin_1234';

-- general technician role
CREATE ROLE technician;

GRANT SELECT, INSERT, UPDATE ON bookings TO technician;
GRANT SELECT ON booking_packages TO technician;
GRANT SELECT ON booking_services TO technician;
GRANT SELECT, INSERT, UPDATE ON jobs TO technician;
GRANT SELECT ON bays TO technician;
GRANT SELECT ON parts TO technician;
GRANT SELECT ON part_categories TO technician;
GRANT SELECT, INSERT, UPDATE ON branch_parts TO technician;
GRANT SELECT, INSERT ON part_usage TO technician;
GRANT SELECT ON customer_safe TO technician;
GRANT SELECT ON vehicle_safe TO technician;
GRANT SELECT ON staff_safe TO technician;
GRANT SELECT ON service_discounts TO technician;
GRANT SELECT ON staff_schedule TO technician;
GRANT SELECT ON roles TO technician;
GRANT SELECT ON staff_role_detailed TO technician;
GRANT SELECT ON staff_roles TO technician;
GRANT SELECT ON staff_safe TO technician;
GRANT SELECT ON services TO technician;
GRANT SELECT ON cities TO technician;
GRANT SELECT ON vehicles TO technician;
GRANT SELECT ON vehicle_brands TO technician;
GRANT SELECT ON branches TO technician;

-- sequence permissions for technician
GRANT USAGE, SELECT ON SEQUENCE bookings_booking_id_seq TO technician;
GRANT USAGE, SELECT ON SEQUENCE jobs_job_id_seq TO technician;


-- different technician roles
-- they inherit from each other
CREATE ROLE trainee_technician INHERIT;
CREATE ROLE senior_technician INHERIT;
CREATE ROLE master_technician INHERIT;

GRANT technician TO trainee_technician;
GRANT trainee_technician TO senior_technician;
GRANT senior_technician TO master_technician;

-- different privileges based on different technician levels

-- trainee technician has the most limited access
-- they do not have any additional privilege than technician
-- the name trainee_technician is just used for convenience, but has all the same as "technician"

-- senior technician
GRANT DELETE ON bookings TO senior_technician;
GRANT SELECT, INSERT, UPDATE ON invoices TO senior_technician;
GRANT SELECT, INSERT, UPDATE ON installments TO senior_technician;
GRANT ALL ON vehicle_safe TO senior_technician;
GRANT SELECT ON staff_certifications TO senior_technician;
GRANT ALL ON vehicle_brands TO senior_technician;


-- sequence permissions for senior technician
GRANT USAGE, SELECT ON SEQUENCE invoices_inv_id_seq TO senior_technician;
GRANT USAGE, SELECT ON SEQUENCE installments_inst_id_seq TO senior_technician;
GRANT USAGE, SELECT ON SEQUENCE vehicles_vec_id_seq TO senior_technician;
GRANT USAGE, SELECT ON SEQUENCE vehicle_brands_vec_brand_id_seq TO senior_technician;

-- master technician
GRANT ALL ON mot_results TO master_technician;
GRANT ALL ON staff TO master_technician;
GRANT ALL ON customers TO master_technician;

-- sequence permissions for master technician
GRANT USAGE, SELECT ON SEQUENCE mot_results_mot_res_id_seq TO master_technician;

-- owner can see everything, but cannot create new user or database
-- that is the duty of admins
CREATE USER owner WITH SUPERUSER NOCREATEDB NOCREATEROLE LOGIN PASSWORD 'owner_1234';

-- managers leaderships
CREATE ROLE general_manager;
CREATE ROLE human_resources;

-- general manager can do all things a master technician can do
GRANT master_technician TO general_manager;

GRANT ALL ON parts TO general_manager;
GRANT ALL ON part_categories TO general_manager;
GRANT ALL ON part_transfers TO general_manager;
GRANT ALL ON branch_parts TO general_manager;
GRANT ALL ON invoices TO general_manager;
GRANT ALL ON refunds TO general_manager;
GRANT ALL ON staff TO general_manager;
GRANT ALL ON cities TO general_manager;
GRANT ALL ON staff_certifications TO general_manager;
GRANT ALL ON staff_schedule TO general_manager;
GRANT ALL ON mot_results TO general_manager;
GRANT ALL ON customers TO general_manager;

-- sequence permissions for general manager
GRANT USAGE, SELECT ON SEQUENCE parts_part_id_seq TO general_manager;
GRANT USAGE, SELECT ON SEQUENCE part_categories_part_cat_id_seq TO general_manager;
GRANT USAGE, SELECT ON SEQUENCE refunds_refund_id_seq TO general_manager;
GRANT USAGE, SELECT ON SEQUENCE staff_staff_id_seq TO general_manager;
GRANT USAGE, SELECT ON SEQUENCE cities_city_id_seq TO general_manager;
GRANT USAGE, SELECT ON SEQUENCE staff_certifications_staff_cert_id_seq TO general_manager;
GRANT USAGE, SELECT ON SEQUENCE staff_schedule_schedule_id_seq TO general_manager;
GRANT USAGE, SELECT ON SEQUENCE customers_cust_id_seq TO general_manager;

-- human resources
GRANT SELECT ON roles TO human_resources;
GRANT ALL ON staff_roles TO human_resources;
GRANT ALL ON staff TO human_resources;
GRANT ALL ON staff_schedule TO human_resources;
GRANT ALL ON staff_certifications TO human_resources;
GRANT ALL ON branch_managers TO human_resources;
GRANT SELECT ON branches TO human_resources;
GRANT SELECT ON cities to human_resources;

-- sequence permissions for human resources
GRANT USAGE, SELECT ON SEQUENCE staff_staff_id_seq TO human_resources;
GRANT USAGE, SELECT ON SEQUENCE staff_schedule_schedule_id_seq TO human_resources;
GRANT USAGE, SELECT ON SEQUENCE staff_certifications_staff_cert_id_seq TO human_resources;
GRANT USAGE, SELECT ON SEQUENCE branch_managers_branch_man_id_seq TO human_resources;


-- a data analyst needs to only have access to data that they can use to do calculations, so no personal information is required
-- they only need select permissions, as shouldn't modify data at all
CREATE ROLE data_analyst;

GRANT SELECT ON vehicle_analyst TO data_analyst;
GRANT SELECT ON vehicle_brands TO data_analyst;
GRANT SELECT ON customer_analyst TO data_analyst;
GRANT SELECT ON memberships TO data_analyst;
GRANT SELECT ON membership_services TO data_analyst;
GRANT SELECT ON bookings TO data_analyst;
GRANT SELECT ON booking_services TO data_analyst;
GRANT SELECT ON services TO data_analyst;
GRANT SELECT ON service_discounts TO data_analyst;
GRANT SELECT ON additional_services TO data_analyst;
GRANT SELECT ON packages TO data_analyst;
GRANT SELECT ON booking_packages TO data_analyst;
GRANT SELECT ON bay_analyst TO data_analyst;
GRANT SELECT ON branch_analyst TO data_analyst;
GRANT SELECT ON parts TO data_analyst;
GRANT SELECT ON part_categories TO data_analyst;
GRANT SELECT ON branch_parts TO data_analyst;
GRANT SELECT ON part_suppliers TO data_analyst;
GRANT SELECT ON supplier_analyst TO data_analyst;
GRANT SELECT ON cities TO data_analyst;
GRANT SELECT ON part_transfer_analyst TO data_analyst;
GRANT SELECT ON invoices_analyst TO data_analyst;
GRANT SELECT ON refund_analyst TO data_analyst;
GRANT SELECT ON mot_result_analyst TO data_analyst;
GRANT SELECT ON customer_feedback_analyst TO data_analyst;


CREATE ROLE senior_analyst WITH LOGIN PASSWORD 'password123' INHERIT;

GRANT data_analyst TO senior_analyst;