select * from Branch;
select * from employees;
select * from issued_status;
select * from members;
select * from return_status;

-- =================================================================================
-- Project Tasks
-- =================================================================================
-- Q-1) Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird',
--      'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
INSERT INTO BooksNew(
    isbn,
    book_title,
    category,
    rental_price,
    status,
    author,
    publisher
)
VALUES(
    '978-1-60129-456-2',
    'To Kill a Mockingbird',
    'Classic',
    6.00,       -- Numbers usually don't need quotes (but it works with them too)
    'yes', 
    'Harper Lee', 
    'J.B. Lippincott & Co.'
);

-- Q-2) Update an Existing Member's Address

UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C103';

-- Q-3) Delete a Record from the Issued Status Table -- Objective: 
-- Delete the record with issued_id = 'IS121' from the issued_status table.
delete from issued_status
where issued_id = 'IS121'

-- Q-4) Retrieve All Books Issued by a Specific Employee -- Objective:
-- Select all books issued by the employee with emp_id = 'E101'.

select 
issued_book_name 
from issued_status
where issued_emp_id = 'E101'

-- Q-5)  List Members Who Have Issued More Than One Book -- Objective: 
-- Use GROUP BY to find members who have issued more than one book.

select
	issued_emp_id,
	count(issued_emp_id)
from issued_status
group by issued_emp_id
having count(issued_emp_id)>1

-- =============================================================================
-- 3. CTAS (Create Table As Select)
-- =============================================================================

-- Q-6) Create Summary Tables: Used CTAS to generate new tables based on query results
--      - each book and total book_issued_cnt**

-- This is for the PgAdmin and MySql 

CREATE TABLE book_issued_cnt 
AS
select 
	b.isbn,
	b.book_title,
	count(b.book_title) as issue_count
from issued_status i
left join BooksNew b
ON i.issued_book_isbn = b.isbn
group by b.book_title,b.isbn

-- This is for the MSSQL 

SELECT 
    b.isbn,
    b.book_title,
    COUNT(b.book_title) as issue_count
INTO book_issued_cnt    -- <--- This creates the new table automatically
FROM issued_status i
LEFT JOIN BooksNew b
ON i.issued_book_isbn = b.isbn
GROUP BY b.book_title, b.isbn;

-- =============================================================================
-- 4. Data Analysis & Findings
-- =============================================================================
-- Q-7) Retrieve All Books in a Specific Category:
select
*
from BooksNew
WHERE category = 'Classic';

-- Q-8) Find Total Rental Income by Category:
select
	b.category,
	sum(b.rental_price) as Total_Rental_Income,
	COUNT(*)
from issued_status i
left join BooksNew b
ON i.issued_book_isbn = b.isbn
Group by category

-- Q-9) List Members Who Registered in the Last 180 Days:
SELECT 
	* 
FROM members
WHERE reg_date >= DATEADD(day, -180, GETDATE()); -- GETDATE() this give us the curr date with time
--	DATEADD(day, -180, GETDATE()) || and dateadd use for adding date and day- means add or substract as a day

-- Q-10) List Employees with Their Branch Manager's Name and their branch details:

select
	e1.emp_id,
	e1.emp_name,
	e1.position,
	e1.salary,
	b.*,
	e2.emp_name as manger_name
from employees e1
inner join branch b
ON e1.branch_id = b.branch_id
inner join employees e2
ON e2.emp_id = b.manager_id

-- Q-11) Create a Table of Books with Rental Price Above a Certain Threshold:

select
	*
INTO expensive_books  -- New table created with this info (expensive_books )
FROM BooksNew
where rental_price>7.00

select * from expensive_books 

-- Q-12) Retrieve the List of Books Not Yet Returned

select 
	--i.issued_book_name
	*
from issued_status i
left join return_status r
ON i.issued_id = r.issued_id
where r.issued_id is null

-- ====================================================
-- Advanced SQL Operations
-- ====================================================
-- Q-13) Identify Members with Overdue Books
-- Write a query to identify members who have overdue books (assume a 30-day return period). 
-- Display the member's_id, member's name, book title, issue date, and days overdue.
-- 1st Query
-- This looks for books that have already been returned, but were returned late
select
	m.member_name,
	m.member_id,
	i.issued_book_name,
	i.issued_date,
	(DATEDIFF(day, i.issued_date, r.return_date))-30 as overdue
