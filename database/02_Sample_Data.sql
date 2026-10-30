-- ============================================================
-- MEDICAL STORE NETWORK AND MEDICINE AVAILABILITY SYSTEM
-- Phase 2: Sample data (DML)
-- MySQL 8.0.16+ | Designed for the Phase 1 schema
-- Safe to re-run: seed rows use fixed IDs and upsert statements.
-- Demo contact details and accounts are fictional.
-- SHA-256 values below are demonstration placeholders only;
-- real systems should use a salted password hash such as Argon2id/bcrypt.
-- ============================================================
USE medical_store_network;

INSERT INTO Pharmacy (PharmacyID, Name, LicenseNo, Phone, Email, Address, Latitude, Longitude, Status) VALUES
    (1, 'Demo Pharmacy - Kothrud', 'DEMO-MH-PN-0001', '9000000001', 'kothrud@example.com', 'Karve Road, Kothrud, Pune, Maharashtra', 18.5074, 73.8077, 'ACTIVE'),
    (2, 'Demo Pharmacy - Deccan', 'DEMO-MH-PN-0002', '9000000002', 'deccan@example.com', 'JM Road, Deccan Gymkhana, Pune, Maharashtra', 18.5196, 73.841, 'ACTIVE'),
    (3, 'Demo Pharmacy - Aundh', 'DEMO-MH-PN-0003', '9000000003', 'aundh@example.com', 'ITI Road, Aundh, Pune, Maharashtra', 18.559, 73.807, 'ACTIVE'),
    (4, 'Demo Pharmacy - Viman Nagar', 'DEMO-MH-PN-0004', '9000000004', 'vimannagar@example.com', 'Datta Mandir Chowk, Viman Nagar, Pune, Maharashtra', 18.5679, 73.9143, 'ACTIVE'),
    (5, 'Demo Pharmacy - Karve Nagar', 'DEMO-MH-PN-0005', '9000000005', 'karvenagar@example.com', 'Hingne Home Colony, Karve Nagar, Pune, Maharashtra', 18.4833, 73.821, 'ACTIVE')
ON DUPLICATE KEY UPDATE Name=VALUES(Name), LicenseNo=VALUES(LicenseNo), Phone=VALUES(Phone), Email=VALUES(Email), Address=VALUES(Address), Latitude=VALUES(Latitude), Longitude=VALUES(Longitude), Status=VALUES(Status);

INSERT INTO Supplier (SupplierID, Name, Phone, Email, Address) VALUES
    (1, 'Demo MediSource Distributors', '9100000001', 'medisource@example.com', 'Market Yard, Gultekdi, Pune, Maharashtra'),
    (2, 'Demo Prime Pharma Supply', '9100000002', 'primepharma@example.com', 'Nana Peth, Pune, Maharashtra'),
    (3, 'Demo CareLink Wholesalers', '9100000003', 'carelink@example.com', 'Bhosari MIDC, Pune, Maharashtra'),
    (4, 'Demo Aarogya Pharma Distributors', '9100000004', 'aarogya@example.com', 'Hadapsar, Pune, Maharashtra')
ON DUPLICATE KEY UPDATE Name=VALUES(Name), Phone=VALUES(Phone), Email=VALUES(Email), Address=VALUES(Address);

