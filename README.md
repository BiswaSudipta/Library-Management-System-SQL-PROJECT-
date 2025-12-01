
---

# 📚 **Library Management System – SQL Project**

![Intro](Picture/Data_to_Decision.png)

---

## 📝 **Project Overview**

This SQL project is a complete end-to-end **Library Management Database System** designed using **Microsoft SQL Server (T-SQL)**.
It simulates a real-world library environment where data is used to:

* Manage inventory
* Track book issuance and returns
* Automate workflows using Stored Procedures
* Generate analytical reports
* Identify business insights and member behavior

The project solves **20 structured business use cases**, ranging from basic CRUD operations to advanced analytics using **CTEs, window functions, Stored Procedures, CTAS**, and **SELECT INTO**.

---

## 🎯 **Project Objectives**

### ✔️ **1. Build a Normalized Relational Database**

Connecting **Books**, **Members**, **Employees**, **Branches**, **Issued Status**, and **Return Status** using primary and foreign keys.

### ✔️ **2. Automate Operations**

Using Stored Procedures for:

* Issuing books
* Handling returns
* Updating inventory status

### ✔️ **3. Perform Business Analytics**

* Branch performance
* Revenue reporting
* Overdue books calculation
* Member activity tracking

### ✔️ **4. Generate Actionable Insights**

Helping libraries make data-driven decisions.

---

## 🗂️ **Database Schema**

![ERD](Picture/library_erd.png)

### **Tables Included**

* **BooksNew**
* **Branch**
* **Employees**
* **Members**
* **Issued_Status**
* **Return_Status**

---

## 📁 **Project Folder Structure**

```
📦 Library-Management-SQL-Project
 ┣ 📂 Datasets
 ┃ ┣ 📄 books.csv
 ┃ ┣ 📄 employees.csv
 ┃ ┣ 📄 issued_status.csv
 ┃ ┣ 📄 members.csv
 ┃ ┣ 📄 return_status.csv
 ┃ ┗ 📄 branch.csv
 ┣ 📂 PPT & Report
 ┃ ┣ 📄 Library Management SQL Project PPT.pdf
 ┃ ┗ 📄 Library Management SQL Project Report.pdf
 ┣ 📂 Picture
 ┃ ┣ 📄 From_Data_to_Decision.png
 ┃ ┗ 📄 library_erd.png
 ┣ 📂 SQL Query
 ┃ ┣ 📄 Business_Query.sql
 ┃ ┗ 📄 FK&PK_Declearing_Query.sql
 ┣ 📂 Webpage
 ┃ ┣ 📄 Full_functional.htm
 ┃ ┗ 📄 Infographic.htm
 ┗ 📄 README.md
```

---

# 🧩 **Solved Problem Statements (20 Total)**

The project is divided into 3 levels:

---

## 🟢 **LEVEL 1 – BASIC SQL OPERATIONS**

### **Query 1: Insert New Book**

```sql
INSERT INTO BooksNew(
    isbn, book_title, category, rental_price, status, author, publisher
)
VALUES(
    '978-1-60129-456-2', 'To Kill a Mockingbird',
    'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.'
);
```

### **Query 2: Update Member Address**

```sql
UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C103';
```

### **Query 3: Delete Invalid Issued Record**

```sql
DELETE FROM issued_status
WHERE issued_id = 'IS121';
```

### **Query 4: Retrieve Books Issued by Employee E101**

```sql
SELECT issued_book_name
FROM issued_status
WHERE issued_emp_id = 'E101';
```

### **Query 5: Members Who Issued More Than One Book**

```sql
SELECT issued_emp_id, COUNT(issued_emp_id)
FROM issued_status
GROUP BY issued_emp_id
HAVING COUNT(issued_emp_id) > 1;
```

---

## 🟡 **LEVEL 2 – INTERMEDIATE SQL (JOIN, AGGREGATION, CTAS)**

### **Query 6: CTAS – Book Issue Frequency Table**

**(SQL Server Version)**

```sql
SELECT  
    b.isbn,
    b.book_title,
    COUNT(b.book_title) AS issue_count
INTO book_issued_cnt
FROM issued_status i
LEFT JOIN BooksNew b
    ON i.issued_book_isbn = b.isbn
GROUP BY b.book_title, b.isbn;
```

---

### **Query 7: Retrieve All Classic Category Books**

```sql
SELECT * FROM BooksNew
WHERE category = 'Classic';
```

---

### **Query 8: Total Rental Income by Category**

```sql
SELECT
    b.category,
    SUM(b.rental_price) AS Total_Rental_Income,
    COUNT(*)
FROM issued_status i
LEFT JOIN BooksNew b
    ON i.issued_book_isbn = b.isbn
GROUP BY category;
```

---

### **Query 9: Members Registered in Last 180 Days**

```sql
SELECT *
FROM members
WHERE reg_date >= DATEADD(day, -180, GETDATE());
```

---

### **Query 10: Employee Details + Branch Manager Name**

```sql
SELECT
    e1.emp_id, e1.emp_name, e1.position, e1.salary,
    b.*, e2.emp_name AS manager_name
FROM employees e1
INNER JOIN branch b
    ON e1.branch_id = b.branch_id
INNER JOIN employees e2
    ON e2.emp_id = b.manager_id;
```

---

### **Query 11: CTAS – Create Expensive Books Table**

```sql
SELECT *
INTO expensive_books
FROM BooksNew
WHERE rental_price > 7.00;

SELECT * FROM expensive_books;
```