from issued_status i
left join return_status r
ON i.issued_id = r.issued_id
left join members m
ON  i.issued_member_id = m.member_id
where r.return_date >dateadd(day,30,i.issued_date)

-- Diff Query
select
	ist.issued_member_id,
	m.member_name,
	b.book_title,
	ist.issued_date,
	--DATEDIFF(DAY, ist.issued_date, GETDATE()) as days_since_issued,
	DATEDIFF(DAY, ist.issued_date, GETDATE()) - 30 AS days_overdue
from issued_status ist
join members m
ON ist.issued_member_id = m.member_id
JOIN BooksNew b
ON b.isbn = ist.issued_book_isbn
LEFT JOIN return_status rs
ON rs.issued_id = ist.issued_id
WHERE rs.return_date IS NULL and
	DATEDIFF(DAY, ist.issued_date, GETDATE()) > 30


-- Q-14) Update Book Status on Return
-- Write a query to update the status of books in the books table to "Yes" 
-- when they are returned (based on entries in the return_status table).
select 
	ist.issued_book_name,
	ist.issued_book_isbn,
	ist.issued_date,
	rs.return_date,
	b.status
from issued_status ist 
join return_status  rs
ON rs.issued_id = ist.issued_id
join BooksNew b
ON ist.issued_book_isbn = b.isbn

select * from BooksNew
where status='no'


-- Step 1: Add the column (it will initially be NULL for all rows)
ALTER TABLE return_status
ADD book_quality VARCHAR(20);

-- Step 2: Update all existing rows to 'Good'
UPDATE return_status
SET book_quality = 'Good';
-- ==============================================================
-- Store Procedure
-- ==============================================================

-- Testing Variables
-- issued_id = 'IS135'
-- ISBN = '978-0-307-58837-1'

-- Check current status
SELECT * FROM BooksNew
WHERE isbn = '978-0-307-58837-1';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

-- Check return status before action
SELECT * FROM return_status
WHERE issued_id = 'IS135';


CREATE OR ALTER PROCEDURE add_return_records
    @p_return_id VARCHAR(10),
    @p_issued_id VARCHAR(10),
    @p_book_quality VARCHAR(10)
AS
BEGIN
    -- 1. Declare variables
    DECLARE @v_isbn VARCHAR(50);
    DECLARE @v_book_name VARCHAR(80);

    -- 2. Insert into return_status
    INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
    VALUES (@p_return_id, @p_issued_id, CAST(GETDATE() AS DATE), @p_book_quality);

    -- 3. Select ISBN and Book Name into variables
    SELECT 
        @v_isbn = issued_book_isbn,
        @v_book_name = issued_book_name
    FROM issued_status
    WHERE issued_id = @p_issued_id;

    -- 4. Update the books table
    UPDATE BooksNew
    SET status = 'yes'
    WHERE isbn = @v_isbn;

    -- 5. Print confirmation message
    -- Note: We use ISNULL just in case the book name wasn't found, so the print doesn't fail
    PRINT 'Thank you for returning the book: ' + ISNULL(@v_book_name, 'Unknown');

END;
GO

-- Calling the function (Use EXEC in MSSQL)
EXEC add_return_records @p_return_id = 'RS138', @p_issued_id = 'IS135', @p_book_quality = 'Good';

-- Calling the function (Second test case)
EXEC add_return_records @p_return_id = 'RS148', @p_issued_id = 'IS140', @p_book_quality = 'Good';


-- Check return status before action
SELECT * FROM return_status
WHERE issued_id = 'IS135';


/*-- Q-15)
Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, 
showing the number of books issued, the number of books returned, 
and the total revenue generated from book rentals.
*/

-- ==============================================================
-- 1st way of solving this questions
-- ==============================================================
SELECT 
	b.branch_id,
	b.manager_id,
	COUNT(ist.issued_book_name) issued_book_count,
	COUNT(rs.return_id) No_of_book_return,
	SUM(bn.rental_price) Total_revenue
