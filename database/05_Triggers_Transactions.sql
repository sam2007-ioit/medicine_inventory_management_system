-- =====================================================================
-- MEDICAL STORE NETWORK AND MEDICINE AVAILABILITY SYSTEM
-- PHASE 5: TRIGGERS AND TRANSACTION MANAGEMENT
-- MySQL 8.0.16+
-- This file creates triggers and provides SAFE, COMMENTED transaction
-- demonstrations. Running the file does not change existing stock data.
-- =====================================================================

USE medical_store_network;

-- =====================================================================
-- SECTION A: REMOVE EARLIER VERSIONS OF THESE TRIGGERS
-- This makes the script safe to execute again.
-- =====================================================================

DROP TRIGGER IF EXISTS trg_inventory_batch_before_update;
DROP TRIGGER IF EXISTS trg_reservation_before_insert;
DROP TRIGGER IF EXISTS trg_reservation_before_update;
DROP TRIGGER IF EXISTS trg_stock_verification_after_insert;
DROP TRIGGER IF EXISTS trg_stock_verification_after_update;

DELIMITER $$

-- =====================================================================
-- TRIGGER 1: PREVENT STOCK FROM FALLING BELOW ACTIVE RESERVATIONS
-- If a batch has active reservations, a direct stock update cannot
-- reduce the batch quantity below the total quantity currently held.
-- The stock transaction procedure already performs this check; this
-- trigger also protects updates made directly on Inventory_Batch.
-- =====================================================================

CREATE TRIGGER trg_inventory_batch_before_update
BEFORE UPDATE ON Inventory_Batch
FOR EACH ROW
BEGIN
    DECLARE v_reserved_quantity BIGINT UNSIGNED DEFAULT 0;

    IF NEW.Quantity < OLD.Quantity THEN
        SELECT COALESCE(SUM(Quantity), 0)
          INTO v_reserved_quantity
          FROM Reservation
         WHERE BatchID = OLD.BatchID
           AND Status = 'ACTIVE'
           AND ExpiryDate > CURRENT_TIMESTAMP();

        IF NEW.Quantity < v_reserved_quantity THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Stock cannot be reduced below the quantity held by active reservations.';
        END IF;
    END IF;
END$$


-- =====================================================================
-- TRIGGER 2: VALIDATE A NEW RESERVATION
-- Checks that the batch exists, its pharmacy is active, the medicine
-- batch has not expired, the reservation expiry is valid, and enough
-- unreserved stock is available.
-- =====================================================================

CREATE TRIGGER trg_reservation_before_insert
BEFORE INSERT ON Reservation
FOR EACH ROW
BEGIN
    DECLARE v_batch_count INT DEFAULT 0;
    DECLARE v_batch_quantity BIGINT UNSIGNED DEFAULT 0;
    DECLARE v_batch_expiry DATE;
    DECLARE v_pharmacy_status VARCHAR(10);
    DECLARE v_reserved_quantity BIGINT UNSIGNED DEFAULT 0;

    SELECT COUNT(*)
      INTO v_batch_count
      FROM Inventory_Batch ib
      JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
     WHERE ib.BatchID = NEW.BatchID;

    IF v_batch_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Reservation cannot be created because the inventory batch does not exist.';
    END IF;

    IF NEW.Status = 'ACTIVE' THEN
        SELECT ib.Quantity, ib.ExpiryDate, p.Status
          INTO v_batch_quantity, v_batch_expiry, v_pharmacy_status
          FROM Inventory_Batch ib
          JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
         WHERE ib.BatchID = NEW.BatchID;

        IF v_pharmacy_status <> 'ACTIVE' THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Reservations are allowed only at active pharmacies.';
        END IF;

        IF v_batch_expiry < CURDATE() THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Expired medicine batches cannot be reserved.';
        END IF;

        IF NEW.ExpiryDate <= CURRENT_TIMESTAMP() THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Reservation expiry must be in the future.';
        END IF;

        IF DATE(NEW.ExpiryDate) > v_batch_expiry THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Reservation cannot extend beyond the medicine batch expiry date.';
        END IF;

        SELECT COALESCE(SUM(Quantity), 0)
          INTO v_reserved_quantity
          FROM Reservation
         WHERE BatchID = NEW.BatchID
           AND Status = 'ACTIVE'
           AND ExpiryDate > CURRENT_TIMESTAMP();

        IF v_reserved_quantity + NEW.Quantity > v_batch_quantity THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Insufficient unreserved stock for this reservation.';
        END IF;
    END IF;
