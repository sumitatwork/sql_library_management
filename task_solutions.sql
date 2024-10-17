SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT * FROM return_status;
SELECT * FROM members;


-- Project Task

-- Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
SELECT * FROM books;

-- Task 2: Update an Existing Member's Address

UPDATE members
SET member_address = '125 Main St'
WHERE member_id = 'C101';
SELECT * FROM members;

-- Task 3: Delete a Record from the Issued Status Table 
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.

DELETE FROM issued_status
WHERE issued_id = 'IS121';
SELECT * FROM issued_status;

-- Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.

SELECT * FROM issued_status
WHERE issued_emp_id = 'E101';

-- Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.

SELECT ist.issued_emp_id, e.emp_name
FROM issued_status as ist
JOIN employees as e ON e.emp_id = ist.issued_emp_id
GROUP BY 1, 2
HAVING COUNT(ist.issued_id) > 1;

-- <<CTAS>>
-- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**

CREATE TABLE book_cnts AS
SELECT b.isbn, b.book_title, COUNT(ist.issued_id) as no_issued
FROM books as b
JOIN issued_status as ist ON ist.issued_book_isbn = b.isbn
GROUP BY 1, 2;

SELECT * FROM book_cnts;

-- Task 7. Retrieve All Books in a Specific Category:

SELECT * FROM books
WHERE category = 'Classic';

-- Task 8: Find Total Rental Income by Category:

SELECT b.category, SUM(b.rental_price), COUNT(*)
FROM books as b
JOIN issued_status as ist ON ist.issued_book_isbn = b.isbn
GROUP BY 1;

-- Task 9: List Members Who Registered in the Last 180 Days:

SELECT * FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '180 days';

INSERT INTO members(member_id, member_name, member_address, reg_date)
VALUES ('C118', 'sam', '145 Main St', '2024-06-01'),
       ('C119', 'john', '133 Main St', '2024-05-01');

INSERT INTO members(member_id, member_name, member_address, reg_date)
VALUES
('C118', 'sam', '145 Main St', '2024-06-01'),
('C119', 'john', '133 Main St', '2024-05-01');

-- task 10 List Employees with Their Branch Manager's Name and their branch details:

SELECT e1.*, b.manager_id, e2.emp_name as manager
FROM employees as e1
JOIN branch as b ON b.branch_id = e1.branch_id
JOIN employees as e2 ON b.manager_id = e2.emp_id;

-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold 7USD:

CREATE TABLE books_price_greater_than_seven AS
SELECT * FROM Books
WHERE rental_price > 7;

SELECT * FROM books_price_greater_than_seven;

-- Task 12: Retrieve the List of Books Not Yet Returned

SELECT DISTINCT ist.issued_book_name
FROM issued_status as ist
LEFT JOIN return_status as rs ON ist.issued_id = rs.issued_id
WHERE rs.return_id IS NULL;

/*
Task 13: Identify Members with Overdue Books
Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue.
*/

SELECT issued_status.issued_member_id, members.member_name, issued_status.issued_book_name, 
       issued_status.issued_date, CURRENT_DATE - issued_status.issued_date as overdues
FROM issued_status
JOIN members ON members.member_id = issued_status.issued_member_id
LEFT JOIN return_status ON return_status.issued_id = issued_status.issued_id
WHERE return_status.return_date IS NULL
AND (CURRENT_DATE - issued_status.issued_date) > 200;

/*
Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).
*/

UPDATE books
SET status = 'yes'
WHERE isbn = '978-0-451-52994-2';

INSERT INTO return_status(return_id, issued_id, return_date)
VALUES ('RS125', 'IS130', CURRENT_DATE);

-- Store Procedures
CREATE OR REPLACE PROCEDURE add_return_records(p_return_id VARCHAR(10),p_issued_id VARCHAR(10),p_return_date DATE)
LANGUAGE plpgsql
AS $$

DECLARE
	v_isbn VARCHAR(50);
	v_book_name VARCHAR(80);
BEGIN
	-- Inserting into return_status based on user input
	INSERT INTO return_status(return_id,issued_id,return_date)
	VALUES
	(p_return_id,p_issued_id,p_return_date);
	
	SELECT 
		issued_book_isbn,
		issued_book_name
		INTO
		v_isbn,v_book_name
	FROM issued_status
	WHERE issued_id = p_issued_id;
	
	UPDATE books
	SET	status = 'yes'
	WHERE isbn = v_isbn;
	
	RAISE NOTICE 'Thank you for returning the book: %', v_book_name;

END;
$$

-- calling function 
CALL add_return_records('RS126','IS135',CURRENT_DATE)

/*
Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.
*/

SELECT
	branch.branch_id, 
	COUNT(issued_status.issued_id) as num_books_issued, 
    COUNT(return_status.return_id) as num_books_returned, 
    SUM(books.rental_price) as total_revenue
FROM issued_status
LEFT JOIN return_status ON return_status.issued_id = issued_status.issued_id
JOIN books ON books.isbn = issued_status.issued_book_isbn
JOIN employees ON employees.emp_id = issued_status.issued_emp_id
JOIN branch ON branch.branch_id = employees.branch_id
GROUP BY 1
ORDER BY 4 DESC;

/*
Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months.
*/

CREATE TABLE active_members AS
SELECT * FROM members
WHERE member_id IN (
    SELECT DISTINCT issued_member_id
    FROM issued_status
    WHERE issued_date >= CURRENT_DATE - INTERVAL '7 months'
);

SELECT * FROM active_members;

/*
Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.
*/

SELECT employees.emp_name, employees.branch_id, COUNT(*) as issued_qty
FROM issued_status
JOIN employees ON employees.emp_id = issued_status.issued_emp_id
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 3;

/*
Task 18: Stored Procedure Objective: Create a stored procedure to manage the status of books in a library system. Description: Write a stored procedure that updates the status of a book in the library based on its issuance. The procedure should function as follows: The stored procedure should take the book_id as an input parameter. The procedure should first check if the book is available (status = 'yes'). If the book is available, it should be issued, and the status in the books table should be updated to 'no'. If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.
*/

CREATE OR REPLACE PROCEDURE manage_book_status(p_issued_id VARCHAR(10), p_member_id VARCHAR(10), 
                                               p_book_isbn VARCHAR(50), p_emp_id VARCHAR(10))
LANGUAGE plpgsql AS $$
DECLARE
    v_status VARCHAR(15);
BEGIN
    -- Check if the book is available
    SELECT status INTO v_status FROM books WHERE isbn = p_book_isbn;

    IF v_status = 'yes' THEN
        INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
        VALUES (p_issued_id, p_member_id, CURRENT_DATE, p_book_isbn, p_emp_id);
        
        UPDATE books SET status = 'no' WHERE isbn = p_book_isbn;
        
        RAISE NOTICE 'Book record added successfully for isbn: %', p_book_isbn;
    ELSE
        RAISE NOTICE 'Sorry! The book is not available: %', p_book_isbn;
    END IF;
END;
$$;

CALL manage_book_status('IS777', 'C108', '978-0-7432-7357-1', 'E104');

