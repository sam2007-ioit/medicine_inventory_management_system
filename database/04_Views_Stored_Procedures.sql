-- =====================================================================
-- MEDICAL STORE NETWORK AND MEDICINE AVAILABILITY SYSTEM
-- PHASE 4: VIEWS AND STORED PROCEDURES
-- Database: MySQL 8.0.16+
--
-- This file creates/replaces views and recreates stored procedures.
-- It does not insert or modify sample records merely by being executed.
-- =====================================================================

USE medical_store_network;
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- =====================================================================
-- SECTION A: VIEWS
-- =====================================================================

-- 1. Batch-wise stock status, including quantities reserved by customers.
-- An active reservation is counted only until its reservation expiry time.
CREATE OR REPLACE VIEW vw_batch_stock_status AS
SELECT
    ib.BatchID,
    ib.BatchNo,
    ib.PharmacyID,
    p.Name AS PharmacyName,
    p.Status AS PharmacyStatus,
    ib.MedicineID,
    m.BrandName,
    m.GenericName,
    m.DosageForm,
    ib.SupplierID,
    s.Name AS SupplierName,
    ib.MfgDate,
    ib.ExpiryDate AS MedicineExpiryDate,
    ib.PurchaseDate,
    ib.Quantity AS RecordedQuantity,
    COALESCE(r.ReservedQuantity, 0) AS ReservedQuantity,
    GREATEST(CAST(ib.Quantity AS SIGNED) - CAST(COALESCE(r.ReservedQuantity, 0) AS SIGNED), 0) AS AvailableQuantity,
    ib.PurchasePrice,
    CASE
        WHEN ib.ExpiryDate < CURDATE() THEN 'EXPIRED'
        WHEN ib.Quantity = 0 THEN 'OUT_OF_STOCK'
        WHEN GREATEST(CAST(ib.Quantity AS SIGNED) - CAST(COALESCE(r.ReservedQuantity, 0) AS SIGNED), 0) = 0 THEN 'FULLY_RESERVED'
        WHEN ib.ExpiryDate <= DATE_ADD(CURDATE(), INTERVAL 90 DAY) THEN 'EXPIRING_SOON'
        WHEN GREATEST(CAST(ib.Quantity AS SIGNED) - CAST(COALESCE(r.ReservedQuantity, 0) AS SIGNED), 0) <= 10 THEN 'LOW_STOCK'
        ELSE 'NORMAL'
    END AS StockStatus
FROM Inventory_Batch ib
JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
JOIN Medicine m ON m.MedicineID = ib.MedicineID
JOIN Supplier s ON s.SupplierID = ib.SupplierID
LEFT JOIN (
    SELECT BatchID, SUM(Quantity) AS ReservedQuantity
    FROM Reservation
    WHERE Status = 'ACTIVE'
      AND ExpiryDate > CURRENT_TIMESTAMP()
    GROUP BY BatchID
) r ON r.BatchID = ib.BatchID;


-- 2. Available quantity of each medicine at each active pharmacy.
-- Expired batches and active reservations are excluded from available stock.
CREATE OR REPLACE VIEW vw_active_medicine_availability AS
SELECT
    m.MedicineID,
    m.BrandName,
    m.GenericName,
    m.DosageForm,
    p.PharmacyID,
    p.Name AS PharmacyName,
    p.Address,
    p.Phone,
    COUNT(DISTINCT CASE
        WHEN GREATEST(CAST(ib.Quantity AS SIGNED) - CAST(COALESCE(r.ReservedQuantity, 0) AS SIGNED), 0) > 0
        THEN ib.BatchID
    END) AS AvailableBatchCount,
    SUM(GREATEST(CAST(ib.Quantity AS SIGNED) - CAST(COALESCE(r.ReservedQuantity, 0) AS SIGNED), 0)) AS AvailableQuantity,
    MIN(CASE
        WHEN GREATEST(CAST(ib.Quantity AS SIGNED) - CAST(COALESCE(r.ReservedQuantity, 0) AS SIGNED), 0) > 0
        THEN ib.ExpiryDate
    END) AS NearestBatchExpiry
