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

-- Branch Level Workload
SELECT b.branch_name,
       COUNT(DISTINCT s.staff_id) as total_staff,
       COUNT(j.job_id)            as total_jobs,
       ROUND(
               COUNT(j.job_id) :: NUMERIC / NULLIF(COUNT(DISTINCT s.staff_id), 0),
               1
       )                          as avg_jobs_per_staff,
       COUNT(
               CASE
                   WHEN j.job_status = 'SCHEDULED' THEN 1
                   END
       )                          as pending_jobs,
       COUNT(
               CASE
                   WHEN j.job_status = 'IN_PROGRESS' THEN 1
                   END
       )                          as active_jobs
FROM branches b
         INNER JOIN staff s ON b.branch_id = s.branch_id
         LEFT JOIN jobs j ON s.staff_id = j.staff_id
GROUP BY b.branch_name
ORDER BY total_jobs DESC;

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
WITH booking_count_with_feedbacks
         AS (SELECT COUNT(*) FILTER ( WHERE EXISTS (SELECT 1
                                                    FROM customer_feedback_analyst cfa
                                                    WHERE cfa.booking_id = b.booking_id) ) as count
             FROM bookings b)
SELECT (SELECT count FROM booking_count_with_feedbacks)       AS "Bookigns with feedbacks",
       CONCAT(ROUND(((SELECT count FROM booking_count_with_feedbacks)::NUMERIC
           / (SELECT count(*) FROM bookings)) * 100, 2), '%') AS "% of bookings with feedback";
