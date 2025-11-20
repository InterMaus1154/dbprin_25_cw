

-- Show MOTs that are either expired, or will expire in the next 7 or 30 days
-- For identificiation it includes vehicle reg, customer full name, and customer contact number, as well as the expiry date
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
ORDER BY expiry_date ASC, "Status" ASC;



-- performance per branch in the year of 2025
-- total number of bookings
-- total income per branch, paid invoices only
-- % of invoices that are overdue, compared to total per branch
-- missing income due to not yet paid invoices
-- total jobs completed in the branch
-- the staff who completed the most number of jobs
-- the number of jobs completed by that staff
WITH filtered_bookings AS (SELECT booking_id, branch_id
                           FROM bookings
                           WHERE booking_date >= '2025-01-01'
                             AND booking_date <= '2025-12-31'),
     invoice_data AS (SELECT booking_id,
                             SUM(inv_final) FILTER ( WHERE inv_status = 'PAID' ) AS paid_inv_final,
                             SUM(inv_final) FILTER (WHERE inv_status != 'PAID')  AS due_inv_final,
                             COUNT(*)                                            AS total_invoices,
                             COUNT(CASE WHEN inv_status != 'PAID' THEN 1 END)    AS due_count
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
       b.branch_name                                                                            AS "Branch",
       COUNT(DISTINCT fb.booking_id)                                                            AS "No. of Bookings",
       COALESCE(ROUND(SUM(paid_inv_final), 2), 0)                                               AS "Total Branch Income (GBP)",
       CONCAT(COALESCE(ROUND(SUM(id.due_count) * 100.00 / NULLIF(SUM(id.total_invoices), 0), 2),
                       0), '%')                                                                 AS "Due Invoices %",
       COALESCE(ROUND(SUM(id.due_inv_final), 2), 0)                                             AS "Due Income (GBP)",
       COALESCE(SUM(jd.completed_jobs), 0)                                                      AS "Total Branch Jobs",
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
GROUP BY b.branch_name
ORDER BY "Branch Total Income Rank",
         "No. of Bookings" DESC,
         "Total Branch Income (GBP)" DESC;


-- triggers