INTO branch_reports -- Statement to create a new **table** from a query result to our existing Database
FROM employees e
LEFT JOIN Branch b
ON e.branch_id = b.branch_id
LEFT JOIN issued_status ist
ON e.emp_id = ist.issued_emp_id
LEFT JOIN return_status rs
ON ist.issued_id = rs.issued_id
LEFT JOIN BooksNew bn
ON bn.isbn = ist.issued_book_isbn
GROUP BY b.branch_id,b.manager_id;

-- After createing a new table from the query now we will see our table
SELECT
* 
FROM branch_reports
-- ==============================================================
-- 2nd way of solving this questions
-- ==============================================================

SELECT 
    b.branch_id,
    b.manager_id,
    COUNT(ist.issued_id) as number_book_issued,
    COUNT(rs.return_id) as number_of_book_return,
    SUM(bk.rental_price) as total_revenue
FROM issued_status as ist
JOIN 
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
LEFT JOIN
return_status as rs
ON rs.issued_id = ist.issued_id
JOIN 
BooksNew as bk
ON ist.issued_book_isbn = bk.isbn
GROUP BY b.branch_id,
    b.manager_id;

-- ============================================================================================================================
-- But the thing is both the procedure is same only diff is that joining order for 1st one we 
-- use all the join left join and 2nd one we use left join and inner join
-- ============================================================================================================================


/*
Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a 
new table active_members containing members who have issued at least one book in the last 2 months.
*/

SELECT
	*
INTO active_members -- Statement to create a new **table** from a query result to our existing Database
FROM members 
WHERE member_id IN ( SELECT
						DISTINCT issued_member_id
						FROM issued_status
						WHERE issued_date >= DATEADD(MONTH, -2, GETDATE())
)
-- After createing a new table from the query now we will see our table
SELECT * FROM active_members;

/*
Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues. 
Display the employee name, number of books processed, and their branch.
*/
SELECT TOP 3
    e.emp_name,
    b.*,
    COUNT(ist.issued_id) as no_book_issued
FROM issued_status as ist
JOIN
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
GROUP BY e.emp_name, b.branch_address,b.branch_id,b.contact_no,b.manager_id,e.emp_id
ORDER BY COUNT(ist.issued_id) DESC

/*
Task 18: Identify Members Issuing High-Risk Books
Write a query to identify members who have issued books more than twice with 
the status "damaged" in the books table. 
Display the member name, book title, and the number of times they've issued damaged books.
*/

/* We wrap this in a CTE (Common Table Expression) 
   to calculate the count first, then filter.
*/
WITH DamagedBookStats AS (
    SELECT 
        m.member_name,
        ist.issued_book_name,
        -- Count how many damaged books this member has issued in total
        COUNT(ist.issued_id) OVER(PARTITION BY m.member_id) as damaged_count
    FROM issued_status ist
    JOIN members m 
        ON ist.issued_member_id = m.member_id
    JOIN BooksNew bn 
        ON ist.issued_book_isbn = bn.isbn
    WHERE bn.status = 'damaged'
)
SELECT 
    member_name,
    issued_book_name,
    damaged_count
FROM DamagedBookStats
WHERE damaged_count > 2;

--Subquery Approach
SELECT 
    m.member_name,
    ist.issued_book_name
    -- We can't easily put the 'count' here without a Window Function or Group By conflict
FROM issued_status ist
JOIN members m 
    ON ist.issued_member_id = m.member_id
JOIN BooksNew bn 
    ON ist.issued_book_isbn = bn.isbn
WHERE bn.status = 'damaged'
AND m.member_id IN (
    -- Subquery: Find members who have issued > 2 DAMAGED books
    SELECT s.issued_member_id
    FROM issued_status s
    JOIN BooksNew b ON s.issued_book_isbn = b.isbn
    WHERE b.status = 'damaged' -- Critical: Must filter for damaged here too
    GROUP BY s.issued_member_id
    HAVING COUNT(s.issued_id) > 2
);

