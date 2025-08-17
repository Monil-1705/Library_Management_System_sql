SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT * FROM members;
SELECT * FROM return_status;

-- Project TASK

-- ### 2. CRUD

-- Task 1. Create a New Book Record
-- "('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES
	('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');


-- Task 2: Update an Existing Member's Address

UPDATE members
SET member_address = '123 Oak St'
WHERE member_id = 'C103';

-- updated member_id C103's address


-- Task 3: Delete a Record from the Issued Status Table
-- Objective: Delete the record with issued_id = 'IS104' from the issued_status table.

DELETE FROM issued_status
WHERE issued_id = 'IS104';


-- Task 4: Retrieve All Books Issued by a Specific Employee
-- Objective: Select all books issued by the employee with emp_id = 'E101'.

SELECT 
	issued_book_isbn,
	issued_book_name
FROM issued_status
WHERE issued_emp_id = 'E101';


-- Task 5: List Members Who Have Issued More Than One Book
-- Objective: Use GROUP BY to find members who have issued more than one book.

SELECT 
	issued_member_id,
	COUNT(*) AS book_count
FROM issued_status
GROUP BY issued_member_id
HAVING COUNT(*) > 1;


-- ### 3. CTAS (Create Table As Select)

-- Task 6: Create Summary Tables**: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt
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


-- ### 4. Data Analysis & Findings

-- Task 7. **Retrieve All Books in a Specific Category:

SELECT * FROM books
WHERE category = 'History';


-- Task 8: Find Total Rental Income by Category:

SELECT 
	category, 
	SUM(rental_price) AS total_rental_income
FROM books
GROUP BY category
ORDER BY 2 DESC;


-- Task 9. **List Members Who Registered in the Last 180 Days**:

SELECT * FROM members
WHERE reg_date >= ( 
	SELECT (MAX(reg_date) - INTERVAL '180 DAYS') AS diff
	FROM members M
);


-- Task 10: List Employees with Their Branch Manager's Name and their branch details**:

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


-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold

DROP TABLE books_with_price_gt_4;
CREATE TABLE books_with_price_gt_4 AS 
SELECT * FROM books
WHERE rental_price > 4;
SELECT * FROM books_with_price_gt_4;


-- Task 12: Retrieve the List of Books Not Yet Returned

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




-- ### Advanced SQL Operations

-- Task 13: Identify Members with Overdue Books
-- Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's name, book title, issue date, and days overdue.

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


-- Task 14: Update Book Status on Return
-- Write a query to update the status of books in the books table to "yes" when they are returned (based on entries in the return_status table).

CREATE OR REPLACE PROCEDURE add_return_status(
	p_return_id VARCHAR(10), 
	p_issued_id VARCHAR(10), 
	p_book_quality VARCHAR(15)
)
LANGUAGE plpgsql
AS $$

DECLARE
	v_isbn VARCHAR(30);
	v_book_name VARCHAR(100);

BEGIN

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

	RAISE NOTICE 'Thank you for returning the book: % with isbn: %', v_book_name, v_isbn;
END;
$$;

CALL add_return_status('RS200', 'IS106', 'Good');


-- Task 15: Branch Performance Report
-- Create a query that generates a performance report for each branch, 
-- showing the number of books issued, 
-- the number of books returned, 
-- and the total revenue generated from book rentals.

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


-- Task 16: CTAS: Create a Table of Active Members
-- Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members 
-- who have issued at least one book in the last 6 months.

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


-- Task 17: Find Employees with the Most Book Issues Processed
-- Write a query to find the top 3 employees who have processed the most book issues. 
-- Display the employee name, number of books processed, and their branch.

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


-- Task 18: Identify Members Issuing High-Risk Books
-- Write a query to identify members who have issued books more than twice with the status "damaged" in the books table. 
-- Display the member name, book title, and the number of times they've issued damaged books.    

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

-- Task 19: Stored Procedure
-- Objective: Create a stored procedure to manage the status of books in a library system.
--     Description: Write a stored procedure that updates the status of a book based on its issuance or return. Specifically:
--     If a book is issued, the status should change to 'no'.
--     If a book is returned, the status should change to 'yes'.

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


-- Task 20: Create Table As Select (CTAS)
-- Objective: Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.

-- Description: Write a CTAS query to create a new table that lists each member and the books they have issued but not returned within 30 days. The table should include:
--     The number of overdue books.
--     The total fines, with each day's fine calculated at $0.50.
--     The number of books issued by each member.
--     The resulting table should show:
--     Member ID
--     Number of overdue books
--     Total fines

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


-- Task 21: Write a query to list out Most Popular Books by Category
-- Description : Write a query to display category, book_name and issued_count
-- of the most popular books in each category.

SELECT 
	b.category, 
	b.book_title,
	COUNT(i.*) AS issued_cnt
FROM issued_status i
JOIN books b
ON b.isbn = i.issued_book_isbn
GROUP BY b.category, b.book_title
ORDER BY category, issued_cnt DESC;

-- Task 22: Employee Efficiency Report
-- (books processed per employee per month)

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


-- Task 23: Category-Wise Revenue Contribution
-- Description : Write a query to find out how much each category contribute in total revenue

SELECT 
	b.category,
	SUM(b.rental_price) AS revenue,
	ROUND(SUM(b.rental_price) * 100 / (SELECT SUM(rental_price) FROM books), 2) AS pct_contribution
FROM books b
JOIN issued_status i
ON b.isbn = i.issued_book_isbn
GROUP BY 1
ORDER BY 3 DESC;

-- In this query,
-- Each issue in issued_status creates a row → so if the same book was issued 5 times, its rental_price is added 5 times.
-- This gives you actual revenue generated based on number of issues.

/*
-- In this query, 
-- Each book is only counted once, even if it was issued multiple times.
-- So you are calculating potential revenue from books that have ever been issued.

SELECT 
	category,
	SUM(rental_price) AS revenue,
	ROUND(SUM(rental_price * 100) / (SELECT SUM(rental_price) FROM books), 2) AS pct_contribution
FROM books
WHERE isbn IN (
	SELECT issued_book_isbn
	FROM issued_status
)
GROUP BY category
ORDER BY 2 DESC;
*/

-- If every book in your library was issued only once, both queries give the same result.

-- If books were issued multiple times, Query 1 will give higher revenue (correct for “actual revenue”)
