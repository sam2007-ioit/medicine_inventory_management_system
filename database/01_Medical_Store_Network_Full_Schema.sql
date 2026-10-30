-- ============================================================
-- MEDICAL STORE NETWORK AND MEDICINE AVAILABILITY SYSTEM
-- Database: MySQL 8.0.16+
-- Phase 1: Database and table creation (DDL)
-- ============================================================

CREATE DATABASE IF NOT EXISTS medical_store_network
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE medical_store_network;

-- CREATE TABLE IF NOT EXISTS allows this script to continue safely
-- when earlier tables were already created by a previous attempt.
-- Existing table definitions/data are not overwritten.

-- 1. PHARMACY
CREATE TABLE IF NOT EXISTS Pharmacy (
    PharmacyID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(120) NOT NULL,
    LicenseNo VARCHAR(60) NOT NULL UNIQUE,
    Phone VARCHAR(20),
    Email VARCHAR(120) UNIQUE,
    Address VARCHAR(255) NOT NULL,
    Latitude DECIMAL(10,7),
    Longitude DECIMAL(10,7),
    Status ENUM('ACTIVE', 'INACTIVE') NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT chk_pharmacy_latitude
        CHECK (Latitude IS NULL OR Latitude BETWEEN -90 AND 90),
    CONSTRAINT chk_pharmacy_longitude
        CHECK (Longitude IS NULL OR Longitude BETWEEN -180 AND 180)
) ENGINE=InnoDB;

-- 2. SUPPLIER
CREATE TABLE IF NOT EXISTS Supplier (
    SupplierID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(120) NOT NULL,
    Phone VARCHAR(20),
    Email VARCHAR(120) UNIQUE,
    Address VARCHAR(255)
) ENGINE=InnoDB;

-- 3. MEDICINE
-- Composition and ingredient-level strength are stored in the
-- Composition and Medicine_Composition tables to avoid repeating groups.
CREATE TABLE IF NOT EXISTS Medicine (
    MedicineID INT AUTO_INCREMENT PRIMARY KEY,
    GenericName VARCHAR(150) NOT NULL,
    BrandName VARCHAR(150),
    DosageForm VARCHAR(60) NOT NULL,
    Category VARCHAR(80),
    Description TEXT,
    INDEX idx_medicine_generic_name (GenericName),
    INDEX idx_medicine_brand_name (BrandName)
) ENGINE=InnoDB;

