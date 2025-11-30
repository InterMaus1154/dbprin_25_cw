-- START OF TRIGGERS

-- automatically refresh customer_safe view on new action
CREATE OR REPLACE FUNCTION refresh_customer_safe()
    RETURNS TRIGGER AS
$$
BEGIN
    REFRESH MATERIALIZED VIEW customer_safe;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tgr_refresh_customer_safe
    AFTER INSERT OR UPDATE OR DELETE
    ON customers
    FOR EACH STATEMENT
EXECUTE FUNCTION refresh_customer_safe();

-- refresh staff_role_detailed view
CREATE OR REPLACE FUNCTION refresh_staff_role_detailed()
    RETURNS TRIGGER AS
$$
BEGIN
    REFRESH MATERIALIZED VIEW staff_role_detailed;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tgr_refresh_staff_role_detailed
    AFTER INSERT OR UPDATE OR DELETE
    ON staff_roles
    FOR EACH STATEMENT
EXECUTE FUNCTION refresh_staff_role_detailed();

-- refresh branch_manager_details
CREATE OR REPLACE FUNCTION refresh_branch_manager_details()
    RETURNS TRIGGER AS
$$
BEGIN
    REFRESH MATERIALIZED VIEW branch_manager_details;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tgr_refresh_branch_manager_details
    AFTER INSERT OR UPDATE OR DELETE
    ON branch_managers
    FOR EACH STATEMENT
EXECUTE FUNCTION refresh_branch_manager_details();

--- Prevent inserting the same staff for the same branch as manager, if they are already an active manager there
CREATE OR REPLACE FUNCTION check_same_branch_manager()
    RETURNS TRIGGER AS
$$
BEGIN
    IF EXISTS (SELECT 1
               FROM branch_managers
               WHERE staff_id = NEW.staff_id
                 AND branch_id = NEW.branch_id
                 AND is_active = TRUE
                 AND (TG_OP = 'INSERT' OR branch_man_id <> NEW.branch_man_id)) THEN
        RAISE EXCEPTION 'Staff % is already an active manager at branch %', NEW.staff_id, NEW.branch_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tgr_check_same_branch_manager
    BEFORE INSERT OR UPDATE
    ON branch_managers
    FOR EACH ROW
EXECUTE FUNCTION check_same_branch_manager();

-- update vehicle safe
CREATE OR REPLACE FUNCTION update_vehicle_safe()
    RETURNS TRIGGER AS
$$
BEGIN
    REFRESH MATERIALIZED VIEW vehicle_safe;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tgr_update_vehicle_safe
    AFTER INSERT OR UPDATE OR DELETE
    ON vehicles
    FOR EACH STATEMENT
EXECUTE FUNCTION update_vehicle_safe();

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
             JOIN staff s USING (staff_id)
    WHERE j.job_id = NEW.job_id;

    -- check stock level at branch
    SELECT bp.quantity
    INTO current_part_quantity
    FROM branch_parts bp
    WHERE bp.branch_id = job_branch_id
      AND bp.part_id = NEW.part_id;

    -- if part doesnt exist
    IF current_part_quantity IS NULL THEN
        RAISE EXCEPTION 'Part id % is not available at branch id %', NEW.part_id, job_branch_id;
    END IF;

    IF current_part_quantity < NEW.quantity THEN
        RAISE EXCEPTION 'Quantity is less than available in the branch, available is %, but requested is %', current_part_quantity, NEW.quantity;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

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
$$ LANGUAGE plpgsql;

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
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tgr_check_for_correct_approval_staff_for_part_transfer
    BEFORE INSERT OR UPDATE
    ON part_transfers
    FOR EACH ROW
EXECUTE FUNCTION check_for_correct_approval_staff_for_part_transfer();

-- update stock levels after a part_transfer is completed
CREATE OR REPLACE FUNCTION update_stock_levels_after_part_transfer()
    RETURNS TRIGGER AS
$$
BEGIN
    -- only proceed if transfer was completed
    IF NEW.transfer_status = 'COMPLETED' AND (OLD IS NULL OR OLD.transfer_status <> 'COMPLETED') THEN
        -- decrease at branch it was transferred from
        UPDATE branch_parts
        SET quantity = quantity - NEW.quantity
        WHERE branch_id = NEW.from_branch_id
          AND part_id = NEW.part_id;

        -- increase stock at transferred to branch
        -- create new record, or update
        INSERT INTO branch_parts (branch_id, part_id, quantity)
        VALUES (NEW.to_branch_id, NEW.part_id, NEW.quantity)
        ON CONFLICT (branch_id, part_id) DO UPDATE
            SET quantity = branch_parts.quantity + EXCLUDED.quantity;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tgr_update_stock_levels_after_part_transfer
    AFTER INSERT OR UPDATE
    ON part_transfers
    FOR EACH ROW
    WHEN (NEW.transfer_status = 'COMPLETED')