/*
Task 19: Stored Procedure Objective: 
Create a stored procedure to manage the status of books in a library system. 
Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 
The procedure should function as follows: 

Condition-1 When status='yes'
i) The stored procedure should take the book_id as an input parameter. 
ii) The procedure should first check if the book is available (status = 'yes'). 
iii) If the book is available, it should be issued, and the status in the books table should be updated to 'no'.

Condition-2 When status='no'
iv) If the book is not available (status = 'no'), 
the procedure should return an error message indicating that the book is currently not available.
*/

select 
	* 
from issued_status ist
left JOIN BooksNew bn
ON ist.issued_book_isbn = bn.isbn

-- ==============================================================
-- Store Procedure
-- ==============================================================

-- 1. Drop the procedure if it already exists
IF OBJECT_ID('issue_book', 'P') IS NOT NULL
    DROP PROCEDURE issue_book;
GO

CREATE OR ALTER PROCEDURE issue_book (
    @p_issued_id VARCHAR(10),
    @p_issued_member_id VARCHAR(30),
    @p_issued_book_isbn VARCHAR(30),
    @p_issued_emp_id VARCHAR(10)
)
AS
BEGIN
	-- 1. Declare variables
    DECLARE @v_status VARCHAR(10);

	-- SET NOCOUNT ON prevents the sending of DONE_IN_PROC messages 
	-- to the client for every statement.
	SET NOCOUNT ON;

    -- Checking if book is available 'yes'
	SELECT @v_status = status
    FROM BooksNew
    WHERE isbn = @p_issued_book_isbn;

	IF @v_status = 'yes'
    BEGIN
        INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
        VALUES (@p_issued_id, @p_issued_member_id, GETDATE(), @p_issued_book_isbn, @p_issued_emp_id);

		UPDATE BooksNew
        SET status = 'no'
        WHERE isbn = @p_issued_book_isbn;

		PRINT 'Book records added successfully for book isbn : ' + @p_issued_book_isbn;
	END
    ELSE
    BEGIN
        PRINT 'Sorry to inform you the book you have requested is unavailable book_isbn: ' + @p_issued_book_isbn;
    END
END;
GO

-- ==============================================================
-- Testing Store Procedure
-- ==============================================================

-- View current books
SELECT * FROM BooksNew;

-- View issued status
SELECT * FROM issued_status;

-- Execute the procedure
-- Case 1: Issue a book that is available
EXEC issue_book 
    @p_issued_id = 'IS155', 
    @p_issued_member_id = 'C108', 
    @p_issued_book_isbn = '978-0-553-29698-2', 
    @p_issued_emp_id = 'E104';

-- Case 2: Try to issue a book that is NOT available
EXEC issue_book 
    @p_issued_id = 'IS156', 
    @p_issued_member_id = 'C108', 
    @p_issued_book_isbn = '978-0-375-41398-8', 
    @p_issued_emp_id = 'E104';

-- Verify the update
SELECT * FROM BooksNew
WHERE isbn = '978-0-375-41398-8';

/*
Task 20: Create Table As Select (CTAS) Objective: Create a CTAS (Create Table As Select)
fquery to identify overdue books and calculate fines.

Description: Write a CTAS query to create a new table that lists each member and the books 
they have issued but not returned within 30 days. 

The table should include: 
i)The number of overdue books. 
ii) The total fines, with each day's fine calculated at $0.50. 
iii) The number of books issued by each member. DONE

The resulting table should show: 
iv)Member ID Number of overdue books Total fines
*/
SELECT 
    m.member_id,
    COUNT(ist.issued_id) AS number_of_overdue_books,
    SUM((DATEDIFF(DAY, ist.issued_date, GETDATE()) - 30) * 0.50) AS total_fines
INTO overdue_books_summary
FROM issued_status ist
JOIN members m 
    ON ist.issued_member_id = m.member_id
LEFT JOIN return_status rs 
    ON ist.issued_id = rs.issued_id
WHERE 
    rs.issued_id IS NULL                -- 1. Book has NOT been returned
    AND DATEDIFF(DAY, ist.issued_date, GETDATE()) > 30 -- 2. Book is older than 30 days
GROUP BY m.member_id;
-- Testing
select * from overdue_books_summary