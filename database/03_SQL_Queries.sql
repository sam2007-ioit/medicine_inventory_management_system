-- =====================================================================
-- MEDICAL STORE NETWORK AND MEDICINE AVAILABILITY SYSTEM
-- PHASE 3: SQL QUERIES (DQL)
-- Database: MySQL 8.0+
--
-- Prerequisites:
--   1. Execute 01_Database_Schema.sql
--   2. Execute 02_Sample_Data.sql
--
-- This file contains SELECT queries only. It does not create, alter,
-- insert, update, or delete database objects or records.
-- You may execute the entire file to view the result sets, or run
-- individual queries separately in MySQL Workbench.
-- =====================================================================

USE medical_store_network;

-- Use the same connection collation as the database schema.
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- USER-DEFINED SEARCH VALUES
-- Change these values to test different searches.
-- ---------------------------------------------------------------------
SET @search_term = _utf8mb4'Dolo' COLLATE utf8mb4_unicode_ci;
SET @requested_brand = _utf8mb4'Dolo 650' COLLATE utf8mb4_unicode_ci;
SET @source_medicine_id = 1;
SET @pharmacy_id = 1;

-- =====================================================================
-- SECTION A: BASIC SELECT, WHERE, ORDER BY, DISTINCT AND LIKE
-- =====================================================================

-- 1. Display all registered pharmacies.
SELECT *
FROM Pharmacy
ORDER BY PharmacyID;

-- 2. Display only active pharmacies.
SELECT PharmacyID, Name, Phone, Email, Address
FROM Pharmacy
WHERE Status = 'ACTIVE'
ORDER BY Name;

-- 3. Display the complete medicine catalogue.
SELECT MedicineID, GenericName, BrandName, DosageForm, Category
FROM Medicine
ORDER BY GenericName, BrandName;

-- 4. Search medicines by brand name or generic name.
-- Change @search_term above to search for another medicine.
SELECT MedicineID, GenericName, BrandName, DosageForm, Category
FROM Medicine
WHERE GenericName COLLATE utf8mb4_unicode_ci
          LIKE (CONCAT('%', @search_term, '%') COLLATE utf8mb4_unicode_ci)
   OR BrandName COLLATE utf8mb4_unicode_ci
          LIKE (CONCAT('%', @search_term, '%') COLLATE utf8mb4_unicode_ci)
ORDER BY BrandName;

-- 5. Display the distinct medicine categories available in the catalogue.
SELECT DISTINCT Category
FROM Medicine
WHERE Category IS NOT NULL
ORDER BY Category;

-- 6. Display all suppliers and their contact details.
SELECT SupplierID, Name, Phone, Email, Address
FROM Supplier
ORDER BY Name;

-- =====================================================================
-- SECTION B: JOINS AND MEDICINE COMPOSITION
-- =====================================================================

-- 7. Display each medicine with all its active ingredients and strengths.
SELECT m.MedicineID, m.BrandName, m.GenericName, m.DosageForm,
       c.IngredientName, mc.StrengthPerUnit
FROM Medicine m
JOIN Medicine_Composition mc ON mc.MedicineID = m.MedicineID
JOIN Composition c ON c.CompositionID = mc.CompositionID
ORDER BY m.MedicineID, c.IngredientName;

-- 8. Display the number of ingredients present in each medicine.
SELECT m.MedicineID, m.BrandName, m.GenericName,
       COUNT(mc.CompositionID) AS IngredientCount
FROM Medicine m
LEFT JOIN Medicine_Composition mc ON mc.MedicineID = m.MedicineID
GROUP BY m.MedicineID, m.BrandName, m.GenericName
ORDER BY IngredientCount DESC, m.BrandName;

-- 9. Display inventory batches with medicine, pharmacy and supplier details.
SELECT ib.BatchID, ib.BatchNo, m.BrandName, m.GenericName,
       p.Name AS PharmacyName, s.Name AS SupplierName,
       ib.Quantity, ib.PurchasePrice, ib.ExpiryDate
FROM Inventory_Batch ib
JOIN Medicine m ON m.MedicineID = ib.MedicineID
JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
JOIN Supplier s ON s.SupplierID = ib.SupplierID
ORDER BY p.Name, m.BrandName, ib.ExpiryDate;