FROM Inventory_Batch ib
JOIN Medicine m ON m.MedicineID = ib.MedicineID
JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
LEFT JOIN (
    SELECT BatchID, SUM(Quantity) AS ReservedQuantity
    FROM Reservation
    WHERE Status = 'ACTIVE'
      AND ExpiryDate > CURRENT_TIMESTAMP()
    GROUP BY BatchID
) r ON r.BatchID = ib.BatchID
WHERE p.Status = 'ACTIVE'
  AND ib.ExpiryDate >= CURDATE()
GROUP BY
    m.MedicineID, m.BrandName, m.GenericName, m.DosageForm,
    p.PharmacyID, p.Name, p.Address, p.Phone
HAVING SUM(GREATEST(CAST(ib.Quantity AS SIGNED) - CAST(COALESCE(r.ReservedQuantity, 0) AS SIGNED), 0)) > 0;


-- 3. Pharmacy-wise inventory summary.
-- RecordedUnits includes all recorded batches; AvailableUnits excludes
-- expired batches, inactive pharmacies and unexpired active reservations.
CREATE OR REPLACE VIEW vw_pharmacy_inventory_summary AS
SELECT
    p.PharmacyID,
    p.Name AS PharmacyName,
    p.Status AS PharmacyStatus,
    COUNT(DISTINCT ib.BatchID) AS TotalBatches,
    COUNT(DISTINCT ib.MedicineID) AS DistinctMedicines,
    COALESCE(SUM(ib.Quantity), 0) AS RecordedUnits,
    COALESCE(SUM(
        CASE
            WHEN p.Status = 'ACTIVE' AND ib.ExpiryDate >= CURDATE()
            THEN GREATEST(CAST(ib.Quantity AS SIGNED) - CAST(COALESCE(r.ReservedQuantity, 0) AS SIGNED), 0)
            ELSE 0
        END
    ), 0) AS AvailableUnits
FROM Pharmacy p
LEFT JOIN Inventory_Batch ib ON ib.PharmacyID = p.PharmacyID
LEFT JOIN (
    SELECT BatchID, SUM(Quantity) AS ReservedQuantity
    FROM Reservation
    WHERE Status = 'ACTIVE'
      AND ExpiryDate > CURRENT_TIMESTAMP()
    GROUP BY BatchID
) r ON r.BatchID = ib.BatchID
GROUP BY p.PharmacyID, p.Name, p.Status;


-- 4. Detailed stock transaction ledger.
CREATE OR REPLACE VIEW vw_stock_transaction_ledger AS
SELECT
    st.TransactionID,
    st.TransactionDate,
    st.TransactionType,
    st.Quantity,
    st.ReferenceNo,
    st.Remarks,
    ib.BatchID,
    ib.BatchNo,
    m.MedicineID,
    m.BrandName,
    m.GenericName,
    p.PharmacyID,
    p.Name AS PharmacyName,
    ua.UserID AS PerformedByUserID,
    ua.Name AS PerformedByName
FROM Stock_Transaction st
JOIN Inventory_Batch ib ON ib.BatchID = st.BatchID
JOIN Medicine m ON m.MedicineID = ib.MedicineID
JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
JOIN User_Account ua ON ua.UserID = st.PerformedBy;


-- 5. Stock verification report with any linked discrepancy record.
CREATE OR REPLACE VIEW vw_stock_verification_report AS
SELECT
    sv.VerificationID,
    sv.VerificationDate,
    sv.BatchID,
    ib.BatchNo,
    m.BrandName,
    p.Name AS PharmacyName,
    sv.SystemQuantity,
    sv.PhysicalQuantity,
    sv.Difference,
    sv.VerificationStatus,
    verifier.Name AS VerifiedByName,
    d.DiscrepancyID,
    d.Reason AS DiscrepancyReason,
    d.Status AS DiscrepancyStatus,
    resolver.Name AS ResolvedByName,
    d.ResolvedDate
FROM Stock_Verification sv
JOIN Inventory_Batch ib ON ib.BatchID = sv.BatchID
JOIN Medicine m ON m.MedicineID = ib.MedicineID
JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
JOIN User_Account verifier ON verifier.UserID = sv.VerifiedBy
LEFT JOIN Discrepancy d ON d.VerificationID = sv.VerificationID
LEFT JOIN User_Account resolver ON resolver.UserID = d.ResolvedBy;


