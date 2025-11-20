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

-- do not allow insertion into part usage, if the current stock quantity in the branch is less than what is required
CREATE OR REPLACE FUNCTION check_stock_level_for_part_usage()
    RETURNS TRIGGER AS
$$
DECLARE
    current_part_quantity INTEGER;
    job_branch_id         INTEGER;
BEGIN
    -- get current branch
    SELECT s.branch_id
    INTO job_branch_id
    FROM jobs j
             JOIN staff s
                  USING (staff_id)
    WHERE j.job_id = NEW.job_id;

    -- check stock level at branch
    SELECT bp.quantity
    INTO current_part_quantity
    FROM branch_parts bp
    WHERE bp.branch_id = job_branch_id
      AND bp.part_id = NEW.part_id;

    -- if part doesnt exist
    if current_part_quantity IS NULL THEN
        RAISE EXCEPTION 'Part id % is not available at branch id %', NEW.part_id, job_branch_id;
    end if;

    IF current_part_quantity < NEW.quantity THEN
        RAISE EXCEPTION 'Quantity is less than available in the branch, available is %, but requested is %', current_part_quantity, NEW.quantity;
    END IF;
    RETURN NEW;
END;
$$
    LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tgr_check_stock_level_for_part_usage
    BEFORE INSERT
    ON part_usage
    FOR EACH ROW
EXECUTE FUNCTION check_stock_level_for_part_usage();

-- do not allow insertion of part transfer, if the stock level at the from branch is less than the required
CREATE OR REPLACE FUNCTION check_stock_level_for_part_transfer()
    RETURNS TRIGGER AS
$$
DECLARE
    current_stock_quantity INTEGER;
BEGIN
    SELECT bp.quantity
    INTO current_stock_quantity
    FROM branch_parts bp
    WHERE bp.part_id = NEW.part_id
      AND bp.branch_id = NEW.from_branch_id;

    IF current_stock_quantity IS NULL THEN
        RAISE EXCEPTION 'Part % does not exist at branch %', NEW.part_id, NEW.from_branch_id;
    END IF;

    IF current_stock_quantity < NEW.quantity THEN
        RAISE EXCEPTION 'There are not enough parts available in branch %', NEW.from_branch_id;
    END IF;
    RETURN NEW;
END;
$$
    LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tgr_check_stock_level_for_part_transfer
    BEFORE INSERT
    ON part_transfers
    FOR EACH ROW
EXECUTE FUNCTION check_stock_level_for_part_transfer();


-- do not allow insertion or update, if the approved_by is not the manager of the branch where it is being transferred to
CREATE OR REPLACE FUNCTION check_for_correct_approval_staff_for_part_transfer()
    RETURNS TRIGGER AS
$$
DECLARE
    is_valid_manager INTEGER;
BEGIN
    -- a staff cannot approve their own request
    IF NEW.approved_by = NEW.requested_by THEN
        RAISE EXCEPTION 'A staff cannot approve their own transfer request!';
    END IF;

    -- a staff has to be manager at the to_branch_id
    SELECT EXISTS (SELECT 1
                   FROM branch_managers bm
                   WHERE bm.branch_id = NEW.to_branch_id
                     AND bm.staff_id = NEW.approved_by
                     AND bm.is_active)
    INTO is_valid_manager;

    -- no result was found
    IF NOT is_valid_manager THEN
        RAISE EXCEPTION 'A manager at branch id % needs to approve this request!', NEW.to_branch_id;
    end if;

    RETURN NEW;
END;
$$
    LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tgr_check_for_correct_approval_staff_for_part_transfer
    BEFORE INSERT OR UPDATE
    ON part_transfers
    FOR EACH ROW
EXECUTE FUNCTION check_for_correct_approval_staff_for_part_transfer();
