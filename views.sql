-- minimal information about customer, including emergency phone numbers if any
DROP MATERIALIZED VIEW IF EXISTS customer_safe;
CREATE MATERIALIZED VIEW IF NOT EXISTS customer_safe
AS
SELECT c.cust_id,
       c.cust_fname,
       c.cust_lname,
       c.cust_email,
       c.cust_contact_num,
       c.cust_postcode,
       STRING_AGG(subq.emg_contact, ', ') AS emergency_numbers
FROM customers c
         LEFT JOIN (SELECT cust_id, emg_contact
                    FROM customer_emergency_contacts
                    WHERE emg_type IN ('LANDLINE', 'MOBILE')) AS subq ON subq.cust_id = c.cust_id
GROUP BY c.cust_id, c.cust_fname, c.cust_lname, c.cust_contact_num, c.cust_postcode;


-- staff roles with role name
-- no need to join if information is required
DROP MATERIALIZED VIEW IF EXISTS staff_role_detailed;
CREATE MATERIALIZED VIEW IF NOT EXISTS staff_role_detailed
AS
SELECT s.staff_id,
       CONCAT_WS(' ', s.staff_fname, s.staff_lname) AS staff_name,
       r.role_id,
       r.role_name
FROM staff s
         JOIN staff_roles
              USING (staff_id)
         JOIN roles r
              USING (role_id)
ORDER BY s.staff_fname ASC, s.staff_lname ASC;

-- active branch managers with branch name and full staff name
DROP MATERIALIZED VIEW IF EXISTS branch_manager_details;
CREATE MATERIALIZED VIEW IF NOT EXISTS branch_manager_details
AS
SELECT s.staff_id,
       CONCAT_WS(' ', s.staff_fname, s.staff_lname) AS staff_name,
       b.branch_id,
       b.branch_code,
       b.branch_name,
       subq.assigned_at                             AS manager_from
FROM staff s
         JOIN (SELECT staff_id, branch_id, assigned_at
               FROM branch_managers
               WHERE is_active = TRUE) AS subq ON s.staff_id = subq.staff_id
         JOIN branches b
              ON b.branch_id = subq.branch_id
ORDER BY b.branch_id ASC;

-- excluding VIN, and joining brand name
CREATE MATERIALIZED VIEW IF NOT EXISTS vehicle_safe
AS
SELECT v.vec_id,
       vb.vec_brand_name,
       v.cust_id,
       v.vec_model,
       v.vec_reg,
       v.vec_year,
       v.vec_colour,
       v.vec_fuel_type
FROM vehicles v
         JOIN vehicle_brands vb
              USING (vec_brand_id);