# Library Management System using SQL Project --P2

## Project Overview

**Project Title**: Library Management System  
**Level**: Intermediate  
**Database**: `library_db`

This project demonstrates the implementation of a Library Management System using SQL. It includes creating and managing tables, performing CRUD operations, and executing advanced SQL queries. The goal is to showcase skills in database design, manipulation, and querying.

![Library_project](https://github.com/Monil-1705/Library_Management_System_sql/blob/main/library.jpg)

## Objectives

1. **Set up the Library Management System Database**: Create and populate the database with tables for branches, employees, members, books, issued status, and return status.
2. **CRUD Operations**: Perform Create, Read, Update, and Delete operations on the data.
3. **CTAS (Create Table As Select)**: Utilize CTAS to create new tables based on query results.
4. **Advanced SQL Queries**: Develop complex queries to analyze and retrieve specific data.

## Project Structure

### 1. Database Setup
![ERD](https://github.com/Monil-1705/Library_Management_System_sql/blob/main/ERD.png)

- **Database Creation**: Created a database named `library_db`.
- **Table Creation**: Created tables for branches, employees, members, books, issued status, and return status. Each table includes relevant columns and relationships.

```sql
-- creating branch table
DROP TABLE IF EXISTS branch;
CREATE TABLE branch(
	branch_id VARCHAR(10) PRIMARY KEY,
	manager_id VARCHAR(10),
	branch_address VARCHAR(50),
	contact_no VARCHAR(15)
);

-- creating employee table
DROP TABLE IF EXISTS employees;
CREATE TABLE employees(
	emp_id VARCHAR(10) PRIMARY KEY,
	emp_name VARCHAR(50),
	position VARCHAR(30),
	salary DECIMAL(10, 2),
	branch_id VARCHAR(10) --FK
);

-- creating books table
DROP TABLE IF EXISTS books;
CREATE TABLE books(
	isbn VARCHAR(20) PRIMARY KEY,
	book_title VARCHAR(100),
	category VARCHAR(30),
	rental_price DECIMAL(10, 2),
	status VARCHAR(3),
	author VARCHAR(30),
	publisher VARCHAR(100)
);

-- creating issued_status table
DROP TABLE IF EXISTS issued_status;
CREATE TABLE issued_status(
	issued_id VARCHAR(10) PRIMARY KEY,
	issued_member_id VARCHAR(10), --FK
	issued_book_name VARCHAR(100),
	issued_date DATE,
	issued_book_isbn VARCHAR(30), --FK
	issued_emp_id VARCHAR(10) -- FK
);

-- creating members table 

DROP TABLE IF EXISTS members;
CREATE TABLE members(
	member_id VARCHAR(10) PRIMARY KEY,
	member_name VARCHAR(50),
	member_address VARCHAR(100),
	reg_date DATE
);

-- creating return_status table
DROP TABLE IF EXISTS return_status;
CREATE TABLE return_status(
	return_id VARCHAR(10) PRIMARY KEY,
	issued_id VARCHAR(10), --FK
	return_book_name VARCHAR(100),
	return_date DATE,
	return_book_isbn VARCHAR(50)
);

-- Adding FOREIGN KEY contraints

ALTER TABLE employees
ADD CONSTRAINT fk_branch
FOREIGN KEY (branch_id)
REFERENCES branch(branch_id);

ALTER TABLE issued_status
ADD CONSTRAINT fk_member
FOREIGN KEY (issued_member_id)
REFERENCES members(member_id);

ALTER TABLE issued_status
ADD CONSTRAINT fk_book
FOREIGN KEY (issued_book_isbn)
REFERENCES books(isbn);

ALTER TABLE issued_status
ADD CONSTRAINT fk_employee
FOREIGN KEY (issued_emp_id)
REFERENCES employees(emp_id);

ALTER TABLE return_status
ADD CONSTRAINT fk_issued
FOREIGN KEY (issued_id)
REFERENCES issued_status(issued_id);
```

### 2. CRUD Operations

- **Create**: Inserted sample records into the `books` table.
- **Read**: Retrieved and displayed data from various tables.
- **Update**: Updated records in the `employees` table.
- **Delete**: Removed records from the `members` table as needed.

**Task 1. Create a New Book Record**
-- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

```sql
INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
SELECT * FROM books;
```

**Task 2: Update an Existing Member's Address**

```sql
UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C103';
```

**Task 3: Delete a Record from the Issued Status Table**
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.

```sql
DELETE FROM issued_status
WHERE   issued_id =   'IS121';
```

**Task 4: Retrieve All Books Issued by a Specific Employee**
-- Objective: Select all books issued by the employee with emp_id = 'E101'.
```sql
SELECT * FROM issued_status
WHERE issued_emp_id = 'E101';
```


**Task 5: List Members Who Have Issued More Than One Book**
-- Objective: Use GROUP BY to find members who have issued more than one book.

```sql
SELECT 
	issued_member_id,
	COUNT(*) AS book_count
FROM issued_status
GROUP BY issued_member_id
HAVING COUNT(*) > 1;
```

### 3. CTAS (Create Table As Select)

- **Task 6: Create Summary Tables**: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**

```sql
DROP TABLE IF EXISTS books_issued_cnt;
CREATE TABLE books_issued_cnt AS
SELECT 
	b.isbn, 
	b.book_title, 
	COUNT(i.issued_id) AS total_book_issued_cnt
FROM books AS b
JOIN issued_status AS i
ON b.isbn = i.issued_book_isbn
GROUP BY b.isbn;
SELECT * FROM books_issued_cnt;
```


### 4. Data Analysis & Findings

The following SQL queries were used to address specific questions:

Task 7. **Retrieve All Books in a Specific Category**:

```sql
SELECT * FROM books
WHERE category = 'History';
```

8. **Task 8: Find Total Rental Income by Category**:

```sql
SELECT
            category, 
	SUM(rental_price) AS total_rental_income
FROM books
GROUP BY category
ORDER BY 2 DESC;

```

9. **List Members Who Registered in the Last 180 Days**:
```sql
SELECT * FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '180 days';
```

10. **List Employees with Their Branch Manager's Name and their branch details**:

```sql
SELECT 
	e1.emp_id,
	e1.emp_name,
	e1.position,
	e1.salary,
	b.*,
	e2.emp_name AS branch_manager_name
FROM employees e1
JOIN branch b
ON e1.branch_id = b.branch_id
JOIN employees e2
ON b.manager_id = e2.emp_id;
```

Task 11. **Create a Table of Books with Rental Price Above a Certain Threshold**:
```sql
DROP TABLE books_with_price_gt_4;
CREATE TABLE books_with_price_gt_4 AS 
SELECT * FROM books
WHERE rental_price > 4;
SELECT * FROM books_with_price_gt_4;
```

Task 12: **Retrieve the List of Books Not Yet Returned**
```sql
SELECT i.issued_book_name, i.issued_book_isbn
FROM issued_status i
WHERE i.issued_id NOT IN (
	SELECT r.issued_id
	FROM return_status r
) ;

	------------ OTHER WAY ------------

SELECT i.issued_book_name, i.issued_book_isbn
FROM issued_status i
LEFT JOIN return_status r
ON i.issued_id = r.issued_id
WHERE r.issued_id IS NULL;
```

## Advanced SQL Operations

**Task 13: Identify Members with Overdue Books**  
Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue.

```sql
SELECT 
	m.member_id,
	m.member_name,
	i.issued_book_name,
	i.issued_date,
	CURRENT_DATE - i.issued_date AS overdue_days
FROM members m
JOIN issued_status i
ON m.member_id = i.issued_member_id
LEFT JOIN return_status r
ON i.issued_id = r.issued_id
WHERE 
	r.return_date IS NULL 
	AND
	CURRENT_DATE - i.issued_date > 30
ORDER BY 1, 4;
```


**Task 14: Update Book Status on Return**  
Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).


```sql

CREATE OR REPLACE PROCEDURE add_return_records(p_return_id VARCHAR(10), p_issued_id VARCHAR(10), p_book_quality VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
    v_isbn VARCHAR(50);
    v_book_name VARCHAR(80);
    
BEGIN
    -- all your logic and code
    -- inserting into returns based on users input
    INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
    VALUES
    (p_return_id, p_issued_id, CURRENT_DATE, p_book_quality);

    SELECT 
        issued_book_isbn,
        issued_book_name
        INTO
        v_isbn,
        v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;

    RAISE NOTICE 'Thank you for returning the book: %', v_book_name;
    
END;
$$


-- Testing FUNCTION add_return_records

-- issued_id = IS135
-- ISBN = WHERE isbn = '978-0-307-58837-1'

SELECT * FROM books
WHERE isbn = '978-0-307-58837-1';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

SELECT * FROM return_status
WHERE issued_id = 'IS135';

-- calling function 
CALL add_return_records('RS138', 'IS135', 'Good');

-- calling function 
CALL add_return_records('RS148', 'IS140', 'Good');

```




**Task 15: Branch Performance Report**  
Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.

```sql
DROP TABLE IF EXISTS performance_report;
CREATE TABLE performance_report AS
SELECT 
	b.branch_id,
	b.manager_id,
	COUNT(i.issued_id) AS books_issued_cnt,
	COUNT(r.return_id) AS books_return_cnt,
	SUM(bk.rental_price) AS total_revenue
FROM issued_status i
JOIN employees e
ON e.emp_id = i.issued_emp_id
JOIN branch b
ON e.branch_id = b.branch_id
LEFT JOIN return_status r
ON r.issued_id = i.issued_id
JOIN books bk
ON bk.isbn = i.issued_book_isbn
GROUP BY b.branch_id, b.manager_id;

SELECT * FROM performance_report;
```

**Task 16: CTAS: Create a Table of Active Members**  
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months.

```sql

DROP TABLE IF EXISTS active_members;

CREATE TABLE active_members AS 
SELECT * 
FROM members
WHERE member_id IN (
	SELECT DISTINCT issued_member_id
	FROM issued_status
	WHERE issued_date >= CURRENT_DATE - INTERVAL '6 month'
)
ORDER BY member_id;

SELECT * FROM active_members;
```


**Task 17: Find Employees with the Most Book Issues Processed**  
Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.

```sql
SELECT 
	e.emp_id,
	e.emp_name,
	b.*,
	COUNT(i.issued_id) AS books_processed_cnt
FROM employees e
JOIN branch b
ON b.branch_id = e.branch_id
JOIN issued_status i
ON e.emp_id = i.issued_emp_id
GROUP BY 1, 3
ORDER BY books_processed_cnt DESC
LIMIT 3;
```

**Task 18: Identify Members Issuing High-Risk Books**  
Write a query to identify members who have issued books more than twice with the status "damaged" in the books table. Display the member name, book title, and the number of times they've issued damaged books.    

```sql
SELECT
	m.member_id,
	m.member_name,
	i.issued_book_name,
	COUNT(r.book_quality) AS books_issued_cnt
FROM members m
JOIN issued_status i
ON i.issued_member_id = m.member_id
JOIN return_status r
ON i.issued_id = r.issued_id
WHERE r.book_quality = 'Damaged'
GROUP BY 1, 2, 3
HAVING COUNT(r.book_quality) > 2;
ORDER BY 4;
```


**Task 19: Stored Procedure**

Objective: Create a stored procedure to manage the status of books in a library system.

Description: Write a stored procedure that updates the status of a book in the library based on its issuance. The procedure should function as follows:
The stored procedure should take the book_id as an input parameter.
The procedure should first check if the book is available (status = 'yes').
If the book is available, it should be issued, and the status in the books table should be updated to 'no'.
If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.

```sql

CREATE OR REPLACE PROCEDURE issue_book(
	p_issued_id VARCHAR(10),
	p_issued_member_id VARCHAR(10), 
	p_issued_book_isbn VARCHAR(30),
	p_issued_emp_id VARCHAR(10)
)
LANGUAGE plpgsql
AS $$

DECLARE
	v_status VARCHAR(3);

BEGIN

	-- checking if book status is 'yes' (i.e. book is available)
	SELECT status
	INTO v_status
	FROM books
	WHERE isbn = p_issued_book_isbn;

	IF v_status = 'yes' THEN
		INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
		VALUES
		(p_issued_id, p_issued_member_id, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id);
	
		UPDATE books
		SET status = 'no'
		WHERE isbn = p_issued_book_isbn;

		RAISE NOTICE 'Book record added successfull for book isbn : %', p_issued_book_isbn;	

	ELSE
		RAISE NOTICE 'Sorry, book you requested is unavailble.';
	END IF;
END;
$$;

-- Testing The function
SELECT * FROM books;
-- "978-0-553-29698-2" -- yes
-- "978-0-375-41398-8" -- no
SELECT * FROM issued_status;

CALL issue_book('IS156', 'C108', '978-0-553-29698-2', 'E104');
CALL issue_book('IS156', 'C108', '978-0-553-29698-8', 'E104');

```


**Task 20: Create Table As Select (CTAS)**

Objective: Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.

Description: Write a CTAS query to create a new table that lists each member and the books they have issued but not returned within 30 days. The table should include:
    The number of overdue books.
    The total fines, with each day's fine calculated at $0.50.
    The number of books issued by each member.
    The resulting table should show:
    Member ID
    Number of overdue books
    Total fines

```sql
DROP TABLE IF EXISTS fine;

CREATE TABLE fine AS
WITH overdue_books AS (
	SELECT 
		i.issued_member_id,
		COUNT(*) AS overdue_books_cnt,
		SUM(CURRENT_DATE - i.issued_date) AS total_overdue_days
	FROM issued_status i
	LEFT JOIN return_status r
	ON i.issued_id = r.issued_id
	WHERE r.return_date IS NULL AND CURRENT_DATE > issued_date + INTERVAL '30 day'
	GROUP BY 1
)
SELECT 
	*,
	total_overdue_days * 0.50 AS total_fine	
FROM overdue_books;

SELECT * FROM fine;

```


**Task 21: Most Popular Books by Category**  

Objective: Identify the most popular books within each category based on the number of times they were issued.

Description: This query joins the issued_status and books tables to count how many times each book has been issued. By grouping results by category and book title, we can analyze which books are most in demand across different categories, helping the library in stocking and purchasing decisions.
```sql
SELECT 
	b.category, 
	b.book_title,
	COUNT(i.*) AS issued_cnt
FROM issued_status i
JOIN books b
ON b.isbn = i.issued_book_isbn
GROUP BY b.category, b.book_title
ORDER BY category, issued_cnt DESC;
```


**Task 22: Employee Efficiency Report**

Objective: Generate a monthly report to measure each employee’s efficiency based on the number of books they processed (issued).

Description: The query joins the employees and issued_status tables, grouping results by employee and month. By counting the number of books issued per employee per month, the library can monitor employee performance, identify top performers, and ensure workload is evenly distributed.

```sql
SELECT 
	e.emp_id,
	e.emp_name,
	TO_CHAR(i.issued_date, 'YYYY-MM') AS months,
	COUNT(*) AS issue_cnt
FROM issued_status i
JOIN employees e
ON e.emp_id = i.issued_emp_id
GROUP BY 1, 2, 3
ORDER BY 3 DESC, 4 DESC;
```


**Task 23: Category-Wise Revenue Contribution**

Objective:Analyze how much revenue each book category contributes to the library’s total revenue.

Description:This query joins the books and issued_status tables to calculate the total rental income per category. It then compares each category’s revenue to the overall library revenue by calculating percentage contribution. This helps in identifying the most profitable categories, supporting strategic decisions for resource allocation and future acquisitions.

```sql
SELECT 
	b.category,
	SUM(b.rental_price) AS revenue,
	ROUND(SUM(b.rental_price) * 100 / (SELECT SUM(rental_price) FROM books), 2) AS pct_contribution
FROM books b
JOIN issued_status i
ON b.isbn = i.issued_book_isbn
GROUP BY 1
ORDER BY 3 DESC;
```


## Reports

## 📊 Reports  

The following reports were generated from the queries in this project:  

### 1. Member Analysis Reports  
- Count of total members and active members.  
- Identification of members with overdue books.  
- Members who borrowed from all categories (loyal customers).  
- Detection of inactive members who have not borrowed books in the last 6 months.  

### 2. Book & Category Reports  
- Most popular books in each category (Task 21).  
- Category-wise revenue contribution to total library revenue (Task 23).  
- Tracking of lost and damaged books with estimated cost impact.  
- Comparison between potential revenue (if all books are issued) vs. actual revenue (based on issued records).  

### 3. Employee Reports  
- Employee efficiency report (Task 22) – number of books processed per employee per month.  
- Identification of employees handling the highest workload.  
- Monthly performance trend for employees.  

### 4. Revenue & Fine Reports  
- Calculation of overdue fines based on delay days (Task 20).  
- Total revenue generated by issued books.  
- Fine recovery contribution to overall revenue.  

### 5. Operational Insights  
- High-risk members who repeatedly issue damaged books.  
- Monitoring of employee contribution to library services.  
- Identification of categories generating the most income, supporting acquisition and stocking decisions.  

---

### 📌 Summary of Findings  
From the analysis, it was observed that **Classic and History categories** contribute the highest share of revenue to the library, while **some members repeatedly issue damaged books**, posing a potential risk. Employee performance varies across months, with certain staff handling significantly more book issues than others. The overdue fine system ensures consistent revenue recovery from late returns.  

Overall, the Library Management System not only manages day-to-day operations but also provides valuable **business insights into member behavior, employee efficiency, and financial performance**, making it a robust and analytical system.  


## Conclusion

This project demonstrates the application of SQL skills in creating and managing a library management system. It includes database setup, data manipulation, and advanced querying, providing a solid foundation for data management and analysis.

## How to Use

1. **Clone the Repository**: Clone this repository to your local machine.
   ```sh
   git clone https://github.com/Monil-1705/Library_Management_System_sql.git
   ```

2. **Set Up the Database**: Execute the SQL scripts in the `library_management_system.sql` file to create and populate the database.
3. **Run the Queries**: Use the SQL queries in the `libirary_management_system_queries.sql` file to perform the analysis.
4. **Explore and Modify**: Customize the queries as needed to explore different aspects of the data or answer additional questions.

**THANK YOU :)**
