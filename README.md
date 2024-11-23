# Real-Time-Sales-Analytics-Platform
An end-to-end **E-Commerce Sales Analytics Platform** - Data modeling, Data pipeline, Data Analytics, ETL, Data Visualization

---

### **Step 1: Define the Project Goals**
#### Business Problem:
An e-commerce company wants to:
1. Analyze sales trends.
2. Identify top customers and products.
3. Monitor inventory levels.
4. Visualize regional sales performance.

#### Technologies:
- **Database**: PostgreSQL or MySQL.
- **ETL Tool**: Python (with Pandas and SQLAlchemy) or Apache Airflow.
- **Visualization**: Tableau, Power BI, or Matplotlib/Seaborn.
- **Cloud (Optional)**: GCP BigQuery or AWS Redshift for scalability.

---

### **Step 2: Design the Schema**
#### Schema Details (Star Schema):
1. **Fact Table**:
   - `SalesFact`: Captures transactional data.
     - Columns: `OrderID`, `CustomerID`, `ProductID`, `Quantity`, `TotalPrice`, `OrderDate`, `RegionID`
    
       ![Untitled (1)](https://github.com/user-attachments/assets/e7839c9f-4e44-4a28-ab4f-4e57948db019)


2. **Dimension Tables**:
   - `Customers`: Details of customers.
     - Columns: `CustomerID`, `Name`, `Email`, `Age`, `RegionID`
   - `Products`: Product catalog.
     - Columns: `ProductID`, `ProductName`, `Category`, `Price`, `Stock`
   - `Regions`: Geographic data.
     - Columns: `RegionID`, `RegionName`
   - `Dates`: Time dimensions for analytics.
     - Columns: `DateID`, `Date`, `Month`, `Year`, `Weekday`

---

### **Step 3: Create the Database**
#### Steps:
1. **Set Up the Database**:
   - Install PostgreSQL/MySQL.
   - Create a new database, e.g., `ecommerce_sales`.

2. **Write SQL Scripts**:
   ```sql
    -- Create Customers Table
    CREATE TABLE Customers (
        CustomerID INT IDENTITY(1,1) PRIMARY KEY,  -- Use INT IDENTITY for auto-increment
        Name NVARCHAR(100) NOT NULL,
        Email NVARCHAR(100) NOT NULL UNIQUE,
        Age INT CHECK (Age > 0),
        RegionID INT NOT NULL
    );
    
    -- Create Products Table
    CREATE TABLE Products (
        ProductID INT IDENTITY(1,1) PRIMARY KEY,  -- Use INT IDENTITY for auto-increment
        ProductName NVARCHAR(100) NOT NULL,
        Category NVARCHAR(50) NOT NULL,
        Price DECIMAL(10, 2) NOT NULL CHECK (Price > 0),
        Stock INT NOT NULL CHECK (Stock >= 0)
    );
    
    -- Create Regions Table
    CREATE TABLE Regions (
        RegionID INT IDENTITY(1,1) PRIMARY KEY,  -- Use INT IDENTITY for auto-increment
        RegionName NVARCHAR(50) NOT NULL
    );
    
    -- Create Dates Table
    CREATE TABLE Dates (
        DateID INT IDENTITY(1,1) PRIMARY KEY,  -- Use INT IDENTITY for auto-increment
        Date DATE NOT NULL UNIQUE,
        Month NVARCHAR(20) NOT NULL,
        Year INT NOT NULL,
        Weekday NVARCHAR(20) NOT NULL
    );
    
    -- Create SalesFact Table
    CREATE TABLE SalesFact (
        OrderID INT IDENTITY(1,1) PRIMARY KEY,  -- Use INT IDENTITY for auto-increment
        CustomerID INT NOT NULL,
        ProductID INT NOT NULL,
        Quantity INT NOT NULL CHECK (Quantity > 0),
        TotalPrice DECIMAL(10, 2),  -- Store the total price as a regular column
        OrderDate DATE NOT NULL,
        RegionID INT NOT NULL,
        FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
        FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
        FOREIGN KEY (RegionID) REFERENCES Regions(RegionID)
    );
    
    -- Separate the CREATE TRIGGER statement into its own batch using GO
    GO
    
    -- Create the trigger to update TotalPrice on INSERT
    CREATE TRIGGER trg_UpdateTotalPrice
    ON SalesFact
    FOR INSERT
    AS
    BEGIN
        UPDATE sf
        SET sf.TotalPrice = i.Quantity * p.Price
        FROM SalesFact sf
        INNER JOIN inserted i ON sf.OrderID = i.OrderID
        INNER JOIN Products p ON i.ProductID = p.ProductID;
    END;
    
    -- Separate the CREATE TRIGGER statement into its own batch using GO
    GO
    -- Trigger for UPDATE
    CREATE TRIGGER trg_UpdateTotalPriceUpdate
    ON SalesFact
    FOR UPDATE
    AS
    BEGIN
        UPDATE sf
        SET sf.TotalPrice = i.Quantity * p.Price
        FROM SalesFact sf
        INNER JOIN inserted i ON sf.OrderID = i.OrderID
        INNER JOIN Products p ON i.ProductID = p.ProductID
        INNER JOIN deleted d ON sf.OrderID = d.OrderID
        WHERE i.Quantity <> d.Quantity OR i.ProductID <> d.ProductID;  -- Only update if changed
    END;

   ```

3. **Populate Data**:
   - Use Python's `Faker` library for synthetic data:
     ```python
      #import all reqired libraries
      from faker import Faker
      import pandas as pd
      import random
      import pyodbc
      from datetime import datetime, timedelta
      
      # Initialize Faker
      fake = Faker()
      
      # MSSQL Connection Details
      connection = pyodbc.connect(
          "Driver={ODBC Driver 17 for SQL Server};"
          "Server=NIK-S_PREDATOR;"
          "Database=ecommerce_sales;"
          "Trusted_Connection=yes;"
      )
      cursor = connection.cursor()
      
      # Generate Data for Regions Table
      regions = ['North America', 'Europe', 'Asia', 'South America', 'Africa']
      region_data = [{"RegionName": region} for region in regions]
      for region in region_data:
          cursor.execute("INSERT INTO Regions (RegionName) VALUES (?)", region['RegionName'])
      
      # Generate Data for Products Table
      categories = ['Electronics', 'Furniture', 'Books', 'Appliances']
      products = [
          {
              "ProductName": fake.word().capitalize(),
              "Category": random.choice(categories),
              "Price": round(random.uniform(10, 1000), 2),
              "Stock": random.randint(10, 500),
          } for _ in range(50)
      ]
      for product in products:
          cursor.execute(
              "INSERT INTO Products (ProductName, Category, Price, Stock) VALUES (?, ?, ?, ?)",
              product["ProductName"], product["Category"], product["Price"], product["Stock"]
          )
      
      
      ##### ---------Optional-------------- Run only one time to populate dates, throws IntegrityError because of unique values, can be removed using sessions rollback in SQLAlchemy#####
      # # Generate Data for Dates Table
      # start_date = datetime(2023, 1, 1)
      # end_date = datetime(2023, 12, 31)
      # date_generated = [start_date + timedelta(days=x) for x in range(0, (end_date - start_date).days + 1)]
      # dates_data = [
      #     {
      #         "Date": date,
      #         "Month": date.strftime("%B"),
      #         "Year": date.year,
      #         "Weekday": date.strftime("%A")
      #     } for date in date_generated
      # ]
      # for date in dates_data:
      #     cursor.execute(
      #         "INSERT INTO Dates (Date, Month, Year, Weekday) VALUES (?, ?, ?, ?)",
      #         date["Date"], date["Month"], date["Year"], date["Weekday"]
      #     )
      
      # Generate Data for Customers Table
      customers = [
          {
              "Name": fake.name(),
              "Email": fake.email(),
              "Age": random.randint(18, 70),
              "RegionID": random.randint(1, len(regions))
          } for _ in range(100)
      ]
      for customer in customers:
          cursor.execute(
              "INSERT INTO Customers (Name, Email, Age, RegionID) VALUES (?, ?, ?, ?)",
              customer["Name"], customer["Email"], customer["Age"], customer["RegionID"]
          )
      
      # Generate Data for SalesFact Table
      sales = []
      for _ in range(500):
          customer_id = random.randint(1, 100)
          product_id = random.randint(1, 50)
          quantity = random.randint(1, 10)
          date = random.choice(date_generated)
          region_id = random.randint(1, len(regions))
          sales.append({
              "CustomerID": customer_id,
              "ProductID": product_id,
              "Quantity": quantity,
              "OrderDate": date,
              "RegionID": region_id
          })
      
      for sale in sales:
          cursor.execute(
              "INSERT INTO SalesFact (CustomerID, ProductID, Quantity, OrderDate, RegionID) VALUES (?, ?, ?, ?, ?)",
              sale["CustomerID"], sale["ProductID"], sale["Quantity"], sale["OrderDate"], sale["RegionID"]
          )
      
      # Commit and Close
      connection.commit()
      cursor.close()
      connection.close()
      
      print("Data insertion completed!")

     ```
   - Load this data into the database using Python (e.g., SQLAlchemy).

---

### **Step 4: Build the ETL Pipeline**
#### Tools: Python, SQLAlchemy, Pandas.

1. **Extract**:
   - Simulate data sources as CSV/JSON files.

2. **Transform**:
   - Clean data with Pandas.
   - Add derived columns (e.g., `TotalPrice = Quantity * Price`).

3. **Load**:
   - Insert data into the database using SQLAlchemy:
     ```python
     from sqlalchemy import create_engine
     import pandas as pd

     engine = create_engine("postgresql://user:password@localhost:5432/ecommerce_sales")
     customers_df = pd.read_csv("customers.csv")
     customers_df.to_sql("Customers", engine, if_exists="append", index=False)
     ```

4. **Schedule with Airflow (Optional)**:
   - Create DAGs to automate daily data ingestion.

---

### **Step 5: Query the Data**
Write SQL queries to generate insights:
1. **Top-Selling Products**:
   ```sql
   SELECT ProductName, SUM(Quantity) AS TotalSold
   FROM SalesFact
   JOIN Products ON SalesFact.ProductID = Products.ProductID
   GROUP BY ProductName
   ORDER BY TotalSold DESC;
   ```

2. **Monthly Revenue**:
   ```sql
   SELECT Year, Month, SUM(TotalPrice) AS MonthlyRevenue
   FROM SalesFact
   JOIN Dates ON SalesFact.OrderDate = Dates.Date
   GROUP BY Year, Month
   ORDER BY Year, Month;
   ```

---

### **Step 6: Visualize the Data**
#### Dashboards:
1. **Tools**:
   - Use Tableau/Power BI for professional dashboards.
   - Use Matplotlib/Seaborn for code-based visuals.

2. **Key Charts**:
   - **Sales Over Time**: Line chart showing revenue trends.
   - **Top Customers**: Bar chart of customers by revenue.
   - **Inventory Levels**: Stacked bar chart showing stock per product category.

---

### **Step 7: Advanced Enhancements**
1. **Partitioning**:
   - Partition `SalesFact` by `OrderDate` for performance.
2. **Indexing**:
   - Index foreign keys like `CustomerID`, `ProductID`.
3. **Cloud Setup**:
   - Upload to Snowflake/BigQuery for scalability.

---