INSERT INTO Medicine (MedicineID, GenericName, BrandName, DosageForm, Category, Description) VALUES
    (1, 'Paracetamol', 'Dolo 650', 'Tablet', 'Analgesic / Antipyretic', 'Paracetamol 650 mg tablet.'),
    (2, 'Paracetamol', 'Calpol 650', 'Tablet', 'Analgesic / Antipyretic', 'Paracetamol 650 mg tablet.'),
    (3, 'Paracetamol', 'Crocin 650', 'Tablet', 'Analgesic / Antipyretic', 'Paracetamol 650 mg tablet.'),
    (4, 'Ibuprofen', 'Ibugesic 400', 'Tablet', 'NSAID', 'Ibuprofen 400 mg tablet.'),
    (5, 'Ibuprofen', 'Brufen 400', 'Tablet', 'NSAID', 'Ibuprofen 400 mg tablet.'),
    (6, 'Cetirizine', 'Cetzine 10', 'Tablet', 'Antihistamine', 'Cetirizine 10 mg tablet.'),
    (7, 'Cetirizine', 'Okacet 10', 'Tablet', 'Antihistamine', 'Cetirizine 10 mg tablet.'),
    (8, 'Pantoprazole', 'Pantocid 40', 'Tablet', 'Gastrointestinal', 'Pantoprazole 40 mg tablet.'),
    (9, 'Pantoprazole', 'Pan 40', 'Tablet', 'Gastrointestinal', 'Pantoprazole 40 mg tablet.'),
    (10, 'Azithromycin', 'Azithral 500', 'Tablet', 'Antibiotic', 'Azithromycin 500 mg tablet.'),
    (11, 'Azithromycin', 'Azee 500', 'Tablet', 'Antibiotic', 'Azithromycin 500 mg tablet.'),
    (12, 'Amoxicillin + Clavulanic Acid', 'Augmentin 625', 'Tablet', 'Antibiotic', 'Amoxicillin 500 mg + clavulanic acid 125 mg tablet.'),
    (13, 'Amoxicillin + Clavulanic Acid', 'Clavam 625', 'Tablet', 'Antibiotic', 'Amoxicillin 500 mg + clavulanic acid 125 mg tablet.'),
    (14, 'Omeprazole', 'Omez 20', 'Capsule', 'Gastrointestinal', 'Omeprazole 20 mg capsule.'),
    (15, 'Omeprazole', 'Ocid 20', 'Capsule', 'Gastrointestinal', 'Omeprazole 20 mg capsule.')
ON DUPLICATE KEY UPDATE GenericName=VALUES(GenericName), BrandName=VALUES(BrandName), DosageForm=VALUES(DosageForm), Category=VALUES(Category), Description=VALUES(Description);

INSERT INTO Composition (CompositionID, IngredientName) VALUES
    (1, 'Paracetamol'),
    (2, 'Ibuprofen'),
    (3, 'Cetirizine'),
    (4, 'Pantoprazole'),
    (5, 'Azithromycin'),
    (6, 'Amoxicillin'),
    (7, 'Clavulanic Acid'),
    (8, 'Omeprazole')
ON DUPLICATE KEY UPDATE IngredientName=VALUES(IngredientName);

INSERT INTO Medicine_Composition (MedicineID, CompositionID, StrengthPerUnit) VALUES
    (1, 1, '650 mg'),
    (2, 1, '650 mg'),
    (3, 1, '650 mg'),
    (4, 2, '400 mg'),
    (5, 2, '400 mg'),
    (6, 3, '10 mg'),
    (7, 3, '10 mg'),
    (8, 4, '40 mg'),
    (9, 4, '40 mg'),
    (10, 5, '500 mg'),
    (11, 5, '500 mg'),
    (12, 6, '500 mg'),
    (12, 7, '125 mg'),
    (13, 6, '500 mg'),
    (13, 7, '125 mg'),
    (14, 8, '20 mg'),
    (15, 8, '20 mg')
ON DUPLICATE KEY UPDATE StrengthPerUnit=VALUES(StrengthPerUnit);

INSERT INTO User_Account (UserID, Name, Email, Phone, PasswordHash, Role, Status) VALUES
    (1, 'System Administrator', 'admin@example.com', '9200000001', SHA2('demo-password-change-me', 256), 'ADMIN', 'ACTIVE'),
    (2, 'Kothrud Staff', 'staff.kothrud@example.com', '9200000002', SHA2('demo-password-change-me', 256), 'STAFF', 'ACTIVE'),
    (3, 'Deccan Staff', 'staff.deccan@example.com', '9200000003', SHA2('demo-password-change-me', 256), 'STAFF', 'ACTIVE'),
    (4, 'Inventory Supervisor', 'supervisor@example.com', '9200000004', SHA2('demo-password-change-me', 256), 'STAFF', 'ACTIVE')
ON DUPLICATE KEY UPDATE Name=VALUES(Name), Email=VALUES(Email), Phone=VALUES(Phone), PasswordHash=VALUES(PasswordHash), Role=VALUES(Role), Status=VALUES(Status);