-- 6. Reservations that are still active and have not reached their expiry.
CREATE OR REPLACE VIEW vw_current_active_reservations AS
SELECT
    r.ReservationID,
    r.ReservationDate,
    r.ExpiryDate AS ReservationExpiry,
    r.Quantity AS ReservedQuantity,
    r.Purpose,
    r.Status,
    ib.BatchID,
    ib.BatchNo,
    m.MedicineID,
    m.BrandName,
    p.PharmacyID,
    p.Name AS PharmacyName,
    ua.UserID AS ReservedByUserID,
    ua.Name AS ReservedByName
FROM Reservation r
JOIN Inventory_Batch ib ON ib.BatchID = r.BatchID
JOIN Medicine m ON m.MedicineID = ib.MedicineID
JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
JOIN User_Account ua ON ua.UserID = r.ReservedBy
WHERE r.Status = 'ACTIVE'
  AND r.ExpiryDate > CURRENT_TIMESTAMP();


-- =====================================================================
-- SECTION B: STORED PROCEDURES
-- =====================================================================

DROP PROCEDURE IF EXISTS sp_search_medicine;
DROP PROCEDURE IF EXISTS sp_get_available_alternatives;
DROP PROCEDURE IF EXISTS sp_find_composition_matches;
DROP PROCEDURE IF EXISTS sp_record_stock_transaction;
DROP PROCEDURE IF EXISTS sp_create_reservation;

DELIMITER $$

-- 1. Search the medicine catalogue by brand, generic name or ingredient.
-- Example: CALL sp_search_medicine('paracetamol');
CREATE PROCEDURE sp_search_medicine(IN p_SearchTerm VARCHAR(150))
BEGIN
    DECLARE v_SearchTerm VARCHAR(150)
        CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

    IF p_SearchTerm IS NULL OR CHAR_LENGTH(TRIM(p_SearchTerm)) = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Enter a medicine name, brand or ingredient to search.';
    END IF;

    SET v_SearchTerm = TRIM(p_SearchTerm);

    SELECT DISTINCT
        m.MedicineID,
        m.BrandName,
        m.GenericName,
        m.DosageForm,
        m.Category,
        c.IngredientName
    FROM Medicine m
    LEFT JOIN Medicine_Composition mc ON mc.MedicineID = m.MedicineID
    LEFT JOIN Composition c ON c.CompositionID = mc.CompositionID
    WHERE m.BrandName COLLATE utf8mb4_unicode_ci
              LIKE CONCAT('%', v_SearchTerm, '%') COLLATE utf8mb4_unicode_ci
       OR m.GenericName COLLATE utf8mb4_unicode_ci
              LIKE CONCAT('%', v_SearchTerm, '%') COLLATE utf8mb4_unicode_ci
       OR c.IngredientName COLLATE utf8mb4_unicode_ci
              LIKE CONCAT('%', v_SearchTerm, '%') COLLATE utf8mb4_unicode_ci
    ORDER BY m.BrandName, c.IngredientName;
END$$


