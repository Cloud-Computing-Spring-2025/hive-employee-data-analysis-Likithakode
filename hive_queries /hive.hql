-- Step 1: Create a temporary table for employees
CREATE TABLE employees_temp (
    emp_id INT,
    name STRING,
    age INT,
    job_role STRING,
    salary DOUBLE,
    project STRING,
    join_date STRING,
    department STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

-- Step 2: Load data into the temporary table
LOAD DATA INPATH 'path_to/employees.csv' INTO TABLE employees_temp;

-- Step 3: Create a partitioned table for employees
CREATE TABLE employees (
    emp_id INT,
    name STRING,
    age INT,
    job_role STRING,
    salary DOUBLE,
    project STRING,
    join_date STRING
)
PARTITIONED BY (department STRING)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS PARQUET;

-- Step 4: Insert data into the partitioned table
SET hive.exec.dynamic.partition = true;
SET hive.exec.dynamic.partition.mode = nonstrict;

INSERT INTO TABLE employees PARTITION (department)
SELECT emp_id, name, age, job_role, salary, project, join_date, department FROM employees_temp;

-- Step 5: Create table for departments
CREATE TABLE departments (
    dept_id INT,
    department_name STRING,
    location STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

-- Step 6: Load data into departments table
LOAD DATA INPATH 'path_to/departments.csv' INTO TABLE departments;

-- Query 1: Retrieve all employees who joined after 2015
SELECT * FROM employees WHERE year(TO_DATE(join_date, 'yyyy-MM-dd')) > 2015;

-- Query 2: Find the average salary of employees in each department
SELECT department, AVG(salary) AS avg_salary FROM employees GROUP BY department;

-- Query 3: Identify employees working on the 'Alpha' project
SELECT * FROM employees WHERE project = 'Alpha';

-- Query 4: Count the number of employees in each job role
SELECT job_role, COUNT(*) AS employee_count FROM employees GROUP BY job_role;

-- Query 5: Retrieve employees whose salary is above the average salary of their department
SELECT e.* 
FROM employees e
JOIN (
    SELECT department, AVG(salary) AS avg_salary 
    FROM employees 
    GROUP BY department
) dept_avg
ON e.department = dept_avg.department
WHERE e.salary > dept_avg.avg_salary;

-- Query 6: Find the department with the highest number of employees
SELECT department, COUNT(*) AS employee_count 
FROM employees 
GROUP BY department 
ORDER BY employee_count DESC 
LIMIT 1;

-- Query 7: Check for employees with null values in any column and exclude them from analysis
SELECT * FROM employees 
WHERE emp_id IS NOT NULL 
AND name IS NOT NULL 
AND age IS NOT NULL 
AND job_role IS NOT NULL 
AND salary IS NOT NULL 
AND project IS NOT NULL 
AND join_date IS NOT NULL 
AND department IS NOT NULL;

-- Query 8: Join employees and departments tables to display employee details along with department locations
SELECT e.*, d.location 
FROM employees e 
JOIN departments d 
ON e.department = d.department_name;

-- Query 9: Rank employees within each department based on salary
SELECT emp_id, name, department, salary, 
       RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS salary_rank
FROM employees;

-- Query 10: Find the top 3 highest-paid employees in each department
SELECT emp_id, name, department, salary, salary_rank 
FROM (
    SELECT emp_id, name, department, salary,
           RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS salary_rank
    FROM employees
) ranked
WHERE salary_rank <= 3;