INSERT INTO Medicine_Alternative (MedicineID, AlternativeMedicineID, AddedBy, Remarks, AddedAt) VALUES
    (1, 2, 1, 'Same listed active ingredient(s), strength and dosage form. Confirm suitability before substitution.', '2026-10-01 09:00:00'),
    (1, 3, 1, 'Same listed active ingredient(s), strength and dosage form. Confirm suitability before substitution.', '2026-10-01 09:00:00'),
    (2, 1, 1, 'Same listed active ingredient(s), strength and dosage form. Confirm suitability before substitution.', '2026-10-01 09:00:00'),
    (2, 3, 1, 'Same listed active ingredient(s), strength and dosage form. Confirm suitability before substitution.', '2026-10-01 09:00:00'),
    (3, 1, 1, 'Same listed active ingredient(s), strength and dosage form. Confirm suitability before substitution.', '2026-10-01 09:00:00'),
    (3, 2, 1, 'Same listed active ingredient(s), strength and dosage form. Confirm suitability before substitution.', '2026-10-01 09:00:00'),
    (4, 5, 1, 'Same listed active ingredient(s), strength and dosage form. Confirm suitability before substitution.', '2026-10-01 09:00:00'),
    (5, 4, 1, 'Same listed active ingredient(s), strength and dosage form. Confirm suitability before substitution.', '2026-10-01 09:00:00'),
    (6, 7, 1, 'Same listed active ingredient(s), strength and dosage form. Confirm suitability before substitution.', '2026-10-01 09:00:00'),
    (7, 6, 1, 'Same listed active ingredient(s), strength and dosage form. Confirm suitability before substitution.', '2026-10-01 09:00:00'),
    (8, 9, 1, 'Same listed active ingredient(s), strength and dosage form. Confirm suitability before substitution.', '2026-10-01 09:00:00'),
    (9, 8, 1, 'Same listed active ingredient(s), strength and dosage form. Confirm suitability before substitution.', '2026-10-01 09:00:00'),
    (10, 11, 1, 'Same listed active ingredient(s), strength and dosage form. Confirm suitability before substitution.', '2026-10-01 09:00:00'),
    (11, 10, 1, 'Same listed active ingredient(s), strength and dosage form. Confirm suitability before substitution.', '2026-10-01 09:00:00'),
    (12, 13, 1, 'Same listed active ingredient(s), strength and dosage form. Confirm suitability before substitution.', '2026-10-01 09:00:00'),
    (13, 12, 1, 'Same listed active ingredient(s), strength and dosage form. Confirm suitability before substitution.', '2026-10-01 09:00:00'),
    (14, 15, 1, 'Same listed active ingredient(s), strength and dosage form. Confirm suitability before substitution.', '2026-10-01 09:00:00'),
    (15, 14, 1, 'Same listed active ingredient(s), strength and dosage form. Confirm suitability before substitution.', '2026-10-01 09:00:00')
ON DUPLICATE KEY UPDATE AddedBy=VALUES(AddedBy), Remarks=VALUES(Remarks), AddedAt=VALUES(AddedAt);