-- 2. Display explicitly mapped alternatives and their currently available
-- stock at active pharmacies. This is a catalogue mapping, not a clinical
-- recommendation to substitute one medicine for another.
-- Example: CALL sp_get_available_alternatives(1);
CREATE PROCEDURE sp_get_available_alternatives(IN p_MedicineID INT)
BEGIN
    IF p_MedicineID IS NULL OR NOT EXISTS (
        SELECT 1 FROM Medicine WHERE MedicineID = p_MedicineID
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'The selected MedicineID does not exist.';
    END IF;

    SELECT
        source_medicine.MedicineID AS SearchedMedicineID,
        source_medicine.BrandName AS SearchedMedicine,
        alternative.MedicineID AS AlternativeMedicineID,
        alternative.BrandName AS AlternativeMedicine,
        alternative.GenericName,
        alternative.DosageForm,
        ma.Remarks AS MappingRemarks,
        availability.PharmacyID,
        availability.PharmacyName,
        availability.Address,
        availability.Phone,
        COALESCE(availability.AvailableQuantity, 0) AS AvailableQuantity
    FROM Medicine_Alternative ma
    JOIN Medicine source_medicine
        ON source_medicine.MedicineID = ma.MedicineID
    JOIN Medicine alternative
        ON alternative.MedicineID = ma.AlternativeMedicineID
    LEFT JOIN vw_active_medicine_availability availability
        ON availability.MedicineID = alternative.MedicineID
    WHERE ma.MedicineID = p_MedicineID
    ORDER BY alternative.BrandName, availability.PharmacyName;
END$$


-- 3. Find medicines having exactly the same ingredient/strength set and
-- dosage form as the selected medicine. Availability is shown when present.
-- This is a database composition match, not a clinical substitution decision.
-- Example: CALL sp_find_composition_matches(1);
CREATE PROCEDURE sp_find_composition_matches(IN p_MedicineID INT)
BEGIN
    IF p_MedicineID IS NULL OR NOT EXISTS (
        SELECT 1 FROM Medicine WHERE MedicineID = p_MedicineID
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'The selected MedicineID does not exist.';
    END IF;

    WITH source_medicine AS (
        SELECT MedicineID, BrandName, DosageForm
        FROM Medicine
        WHERE MedicineID = p_MedicineID
    ),
    matching_medicines AS (
        SELECT candidate.MedicineID
        FROM Medicine candidate
        CROSS JOIN source_medicine src
        WHERE candidate.MedicineID <> src.MedicineID
          AND candidate.DosageForm = src.DosageForm
          AND EXISTS (
              SELECT 1
              FROM Medicine_Composition source_mc
              WHERE source_mc.MedicineID = src.MedicineID
          )
          AND NOT EXISTS (
              SELECT 1
              FROM Medicine_Composition src_mc
              WHERE src_mc.MedicineID = src.MedicineID
                AND NOT EXISTS (
                    SELECT 1
                    FROM Medicine_Composition candidate_mc
                    WHERE candidate_mc.MedicineID = candidate.MedicineID
                      AND candidate_mc.CompositionID = src_mc.CompositionID
                      AND candidate_mc.StrengthPerUnit = src_mc.StrengthPerUnit
                )
          )
          AND NOT EXISTS (
              SELECT 1
              FROM Medicine_Composition candidate_mc
              WHERE candidate_mc.MedicineID = candidate.MedicineID
                AND NOT EXISTS (
                    SELECT 1
                    FROM Medicine_Composition src_mc
                    WHERE src_mc.MedicineID = src.MedicineID
                      AND src_mc.CompositionID = candidate_mc.CompositionID
                      AND src_mc.StrengthPerUnit = candidate_mc.StrengthPerUnit
                )
          )
    )
    SELECT
        src.MedicineID AS SearchedMedicineID,
        src.BrandName AS SearchedMedicine,
        candidate.MedicineID AS MatchingMedicineID,
        candidate.BrandName AS CompositionMatch,
        candidate.GenericName,
        candidate.DosageForm,
        availability.PharmacyName,
        availability.Address,
        COALESCE(availability.AvailableQuantity, 0) AS AvailableQuantity
    FROM source_medicine src
    JOIN matching_medicines mm ON TRUE
    JOIN Medicine candidate ON candidate.MedicineID = mm.MedicineID
    LEFT JOIN vw_active_medicine_availability availability
        ON availability.MedicineID = candidate.MedicineID
    ORDER BY candidate.BrandName, availability.PharmacyName;
END$$


-- 4. Record a stock movement and update Inventory_Batch.Quantity atomically.
-- STOCK_IN, ADJUSTMENT_IN and RETURN_IN increase stock.
-- STOCK_OUT, ADJUSTMENT_OUT and RETURN_OUT decrease stock.
-- Example (execute only when you intend to change stock):
-- CALL sp_record_stock_transaction(1, 'STOCK_IN', 10, 'GRN-TEST-001', 1, 'Test stock receipt');
CREATE PROCEDURE sp_record_stock_transaction(
    IN p_BatchID INT,
    IN p_TransactionType VARCHAR(20),
    IN p_Quantity INT UNSIGNED,
    IN p_ReferenceNo VARCHAR(100),
    IN p_PerformedBy INT,
    IN p_Remarks VARCHAR(255)
)
BEGIN
    DECLARE v_CurrentQuantity INT UNSIGNED DEFAULT 0;
    DECLARE v_NewQuantity BIGINT UNSIGNED DEFAULT 0;
    DECLARE v_ReservedQuantity BIGINT UNSIGNED DEFAULT 0;
    DECLARE v_NotFound BOOLEAN DEFAULT FALSE;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_NotFound = TRUE;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_BatchID IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BatchID is required.';
    END IF;

    IF p_Quantity IS NULL OR p_Quantity = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Transaction quantity must be greater than zero.';
    END IF;

    IF p_TransactionType IS NULL OR p_TransactionType NOT IN
       ('STOCK_IN', 'STOCK_OUT', 'ADJUSTMENT_IN', 'ADJUSTMENT_OUT', 'RETURN_IN', 'RETURN_OUT') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid stock transaction type.';
    END IF;

    IF p_PerformedBy IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PerformedBy user is required.';
    END IF;

    START TRANSACTION;

    SELECT Quantity
      INTO v_CurrentQuantity
      FROM Inventory_Batch
     WHERE BatchID = p_BatchID
     FOR UPDATE;

    IF v_NotFound THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The selected inventory batch does not exist.';
    END IF;

    IF p_TransactionType IN ('STOCK_IN', 'ADJUSTMENT_IN', 'RETURN_IN') THEN
        SET v_NewQuantity = v_CurrentQuantity + p_Quantity;
        IF v_NewQuantity > 4294967295 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock quantity exceeds the allowed range.';
        END IF;
    ELSE
        -- Do not allow an outbound movement to consume units already held
        -- for active, unexpired reservations.
        SELECT COALESCE(SUM(Quantity), 0)
          INTO v_ReservedQuantity
          FROM Reservation
         WHERE BatchID = p_BatchID
           AND Status = 'ACTIVE'
           AND ExpiryDate > CURRENT_TIMESTAMP();

        IF v_ReservedQuantity >= v_CurrentQuantity THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No unreserved stock is available for this outbound transaction.';
        ELSEIF p_Quantity > (v_CurrentQuantity - v_ReservedQuantity) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Outbound quantity exceeds the unreserved stock.';
        END IF;
        SET v_NewQuantity = v_CurrentQuantity - p_Quantity;
    END IF;

    INSERT INTO Stock_Transaction
        (BatchID, TransactionType, Quantity, ReferenceNo, PerformedBy, Remarks)
    VALUES
        (p_BatchID, p_TransactionType, p_Quantity, p_ReferenceNo, p_PerformedBy, p_Remarks);

    UPDATE Inventory_Batch
       SET Quantity = v_NewQuantity
     WHERE BatchID = p_BatchID;

    COMMIT;

    SELECT
        p_BatchID AS BatchID,
        v_CurrentQuantity AS PreviousQuantity,
        p_TransactionType AS TransactionType,
        p_Quantity AS TransactionQuantity,
        v_NewQuantity AS UpdatedQuantity,
        'Stock transaction recorded successfully.' AS Result;
END$$


-- 5. Create a reservation only when sufficient unreserved stock exists.
-- The batch row is locked so concurrent calls through this procedure do
-- not reserve more units than are available. Reservation does not reduce
-- Inventory_Batch.Quantity; the availability views subtract active holds.
-- Example (execute only when you intend to create a reservation):
-- CALL sp_create_reservation(1, 1, 2, 'Customer collection', DATE_ADD(NOW(), INTERVAL 2 HOUR));
CREATE PROCEDURE sp_create_reservation(
    IN p_BatchID INT,
    IN p_ReservedBy INT,
    IN p_Quantity INT UNSIGNED,
    IN p_Purpose VARCHAR(255),
    IN p_ReservationExpiry DATETIME
)
BEGIN
    DECLARE v_BatchQuantity INT UNSIGNED DEFAULT 0;
    DECLARE v_BatchExpiry DATE;
    DECLARE v_PharmacyStatus VARCHAR(10);
    DECLARE v_ReservedQuantity BIGINT UNSIGNED DEFAULT 0;
    DECLARE v_NotFound BOOLEAN DEFAULT FALSE;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_NotFound = TRUE;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_BatchID IS NULL OR p_ReservedBy IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BatchID and ReservedBy are required.';
    END IF;

    IF p_Quantity IS NULL OR p_Quantity = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reservation quantity must be greater than zero.';
    END IF;

    IF p_ReservationExpiry IS NULL OR p_ReservationExpiry <= CURRENT_TIMESTAMP() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reservation expiry must be in the future.';
    END IF;

    START TRANSACTION;

    SELECT ib.Quantity, ib.ExpiryDate, p.Status
      INTO v_BatchQuantity, v_BatchExpiry, v_PharmacyStatus
      FROM Inventory_Batch ib
      JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
     WHERE ib.BatchID = p_BatchID
     FOR UPDATE;

    IF v_NotFound THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The selected inventory batch does not exist.';
    END IF;

    IF v_PharmacyStatus <> 'ACTIVE' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reservations are allowed only at active pharmacies.';
    END IF;

    IF v_BatchExpiry < CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Expired medicine batches cannot be reserved.';
    END IF;

    IF DATE(p_ReservationExpiry) > v_BatchExpiry THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reservation cannot extend beyond the medicine batch expiry date.';
    END IF;

    SELECT COALESCE(SUM(Quantity), 0)
      INTO v_ReservedQuantity
      FROM Reservation
     WHERE BatchID = p_BatchID
       AND Status = 'ACTIVE'
       AND ExpiryDate > CURRENT_TIMESTAMP();

    IF v_ReservedQuantity + p_Quantity > v_BatchQuantity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient unreserved stock for this reservation.';
    END IF;

    INSERT INTO Reservation
        (BatchID, ReservedBy, Quantity, Purpose, ExpiryDate, Status)
    VALUES
        (p_BatchID, p_ReservedBy, p_Quantity, p_Purpose, p_ReservationExpiry, 'ACTIVE');

    COMMIT;

    SELECT LAST_INSERT_ID() AS ReservationID,
           p_BatchID AS BatchID,
           p_Quantity AS ReservedQuantity,
           'Reservation created successfully.' AS Result;
END$$

DELIMITER ;

-- =====================================================================
-- SECTION C: VERIFICATION QUERIES
-- Run these after the views and procedures have been created.
-- =====================================================================

-- 1. List all created views.
SHOW FULL TABLES IN medical_store_network WHERE TABLE_TYPE = 'VIEW';

-- 2. Check the pharmacy-wise inventory summary.
SELECT * FROM vw_pharmacy_inventory_summary ORDER BY PharmacyName;

-- 3. Check batch status and available quantities.
SELECT BatchID, BatchNo, BrandName, PharmacyName,
       RecordedQuantity, ReservedQuantity, AvailableQuantity, StockStatus
FROM vw_batch_stock_status
ORDER BY PharmacyName, BrandName;

-- 4. Check the detailed stock transaction ledger.
SELECT * FROM vw_stock_transaction_ledger
ORDER BY TransactionDate DESC, TransactionID DESC;

-- 5. Check stock verification and discrepancy details.
SELECT * FROM vw_stock_verification_report
ORDER BY VerificationDate DESC, VerificationID DESC;

-- =====================================================================
-- OPTIONAL PROCEDURE TESTS
-- These are intentionally commented out because they change data.
-- Uncomment and run one at a time only when you want to test them.
-- =====================================================================

-- CALL sp_search_medicine('paracetamol');
-- CALL sp_get_available_alternatives(1);
-- CALL sp_find_composition_matches(1);
-- CALL sp_record_stock_transaction(1, 'STOCK_IN', 10, 'GRN-TEST-001', 1, 'Test stock receipt');
-- CALL sp_create_reservation(1, 1, 2, 'Customer collection', DATE_ADD(NOW(), INTERVAL 2 HOUR));

-- =====================================================================
-- END OF PHASE 4
-- =====================================================================