-- 10. Display all batches belonging to one selected pharmacy.
-- Change @pharmacy_id above to another PharmacyID.
SELECT p.Name AS PharmacyName, ib.BatchNo, m.BrandName,
       ib.Quantity, ib.PurchasePrice, ib.ExpiryDate
FROM Inventory_Batch ib
JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
JOIN Medicine m ON m.MedicineID = ib.MedicineID
WHERE p.PharmacyID = @pharmacy_id
ORDER BY m.BrandName, ib.ExpiryDate;

-- =====================================================================
-- SECTION C: MEDICINE AVAILABILITY SEARCH
-- =====================================================================

-- 11. Exact-brand availability across all active pharmacies.
-- Only unexpired batches with positive stock are included.
SELECT m.BrandName, m.GenericName,
       p.Name AS PharmacyName, p.Address, p.Phone,
       ib.BatchNo, ib.Quantity AS BatchQuantity, ib.ExpiryDate
FROM Medicine m
JOIN Inventory_Batch ib ON ib.MedicineID = m.MedicineID
JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
WHERE m.BrandName COLLATE utf8mb4_unicode_ci =
      @requested_brand COLLATE utf8mb4_unicode_ci
  AND p.Status = 'ACTIVE'
  AND ib.Quantity > 0
  AND ib.ExpiryDate >= CURDATE()
ORDER BY p.Name, ib.ExpiryDate;

-- 12. Total unexpired stock of each medicine at each active pharmacy.
SELECT m.MedicineID, m.BrandName, m.GenericName,
       p.PharmacyID, p.Name AS PharmacyName,
       SUM(ib.Quantity) AS TotalStock,
       MIN(ib.ExpiryDate) AS NearestExpiryDate
FROM Inventory_Batch ib
JOIN Medicine m ON m.MedicineID = ib.MedicineID
JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
WHERE p.Status = 'ACTIVE'
  AND ib.Quantity > 0
  AND ib.ExpiryDate >= CURDATE()
GROUP BY m.MedicineID, m.BrandName, m.GenericName,
         p.PharmacyID, p.Name
ORDER BY m.BrandName, p.Name;

-- 13. Display mapped alternative brands and their available pharmacies.
-- The mapping is a catalogue relationship, not clinical substitution advice.
SELECT requested.BrandName AS RequestedMedicine,
       alternative.BrandName AS AlternativeMedicine,
       p.Name AS PharmacyName, p.Address,
       SUM(ib.Quantity) AS AvailableBatchQuantity,
       MIN(ib.ExpiryDate) AS NearestExpiryDate,
       ma.Remarks
FROM Medicine_Alternative ma
JOIN Medicine requested ON requested.MedicineID = ma.MedicineID
JOIN Medicine alternative
     ON alternative.MedicineID = ma.AlternativeMedicineID
JOIN Inventory_Batch ib ON ib.MedicineID = alternative.MedicineID
JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
WHERE ma.MedicineID = @source_medicine_id
  AND p.Status = 'ACTIVE'
  AND ib.Quantity > 0
  AND ib.ExpiryDate >= CURDATE()
GROUP BY requested.MedicineID, requested.BrandName,
         alternative.MedicineID, alternative.BrandName,
         p.PharmacyID, p.Name, p.Address, ma.Remarks
ORDER BY alternative.BrandName, p.Name;