INSERT INTO Inventory_Batch (BatchID, PharmacyID, MedicineID, SupplierID, BatchNo, MfgDate, ExpiryDate, PurchaseDate, Quantity, PurchasePrice) VALUES
    (1, 1, 1, 1, 'KTH-DOL-2601', '2025-11-01', '2027-10-31', '2026-01-12', 40, 18.5),
    (2, 1, 2, 2, 'KTH-CAL-2602', '2025-12-01', '2027-11-30', '2026-02-06', 25, 19.0),
    (3, 1, 4, 1, 'KTH-IBU-2601', '2025-10-01', '2027-09-30', '2026-01-18', 18, 22.0),
    (4, 1, 6, 3, 'KTH-CET-2603', '2026-01-01', '2028-01-31', '2026-03-04', 30, 12.0),
    (5, 1, 8, 4, 'KTH-PAN-2602', '2025-12-01', '2027-11-30', '2026-02-12', 20, 28.0),
    (6, 1, 12, 2, 'KTH-AUG-2602', '2025-12-01', '2027-11-30', '2026-02-20', 12, 82.0),
    (7, 1, 14, 3, 'KTH-OME-2603', '2026-01-01', '2028-01-31', '2026-03-10', 15, 16.0),
    (8, 2, 1, 2, 'DEC-DOL-2602', '2025-12-01', '2027-11-30', '2026-02-02', 20, 18.75),
    (9, 2, 3, 1, 'DEC-CRO-2601', '2025-11-01', '2027-10-31', '2026-01-22', 35, 18.25),
    (10, 2, 5, 4, 'DEC-BRU-2603', '2026-01-01', '2028-01-31', '2026-03-12', 22, 21.5),
    (11, 2, 7, 3, 'DEC-OKA-2602', '2025-12-01', '2027-11-30', '2026-02-14', 16, 11.5),
    (12, 2, 9, 2, 'DEC-PAN-2601', '2025-11-01', '2027-10-31', '2026-01-28', 18, 27.5),
    (13, 2, 11, 1, 'DEC-AZE-2603', '2026-01-01', '2028-01-31', '2026-03-18', 14, 55.0),
    (14, 2, 13, 4, 'DEC-CLA-2602', '2025-12-01', '2027-11-30', '2026-02-25', 10, 79.0),
    (15, 3, 2, 3, 'AUN-CAL-2603', '2026-01-01', '2028-01-31', '2026-03-05', 14, 19.25),
    (16, 3, 4, 2, 'AUN-IBU-2602', '2025-12-01', '2027-11-30', '2026-02-11', 25, 22.25),
    (17, 3, 8, 1, 'AUN-PAN-2603', '2026-01-01', '2028-01-31', '2026-03-16', 12, 28.25),
    (18, 3, 10, 4, 'AUN-AZI-2602', '2025-12-01', '2027-11-30', '2026-02-19', 20, 54.0),
    (19, 3, 14, 3, 'AUN-OME-2603', '2026-01-01', '2028-01-31', '2026-03-21', 22, 16.25),
    (20, 4, 1, 4, 'VIM-DOL-2604', '2026-02-01', '2028-02-29', '2026-04-02', 50, 18.4),
    (21, 4, 6, 1, 'VIM-CET-2603', '2026-01-01', '2028-01-31', '2026-03-11', 24, 12.25),
    (22, 4, 9, 2, 'VIM-PAN-2602', '2025-12-01', '2027-11-30', '2026-02-28', 16, 27.75),
    (23, 4, 12, 3, 'VIM-AUG-2604', '2026-02-01', '2028-02-29', '2026-04-09', 8, 81.5),
    (24, 4, 15, 4, 'VIM-OCI-2603', '2026-01-01', '2028-01-31', '2026-03-25', 20, 15.75),
    (25, 5, 3, 1, 'KRV-CRO-2603', '2026-01-01', '2028-01-31', '2026-03-07', 18, 18.3),
    (26, 5, 5, 2, 'KRV-BRU-2604', '2026-02-01', '2028-02-29', '2026-04-05', 14, 21.75),
    (27, 5, 7, 3, 'KRV-OKA-2603', '2026-01-01', '2028-01-31', '2026-03-14', 28, 11.75),
    (28, 5, 10, 4, 'KRV-AZI-2604', '2026-02-01', '2028-02-29', '2026-04-12', 10, 54.5),
    (29, 5, 13, 1, 'KRV-CLA-2603', '2026-01-01', '2028-01-31', '2026-03-28', 15, 79.5),
    (30, 5, 15, 2, 'KRV-OCI-2604', '2026-02-01', '2028-02-29', '2026-04-17', 12, 15.9)
ON DUPLICATE KEY UPDATE PharmacyID=VALUES(PharmacyID), MedicineID=VALUES(MedicineID), SupplierID=VALUES(SupplierID), BatchNo=VALUES(BatchNo), MfgDate=VALUES(MfgDate), ExpiryDate=VALUES(ExpiryDate), PurchaseDate=VALUES(PurchaseDate), Quantity=VALUES(Quantity), PurchasePrice=VALUES(PurchasePrice);

