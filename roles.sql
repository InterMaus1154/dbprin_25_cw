-- roles and permissions
-- passwords are just placeholders, the important parts are roles and permisisons
-- super admin -> owner or someone
CREATE USER admin WITH LOGIN SUPERUSER PASSWORD 'admin_1234';

-- general technician role
CREATE ROLE technician;

GRANT
    SELECT, INSERT, UPDATE
    ON bookings TO technician;

GRANT
    SELECT, INSERT, UPDATE, DELETE
    ON booking_packages TO technician;

GRANT
    SELECT, INSERT, UPDATE, DELETE
    ON booking_services TO technician;

GRANT
    SELECT, INSERT, UPDATE
    ON jobs TO technician;

GRANT
    SELECT
    ON bays TO technician;

GRANT
    SELECT
    ON parts TO technician;

GRANT SELECT
    ON part_categories TO technician;

GRANT
    SELECT, INSERT, UPDATE
    ON branch_parts TO technician;

GRANT
    SELECT, INSERT
    ON part_usage TO technician;

GRANT
    SELECT
    ON customer_safe TO technician;

GRANT
    SELECT
    ON service_discounts TO technician;

GRANT
    SELECT
    ON staff_schedule TO technician;

GRANT SELECT
ON roles TO technician;

GRANT SELECT
ON staff_role_detailed TO technician;

GRANT
    SELECT
    ON staff_roles TO technician;

GRANT SELECT
    ON staff_safe TO technician;

GRANT SELECT
    ON services TO technician;

GRANT SELECT
    ON cities TO technician;

GRANT SELECT
ON vehicles TO technician;

GRANT SELECT
ON vehicle_brands TO technician;


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

-- senior technician
GRANT DELETE
    ON bookings TO senior_technician;

GRANT SELECT, INSERT, UPDATE
    ON invoices
    TO senior_technician;

GRANT SELECT, INSERT, UPDATE
    ON installments
    TO senior_technician;

GRANT ALL ON vehicles TO senior_technician;

GRANT SELECT
ON staff_certifications TO senior_technician;

GRANT ALL ON vehicle_brands TO senior_technician;

-- master technician


-- owner can see everything, but cannot create new user or database
-- that is the duty of admins
CREATE USER owner WITH SUPERUSER NOCREATEDB CREATEROLE LOGIN PASSWORD 'owner_1234';

-- managers leaderships
CREATE ROLE general_manager;
CREATE ROLE human_resources;

-- general manager can do all things a master technician can do
GRANT master_technician TO general_manager;

GRANT ALL ON parts TO general_manager;
GRANT ALL ON part_categories TO general_manager;
GRANT ALL ON branch_parts TO general_manager;
GRANT SELECT ON branches TO general_manager;
GRANT ALL ON invoices TO general_manager;
GRANT ALL ON refunds TO general_manager;
GRANT ALL ON staff TO general_manager;
GRANT ALL ON cities TO general_manager;
GRANT ALL ON staff_certifications TO general_manager;
GRANT ALL ON staff_schedule TO general_manager;

-- human resources
GRANT SELECT ON roles TO human_resources;
GRANT ALL ON staff_roles TO human_resources;
GRANT ALL ON staff TO human_resources;
GRANT ALL ON staff_schedule TO human_resources;
GRANT ALL ON staff_certifications TO human_resources;
GRANT ALL ON branch_managers TO human_resources;
GRANT SELECT ON branches TO human_resources;
GRANT SELECT ON cities to human_resources;

-- for serials
GRANT USAGE, SELECT ON SEQUENCE staff_staff_id_seq TO human_resources;
GRANT USAGE, SELECT ON SEQUENCE staff_schedule_schedule_id_seq TO human_resources;
GRANT USAGE, SELECT ON SEQUENCE staff_certifications_staff_cert_id_seq TO human_resources;
GRANT USAGE, SELECT ON SEQUENCE branch_managers_branch_man_id_seq TO human_resources;


-- vehicles_public view: exposes non-sensitive vehicle fields (HIDE vec_vin)
-- Intended for receptionists and mechanics who need reg/model/year but not VIN
CREATE VIEW public.vehicles_public WITH (security_barrier) AS
SELECT vec_id,
       vec_brand_id,
       cust_id,
       vec_model,
       vec_reg,
       vec_year,
       vec_colour,
       vec_fuel_type
FROM vehicles;

-- Grant read access to typical application roles; adjust role names as needed
GRANT
    SELECT
    ON public.vehicles_public TO receptionist,
    mechanic,
    branch_manager;

-- vehicles_full view: exposes all vehicle fields (including vec_vin) for trusted roles
-- WARNING: vec_vin is sensitive; grant this view only to admin/finance roles and audit its use.
CREATE VIEW public.vehicles_full WITH (security_barrier) AS
SELECT vec_id,
       vec_brand_id,
       cust_id,
       vec_model,
       vec_reg,
       vec_year,
       vec_colour,
       vec_vin,
       vec_fuel_type
FROM vehicles;

-- Grant full vehicle read access (including VIN) to admin and finance
GRANT
    SELECT
    ON public.vehicles_full TO admin,
    finance;

-- a data analyst needs to only have access to data that they can use to do calculations, so no personal information is required
-- they only need select permissions, as shouldn't modify data at all
CREATE ROLE data_analyst;

GRANT SELECT
    ON vehicle_analyst TO data_analyst;

GRANT SELECT
    ON vehicle_brands TO data_analyst;

GRANT SELECT
    ON customer_analyst TO data_analyst;

GRANT SELECT
    ON memberships TO data_analyst;

GRANT SELECT
    ON membership_services TO data_analyst;

GRANT SELECT
    ON bookings TO data_analyst;

GRANT SELECT
    ON booking_services TO data_analyst;

GRANT SELECT
    ON services TO data_analyst;

GRANT SELECT
    ON service_discounts TO data_analyst;

GRANT SELECT
    ON additional_services TO data_analyst;

GRANT SELECT
    ON packages TO data_analyst;

GRANT SELECT
    ON booking_packages TO data_analyst;

GRANT SELECT
    ON bay_analyst TO data_analyst;

GRANT SELECT
    ON branch_analyst TO data_analyst;

GRANT SELECT
    ON parts TO data_analyst;

GRANT SELECT
    ON part_categories TO data_analyst;

GRANT SELECT
    ON branch_parts TO data_analyst;

GRANT SELECT
    ON part_suppliers TO data_analyst;

GRANT SELECT
    ON supplier_analyst TO data_analyst;

GRANT SELECT
    ON cities TO data_analyst;

GRANT SELECT
    ON part_transfer_analyst TO data_analyst;

GRANT SELECT
    ON invoices_analyst TO data_analyst;

GRANT SELECT
    ON refund_analyst TO data_analyst;

GRANT SELECT
    ON mot_result_analyst TO data_analyst;

GRANT SELECT
    ON customer_feedback_analyst TO data_analyst;

CREATE ROLE senior_analyst WITH LOGIN PASSWORD 'password123' INHERIT;

GRANT data_analyst TO senior_analyst;