-- 14. Find catalogue medicines with exactly matching ingredient sets,
-- strengths and dosage form for the medicine selected by ID.
-- This is a database-level composition match only; it is not a clinical
-- determination that the medicines can be substituted.
WITH source_medicine AS (
    -- Include BrandName because it is displayed in the final SELECT.
    SELECT MedicineID, BrandName, DosageForm
    FROM Medicine
    WHERE MedicineID = @source_medicine_id
),
matching_medicines AS (
    SELECT candidate.MedicineID
    FROM Medicine candidate
    CROSS JOIN source_medicine src
    WHERE candidate.MedicineID <> src.MedicineID
      AND candidate.DosageForm = src.DosageForm
      -- Every source ingredient and strength must exist in the candidate.
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
      -- The candidate must not contain an additional ingredient/strength.
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
SELECT src.BrandName AS SearchedMedicine,
       candidate.BrandName AS CompositionMatch,
       candidate.GenericName,
       candidate.DosageForm
FROM source_medicine src
JOIN matching_medicines mm ON TRUE
JOIN Medicine candidate ON candidate.MedicineID = mm.MedicineID
ORDER BY candidate.BrandName;

-- 15. Display available quantity after subtracting active reservations.
-- Reservations are deducted batch-wise to avoid double counting.
SELECT m.BrandName, p.Name AS PharmacyName,
       SUM(ib.Quantity) AS PhysicalSystemStock,
       SUM(COALESCE(r.ReservedQuantity, 0)) AS ActiveReservedQuantity,
       SUM(GREATEST(ib.Quantity - COALESCE(r.ReservedQuantity, 0), 0)) AS AvailableToReserve
FROM Inventory_Batch ib
JOIN Medicine m ON m.MedicineID = ib.MedicineID
JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
LEFT JOIN (
    SELECT BatchID, SUM(Quantity) AS ReservedQuantity
    FROM Reservation
    WHERE Status = 'ACTIVE'
      AND ExpiryDate > NOW()
    GROUP BY BatchID
) r ON r.BatchID = ib.BatchID
WHERE p.Status = 'ACTIVE'
  AND ib.ExpiryDate >= CURDATE()
  AND ib.Quantity > 0
GROUP BY m.MedicineID, m.BrandName, p.PharmacyID, p.Name
ORDER BY m.BrandName, p.Name;

-- =====================================================================
-- SECTION D: AGGREGATE FUNCTIONS, GROUP BY AND HAVING
-- =====================================================================

-- 16. Count the number of medicines, pharmacies and suppliers.
SELECT
    (SELECT COUNT(*) FROM Medicine) AS TotalMedicines,
    (SELECT COUNT(*) FROM Pharmacy) AS TotalPharmacies,
    (SELECT COUNT(*) FROM Supplier) AS TotalSuppliers;

-- 17. Display the total number of batches and total units at each pharmacy.
SELECT p.PharmacyID, p.Name AS PharmacyName,
       COUNT(ib.BatchID) AS NumberOfBatches,
       COALESCE(SUM(ib.Quantity), 0) AS TotalUnits
FROM Pharmacy p
LEFT JOIN Inventory_Batch ib ON ib.PharmacyID = p.PharmacyID
GROUP BY p.PharmacyID, p.Name
ORDER BY TotalUnits DESC;

-- 18. Display pharmacies having more than 5 distinct medicines in stock.
SELECT p.PharmacyID, p.Name AS PharmacyName,
       COUNT(DISTINCT ib.MedicineID) AS DistinctMedicines
FROM Pharmacy p
JOIN Inventory_Batch ib ON ib.PharmacyID = p.PharmacyID
WHERE p.Status = 'ACTIVE'
  AND ib.Quantity > 0
  AND ib.ExpiryDate >= CURDATE()
GROUP BY p.PharmacyID, p.Name
HAVING COUNT(DISTINCT ib.MedicineID) > 5
ORDER BY DistinctMedicines DESC;

-- 19. Display minimum, maximum and average purchase price per medicine.
-- PurchasePrice is the pharmacy's purchase cost, not the retail selling price.
SELECT m.MedicineID, m.BrandName,
       MIN(ib.PurchasePrice) AS MinimumPurchasePrice,
       MAX(ib.PurchasePrice) AS MaximumPurchasePrice,
       ROUND(AVG(ib.PurchasePrice), 2) AS AveragePurchasePrice
FROM Medicine m
JOIN Inventory_Batch ib ON ib.MedicineID = m.MedicineID
GROUP BY m.MedicineID, m.BrandName
ORDER BY m.BrandName;

-- 20. Display the medicines whose total current stock is below 20 units.
SELECT m.MedicineID, m.BrandName,
       SUM(ib.Quantity) AS TotalCurrentStock
FROM Medicine m
JOIN Inventory_Batch ib ON ib.MedicineID = m.MedicineID
WHERE ib.ExpiryDate >= CURDATE()
GROUP BY m.MedicineID, m.BrandName
HAVING SUM(ib.Quantity) < 20
ORDER BY TotalCurrentStock;

-- =====================================================================
-- SECTION E: SUBQUERIES AND EXISTS
-- =====================================================================

-- 21. Find medicines that currently have no unexpired positive stock.
SELECT m.MedicineID, m.BrandName, m.GenericName
FROM Medicine m
WHERE NOT EXISTS (
    SELECT 1
    FROM Inventory_Batch ib
    JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
    WHERE ib.MedicineID = m.MedicineID
      AND ib.Quantity > 0
      AND ib.ExpiryDate >= CURDATE()
      AND p.Status = 'ACTIVE'
)
ORDER BY m.BrandName;

-- 22. Find pharmacies where the selected medicine is available.
SELECT p.PharmacyID, p.Name, p.Address, p.Phone
FROM Pharmacy p
WHERE p.Status = 'ACTIVE'
  AND EXISTS (
      SELECT 1
      FROM Inventory_Batch ib
      JOIN Medicine m ON m.MedicineID = ib.MedicineID
      WHERE ib.PharmacyID = p.PharmacyID
        AND m.BrandName COLLATE utf8mb4_unicode_ci =
            @requested_brand COLLATE utf8mb4_unicode_ci
        AND ib.Quantity > 0
        AND ib.ExpiryDate >= CURDATE()
  )
ORDER BY p.Name;

-- 23. Find batches with a purchase price below the average purchase price
-- of the same medicine across all batches.
SELECT ib.BatchID, m.BrandName, p.Name AS PharmacyName,
       ib.PurchasePrice,
       (SELECT ROUND(AVG(ib2.PurchasePrice), 2)
        FROM Inventory_Batch ib2
        WHERE ib2.MedicineID = ib.MedicineID) AS MedicineAveragePurchasePrice
FROM Inventory_Batch ib
JOIN Medicine m ON m.MedicineID = ib.MedicineID
JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
WHERE ib.PurchasePrice < (
    SELECT AVG(ib2.PurchasePrice)
    FROM Inventory_Batch ib2
    WHERE ib2.MedicineID = ib.MedicineID
)
ORDER BY m.BrandName, ib.PurchasePrice;

-- 24. Display medicines whose total stock is greater than the average
-- total stock per medicine.
SELECT stock_summary.MedicineID,
       stock_summary.BrandName,
       stock_summary.TotalStock
FROM (
    SELECT m.MedicineID, m.BrandName,
           SUM(ib.Quantity) AS TotalStock
    FROM Medicine m
    JOIN Inventory_Batch ib ON ib.MedicineID = m.MedicineID
    WHERE ib.ExpiryDate >= CURDATE()
    GROUP BY m.MedicineID, m.BrandName
) AS stock_summary
WHERE stock_summary.TotalStock > (
    SELECT AVG(per_medicine.TotalStock)
    FROM (
        SELECT SUM(ib2.Quantity) AS TotalStock
        FROM Inventory_Batch ib2
        WHERE ib2.ExpiryDate >= CURDATE()
        GROUP BY ib2.MedicineID
    ) AS per_medicine
)
ORDER BY stock_summary.TotalStock DESC;

-- =====================================================================
-- SECTION F: STOCK, EXPIRY AND SUPPLIER REPORTS
-- =====================================================================

-- 25. Display batches with low stock (10 units or fewer).
SELECT ib.BatchID, ib.BatchNo, m.BrandName,
       p.Name AS PharmacyName, ib.Quantity, ib.ExpiryDate
FROM Inventory_Batch ib
JOIN Medicine m ON m.MedicineID = ib.MedicineID
JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
WHERE ib.Quantity <= 10
  AND ib.ExpiryDate >= CURDATE()
ORDER BY ib.Quantity, p.Name;

-- 26. Display batches expiring in the next 90 days.
SELECT ib.BatchID, ib.BatchNo, m.BrandName,
       p.Name AS PharmacyName, ib.Quantity, ib.ExpiryDate,
       DATEDIFF(ib.ExpiryDate, CURDATE()) AS DaysToExpiry
FROM Inventory_Batch ib
JOIN Medicine m ON m.MedicineID = ib.MedicineID
JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
WHERE ib.Quantity > 0
  AND ib.ExpiryDate BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 90 DAY)
