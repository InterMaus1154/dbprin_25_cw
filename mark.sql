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

CREATE OR REPLACE FUNCTION update_vehicle_safe()
    RETURNS TRIGGER AS
$$
BEGIN
    REFRESH MATERIALIZED VIEW vehicle_safe;
    RETURN NULL;
END;
$$
    LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tgr_update_vehicle_safe
    AFTER INSERT OR UPDATE OR DELETE
    ON vehicles
    FOR EACH STATEMENT
EXECUTE FUNCTION update_vehicle_safe();

-- Show MOTs that are either expired, or will expire in the next 7 or 30 days
-- For identificiation it includes vehicle reg, customer full name, and customer contact number, as well as the expiry date
WITH latest_mot AS (SELECT vec_id,
                           ROW_NUMBER() OVER (
                               PARTITION BY vec_id
                               ORDER BY expiry_date DESC
                               ) AS rank
                    FROM mot_results
                    WHERE expiry_date <= CURRENT_DATE)
SELECT v.vec_reg                                  AS "Registration",
       CONCAT_WS(' ', c.cust_fname, c.cust_lname) AS "Customer",
       c.cust_contact_num                         AS "Contact Number",
       mt.expiry_date                             AS "Expiry",
       CASE
           WHEN mt.expiry_date <= CURRENT_DATE THEN 'EXPIRED'
           WHEN mt.expiry_date <= CURRENT_DATE + INTERVAL '7 days' THEN 'EXPIRE IN 7 DAYS'
           WHEN mt.expiry_date <= CURRENT_DATE + INTERVAL '30 days' THEN 'EXPIRE IN 30 DAYS'
           END                                    AS "Status"
FROM latest_mot mt
         JOIN vehicle_safe v
              USING (vec_id)
         JOIN customer_safe c
              USING (cust_id)
WHERE mt.rank = 1
ORDER BY expiry_date ASC, "Status" ASC;

-- performance per branch in the last 60 days
-- with more than 10 bookings
SELECT b.branch_name                   AS "Branch",
       CONCAT('£', SUM(inv.inv_final)) AS "Total Income",
       COUNT(bk_subq.booking_id)       AS "No. of Bookings",
       ROUND(COUNT(CASE WHEN inv.inv_status = 'OVERDUE' THEN 1 END) * 100.0 / COUNT(bk_subq.booking_id),
             2)                        AS "Overdue Payments %",
       COUNT(CASE WHEN j.job_status = 'COMPLETED' THEN 1 END) AS "No. of Jobs Completed"
FROM branches b
         JOIN (SELECT *
               FROM bookings
               WHERE booking_date <= CURRENT_DATE - INTERVAL '60 days') AS bk_subq ON bk_subq.branch_id = b.branch_id
         LEFT JOIN invoices inv
                   USING (booking_id)
         JOIN booking_services bs
              USING (booking_id)
         JOIN jobs j
                USING (booking_service_id)
GROUP BY b.branch_name, b.branch_id
HAVING COUNT(bk_subq.booking_id) > 10
ORDER BY "Total Income" DESC,
         "No. of Bookings" DESC,
         "Overdue Payments %" DESC;

-- WITH filtered_bookings AS (
--     SELECT *
--     FROM bookings
--     WHERE booking_date <= CURRENT_DATE - INTERVAL '60 days'
-- ),
--     invoice_data AS (
--         SELECT booking_id,
--                SUM(inv_final) AS total_inv,
--                COUNT(CASE WHEN inv_status = 'OVERDUE' THEN 1 END) AS overdue_count
--         FROM invoices
--         GROUP BY booking_id
--     );

