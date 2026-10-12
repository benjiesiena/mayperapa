-- V3__account_enhancements.sql
-- Adds institution metadata, masked account number, and inter-account transfer linkage.

ALTER TABLE accounts ADD COLUMN institution_name TEXT;
ALTER TABLE accounts ADD COLUMN account_number_masked TEXT;

ALTER TABLE transactions ADD COLUMN transfer_account_id INTEGER REFERENCES accounts(id) ON DELETE SET NULL;
ALTER TABLE transactions ADD COLUMN is_transfer_inflow INTEGER DEFAULT 0;
