
--==================================================================================================================
--												DEFINING PRIMARY KEY TO ALL THE TABLE
--===================================================================================================================

-- Step 1: Make sure the column does not allow NULLs
-- (Assuming branch_id is an Integer. If it is text like 'B001', change INT to VARCHAR(50))

--==========================================================
--1. for the Branch Table
--==========================================================

ALTER TABLE Branch
ALTER COLUMN branch_id  VARCHAR(50) NOT NULL;

-- Step 2: Add the Primary Key Constraint
ALTER TABLE Branch
ADD CONSTRAINT PK_Branch PRIMARY KEY (branch_id);

--==========================================================
--2. for the BooksNew Table
--==========================================================

ALTER TABLE BooksNew
ALTER COLUMN isbn  VARCHAR(50) NOT NULL;

-- Step 2: Add the Primary Key Constraint
ALTER TABLE BooksNew
ADD CONSTRAINT PK_isbn PRIMARY KEY (isbn);

--==========================================================
--3. for the employees Table
--==========================================================

ALTER TABLE employees
ALTER COLUMN emp_id  VARCHAR(50) NOT NULL;

-- Step 2: Add the Primary Key Constraint
ALTER TABLE employees
ADD CONSTRAINT PK_emp_id PRIMARY KEY (emp_id);

--==========================================================
--4. for the issued_status Table
--==========================================================

ALTER TABLE issued_status
ALTER COLUMN issued_id  VARCHAR(50) NOT NULL;

-- Step 2: Add the Primary Key Constraint
ALTER TABLE issued_status
ADD CONSTRAINT PK_issued_status PRIMARY KEY (issued_id);

--==========================================================
--5. for the members Table
--==========================================================

ALTER TABLE members
ALTER COLUMN member_id  VARCHAR(50) NOT NULL;

-- Step 2: Add the Primary Key Constraint
ALTER TABLE members
ADD CONSTRAINT PK_member_id PRIMARY KEY (member_id);


--==========================================================
--6. for the return_status Table
--==========================================================

ALTER TABLE return_status
ALTER COLUMN return_id VARCHAR(50) NOT NULL;

-- Step 2: Add the Primary Key Constraint
ALTER TABLE return_status
ADD CONSTRAINT PK_return_id PRIMARY KEY (return_id);

--==================================================================================================================
--												DEFINING FOREIGN KEY TO ALL THE TABLE
--===================================================================================================================
-- Createing Foreign Key for the Diagram

-- ================================================================
-- (i) Createing foreign key for the table issued_Status and the column is issued_member_id and ref table is members
-- ================================================================

-- 1. Change the child column to match the parent exactly
-- (I am assuming your member_id is VARCHAR(50). If it is INT, change this to INT)
ALTER TABLE issued_status
ALTER COLUMN issued_member_id VARCHAR(50);

-- 2. NOW run your constraint code
ALTER TABLE issued_status
ADD CONSTRAINT fk_members
FOREIGN KEY (issued_member_id)
REFERENCES members(member_id);

-- ================================================================
-- (ii) Createing foreign key for the table issued_Status and the column is issued_book_isbn and ref table is BooksNew
-- ================================================================

ALTER TABLE issued_status
ALTER COLUMN issued_book_isbn VARCHAR(50);

ALTER TABLE issued_status -- the table where it's changing
ADD CONSTRAINT fk_BooksNew	-- name of the fk
FOREIGN KEY (issued_book_isbn) -- that table col name
REFERENCES BooksNew(isbn); -- pk of the 2nd table


-- ================================================================
-- (iii) Createing foreign key for the table issued_Status and the column is issued_book_isbn and ref table is employees
-- ================================================================
ALTER TABLE issued_status
ALTER COLUMN issued_emp_id VARCHAR(50);

ALTER TABLE issued_status
ADD CONSTRAINT fk_employees
FOREIGN KEY (issued_emp_id)
REFERENCES employees(emp_id);

-- ================================================================
-- (iv) Createing foreign key for the table employees and the column is issued_book_isbn and ref table is Branch
-- ================================================================
ALTER TABLE employees
ALTER COLUMN branch_id VARCHAR(50);

ALTER TABLE employees
ADD CONSTRAINT fk_Branch
FOREIGN KEY (branch_id) --# This column comes from the employees table
REFERENCES Branch(branch_id); 


-- ================================================================
-- (v) Createing foreign key for the table return_status and the column is issued_book_isbn and ref table is issued_status
-- ================================================================
ALTER TABLE return_status
ALTER COLUMN issued_id VARCHAR(50);

ALTER TABLE return_status
ADD CONSTRAINT fk_issued_status
FOREIGN KEY (issued_id)
REFERENCES issued_status(issued_id);

-- This is we create some of the values were not matching
SELECT * FROM return_status
WHERE issued_id NOT IN (SELECT issued_id FROM issued_status);

-- By using this we deleted from return_status table which are not matching
DELETE FROM return_status
WHERE issued_id NOT IN (SELECT issued_id FROM issued_status);