EXECUTE FUNCTION update_stock_levels_after_part_transfer();

-- prevent deleting paid invoices
CREATE OR REPLACE FUNCTION prevent_paid_invoice_deletion()
    RETURNS TRIGGER AS
$$
BEGIN
    IF OLD.inv_status = 'PAID' THEN
        RAISE EXCEPTION 'Paid invoice deletion is not allowed on invoice id %', OLD.inv_id;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tgr_prevent_paid_invoice_deletion
    BEFORE DELETE
    ON invoices
    FOR EACH ROW
EXECUTE FUNCTION prevent_paid_invoice_deletion();

-- automatically set invoice to paid if all installments are paid
CREATE OR REPLACE FUNCTION update_invoice_status()
    RETURNS TRIGGER AS
$$
BEGIN
    -- check if all installments of an invoice are paid
    IF NOT EXISTS (SELECT 1
                   FROM installments inst
                   WHERE inst.inv_id = NEW.inv_id
                     AND inst.inst_status != 'PAID') THEN
        UPDATE invoices
        SET inv_status = 'PAID'
        WHERE inv_id = NEW.inv_id;
    END IF;

    -- check if current installment is overdue
    -- if installment is overdue, set invoice as overdue
    IF NEW.inst_status = 'OVERDUE' THEN
        UPDATE invoices
        SET inv_status = 'OVERDUE'
        WHERE inv_id = NEW.inv_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tgr_update_invoice_status
    AFTER UPDATE
    ON installments
    FOR EACH ROW
EXECUTE FUNCTION update_invoice_status();

-- check if a bay assigned to a job is available or not
-- reject job if not available
CREATE OR REPLACE FUNCTION check_bay_status()
    RETURNS TRIGGER AS
$$
DECLARE
    current_bay_status bay_status;
BEGIN
    SELECT bay_status
    INTO current_bay_status
    FROM bays
    WHERE bay_id = NEW.bay_id;

    -- reject bay if not available
    IF current_bay_status != 'AVAILABLE' THEN
        RAISE EXCEPTION 'Bay % is not available!', NEW.bay_id;
    END IF;

    -- update bay status to occupied
    UPDATE bays
    SET bay_status = 'OCCUPIED'
    WHERE bay_id = NEW.bay_id
      AND bay_status = 'AVAILABLE';

    IF NOT FOUND
    THEN
        RAISE EXCEPTION 'Bay % is not available', NEW.bay_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tgr_check_bay_status
    BEFORE INSERT
    ON jobs
    FOR EACH ROW
EXECUTE FUNCTION check_bay_status();

-- before invoice insertion, automatically get money for total services, then discount, and subtract discount for the final amount to be paid
CREATE OR REPLACE FUNCTION calculate_invoice_amount()
    RETURNS TRIGGER AS
$$
DECLARE
    total                     DECIMAL(10, 2) := 0.00;
    temp_total                DECIMAL(10, 2) := 0.00;
    service_discounts         DECIMAL        := 0.00;
    service_package_discounts DECIMAL        := 0.00;
    total_discount            DECIMAL(10, 2) := 0.00;
    membership_discount       DECIMAL        := 0.00;
    temp_membership_discount  DECIMAL        := 0.00;
    membership_id             INTEGER;