END$$


-- =====================================================================
-- TRIGGER 3: VALIDATE AN UPDATED RESERVATION
-- When a reservation is activated, moved to another batch, or its
-- quantity/expiry is changed, ensure that total active reservations
-- still fit within the selected batch's stock.
-- The current reservation is excluded from the reserved total.
-- =====================================================================

CREATE TRIGGER trg_reservation_before_update
BEFORE UPDATE ON Reservation
FOR EACH ROW
BEGIN
    DECLARE v_batch_count INT DEFAULT 0;
    DECLARE v_batch_quantity BIGINT UNSIGNED DEFAULT 0;
    DECLARE v_batch_expiry DATE;
    DECLARE v_pharmacy_status VARCHAR(10);
    DECLARE v_reserved_quantity BIGINT UNSIGNED DEFAULT 0;

    IF NEW.Status = 'ACTIVE' THEN
        SELECT COUNT(*)
          INTO v_batch_count
          FROM Inventory_Batch ib
          JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
         WHERE ib.BatchID = NEW.BatchID;

        IF v_batch_count = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Reservation cannot be updated because the inventory batch does not exist.';
        END IF;

        SELECT ib.Quantity, ib.ExpiryDate, p.Status
          INTO v_batch_quantity, v_batch_expiry, v_pharmacy_status
          FROM Inventory_Batch ib
          JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
         WHERE ib.BatchID = NEW.BatchID;

        IF v_pharmacy_status <> 'ACTIVE' THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Active reservations require an active pharmacy.';
        END IF;

        IF v_batch_expiry < CURDATE() THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'An expired medicine batch cannot have an active reservation.';
        END IF;

        IF NEW.ExpiryDate <= CURRENT_TIMESTAMP() THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'An active reservation must have an expiry time in the future.';
        END IF;

        IF DATE(NEW.ExpiryDate) > v_batch_expiry THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Reservation cannot extend beyond the medicine batch expiry date.';
        END IF;

        SELECT COALESCE(SUM(Quantity), 0)
          INTO v_reserved_quantity
          FROM Reservation
         WHERE BatchID = NEW.BatchID
           AND ReservationID <> OLD.ReservationID
           AND Status = 'ACTIVE'
           AND ExpiryDate > CURRENT_TIMESTAMP();

        IF v_reserved_quantity + NEW.Quantity > v_batch_quantity THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Updated reservation exceeds the available unreserved stock.';
        END IF;
    END IF;
END$$


-- =====================================================================
-- TRIGGER 4: AUTOMATICALLY CREATE A DISCREPANCY AFTER VERIFICATION
-- When physical stock differs from system stock, create a linked
-- discrepancy record. The verifying user is recorded as the reporter.
-- =====================================================================

CREATE TRIGGER trg_stock_verification_after_insert
AFTER INSERT ON Stock_Verification
FOR EACH ROW
BEGIN
    IF NEW.SystemQuantity <> NEW.PhysicalQuantity THEN
        INSERT INTO Discrepancy
            (VerificationID, ReportedBy, Reason, Status, Remarks)
        VALUES
            (
                NEW.VerificationID,
                NEW.VerifiedBy,
                CONCAT(
                    'Automatic discrepancy: system quantity = ',
                    NEW.SystemQuantity,
                    ', physical quantity = ',
                    NEW.PhysicalQuantity,
                    ', difference = ',
                    CAST(NEW.PhysicalQuantity AS SIGNED) - CAST(NEW.SystemQuantity AS SIGNED),
                    '.'
                ),
                'OPEN',
                'Automatically generated after stock verification.'
            );
    END IF;
END$$


-- =====================================================================
-- TRIGGER 5: KEEP A DISCREPANCY IN SYNC WHEN VERIFICATION IS UPDATED
-- If the quantities still differ, create/update the discrepancy.
-- If they match, mark the linked discrepancy as resolved.
-- =====================================================================