-- 4. COMPOSITION
CREATE TABLE IF NOT EXISTS Composition (
    CompositionID INT AUTO_INCREMENT PRIMARY KEY,
    IngredientName VARCHAR(150) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- 5. MEDICINE_COMPOSITION (junction table)
-- StrengthPerUnit records the strength of each ingredient in a medicine.
CREATE TABLE IF NOT EXISTS Medicine_Composition (
    MedicineID INT NOT NULL,
    CompositionID INT NOT NULL,
    StrengthPerUnit VARCHAR(50) NOT NULL,
    PRIMARY KEY (MedicineID, CompositionID),
    INDEX idx_medicine_composition_ingredient (CompositionID),
    CONSTRAINT fk_mc_medicine
        FOREIGN KEY (MedicineID) REFERENCES Medicine(MedicineID)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_mc_composition
        FOREIGN KEY (CompositionID) REFERENCES Composition(CompositionID)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 6. USER_ACCOUNT
-- PasswordHash should contain a hash, never a plain-text password.
CREATE TABLE IF NOT EXISTS User_Account (
    UserID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(120) NOT NULL,
    Email VARCHAR(120) NOT NULL UNIQUE,
    Phone VARCHAR(20),
    PasswordHash VARCHAR(255) NOT NULL,
    Role ENUM('ADMIN', 'STAFF') NOT NULL DEFAULT 'STAFF',
    Status ENUM('ACTIVE', 'INACTIVE') NOT NULL DEFAULT 'ACTIVE'
) ENGINE=InnoDB;

-- 7. MEDICINE_ALTERNATIVE (self-referencing junction table)
-- A row means AlternativeMedicineID is listed as an alternative to MedicineID.
CREATE TABLE IF NOT EXISTS Medicine_Alternative (
    MedicineID INT NOT NULL,
    AlternativeMedicineID INT NOT NULL,
    AddedBy INT,
    Remarks VARCHAR(255),
    AddedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (MedicineID, AlternativeMedicineID),
    INDEX idx_alternative_medicine (AlternativeMedicineID),
    CONSTRAINT fk_ma_medicine
        FOREIGN KEY (MedicineID) REFERENCES Medicine(MedicineID)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_ma_alternative_medicine
        FOREIGN KEY (AlternativeMedicineID) REFERENCES Medicine(MedicineID)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_ma_added_by
        FOREIGN KEY (AddedBy) REFERENCES User_Account(UserID)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- 8. INVENTORY_BATCH
-- Each batch belongs to one pharmacy, one medicine and one supplier.
CREATE TABLE IF NOT EXISTS Inventory_Batch (
    BatchID INT AUTO_INCREMENT PRIMARY KEY,
    PharmacyID INT NOT NULL,
    MedicineID INT NOT NULL,
    SupplierID INT NOT NULL,
    BatchNo VARCHAR(60) NOT NULL,
    MfgDate DATE NOT NULL,
    ExpiryDate DATE NOT NULL,
    PurchaseDate DATE NOT NULL,
    Quantity INT UNSIGNED NOT NULL DEFAULT 0,
    PurchasePrice DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    UNIQUE KEY uq_batch_at_pharmacy (PharmacyID, MedicineID, BatchNo),
    INDEX idx_batch_expiry (ExpiryDate),
    INDEX idx_batch_medicine_pharmacy (MedicineID, PharmacyID),
    CONSTRAINT chk_batch_dates
        CHECK (ExpiryDate > MfgDate AND ExpiryDate > PurchaseDate),
    CONSTRAINT chk_batch_purchase_price
        CHECK (PurchasePrice >= 0),
    CONSTRAINT fk_batch_pharmacy
        FOREIGN KEY (PharmacyID) REFERENCES Pharmacy(PharmacyID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_batch_medicine
        FOREIGN KEY (MedicineID) REFERENCES Medicine(MedicineID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_batch_supplier
        FOREIGN KEY (SupplierID) REFERENCES Supplier(SupplierID)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 9. STOCK_TRANSACTION
-- Quantity is always entered as a positive number.
-- Triggers/procedures in a later phase will apply the stock movement
-- to Inventory_Batch.Quantity.
CREATE TABLE IF NOT EXISTS Stock_Transaction (
    TransactionID INT AUTO_INCREMENT PRIMARY KEY,
    BatchID INT NOT NULL,
    TransactionType ENUM(
        'STOCK_IN', 'STOCK_OUT',
        'ADJUSTMENT_IN', 'ADJUSTMENT_OUT',
        'RETURN_IN', 'RETURN_OUT'
    ) NOT NULL,
    Quantity INT UNSIGNED NOT NULL,
    ReferenceNo VARCHAR(100),
    PerformedBy INT NOT NULL,
    TransactionDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Remarks VARCHAR(255),
    CONSTRAINT chk_transaction_quantity CHECK (Quantity > 0),
    INDEX idx_transaction_batch_date (BatchID, TransactionDate),
    INDEX idx_transaction_user (PerformedBy),
    CONSTRAINT fk_transaction_batch
        FOREIGN KEY (BatchID) REFERENCES Inventory_Batch(BatchID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_transaction_user
        FOREIGN KEY (PerformedBy) REFERENCES User_Account(UserID)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 10. STOCK_VERIFICATION
-- Difference and VerificationStatus are generated automatically.
CREATE TABLE IF NOT EXISTS Stock_Verification (
    VerificationID INT AUTO_INCREMENT PRIMARY KEY,
    BatchID INT NOT NULL,
    VerifiedBy INT NOT NULL,
    VerificationDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    SystemQuantity INT UNSIGNED NOT NULL,
    PhysicalQuantity INT UNSIGNED NOT NULL,
    Difference INT GENERATED ALWAYS AS (
        CAST(PhysicalQuantity AS SIGNED) - CAST(SystemQuantity AS SIGNED)
    ) STORED,
    VerificationStatus VARCHAR(20) GENERATED ALWAYS AS (
        CASE
            WHEN PhysicalQuantity = SystemQuantity THEN 'MATCHED'
            ELSE 'DISCREPANCY'
        END
    ) STORED,
    Remarks VARCHAR(255),
    INDEX idx_verification_batch_date (BatchID, VerificationDate),
    CONSTRAINT fk_verification_batch
        FOREIGN KEY (BatchID) REFERENCES Inventory_Batch(BatchID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_verification_user
        FOREIGN KEY (VerifiedBy) REFERENCES User_Account(UserID)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 11. DISCREPANCY
-- One discrepancy record can be associated with a stock verification.
-- Quantity values are not duplicated; they can be read from Stock_Verification.
CREATE TABLE IF NOT EXISTS Discrepancy (
    DiscrepancyID INT AUTO_INCREMENT PRIMARY KEY,
    VerificationID INT NOT NULL UNIQUE,
    ReportedBy INT NOT NULL,
    ReportDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Reason VARCHAR(255) NOT NULL,
    ResolvedBy INT,
    ResolvedDate DATETIME,
    Status ENUM('OPEN', 'IN_PROGRESS', 'RESOLVED', 'REJECTED')
        NOT NULL DEFAULT 'OPEN',
    Remarks VARCHAR(255),
    CONSTRAINT chk_discrepancy_resolution_date
        CHECK (ResolvedDate IS NULL OR ResolvedDate >= ReportDate),
    CONSTRAINT fk_discrepancy_verification
        FOREIGN KEY (VerificationID) REFERENCES Stock_Verification(VerificationID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_discrepancy_reported_by
        FOREIGN KEY (ReportedBy) REFERENCES User_Account(UserID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_discrepancy_resolved_by
        FOREIGN KEY (ResolvedBy) REFERENCES User_Account(UserID)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- 12. RESERVATION
CREATE TABLE IF NOT EXISTS Reservation (
    ReservationID INT AUTO_INCREMENT PRIMARY KEY,
    BatchID INT NOT NULL,
    ReservedBy INT NOT NULL,
    Quantity INT UNSIGNED NOT NULL,
    Purpose VARCHAR(255),
    ReservationDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ExpiryDate DATETIME NOT NULL,
    Status ENUM('ACTIVE', 'FULFILLED', 'CANCELLED', 'EXPIRED')
        NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT chk_reservation_quantity CHECK (Quantity > 0),
    CONSTRAINT chk_reservation_dates CHECK (ExpiryDate > ReservationDate),
    INDEX idx_reservation_batch_status (BatchID, Status),
    CONSTRAINT fk_reservation_batch
        FOREIGN KEY (BatchID) REFERENCES Inventory_Batch(BatchID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_reservation_user
        FOREIGN KEY (ReservedBy) REFERENCES User_Account(UserID)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
-- VALIDATION TRIGGERS FOR MEDICINE_ALTERNATIVE
-- MySQL rejects a CHECK on MedicineID when that column also has
-- a cascading foreign key. These triggers enforce the same rule.
-- ============================================================

DROP TRIGGER IF EXISTS trg_ma_before_insert;
DROP TRIGGER IF EXISTS trg_ma_before_update;

DELIMITER $$

CREATE TRIGGER trg_ma_before_insert
BEFORE INSERT ON Medicine_Alternative
FOR EACH ROW
BEGIN
    IF NEW.MedicineID = NEW.AlternativeMedicineID THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A medicine cannot be its own alternative.';
    END IF;
END$$

CREATE TRIGGER trg_ma_before_update
BEFORE UPDATE ON Medicine_Alternative
FOR EACH ROW
BEGIN
    IF NEW.MedicineID = NEW.AlternativeMedicineID THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A medicine cannot be its own alternative.';
    END IF;
END$$

DELIMITER ;

-- Verify that all tables and validation triggers are present.
SHOW TABLES;
SHOW TRIGGERS LIKE 'Medicine_Alternative';
