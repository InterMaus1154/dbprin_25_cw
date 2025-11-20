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
$$
    LANGUAGE plpgsql;

CREATE OR REPLACE trigger tgr_refresh_staff_role_detailed
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
$$
    LANGUAGE plpgsql;

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
                 AND (TG_OP = 'INSERT'
                   OR branch_man_id <> NEW.branch_man_id))
    THEN
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
$$
    LANGUAGE plpgsql;

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
        ON CONFLICT (branch_id, part_id)
            DO UPDATE SET quantity = branch_parts.quantity + EXCLUDED.quantity;
    END IF;

    RETURN NEW;
END;
$$
    LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tgr_update_stock_levels_after_part_transfer
    AFTER INSERT OR UPDATE
    ON part_transfers
    FOR EACH ROW
    WHEN (NEW.transfer_status = 'COMPLETED')
EXECUTE FUNCTION check_stock_level_for_part_usage();