CREATE TRIGGER trg_stock_verification_after_update
AFTER UPDATE ON Stock_Verification
FOR EACH ROW
BEGIN
    DECLARE v_discrepancy_count INT DEFAULT 0;

    SELECT COUNT(*)
      INTO v_discrepancy_count
      FROM Discrepancy
     WHERE VerificationID = NEW.VerificationID;

    IF NEW.SystemQuantity <> NEW.PhysicalQuantity THEN
        IF v_discrepancy_count = 0 THEN
            INSERT INTO Discrepancy
                (VerificationID, ReportedBy, Reason, Status, Remarks)
            VALUES
                (
                    NEW.VerificationID,
                    NEW.VerifiedBy,
                    CONCAT(
                        'Automatic discrepancy: system quantity = ',
                        NEW.SystemQuantity,
                        ', physical quantity = ',
                        NEW.PhysicalQuantity,
                        ', difference = ',
                        CAST(NEW.PhysicalQuantity AS SIGNED) - CAST(NEW.SystemQuantity AS SIGNED),
                        '.'
                    ),
                    'OPEN',
                    'Automatically generated after stock verification was updated.'
                );
        ELSE
            UPDATE Discrepancy
               SET Reason = CONCAT(
                       'Automatic discrepancy: system quantity = ',
                       NEW.SystemQuantity,
                       ', physical quantity = ',
                       NEW.PhysicalQuantity,
                       ', difference = ',
                       CAST(NEW.PhysicalQuantity AS SIGNED) - CAST(NEW.SystemQuantity AS SIGNED),
                       '.'
                   ),
                   Status = CASE
                       WHEN Status IN ('RESOLVED', 'REJECTED') THEN 'OPEN'
                       ELSE Status
                   END,
                   ResolvedBy = NULL,
                   ResolvedDate = NULL,
                   Remarks = 'Updated automatically after stock verification changed.'
             WHERE VerificationID = NEW.VerificationID;
        END IF;
    ELSE
        UPDATE Discrepancy
           SET Status = 'RESOLVED',
               ResolvedBy = NEW.VerifiedBy,
               ResolvedDate = GREATEST(CURRENT_TIMESTAMP(), ReportDate),
               Remarks = 'Automatically resolved because verified quantities now match.'
         WHERE VerificationID = NEW.VerificationID
           AND Status <> 'RESOLVED';
    END IF;
END$$

DELIMITER ;

-- =====================================================================
-- SECTION B: TRANSACTION MANAGEMENT EXAMPLES
-- The examples below are intentionally comments. They do NOT execute
-- automatically when this file is run. Uncomment one block at a time
-- only when you want to test it and are ready to modify demo data.
-- =====================================================================

-- ---------------------------------------------------------------------
-- TRANSACTION 1: COMMIT A STOCK-IN OPERATION
-- Both the inventory quantity and its ledger entry are saved together.
-- Use the stored procedure as a standalone call: it starts and commits
-- its own transaction internally. Do not wrap this CALL in another
-- START TRANSACTION / COMMIT block.
-- ---------------------------------------------------------------------
-- CALL sp_record_stock_transaction(
--     1,                  -- BatchID
--     'STOCK_IN',         -- TransactionType
--     5,                  -- Quantity
--     'GRN-TRANSACTION-DEMO-001',
--     1,                  -- PerformedBy (UserID)
--     'Demonstration stock receipt'
-- );


-- ---------------------------------------------------------------------
-- TRANSACTION 2: MANUAL TRANSACTION WITH ROLLBACK
-- This demonstrates that both updates are undone together.
-- It is safe to run after uncommenting because it ends with ROLLBACK.
-- ---------------------------------------------------------------------
-- SET @demo_batch_id = 1;
-- SET @demo_user_id = 1;
-- SET @demo_quantity = 3;
--
-- START TRANSACTION;
--
-- SELECT Quantity INTO @quantity_before
-- FROM Inventory_Batch
-- WHERE BatchID = @demo_batch_id
-- FOR UPDATE;
--
-- UPDATE Inventory_Batch
-- SET Quantity = Quantity + @demo_quantity
-- WHERE BatchID = @demo_batch_id;
--
-- INSERT INTO Stock_Transaction
--     (BatchID, TransactionType, Quantity, ReferenceNo, PerformedBy, Remarks)
-- VALUES
--     (@demo_batch_id, 'STOCK_IN', @demo_quantity,
--      'ROLLBACK-DEMO-001', @demo_user_id,
--      'This demonstration transaction will be rolled back.');
--
-- ROLLBACK;
--
-- SELECT @quantity_before AS QuantityBefore,
--        Quantity AS QuantityAfterRollback
-- FROM Inventory_Batch
-- WHERE BatchID = @demo_batch_id;


