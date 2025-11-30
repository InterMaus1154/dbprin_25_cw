-- QUERY 1
-- Show MOTs that are either expired, or will expire in the next 7 or 30 days
-- For identification it includes vehicle reg, customer full name, and customer contact number, as well as the expiry date
WITH latest_mot AS (SELECT vec_id,
                           expiry_date,
                           ROW_NUMBER() OVER (
                               PARTITION BY vec_id
                               ORDER BY expiry_date DESC
                               ) AS rank
                    FROM mot_results
                    WHERE expiry_date <= CURRENT_DATE + INTERVAL '30 days')
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
ORDER BY expiry_date DESC, "Status" ASC;

-- END QUERY 1

-- QUERY 2
-- performance per branch in the year of 2025
-- ranking over branches based on total income (includes already paid, and unpaid invoices)
-- total number of bookings
-- total income per branch, paid invoices only
-- % of invoices that are unpaid, compared to total count of invoices per branch
-- missing (unpaid) invoices in GBP
-- total jobs completed in the branch
-- the staff who completed the most number of jobs
-- the number of jobs completed by that staff,
-- ordered by the branch rank, from highest to lowest
WITH filtered_bookings AS (SELECT booking_id, branch_id
                           FROM bookings
                           WHERE booking_date >= '2025-01-01'
                             AND booking_date <= '2025-12-31'),
     invoice_data AS (SELECT booking_id,
                             SUM(inv_final) FILTER ( WHERE inv_status = 'PAID' ) AS paid_inv_final,
                             SUM(inv_final) FILTER (WHERE inv_status != 'PAID')  AS due_inv_final,
                             COUNT(*)                                            AS total_invoices,
                             COUNT(*) FILTER (WHERE inv_status != 'PAID')        AS due_count
                      FROM invoices
                      GROUP BY booking_id),
     job_data AS (SELECT bs.booking_id AS booking_id,
                         COUNT(*)      AS completed_jobs
                  FROM booking_services bs
                           JOIN jobs j
                                ON j.booking_service_id = bs.booking_service_id
                  WHERE j.job_status = 'COMPLETED'
                    AND j.job_end >= '2025-01-01'
                    AND j.job_end <= '2025-12-31'
                  GROUP BY bs.booking_id),
     staff_data AS (SELECT s.branch_id,
                           j.staff_id,
                           COUNT(*) AS staff_jobs_no
                    FROM jobs j
                             JOIN staff s
                                  USING (staff_id)
                    WHERE j.job_status = 'COMPLETED'
                      AND j.job_end >= '2025-01-01'
                      AND j.job_end <= '2025-12-31'
                    GROUP BY s.branch_id, j.staff_id),
     top_staff AS (SELECT branch_id, staff_id, staff_jobs_no
                   FROM (SELECT branch_id,
                                staff_id,
                                staff_jobs_no,
                                ROW_NUMBER() OVER (
                                    PARTITION BY branch_id
                                    ORDER BY staff_jobs_no DESC
                                    ) AS rn
                         FROM staff_data) ranked
                   WHERE rn = 1)
SELECT RANK()
       OVER (ORDER BY SUM(COALESCE(id.paid_inv_final, 0) + COALESCE(id.due_inv_final, 0)) DESC) AS "Branch Total Income Rank",
       CONCAT_WS(' ', b.branch_code, b.branch_name)                                             AS "Branch",
       COUNT(DISTINCT fb.booking_id)                                                            AS "No. of Branch Bookings",
       COALESCE(ROUND(SUM(paid_inv_final), 2), 0)                                               AS "Total Branch Income (GBP)",
       CONCAT(COALESCE(ROUND(SUM(id.due_count) * 100.00 / NULLIF(SUM(id.total_invoices), 0), 2),
                       0),
              '%')                                                                              AS "Unpaid Invoices / Total Invoices (%)",
       COALESCE(ROUND(SUM(id.due_inv_final), 2), 0)                                             AS "Missing Income from Unpaid Invoices (GBP)",
       COALESCE(SUM(jd.completed_jobs), 0)                                                      AS "Total Completed Branch Jobs",
       COALESCE(MAX(CONCAT_WS(' ', s.staff_fname, s.staff_lname)),
                'N/A')                                                                          AS "Most Jobs Completed By",
       COALESCE(MAX(ts.staff_jobs_no), 0)                                                       AS "Staff Completed Jobs"
FROM branches b
         LEFT JOIN filtered_bookings fb
                   ON fb.branch_id = b.branch_id
         LEFT JOIN invoice_data id
                   ON id.booking_id = fb.booking_id
         LEFT JOIN job_data jd
                   ON jd.booking_id = fb.booking_id
         LEFT JOIN top_staff ts
                   ON ts.branch_id = b.branch_id
         LEFT JOIN staff s
                   ON s.staff_id = ts.staff_id
GROUP BY b.branch_name, b.branch_code
ORDER BY "Branch Total Income Rank",
         "No. of Branch Bookings" DESC,
         "Total Branch Income (GBP)" DESC;