ORDER BY ib.ExpiryDate;

-- 27. Display expired batches that still have a positive recorded quantity.
SELECT ib.BatchID, ib.BatchNo, m.BrandName,
       p.Name AS PharmacyName, ib.Quantity, ib.ExpiryDate
FROM Inventory_Batch ib
JOIN Medicine m ON m.MedicineID = ib.MedicineID
JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
WHERE ib.ExpiryDate < CURDATE()
  AND ib.Quantity > 0
ORDER BY ib.ExpiryDate;

-- 28. Display suppliers and the batches supplied by them.
SELECT s.SupplierID, s.Name AS SupplierName,
       COUNT(ib.BatchID) AS BatchesSupplied,
       COALESCE(SUM(ib.Quantity), 0) AS UnitsInThoseBatches
FROM Supplier s
LEFT JOIN Inventory_Batch ib ON ib.SupplierID = s.SupplierID
GROUP BY s.SupplierID, s.Name
ORDER BY BatchesSupplied DESC, s.Name;

-- =====================================================================
-- SECTION G: STOCK TRANSACTIONS AND VERIFICATION
-- =====================================================================

-- 29. Display the stock transaction ledger with user and batch details.
SELECT st.TransactionID, st.TransactionType, st.Quantity,
       st.ReferenceNo, st.TransactionDate,
       m.BrandName, ib.BatchNo, p.Name AS PharmacyName,
       ua.Name AS PerformedBy, st.Remarks
