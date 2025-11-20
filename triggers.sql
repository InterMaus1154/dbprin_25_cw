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