BEGIN
    -- check if the customer has membership
    SELECT customers.mship_id
    INTO membership_id
    FROM bookings
             JOIN vehicles USING (vec_id)
             JOIN customers USING (cust_id)
    WHERE bookings.booking_id = NEW.booking_id
      AND customers.mship_id IS NOT NULL;

    -- a booking may only have services from packages, not individual services
    IF EXISTS(SELECT 1
              FROM booking_services
              WHERE booking_services.booking_id = NEW.booking_id) THEN
        -- calculate the total from booking_services
        SELECT COALESCE(SUM(service_price), 0)
        INTO total
        FROM booking_services
                 JOIN services USING (service_id)
        WHERE booking_id = NEW.booking_id;

        -- calculate service_discounts
        SELECT COALESCE(SUM(sd.disc_amount), 0)
        INTO service_discounts
        FROM booking_services bs
                 JOIN service_discounts sd ON bs.service_id = sd.service_id AND sd.is_active = TRUE
        WHERE bs.booking_id = NEW.booking_id;
    END IF;

    IF EXISTS(SELECT 1
              FROM booking_packages
              WHERE booking_packages.booking_id = NEW.booking_id) THEN
        -- calculate the sum of booking package services
        SELECT COALESCE(SUM(s.service_price), 0)
        INTO temp_total
        FROM booking_packages
                 JOIN packages USING (pkg_id)
                 JOIN package_services USING (pkg_id)
                 JOIN services s USING (service_id)
        WHERE booking_packages.booking_id = NEW.booking_id;

        -- calculate discounts for services in the packages
        SELECT COALESCE(SUM(sd.disc_amount), 0)
        INTO service_package_discounts
        FROM booking_packages
                 JOIN packages USING (pkg_id)
                 JOIN package_services USING (pkg_id)
                 JOIN service_discounts sd USING (service_id)
        WHERE booking_packages.booking_id = NEW.booking_id
          AND sd.is_active = TRUE;
    END IF;

    -- calculate membership discounts
    IF membership_id IS NOT NULL THEN
        -- calculate for individual services
        IF EXISTS(SELECT 1
                  FROM booking_services
                  WHERE booking_id = NEW.booking_id) THEN
            SELECT COALESCE(
                           SUM(
                                   CASE
                                       WHEN discount_type = 'FIXED' THEN discount_value
                                       WHEN discount_type = 'PERCENT' THEN service_price * (discount_value / 100)
                                       END
                           ),
                           0
                   )
            INTO membership_discount
            FROM bookings b
                     JOIN vehicles USING (vec_id)
                     JOIN customers USING (cust_id)
                     JOIN membership_services ms USING (mship_id)
                     JOIN booking_services bs ON ms.service_id = bs.service_id AND bs.booking_id = NEW.booking_id
                     JOIN services s ON bs.service_id = s.service_id
            WHERE b.booking_id = NEW.booking_id;
        END IF;

        -- calculate for package services
        IF EXISTS(SELECT 1
                  FROM booking_packages
                  WHERE booking_id = NEW.booking_id) THEN
            SELECT COALESCE(
                           SUM(
                                   CASE
                                       WHEN discount_type = 'FIXED' THEN discount_value
                                       WHEN discount_type = 'PERCENT' THEN service_price * (discount_value / 100)
                                       END
                           ),
                           0
                   )
            INTO temp_membership_discount
            FROM bookings b
                     JOIN vehicles USING (vec_id)
                     JOIN customers USING (cust_id)
                     JOIN membership_services ms USING (mship_id)
                     JOIN booking_packages bp ON bp.booking_id = NEW.booking_id
                     JOIN packages USING (pkg_id)
                     JOIN package_services ps ON ms.service_id = ps.service_id AND ps.pkg_id = bp.pkg_id
                     JOIN services s ON ps.service_id = s.service_id
            WHERE b.booking_id = NEW.booking_id;
        END IF;
    END IF;

    -- add the package + service price
    total := total + temp_total;
    NEW.inv_total := total;

    -- calculate total discount
    total_discount := service_discounts + service_package_discounts + membership_discount + temp_membership_discount;
    NEW.inv_discount := total_discount;

    -- calculate final amount
    NEW.inv_final := total - total_discount;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tgr_calculate_invoice_amount
    BEFORE INSERT
    ON invoices
    FOR EACH ROW
EXECUTE FUNCTION calculate_invoice_amount();

CREATE OR REPLACE FUNCTION deduct_parts_after_usage()
    RETURNS TRIGGER AS
$$
DECLARE
    job_branch_id INTEGER;
BEGIN
    SELECT s.branch_id
    INTO job_branch_id
    FROM jobs j
             JOIN staff s USING (staff_id)
    WHERE j.job_id = NEW.job_id;

    UPDATE branch_parts
    SET quantity = quantity - NEW.quantity
    WHERE branch_id = job_branch_id
      AND part_id = NEW.part_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tgr_deduct_parts_after_usage
    AFTER INSERT
    ON part_usage
    FOR EACH ROW
EXECUTE FUNCTION deduct_parts_after_usage();

CREATE OR REPLACE FUNCTION refresh_customer_booking_history()
    RETURNS TRIGGER AS
$$
BEGIN
    REFRESH MATERIALIZED VIEW customer_booking_history;
    RETURN NULL;
END;
    $$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tgr_refresh_customer_booking_history_on_bookings
    AFTER INSERT OR DELETE OR UPDATE ON bookings
    FOR EACH STATEMENT
    EXECUTE FUNCTION refresh_customer_booking_history();

CREATE OR REPLACE TRIGGER tgr_refresh_customer_booking_history_on_customers
    AFTER INSERT ON customers
    FOR EACH STATEMENT
    EXECUTE FUNCTION refresh_customer_booking_history();


-- END OF TRIGGERS