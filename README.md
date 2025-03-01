# Hive Data Analysis - Employees & Departments

## **Project Overview**
This project involves analyzing employee and department data using Apache Hive. The goal is to efficiently store, query, and extract insights from the datasets by leveraging Hive’s partitioning and querying capabilities. Additionally, we will export results for further analysis.

---

## **Datasets Used**

### **1. Employees Dataset (employees.csv)**
This dataset contains employee-related information such as job role, salary, department, and project assignment.

| Column Name | Description |
|-------------|-------------|
| emp_id | Unique identifier for the employee |
| name | Full name of the employee |
| age | Age of the employee |
| job_role | Designation/job title of the employee |
| salary | Annual salary of the employee |
| project | Assigned project (Alpha, Beta, Gamma, Delta, Omega) |
| join_date | Employee's joining date |
| department | The department the employee belongs to (used for partitioning) |

### **2. Departments Dataset (departments.csv)**
This dataset provides information on company departments.

| Column Name | Description |
|-------------|-------------|
| dept_id | Unique identifier for the department |
| department_name | Name of the department |
| location | Location of the department |

---

## **Steps to Load Data into Hive**

### **Step 1: Upload CSV Files to HDFS**
```sh
hdfs dfs -mkdir -p /user/hive/warehouse/data
hdfs dfs -put employees.csv /user/hive/warehouse/data/
hdfs dfs -put departments.csv /user/hive/warehouse/data/
```

### **Step 2: Create Hive Tables**
#### **Creating a Temporary Table for Employees**
```sql
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
```
#### **Load Data into Temporary Table**
```sql
LOAD DATA INPATH '/user/hive/warehouse/data/employees.csv' INTO TABLE employees_temp;
```

#### **Create a Partitioned Table for Employees**
```sql
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
```
#### **Insert Data into Partitioned Table**
```sql
SET hive.exec.dynamic.partition = true;
SET hive.exec.dynamic.partition.mode = nonstrict;

INSERT INTO TABLE employees PARTITION (department)
SELECT emp_id, name, age, job_role, salary, project, join_date, department FROM employees_temp;
```

#### **Create the Departments Table**
```sql
CREATE TABLE departments (
    dept_id INT,
    department_name STRING,
    location STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;
```
#### **Load Data into Departments Table**
```sql
LOAD DATA INPATH '/user/hive/warehouse/data/departments.csv' INTO TABLE departments;
```

---

## **Hive Queries and Sample Outputs**

### **1. List Employees Who Joined After 2015**
```sql
SELECT * FROM employees WHERE year(TO_DATE(join_date, 'yyyy-MM-dd')) > 2015;
```
**Sample Output:**
| emp_id | name | age | job_role | salary | project | join_date | department |
|--------|------|-----|----------|--------|---------|-----------|------------|
| 201 | John | 28 | Developer | 80000 | Alpha | 2017-05-12 | IT |

---

### **2. Compute Average Salary by Department**
```sql
SELECT department, AVG(salary) AS avg_salary FROM employees GROUP BY department;
```
**Sample Output:**
| department | avg_salary |
|------------|------------|
| Finance | 90000 |
| Sales | 65000 |

---

### **3. Employees Assigned to 'Alpha' Project**
```sql
SELECT * FROM employees WHERE project = 'Alpha';
```

---

### **4. Employee Count by Job Role**
```sql
SELECT job_role, COUNT(*) AS employee_count FROM employees GROUP BY job_role;
```

---

### **5. Employees with Salary Above Department Average**
```sql
SELECT e.* FROM employees e
JOIN (
    SELECT department, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department
) dept_avg
ON e.department = dept_avg.department
WHERE e.salary > dept_avg.avg_salary;
```

---

### **6. Department with Maximum Employees**
```sql
SELECT department, COUNT(*) AS employee_count
FROM employees
GROUP BY department
ORDER BY employee_count DESC
LIMIT 1;
```

---

### **7. Exclude Employees with Missing Data**
```sql
SELECT * FROM employees
WHERE emp_id IS NOT NULL
AND name IS NOT NULL
AND age IS NOT NULL
AND job_role IS NOT NULL
AND salary IS NOT NULL
AND project IS NOT NULL
AND join_date IS NOT NULL
AND department IS NOT NULL;
```

---

### **8. Join Employees with Departments for Location Info**
```sql
SELECT e.*, d.location
FROM employees e
JOIN departments d
ON e.department = d.department_name;
```

---

### **9. Rank Employees by Salary in Each Department**
```sql
SELECT emp_id, name, department, salary,
       RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS salary_rank
FROM employees;
```

---

### **10. Retrieve Top 3 Highest Paid Employees Per Department**
```sql
SELECT emp_id, name, department, salary, salary_rank
FROM (
    SELECT emp_id, name, department, salary,
           RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS salary_rank
    FROM employees
) ranked
WHERE salary_rank <= 3;
```

---

## **Exporting Query Results in Hue**
### **Manual Export**
1. Run a query in Hue.
2. Click on the **Export** button in the results.
3. Choose **CSV, Excel, or JSON** and download the file.

### **Automated Export to HDFS**
```sql
INSERT OVERWRITE DIRECTORY '/user/hive/output/avg_salary'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
SELECT department, AVG(salary) FROM employees GROUP BY department;
```
To view the output:
```sh
hdfs dfs -cat /user/hive/output/avg_salary/*
```

---

## **Conclusion**
This project effectively utilizes Apache Hive for large-scale employee and department data analysis. By partitioning data and exporting query results, we enhance efficiency and ensure valuable insights.

---

**Prepared by:** Likitha Sri Kode