INSERT INTO Stock_Transaction (TransactionID, BatchID, TransactionType, Quantity, ReferenceNo, PerformedBy, TransactionDate, Remarks) VALUES
    (1, 1, 'STOCK_IN', 50, 'GRN-KTH-DOL-2601', 2, '2026-01-12 10:00:00', 'Opening receipt for demo data'),
    (2, 1, 'STOCK_OUT', 10, 'SALE-KTH-DOL-2601', 2, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (3, 2, 'STOCK_IN', 35, 'GRN-KTH-CAL-2602', 2, '2026-02-06 10:00:00', 'Opening receipt for demo data'),
    (4, 2, 'STOCK_OUT', 10, 'SALE-KTH-CAL-2602', 2, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (5, 3, 'STOCK_IN', 28, 'GRN-KTH-IBU-2601', 2, '2026-01-18 10:00:00', 'Opening receipt for demo data'),
    (6, 3, 'STOCK_OUT', 10, 'SALE-KTH-IBU-2601', 2, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (7, 4, 'STOCK_IN', 40, 'GRN-KTH-CET-2603', 2, '2026-03-04 10:00:00', 'Opening receipt for demo data'),
    (8, 4, 'STOCK_OUT', 10, 'SALE-KTH-CET-2603', 2, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (9, 5, 'STOCK_IN', 30, 'GRN-KTH-PAN-2602', 2, '2026-02-12 10:00:00', 'Opening receipt for demo data'),
    (10, 5, 'STOCK_OUT', 10, 'SALE-KTH-PAN-2602', 2, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (11, 6, 'STOCK_IN', 22, 'GRN-KTH-AUG-2602', 2, '2026-02-20 10:00:00', 'Opening receipt for demo data'),
    (12, 6, 'STOCK_OUT', 10, 'SALE-KTH-AUG-2602', 2, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (13, 7, 'STOCK_IN', 25, 'GRN-KTH-OME-2603', 2, '2026-03-10 10:00:00', 'Opening receipt for demo data'),
    (14, 7, 'STOCK_OUT', 10, 'SALE-KTH-OME-2603', 2, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (15, 8, 'STOCK_IN', 30, 'GRN-DEC-DOL-2602', 3, '2026-02-02 10:00:00', 'Opening receipt for demo data'),
    (16, 8, 'STOCK_OUT', 10, 'SALE-DEC-DOL-2602', 3, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (17, 9, 'STOCK_IN', 45, 'GRN-DEC-CRO-2601', 3, '2026-01-22 10:00:00', 'Opening receipt for demo data'),
    (18, 9, 'STOCK_OUT', 10, 'SALE-DEC-CRO-2601', 3, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (19, 10, 'STOCK_IN', 32, 'GRN-DEC-BRU-2603', 3, '2026-03-12 10:00:00', 'Opening receipt for demo data'),
    (20, 10, 'STOCK_OUT', 10, 'SALE-DEC-BRU-2603', 3, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (21, 11, 'STOCK_IN', 26, 'GRN-DEC-OKA-2602', 3, '2026-02-14 10:00:00', 'Opening receipt for demo data'),
    (22, 11, 'STOCK_OUT', 10, 'SALE-DEC-OKA-2602', 3, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (23, 12, 'STOCK_IN', 28, 'GRN-DEC-PAN-2601', 3, '2026-01-28 10:00:00', 'Opening receipt for demo data'),
    (24, 12, 'STOCK_OUT', 10, 'SALE-DEC-PAN-2601', 3, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (25, 13, 'STOCK_IN', 24, 'GRN-DEC-AZE-2603', 3, '2026-03-18 10:00:00', 'Opening receipt for demo data'),
    (26, 13, 'STOCK_OUT', 10, 'SALE-DEC-AZE-2603', 3, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (27, 14, 'STOCK_IN', 20, 'GRN-DEC-CLA-2602', 3, '2026-02-25 10:00:00', 'Opening receipt for demo data'),
    (28, 14, 'STOCK_OUT', 10, 'SALE-DEC-CLA-2602', 3, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (29, 15, 'STOCK_IN', 24, 'GRN-AUN-CAL-2603', 4, '2026-03-05 10:00:00', 'Opening receipt for demo data'),
    (30, 15, 'STOCK_OUT', 10, 'SALE-AUN-CAL-2603', 4, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (31, 16, 'STOCK_IN', 35, 'GRN-AUN-IBU-2602', 4, '2026-02-11 10:00:00', 'Opening receipt for demo data'),
    (32, 16, 'STOCK_OUT', 10, 'SALE-AUN-IBU-2602', 4, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (33, 17, 'STOCK_IN', 22, 'GRN-AUN-PAN-2603', 4, '2026-03-16 10:00:00', 'Opening receipt for demo data'),
    (34, 17, 'STOCK_OUT', 10, 'SALE-AUN-PAN-2603', 4, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (35, 18, 'STOCK_IN', 30, 'GRN-AUN-AZI-2602', 4, '2026-02-19 10:00:00', 'Opening receipt for demo data'),
    (36, 18, 'STOCK_OUT', 10, 'SALE-AUN-AZI-2602', 4, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (37, 19, 'STOCK_IN', 32, 'GRN-AUN-OME-2603', 4, '2026-03-21 10:00:00', 'Opening receipt for demo data'),
    (38, 19, 'STOCK_OUT', 10, 'SALE-AUN-OME-2603', 4, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (39, 20, 'STOCK_IN', 60, 'GRN-VIM-DOL-2604', 4, '2026-04-02 10:00:00', 'Opening receipt for demo data'),
    (40, 20, 'STOCK_OUT', 10, 'SALE-VIM-DOL-2604', 4, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (41, 21, 'STOCK_IN', 34, 'GRN-VIM-CET-2603', 4, '2026-03-11 10:00:00', 'Opening receipt for demo data'),
    (42, 21, 'STOCK_OUT', 10, 'SALE-VIM-CET-2603', 4, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (43, 22, 'STOCK_IN', 26, 'GRN-VIM-PAN-2602', 4, '2026-02-28 10:00:00', 'Opening receipt for demo data'),
    (44, 22, 'STOCK_OUT', 10, 'SALE-VIM-PAN-2602', 4, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (45, 23, 'STOCK_IN', 18, 'GRN-VIM-AUG-2604', 4, '2026-04-09 10:00:00', 'Opening receipt for demo data'),
    (46, 23, 'STOCK_OUT', 10, 'SALE-VIM-AUG-2604', 4, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (47, 24, 'STOCK_IN', 30, 'GRN-VIM-OCI-2603', 4, '2026-03-25 10:00:00', 'Opening receipt for demo data'),
    (48, 24, 'STOCK_OUT', 10, 'SALE-VIM-OCI-2603', 4, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (49, 25, 'STOCK_IN', 28, 'GRN-KRV-CRO-2603', 2, '2026-03-07 10:00:00', 'Opening receipt for demo data'),
    (50, 25, 'STOCK_OUT', 10, 'SALE-KRV-CRO-2603', 2, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (51, 26, 'STOCK_IN', 24, 'GRN-KRV-BRU-2604', 2, '2026-04-05 10:00:00', 'Opening receipt for demo data'),
    (52, 26, 'STOCK_OUT', 10, 'SALE-KRV-BRU-2604', 2, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (53, 27, 'STOCK_IN', 38, 'GRN-KRV-OKA-2603', 2, '2026-03-14 10:00:00', 'Opening receipt for demo data'),
    (54, 27, 'STOCK_OUT', 10, 'SALE-KRV-OKA-2603', 2, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (55, 28, 'STOCK_IN', 20, 'GRN-KRV-AZI-2604', 2, '2026-04-12 10:00:00', 'Opening receipt for demo data'),
    (56, 28, 'STOCK_OUT', 10, 'SALE-KRV-AZI-2604', 2, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (57, 29, 'STOCK_IN', 25, 'GRN-KRV-CLA-2603', 2, '2026-03-28 10:00:00', 'Opening receipt for demo data'),
    (58, 29, 'STOCK_OUT', 10, 'SALE-KRV-CLA-2603', 2, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity'),
    (59, 30, 'STOCK_IN', 22, 'GRN-KRV-OCI-2604', 2, '2026-04-17 10:00:00', 'Opening receipt for demo data'),
    (60, 30, 'STOCK_OUT', 10, 'SALE-KRV-OCI-2604', 2, '2026-06-15 16:30:00', 'Demo stock issue; ledger net equals current batch quantity')
ON DUPLICATE KEY UPDATE BatchID=VALUES(BatchID), TransactionType=VALUES(TransactionType), Quantity=VALUES(Quantity), ReferenceNo=VALUES(ReferenceNo), PerformedBy=VALUES(PerformedBy), TransactionDate=VALUES(TransactionDate), Remarks=VALUES(Remarks);

INSERT INTO Stock_Verification (VerificationID, BatchID, VerifiedBy, VerificationDate, SystemQuantity, PhysicalQuantity, Remarks) VALUES
    (1, 1, 2, '2026-10-05 10:00:00', 40, 40, 'Routine count - matched.'),
    (2, 2, 2, '2026-10-06 10:30:00', 25, 23, 'Two units less than system stock.'),
    (3, 4, 4, '2026-10-07 11:00:00', 30, 32, 'Two extra units found during physical count.'),
    (4, 8, 3, '2026-10-08 12:00:00', 20, 20, 'Routine count - matched.'),
    (5, 10, 3, '2026-10-09 12:30:00', 22, 22, 'Routine count - matched.'),
    (6, 18, 4, '2026-10-10 14:00:00', 20, 18, 'Two units short during physical count.')
ON DUPLICATE KEY UPDATE BatchID=VALUES(BatchID), VerifiedBy=VALUES(VerifiedBy), VerificationDate=VALUES(VerificationDate), SystemQuantity=VALUES(SystemQuantity), PhysicalQuantity=VALUES(PhysicalQuantity), Remarks=VALUES(Remarks);

INSERT INTO Discrepancy (DiscrepancyID, VerificationID, ReportedBy, ReportDate, Reason, ResolvedBy, ResolvedDate, Status, Remarks) VALUES
    (1, 2, 2, '2026-10-06 11:00:00', 'Possible unrecorded stock issue.', 1, '2026-10-07 15:00:00', 'RESOLVED', 'Issue reviewed and inventory record reconciled.'),
    (2, 3, 4, '2026-10-07 11:30:00', 'Physical count exceeded system quantity.', NULL, NULL, 'OPEN', 'Pending supervisor review.'),
    (3, 6, 4, '2026-10-10 14:30:00', 'Possible damaged or misplaced units.', 1, '2026-10-11 10:00:00', 'RESOLVED', 'Two units were identified as damaged and documented.')
ON DUPLICATE KEY UPDATE VerificationID=VALUES(VerificationID), ReportedBy=VALUES(ReportedBy), ReportDate=VALUES(ReportDate), Reason=VALUES(Reason), ResolvedBy=VALUES(ResolvedBy), ResolvedDate=VALUES(ResolvedDate), Status=VALUES(Status), Remarks=VALUES(Remarks);

INSERT INTO Reservation (ReservationID, BatchID, ReservedBy, Quantity, Purpose, ReservationDate, ExpiryDate, Status) VALUES
    (1, 1, 2, 5, 'Demo customer request REF-RSV-001', '2026-10-28 10:00:00', '2026-10-31 18:00:00', 'ACTIVE'),
    (2, 4, 2, 3, 'Demo customer request REF-RSV-002', '2026-10-20 12:00:00', '2026-10-21 18:00:00', 'FULFILLED'),
    (3, 8, 3, 4, 'Demo customer request REF-RSV-003', '2026-10-29 09:30:00', '2026-11-01 18:00:00', 'ACTIVE'),
    (4, 10, 3, 2, 'Demo customer request REF-RSV-004', '2026-10-15 14:00:00', '2026-10-16 18:00:00', 'CANCELLED'),
    (5, 18, 4, 2, 'Demo customer request REF-RSV-005', '2026-10-27 16:00:00', '2026-10-30 20:00:00', 'ACTIVE')
ON DUPLICATE KEY UPDATE BatchID=VALUES(BatchID), ReservedBy=VALUES(ReservedBy), Quantity=VALUES(Quantity), Purpose=VALUES(Purpose), ReservationDate=VALUES(ReservationDate), ExpiryDate=VALUES(ExpiryDate), Status=VALUES(Status);

-- ============================================================
-- BASIC VERIFICATION QUERIES
-- Run these after the inserts to confirm sample data.
-- ============================================================
SELECT COUNT(*) AS TotalPharmacies FROM Pharmacy;
SELECT COUNT(*) AS TotalSuppliers FROM Supplier;
SELECT COUNT(*) AS TotalMedicines FROM Medicine;
SELECT COUNT(*) AS TotalMedicineIngredients FROM Medicine_Composition;
SELECT COUNT(*) AS TotalInventoryBatches FROM Inventory_Batch;
SELECT COUNT(*) AS TotalStockTransactions FROM Stock_Transaction;
SELECT COUNT(*) AS TotalReservations FROM Reservation;

-- Sample availability report: current non-expired stock by pharmacy.
SELECT m.MedicineID, m.BrandName, p.Name AS PharmacyName,
       SUM(ib.Quantity) AS AvailableQuantity, MIN(ib.ExpiryDate) AS NearestExpiry
FROM Inventory_Batch ib
JOIN Medicine m ON m.MedicineID = ib.MedicineID
JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
WHERE ib.ExpiryDate >= CURDATE() AND ib.Quantity > 0 AND p.Status = 'ACTIVE'
GROUP BY m.MedicineID, m.BrandName, p.PharmacyID, p.Name
ORDER BY m.BrandName, p.Name;

-- Sample composition-based alternative mapping.
SELECT source.BrandName AS RequestedMedicine, alternative.BrandName AS AlternativeMedicine, ma.Remarks
FROM Medicine_Alternative ma
JOIN Medicine source ON source.MedicineID = ma.MedicineID
JOIN Medicine alternative ON alternative.MedicineID = ma.AlternativeMedicineID
WHERE ma.MedicineID = 1
ORDER BY alternative.BrandName;

-- Note: The alternatives are sample catalogue mappings. They are not clinical
-- substitution advice; suitability must be confirmed by a qualified professional.
-- Exact-brand availability example (Dolo 650).
SELECT m.BrandName, p.Name AS PharmacyName, p.Address,
       ib.BatchNo, ib.Quantity AS BatchQuantity, ib.ExpiryDate
FROM Medicine m
JOIN Inventory_Batch ib ON ib.MedicineID = m.MedicineID
JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
WHERE m.BrandName = 'Dolo 650'
  AND ib.Quantity > 0
  AND ib.ExpiryDate >= CURDATE()
  AND p.Status = 'ACTIVE'
ORDER BY p.Name, ib.ExpiryDate;

-- Alternative-brand availability example for Dolo 650.
SELECT requested.BrandName AS RequestedMedicine,
       alternative.BrandName AS AlternativeMedicine,
       p.Name AS PharmacyName,
       ib.Quantity AS BatchQuantity,
       ib.ExpiryDate
FROM Medicine_Alternative ma
JOIN Medicine requested ON requested.MedicineID = ma.MedicineID
JOIN Medicine alternative ON alternative.MedicineID = ma.AlternativeMedicineID
JOIN Inventory_Batch ib ON ib.MedicineID = alternative.MedicineID
JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
WHERE ma.MedicineID = 1
  AND ib.Quantity > 0
  AND ib.ExpiryDate >= CURDATE()
  AND p.Status = 'ACTIVE'
ORDER BY alternative.BrandName, p.Name;

-- Available stock after subtracting active, unexpired reservations.
SELECT m.BrandName, p.Name AS PharmacyName,
       SUM(ib.Quantity) AS PhysicalSystemStock,
       SUM(COALESCE(r.ReservedQuantity, 0)) AS ReservedQuantity,
       SUM(ib.Quantity - COALESCE(r.ReservedQuantity, 0)) AS AvailableToReserve
FROM Inventory_Batch ib
JOIN Medicine m ON m.MedicineID = ib.MedicineID
JOIN Pharmacy p ON p.PharmacyID = ib.PharmacyID
LEFT JOIN (
    SELECT BatchID, SUM(Quantity) AS ReservedQuantity
    FROM Reservation
    WHERE Status = 'ACTIVE' AND ExpiryDate > NOW()
    GROUP BY BatchID
) r ON r.BatchID = ib.BatchID
WHERE ib.ExpiryDate >= CURDATE()
  AND p.Status = 'ACTIVE'
GROUP BY m.MedicineID, m.BrandName, p.PharmacyID, p.Name
ORDER BY m.BrandName, p.Name;