-- Query 3
SELECT
    -- Customer Info (cust email and name to send reminders abour mship)
    c.cust_id                               as id,
    c.cust_fname || ' ' || c.cust_lname     as name,
    c.cust_email                            as email,
    -- Spend Metrics ( check avg price and overall price cust spends)
    COALESCE(SUM(i.inv_final), 0)           as total_spend,
    COUNT(DISTINCT b.booking_id)            as visits,
    ROUND(COALESCE(AVG(i.inv_final), 0), 2) as avg_invoice,
    -- Last Visit ( check frequency of how often cust comes)
    MAX(b.booking_date)                     as last_visit,
    CURRENT_DATE - MAX(b.booking_date)      as days_ago,
    -- Membership (clear overview of who has one or not )
    CASE
        WHEN c.mship_id IS NOT NULL
            AND c.mship_end_date >= CURRENT_DATE THEN 'ACTIVE'
        WHEN c.mship_id IS NOT NULL
            AND c.mship_end_date < CURRENT_DATE THEN 'EXPIRED'
        ELSE 'NONE'
        END                                 as mship_status,
    m.mship_name                            as mship_type,
    -- Tier (good for checking which customer is spending the most)
    CASE
        WHEN COALESCE(SUM(i.inv_final), 0) >= 2000 THEN 'PLATINUM'
        WHEN COALESCE(SUM(i.inv_final), 0) >= 1000 THEN 'GOLD'
        WHEN COALESCE(SUM(i.inv_final), 0) >= 500 THEN 'SILVER'
        ELSE 'BRONZE'
        END                                 as tier,
    -- Status ( good for setting up email reminders when at risk or inactive)
    CASE
        WHEN MAX(b.booking_date) >= CURRENT_DATE - INTERVAL '90 days' THEN 'ACTIVE'
        WHEN MAX(b.booking_date) >= CURRENT_DATE - INTERVAL '180 days' THEN 'AT_RISK'
        WHEN MAX(b.booking_date) IS NOT NULL THEN 'INACTIVE'
        ELSE 'NEW'
        END                                 as status,
    -- Upsell Opportunity (good for receptionists to know so they can sell to customer at appointment)
    CASE
        WHEN c.mship_id IS NULL
            AND COUNT(DISTINCT b.booking_id) >= 3
            AND COALESCE(SUM(i.inv_final), 0) >= 500 THEN 'YES'
        ELSE 'NO'
        END                                 as upsell
FROM customers c
         LEFT JOIN vehicles v ON c.cust_id = v.cust_id
         LEFT JOIN bookings b ON v.vec_id = b.vec_id
         LEFT JOIN invoices i ON b.booking_id = i.booking_id
         LEFT JOIN memberships m ON c.mship_id = m.mship_id
GROUP BY c.cust_id,
         c.cust_fname,
         c.cust_lname,
         c.cust_email,
         c.cust_contact_num,
         c.mship_id,
         c.mship_end_date,
         m.mship_name
ORDER BY total_spend DESC;

-- Query 4
-- Branch Level Workload
SELECT b.branch_name,
       COUNT(DISTINCT s.staff_id)                                                   as total_staff,
       COUNT(j.job_id)                                                              as total_jobs,
       ROUND(COUNT(j.job_id) :: NUMERIC / NULLIF(COUNT(DISTINCT s.staff_id), 0), 0) as avg_jobs_per_staff,
       COUNT(j.job_id) FILTER ( WHERE j.job_status = 'SCHEDULED' )                  as pending_jobs,
       COUNT(j.job_id) FILTER ( WHERE j.job_status = 'IN_PROGRESS' )                as active_jobs
FROM branches b
         INNER JOIN staff s ON b.branch_id = s.branch_id
         LEFT JOIN jobs j ON s.staff_id = j.staff_id
GROUP BY b.branch_name
ORDER BY total_jobs DESC;

-- Query 5
SELECT p.part_name,
       pc.part_cat_name,
       bp.branch_id,
       bp.quantity,
       ps.unit_cost,
       s.sup_name
FROM branch_parts bp
         JOIN parts p ON bp.part_id = p.part_id
         JOIN part_categories pc ON p.part_cat_id = pc.part_cat_id
         JOIN part_suppliers ps ON p.part_id = ps.part_id
         JOIN suppliers s ON ps.sup_id = s.sup_id
WHERE bp.quantity < 10 -- Threshold for low stock, will change for more realistic qty
  AND s.is_active = TRUE
ORDER BY bp.quantity ASC,
         ps.unit_cost DESC;


-- Query 6
-- A simple example query, that can be run as a data_analyst, using the views they have access to
-- For each part, find the active supplier that supplies it with the lowest unit cost
SELECT CONCAT_WS(': ', part_id, part_name) AS "Part",
       MIN(unit_cost)                      AS "Unit Cost £",
       MAX(sup_name)                       AS "Supplier",
       CASE
           WHEN BOOL_OR(is_active) THEN 'Supplying'
           ELSE 'Not supplying'
           END                             AS "Is active supplier?"
FROM supplier_analyst
         JOIN part_suppliers
              USING (sup_id)
         JOIN parts
              USING (part_id)
GROUP BY part_id, part_name
ORDER BY part_id;

-- Query 7
-- Another simple example as a data analyst
-- Showing the number of bookings, where customer left a feedback
-- Including percentage
WITH booking_count_with_feedbacks -- separately count the bookings with feedbacks
         AS (SELECT COUNT(*) FILTER ( WHERE EXISTS (SELECT 1
                                                    FROM customer_feedback_analyst cfa
                                                    WHERE cfa.booking_id = b.booking_id) ) as count
             FROM bookings b)
SELECT (SELECT count FROM booking_count_with_feedbacks)       AS "Bookigns with feedbacks",
       CONCAT(ROUND(((SELECT count FROM booking_count_with_feedbacks)::NUMERIC
           / (SELECT count(*) FROM bookings)) * 100, 2), '%') AS "% of bookings with feedback"; -- calculate percentage