---

### **Query 12: Books Not Returned Yet**

```sql
SELECT *
FROM issued_status i
LEFT JOIN return_status r
    ON i.issued_id = r.issued_id
WHERE r.issued_id IS NULL;
```

---

## 🔴 **LEVEL 3 – ADVANCED SQL (CTE, PROCEDURES, ANALYTICS)**

---

### **Query 13: Overdue Books (30-Day Limit)**

#### Method 1 – Returned late:

```sql
SELECT
    m.member_name, m.member_id,
    i.issued_book_name, i.issued_date,
    (DATEDIFF(day, i.issued_date, r.return_date)) - 30 AS overdue
FROM issued_status i
LEFT JOIN return_status r
    ON i.issued_id = r.issued_id
LEFT JOIN members m
    ON i.issued_member_id = m.member_id
WHERE r.return_date > DATEADD(day, 30, i.issued_date);
```

#### Method 2 – Not returned and overdue:

```sql
SELECT
    ist.issued_member_id,
    m.member_name,
    b.book_title,
    ist.issued_date,
    DATEDIFF(DAY, ist.issued_date, GETDATE()) - 30 AS days_overdue
FROM issued_status ist
JOIN members m ON ist.issued_member_id = m.member_id
JOIN BooksNew b ON b.isbn = ist.issued_book_isbn
LEFT JOIN return_status rs ON rs.issued_id = ist.issued_id
WHERE rs.return_date IS NULL
AND DATEDIFF(DAY, ist.issued_date, GETDATE()) > 30;
```

---

### **Query 14: Update Book Status After Return**

```sql
ALTER TABLE return_status
ADD book_quality VARCHAR(20);

UPDATE return_status
SET book_quality = 'Good';
```

---

## 🛠️ **Stored Procedure – Add Return Record**

```sql
CREATE OR ALTER PROCEDURE add_return_records
    @p_return_id VARCHAR(10),
    @p_issued_id VARCHAR(10),
    @p_book_quality VARCHAR(10)
AS
BEGIN
    DECLARE @v_isbn VARCHAR(50);
    DECLARE @v_book_name VARCHAR(80);

    INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
    VALUES (@p_return_id, @p_issued_id, CAST(GETDATE() AS DATE), @p_book_quality);

    SELECT  
        @v_isbn = issued_book_isbn,
        @v_book_name = issued_book_name
    FROM issued_status
    WHERE issued_id = @p_issued_id;

    UPDATE BooksNew
    SET status = 'yes'
    WHERE isbn = @v_isbn;

    PRINT 'Thank you for returning the book: ' + ISNULL(@v_book_name,'Unknown');
END;
GO

EXEC add_return_records 'RS138', 'IS135', 'Good';
EXEC add_return_records 'RS148', 'IS140', 'Good';
```

---

## 📊 **Branch Performance Report (CTAS)**

### **Method 1 – Create Table**

```sql
SELECT  
    b.branch_id,
    b.manager_id,
    COUNT(ist.issued_book_name) AS issued_book_count,
    COUNT(rs.return_id) AS No_of_book_return,
    SUM(bn.rental_price) AS Total_revenue
INTO branch_reports
FROM employees e
LEFT JOIN Branch b ON e.branch_id = b.branch_id
LEFT JOIN issued_status ist ON e.emp_id = ist.issued_emp_id
LEFT JOIN return_status rs ON ist.issued_id = rs.issued_id
LEFT JOIN BooksNew bn ON bn.isbn = ist.issued_book_isbn
GROUP BY b.branch_id, b.manager_id;
```

---

## 👥 **Top 3 Employees With Most Issued Books**

```sql
SELECT TOP 3
    e.emp_name, b.*,
    COUNT(ist.issued_id) AS no_book_issued
FROM issued_status ist
JOIN employees e ON e.emp_id = ist.issued_emp_id
JOIN branch b ON e.branch_id = b.branch_id
GROUP BY e.emp_name, b.branch_address, b.branch_id, b.contact_no, b.manager_id, e.emp_id
ORDER BY COUNT(ist.issued_id) DESC;
```

---

## ⚠️ **High-Risk Members (CTE)**

```sql
WITH DamagedBookStats AS (
    SELECT  
        m.member_name,
        ist.issued_book_name,
        COUNT(ist.issued_id) OVER(PARTITION BY m.member_id) AS damaged_count
    FROM issued_status ist
    JOIN members m ON ist.issued_member_id = m.member_id
    JOIN BooksNew bn ON ist.issued_book_isbn = bn.isbn
    WHERE bn.status = 'damaged'
)
SELECT *
FROM DamagedBookStats
WHERE damaged_count > 2;
```

---

# 📈 **Business Insights**

### 🔹 **Revenue Optimization**

* Classic and Fiction categories generate higher rental income.

### 🔹 **Operational Efficiency**

* Stored procedures reduce manual updates and maintain consistent book status.

### 🔹 **Risk Management**

* Overdue and damaged book analysis helps identify high-risk members.

### 🔹 **Branch Analysis**

* Branch performance tables reveal high-traffic locations.

---

# 🛠️ **Tech Stack**

| Component      | Technology                                             |
| -------------- | ------------------------------------------------------ |
| Database       | MS SQL Server                                          |
| Query Language | T-SQL                                                  |
| IDE            | SSMS                                                   |
| Techniques     | Joins, CTAS, CTEs, Window Functions, Stored Procedures |

---

# 👤 **Author**

**Created by: *Sudipta Biswas***

---