FROM Stock_Transaction st
JOIN Inventory_Batch ib ON ib.BatchID = st.BatchID
JOIN Medicine m ON m.MedicineID = ib.MedicineID
JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
JOIN User_Account ua ON ua.UserID = st.PerformedBy
ORDER BY st.TransactionDate DESC, st.TransactionID DESC;

-- 30. Count transactions and units by transaction type.
SELECT TransactionType,
       COUNT(*) AS NumberOfTransactions,
       SUM(Quantity) AS TotalUnitsMoved
FROM Stock_Transaction
GROUP BY TransactionType
ORDER BY NumberOfTransactions DESC;

-- 31. Display monthly stock transaction totals.
SELECT DATE_FORMAT(TransactionDate, '%Y-%m') AS TransactionMonth,
       TransactionType,
       COUNT(*) AS NumberOfTransactions,
       SUM(Quantity) AS TotalUnits
FROM Stock_Transaction
GROUP BY DATE_FORMAT(TransactionDate, '%Y-%m'), TransactionType
ORDER BY TransactionMonth, TransactionType;

-- 32. Display stock verification results and calculated differences.
SELECT sv.VerificationID, ib.BatchNo, m.BrandName,
       p.Name AS PharmacyName, sv.VerificationDate,
       sv.SystemQuantity, sv.PhysicalQuantity,
       sv.Difference, sv.VerificationStatus,
       ua.Name AS VerifiedBy, sv.Remarks
FROM Stock_Verification sv
JOIN Inventory_Batch ib ON ib.BatchID = sv.BatchID
JOIN Medicine m ON m.MedicineID = ib.MedicineID
JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
JOIN User_Account ua ON ua.UserID = sv.VerifiedBy
ORDER BY sv.VerificationDate DESC;

-- 33. Display discrepancy records, including resolution details.
SELECT d.DiscrepancyID, sv.VerificationID, ib.BatchNo,
       m.BrandName, p.Name AS PharmacyName,
       d.ReportDate, d.Reason, d.Status,
       reporter.Name AS ReportedBy,
       resolver.Name AS ResolvedBy,
       d.ResolvedDate, d.Remarks
FROM Discrepancy d
JOIN Stock_Verification sv ON sv.VerificationID = d.VerificationID
JOIN Inventory_Batch ib ON ib.BatchID = sv.BatchID
JOIN Medicine m ON m.MedicineID = ib.MedicineID
JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
JOIN User_Account reporter ON reporter.UserID = d.ReportedBy
LEFT JOIN User_Account resolver ON resolver.UserID = d.ResolvedBy
ORDER BY d.ReportDate DESC;

-- =====================================================================
-- SECTION H: RESERVATION REPORTS
-- =====================================================================

-- 34. Display all reservations with medicine, pharmacy and user details.
SELECT r.ReservationID, m.BrandName, p.Name AS PharmacyName,
       ib.BatchNo, r.Quantity, r.Purpose,
       r.ReservationDate, r.ExpiryDate, r.Status,
       ua.Name AS ReservedBy
FROM Reservation r
JOIN Inventory_Batch ib ON ib.BatchID = r.BatchID
JOIN Medicine m ON m.MedicineID = ib.MedicineID
JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
JOIN User_Account ua ON ua.UserID = r.ReservedBy
ORDER BY r.ReservationDate DESC;

-- 35. Display reservations that are active and whose expiry time has not passed.
SELECT r.ReservationID, m.BrandName,
       p.Name AS PharmacyName, r.Quantity,
       r.ExpiryDate, ua.Name AS ReservedBy
