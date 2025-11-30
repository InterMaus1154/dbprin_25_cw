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

-- show branch stock with part names and branch codes for better readability
-- not MV, as it is updated regularly
CREATE VIEW branch_part_detailed
AS
SELECT b.branch_code AS "Branch Code",
       p.part_name   AS "Part",
       bp.quantity   AS "Quantity"
FROM parts p
         LEFT JOIN branch_parts bp
                   ON bp.part_id = p.part_id
         LEFT JOIN branches b
                   ON b.branch_id = bp.branch_id
ORDER BY b.branch_code;

-- show bookings in the next 7 days, alongside with vehicle registration number
CREATE VIEW next_week_bookings
AS
SELECT booking_id,
       vec_reg,
       branch_id,
       booking_date,
       booking_time,
       booking_comments
FROM bookings
         JOIN vehicles
              USING (vec_id)
WHERE booking_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '7 days'
ORDER BY booking_date ASC, booking_time ASC;

-- show parts with lowest stock (<=20 qty) including branch
CREATE VIEW branch_low_stock
AS
SELECT branch_id,
       branch_code,
       part_id,
       part_name,
       quantity
FROM branch_parts
         JOIN parts
              USING (part_id)
         JOIN branches
              USING (branch_id)
WHERE quantity <= 20
ORDER BY branch_code ASC, quantity ASC;



-- START OF DATA ANALYST VIEWS
-- Views for data_analyst role
-- These views include just minimal data, and excluding as much personal information as possible, since it is not required for analysts to do calculations and statistics

CREATE VIEW vehicle_analyst
AS
SELECT vec_id,
       vec_brand_id,
       cust_id,
       vec_model,
       vec_year,
       vec_fuel_type
FROM vehicles;

CREATE VIEW customer_analyst
AS
SELECT cust_id,
       mship_id,
       mship_start_date,
       mship_end_date,
       mship_auto_renew,
       cust_city -- included for city level groupings if ever required
FROM customers;

CREATE VIEW staff_analyst
AS
SELECT staff_id,
       branch_id,
       staff_city
FROM staff;

CREATE VIEW bay_analyst
AS
SELECT bay_id,
       branch_id,
       bay_capacity
FROM bays;

CREATE VIEW branch_analyst
AS
SELECT branch_id,
       branch_code,
       branch_name,
       branch_city
FROM branches;

CREATE VIEW supplier_analyst
AS
SELECT sup_id,
       sup_name,
       sup_city,
       is_active
FROM suppliers;

-- only completed part transfers
CREATE VIEW part_transfer_analyst
AS
SELECT transfer_id,
       part_id,
       from_branch_id,
       to_branch_id,
       quantity,
       transfer_date
FROM part_transfers
WHERE transfer_status = 'COMPLETED';

CREATE VIEW invoices_analyst
AS
SELECT inv_id,
       booking_id,
       inv_issue_date,
       inv_due_date,
       inv_total,
       inv_discount,
       inv_final,
       inv_status
FROM invoices;

CREATE VIEW refund_analyst
AS
SELECT refund_id,
       inv_id,
       refund_amount
FROM refunds;

CREATE VIEW mot_result_analyst
AS
SELECT mot_res_id,
       booking_id,
       vec_id,
       test_date,
       expiry_date,
       result
FROM mot_results;

CREATE VIEW customer_feedback_analyst
AS
SELECT cust_fb_id,
       cust_id,
       booking_id
FROM customer_feedbacks;

-- END OF DATA ANALYST VIEWS