-- ---------------------------------------------------------------------
-- TRANSACTION 3: SAVEPOINT
-- The first stock increase is retained; the second is rolled back to
-- the savepoint. The final COMMIT saves only the first increase and its
-- matching stock transaction. Uncomment the entire block to test it.
-- ---------------------------------------------------------------------
-- SET @demo_batch_id = 1;
-- SET @demo_user_id = 1;
--
-- START TRANSACTION;
--
-- UPDATE Inventory_Batch
-- SET Quantity = Quantity + 2
-- WHERE BatchID = @demo_batch_id;
--
-- INSERT INTO Stock_Transaction
--     (BatchID, TransactionType, Quantity, ReferenceNo, PerformedBy, Remarks)
-- VALUES
--     (@demo_batch_id, 'ADJUSTMENT_IN', 2,
--      'SAVEPOINT-DEMO-001', @demo_user_id,
--      'First change, retained after savepoint rollback.');
--
-- SAVEPOINT after_first_change;
--
-- UPDATE Inventory_Batch
-- SET Quantity = Quantity + 100
-- WHERE BatchID = @demo_batch_id;
--
-- ROLLBACK TO SAVEPOINT after_first_change;
-- COMMIT;
--
-- SELECT BatchID, Quantity
-- FROM Inventory_Batch
-- WHERE BatchID = @demo_batch_id;


-- =====================================================================
-- SECTION C: OPTIONAL TRIGGER TESTS
-- These tests are commented so they do not add reservations or
-- verification/discrepancy records automatically on file execution.
-- =====================================================================

-- TEST 1: A mismatch should automatically create a discrepancy.
-- INSERT INTO Stock_Verification
--     (BatchID, VerifiedBy, SystemQuantity, PhysicalQuantity, Remarks)
-- VALUES
--     (1, 1, 40, 37, 'Trigger demonstration: physical count is lower.');
--
-- SELECT *
-- FROM Discrepancy
-- ORDER BY DiscrepancyID DESC
-- LIMIT 1;

-- TEST 2: Updating the same verification to matching quantities should
-- automatically resolve its discrepancy.
-- Replace 7 with the VerificationID returned by your insert above.
-- UPDATE Stock_Verification
-- SET PhysicalQuantity = SystemQuantity,
--     Remarks = 'Recount completed; quantities now match.'
-- WHERE VerificationID = 7;
--
-- SELECT *
-- FROM Discrepancy
-- WHERE VerificationID = 7;

-- TEST 3: Attempting to lower a batch below active reserved stock
-- should be rejected by trg_inventory_batch_before_update.
-- UPDATE Inventory_Batch
-- SET Quantity = 0
-- WHERE BatchID = 1;


-- =====================================================================
-- SECTION D: VERIFY CREATED TRIGGERS
-- =====================================================================

SHOW TRIGGERS FROM medical_store_network;

-- View the latest discrepancy records.
SELECT
    d.DiscrepancyID,
    d.VerificationID,
    d.Reason,
    d.Status,
    d.ReportDate,
    d.ResolvedDate
FROM Discrepancy d
ORDER BY d.DiscrepancyID DESC;

-- Confirm that active reservations do not exceed batch stock.
SELECT
    ib.BatchID,
    ib.Quantity AS BatchQuantity,
    COALESCE(SUM(
        CASE
            WHEN r.Status = 'ACTIVE' AND r.ExpiryDate > CURRENT_TIMESTAMP()
            THEN r.Quantity ELSE 0
        END
    ), 0) AS ActiveReservedQuantity
FROM Inventory_Batch ib
LEFT JOIN Reservation r ON r.BatchID = ib.BatchID
GROUP BY ib.BatchID, ib.Quantity
HAVING ActiveReservedQuantity > BatchQuantity;

-- No rows should be returned by the final query.

-- ======================= END OF PHASE 5 =============================