FROM Reservation r
JOIN Inventory_Batch ib ON ib.BatchID = r.BatchID
JOIN Medicine m ON m.MedicineID = ib.MedicineID
JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
JOIN User_Account ua ON ua.UserID = r.ReservedBy
WHERE r.Status = 'ACTIVE'
  AND r.ExpiryDate > NOW()
ORDER BY r.ExpiryDate;

-- 36. Display reservation counts and quantities grouped by status.
SELECT Status,
       COUNT(*) AS NumberOfReservations,
       SUM(Quantity) AS TotalReservedUnits
FROM Reservation
GROUP BY Status
ORDER BY NumberOfReservations DESC;

-- =====================================================================
-- SECTION I: SET OPERATIONS AND STRING/DATE FUNCTIONS
-- =====================================================================

-- 37. Display a combined contact directory of pharmacies and suppliers.
SELECT 'PHARMACY' AS EntityType, Name, Phone, Email, Address
FROM Pharmacy
UNION ALL
SELECT 'SUPPLIER' AS EntityType, Name, Phone, Email, Address
FROM Supplier
ORDER BY EntityType, Name;

-- 38. Demonstrate string functions on medicine names.
SELECT MedicineID,
       UPPER(BrandName) AS BrandNameUppercase,
       LOWER(GenericName) AS GenericNameLowercase,
       CHAR_LENGTH(BrandName) AS BrandNameLength,
       CONCAT(BrandName, ' - ', DosageForm) AS MedicineLabel
FROM Medicine
ORDER BY BrandName;

-- 39. Demonstrate date functions for inventory batches.
SELECT BatchID, BatchNo,
       DATE_FORMAT(MfgDate, '%d-%m-%Y') AS ManufacturingDate,
       DATE_FORMAT(ExpiryDate, '%d-%m-%Y') AS ExpiryDate,
       DATEDIFF(ExpiryDate, CURDATE()) AS DaysUntilExpiry
FROM Inventory_Batch
ORDER BY ExpiryDate;

-- =====================================================================
-- SECTION J: COMBINED PROJECT SUMMARY
-- =====================================================================

-- 40. Pharmacy-wise summary of currently available medicines and units.
SELECT p.PharmacyID, p.Name AS PharmacyName,
       COUNT(DISTINCT ib.MedicineID) AS DifferentMedicinesAvailable,
       COUNT(ib.BatchID) AS AvailableBatches,
       SUM(ib.Quantity) AS TotalUnexpiredUnits
FROM Pharmacy p
LEFT JOIN Inventory_Batch ib
       ON ib.PharmacyID = p.PharmacyID
      AND ib.Quantity > 0
      AND ib.ExpiryDate >= CURDATE()
WHERE p.Status = 'ACTIVE'
GROUP BY p.PharmacyID, p.Name
ORDER BY p.Name;

-- 41. Calculate the recorded inventory purchase-cost value per pharmacy.
-- This is based on PurchasePrice x Quantity, not customer selling price.
SELECT p.PharmacyID, p.Name AS PharmacyName,
       ROUND(SUM(ib.PurchasePrice * ib.Quantity), 2) AS InventoryPurchaseValue
FROM Pharmacy p
LEFT JOIN Inventory_Batch ib ON ib.PharmacyID = p.PharmacyID
GROUP BY p.PharmacyID, p.Name
ORDER BY InventoryPurchaseValue DESC;

-- 42. Compare stock ledger net movement with the quantity in each batch.
-- This is a reconciliation report; it does not update inventory.
SELECT ib.BatchID, ib.BatchNo, m.BrandName,
       ib.Quantity AS RecordedBatchQuantity,
       COALESCE(SUM(
           CASE
               WHEN st.TransactionType IN ('STOCK_IN', 'ADJUSTMENT_IN', 'RETURN_IN')
                   THEN st.Quantity
               WHEN st.TransactionType IN ('STOCK_OUT', 'ADJUSTMENT_OUT', 'RETURN_OUT')
                   THEN -st.Quantity
               ELSE 0
           END
       ), 0) AS NetLedgerMovement
FROM Inventory_Batch ib
JOIN Medicine m ON m.MedicineID = ib.MedicineID
LEFT JOIN Stock_Transaction st ON st.BatchID = ib.BatchID
GROUP BY ib.BatchID, ib.BatchNo, m.BrandName, ib.Quantity
ORDER BY ib.BatchID;

-- End of Phase 3: SQL Queries.
