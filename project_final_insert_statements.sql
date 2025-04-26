--------------------------------------------------------------------------------------------------------


--select * from Customers
DECLARE @count INT = 1000;  -- Number of customers to insert
DECLARE @num INT = 1;

WHILE @num <= @count
BEGIN
    DECLARE @FullName NVARCHAR(100) = 'Customer ' + CAST(@num AS NVARCHAR(10));
    DECLARE @DOB DATE = DATEADD(YEAR, -ABS(CHECKSUM(NEWID())) % 62 - 18, GETDATE());
    DECLARE @Email NVARCHAR(100) = 'customer' + CAST(@num AS NVARCHAR(10)) + '@example.com';
    DECLARE @PhoneNumber NVARCHAR(15);
    DECLARE @NationalID NVARCHAR(20);
    DECLARE @TaxID NVARCHAR(20);

    -- Generate unique phone number
    WHILE 1 = 1
    BEGIN
        SET @PhoneNumber = '123-456-' + RIGHT('0000' + CAST(ABS(CHECKSUM(NEWID())) % 10000 AS NVARCHAR(10)), 4);
        
        IF NOT EXISTS (SELECT 1 FROM Customers WHERE PhoneNumber = @PhoneNumber)
            BREAK;  -- Exit loop if unique
    END

    -- Generate unique NationalID
    WHILE 1 = 1
    BEGIN
        SET @NationalID = 'NAT' + CAST(@num AS NVARCHAR(10)) + CAST(ABS(CHECKSUM(NEWID())) % 100000 AS NVARCHAR(10));
        
        IF NOT EXISTS (SELECT 1 FROM Customers WHERE NationalID = @NationalID)
            BREAK;
    END

    -- Generate unique TaxID
    WHILE 1 = 1
    BEGIN
        SET @TaxID = 'TAX' + CAST(@num AS NVARCHAR(10)) + CAST(ABS(CHECKSUM(NEWID())) % 10000 AS NVARCHAR(10));
        
        IF NOT EXISTS (SELECT 1 FROM Customers WHERE TaxID = @TaxID)
            BREAK;
    END

    -- Insert the unique customer record
    INSERT INTO Customers (FullName, DOB, Email, PhoneNumber, Address, NationalID, TaxID, EmploymentStatus, AnnualIncome, CreatedAt, UpdatedAt, IsActive)
    VALUES (
        @FullName, 
        @DOB, 
        @Email, 
        @PhoneNumber, 
        'Address ' + CAST(@num AS NVARCHAR(10)), 
        @NationalID, 
        @TaxID, 
        CASE WHEN @num % 3 = 0 THEN 'Employed' 
             WHEN @num % 3 = 1 THEN 'Self-Employed' 
             ELSE 'Unemployed' 
        END,
        CAST(ABS(CHECKSUM(NEWID())) % 100000 + 30000 AS DECIMAL(15,2)), 
        GETDATE(),
        GETDATE(),
        1
    );

    SET @num = @num + 1;
END;


-------------------------------------------------------------------------------------------------------------------------------
--select * from Branches
-- Insert Branches
SET IDENTITY_INSERT Branches ON;

WITH Numbers AS (
    SELECT TOP 50 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS number
    FROM sys.all_objects
)
INSERT INTO Branches (BranchID, BranchName, Address, City, State, Country, ManagerID, ContactNumber, IsActive)
SELECT 
    number AS BranchID,  
    'Branch ' + CAST(number AS NVARCHAR(10)), 
    'Address ' + CAST(number AS NVARCHAR(10)), 
    'City ' + CAST(number AS NVARCHAR(10)), 
    'State ' + CAST(number AS NVARCHAR(10)), 
    'Country ' + CAST(number AS NVARCHAR(10)), 
    ABS(CHECKSUM(NEWID())) % 50 + 1,  -- Random ManagerID (1-50)
    '123456' + RIGHT('0000' + CAST(number AS NVARCHAR(10)), 4), 
    1 
FROM Numbers
WHERE NOT EXISTS (SELECT 1 FROM Branches WHERE BranchID = Numbers.number);  -- Prevent duplicates

SET IDENTITY_INSERT Branches OFF;


--------------------------------------------------------------------------------------------------------------------------------
-- Insert Employees
-- Insert Employees without manually inserting BranchID
INSERT INTO Employees (FullName, BranchID, Position, Department, Salary, HireDate, Status)
SELECT 
    'Employee ' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS NVARCHAR(10)) AS FullName,
    b.BranchID, -- Ensure BranchID is auto-generated in Branches table
    CASE 
        WHEN ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 3 = 0 THEN 'Teller'
        WHEN ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 3 = 1 THEN 'Manager'
        ELSE 'Loan Officer' 
    END AS Position,
    'Banking' AS Department, 
    ABS(CHECKSUM(NEWID())) % 30000 + 30000 AS Salary, 
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 3650, GETDATE()) AS HireDate, 
    CASE 
        WHEN ABS(CHECKSUM(NEWID())) % 10 = 0 THEN 'Inactive' 
        ELSE 'Active' 
    END AS Status
FROM Branches b;

--------------------------------------------------------------------------------------------------------------------------------

INSERT INTO Departments (DepartmentName, ManagerID)
VALUES 
    ('HR', 101),
    ('Finance', 102),
    ('IT', 103),
    ('Marketing', 104),
    ('Sales', 105),
    ('Operations', 106),
    ('Logistics', 107),
    ('Customer Support', 108),
    ('Legal', 109),
    ('R&D', 110),
    ('Procurement', 111),
    ('Quality Assurance', 112),
    ('Security', 113),
    ('Administration', 114),
    ('Training & Development', 115),
    ('Public Relations', 116),
    ('Business Intelligence', 117),
    ('Data Analytics', 118),
    ('Cybersecurity', 119),
    ('Product Management', 120);

	---------------------------------------------------------------------------------------------------------------------------------

	-- Insert Accounts
INSERT INTO Accounts (CustomerID, BranchID, AccountType, Balance, Currency, Status, CreatedDate)
SELECT 
    c.CustomerID,
    (SELECT TOP 1 BranchID FROM Branches ORDER BY NEWID()), -- Ensuring existing BranchID
    CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'Savings' ELSE 'Checking' END,
    CAST(ABS(CHECKSUM(NEWID())) % 50000 + 1000 AS DECIMAL(15,2)), -- Random balance
    CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'USD' ELSE 'EUR' END, -- Random currency
    --  Use only 'Active' or 'Closed' for Status
    CASE 
        WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'Active' 
        ELSE 'Closed' 
    END,
    GETDATE()
FROM Customers c
WHERE c.CustomerID BETWEEN (SELECT MIN(CustomerID) FROM Customers) 
                        AND (SELECT MAX(CustomerID) FROM Customers);

-----------------------------------------------------------------------------------------------------------

-- Insert CreditCards
INSERT INTO CreditCards (CustomerID, CardNumber, CardType, CVV, ExpiryDate, Limit, Status)
SELECT 
    c.CustomerID,
    '4000' + RIGHT(CAST(ABS(CHECKSUM(NEWID())) % 1000000000000 AS BIGINT), 12) AS CardNumber, -- Unique 12-digit suffix
    CASE 
        WHEN ABS(CHECKSUM(NEWID())) % 3 = 0 THEN 'Visa'
        WHEN ABS(CHECKSUM(NEWID())) % 3 = 1 THEN 'MasterCard'
        ELSE 'Amex' 
    END AS CardType, 
    RIGHT('000' + CAST(ABS(CHECKSUM(NEWID())) % 1000 AS NVARCHAR(3)), 3) AS CVV, 
    DATEADD(YEAR, 3, GETDATE()) AS ExpiryDate, 
    ABS(CHECKSUM(NEWID())) % 20000 + 5000 AS Limit, 
    'Active' AS Status
FROM Customers c
WHERE c.CustomerID BETWEEN (SELECT MIN(CustomerID) FROM Customers) 
                        AND (SELECT MAX(CustomerID) FROM Customers)
AND NOT EXISTS (SELECT 1 FROM CreditCards cc WHERE cc.CustomerID = c.CustomerID);

--------------------------------------------------------------------------------------------------------------------------------------

--select * from OnlineBankingUsers
-- 8. OnlineBankingUsers Table (1,000 rows)
INSERT INTO OnlineBankingUsers (CustomerID, Username, PasswordHash, LastLogin, IsActive)
SELECT 
    c.CustomerID, 
    'user' + CAST(c.CustomerID AS NVARCHAR(10)) + '_' + CAST(ABS(CHECKSUM(NEWID())) % 10000 AS NVARCHAR(10)),  -- Ensure uniqueness
    'hash' + CAST(c.CustomerID AS NVARCHAR(10)), 
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, GETDATE()), 
    1
FROM Customers c
LEFT JOIN OnlineBankingUsers o ON c.CustomerID = o.CustomerID
WHERE o.CustomerID IS NULL;  -- Only insert if the customer does not already exist

------------------------------------------------------------------------------------------------------------------------------------------

-- Insert KYC
WITH NumberedCustomers AS (
    SELECT 
        c.CustomerID, 
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum
    FROM Customers c
    LEFT JOIN KYC k ON c.CustomerID = k.CustomerID
    WHERE k.CustomerID IS NULL  -- Avoid inserting duplicates
)
INSERT INTO KYC (CustomerID, DocumentType, DocumentNumber, VerifiedBy)
SELECT 
    CustomerID,
    CASE 
        WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'Passport' 
        ELSE 'Driver License' 
    END AS DocumentType,
    'DOC-' + CAST(NEWID() AS VARCHAR(36)), -- Completely unique document number using GUID
    'Verifier_' + CAST(ABS(CHECKSUM(NEWID())) % 5 + 1 AS VARCHAR)
FROM NumberedCustomers;

--------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO Investments (CustomerID, InvestmentType, Amount, ROI, MaturityDate)
SELECT 
    c.CustomerID,  -- Ensure valid CustomerID from Customers table
    CASE ABS(CHECKSUM(NEWID())) % 6 
        WHEN 0 THEN 'Stocks'
        WHEN 1 THEN 'Bonds'
        WHEN 2 THEN 'Mutual Funds'
        WHEN 3 THEN 'Real Estate'
        WHEN 4 THEN 'Crypto'
        ELSE 'Fixed Deposit'
    END, 
    ABS(CHECKSUM(NEWID())) % 50000 + 1000, -- Random Amount between 1,000 - 50,000
    CAST(ABS(CHECKSUM(NEWID())) % 15 + 1 AS DECIMAL(5,2)), -- Random ROI between 1% - 15%
    DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 365 * 5, GETDATE()) -- Random MaturityDate up to 5 years
FROM Customers c
ORDER BY NEWID() -- Shuffle customers to randomize selection
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY; -- Insert only 50 records

----------------------------------------------------------------------------------------------------------------------------------

INSERT INTO StockTradingAccounts (CustomerID, BrokerageFirm, TotalInvested, CurrentValue)
SELECT 
    c.CustomerID,  -- Ensure valid CustomerID from the Customers table
    CASE ABS(CHECKSUM(NEWID())) % 6 
        WHEN 0 THEN 'Morgan Stanley'
        WHEN 1 THEN 'Goldman Sachs'
        WHEN 2 THEN 'Charles Schwab'
        WHEN 3 THEN 'Fidelity'
        WHEN 4 THEN 'Robinhood'
        ELSE 'E-Trade'
    END, -- Random Brokerage Firm
    ABS(CHECKSUM(NEWID())) % 50000 + 500, -- Random TotalInvested (between 500 - 50,000)
    ABS(CHECKSUM(NEWID())) % 60000 + 500 -- Random CurrentValue (between 500 - 60,000)
FROM Customers c
ORDER BY NEWID()  -- Randomize selection
OFFSET 0 ROWS FETCH NEXT 250 ROWS ONLY;  -- Insert 250 records

------------------------------------------------------------------------------------------------------------------------------------------

-- Insert ForeignExchange
-- Insert ForeignExchange
-- Insert ForeignExchange
INSERT INTO ForeignExchange (CustomerID, CurrencyPair, ExchangeRate, AmountExchanged)
SELECT TOP 100  -- Insert 100 rows
    c.CustomerID,  -- Ensure valid CustomerID from Customers table
    CASE 
        WHEN ABS(CHECKSUM(NEWID())) % 3 = 0 THEN 'USD/EUR' 
        WHEN ABS(CHECKSUM(NEWID())) % 3 = 1 THEN 'USD/GBP' 
        ELSE 'USD/JPY' 
    END, -- Random Currency Pair
    ROUND(RAND() * (1.5 - 0.5) + 0.5, 4), -- Random Exchange Rate between 0.5 and 1.5
    ABS(CHECKSUM(NEWID())) % 10000 + 50 -- Random Amount Exchanged (between 50 - 10,000)
FROM Customers c
ORDER BY NEWID(); -- Ensures random selection

------------------------------------------------------------------------------------------------------------------------------------

--delete from InsurancePolicies
-- Insert InsurancePolicies
INSERT INTO InsurancePolicies (CustomerID, InsuranceType, PremiumAmount, CoverageAmount)
SELECT 
    c.CustomerID,
    CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'Health' ELSE 'Auto' END AS InsuranceType, 
    ABS(CHECKSUM(NEWID())) % 1000 + 200 AS PremiumAmount, -- Random Premium Amount (200 - 1200)
    ABS(CHECKSUM(NEWID())) % 50000 + 10000 AS CoverageAmount -- Random Coverage Amount (10,000 - 60,000)
FROM Customers c;

-------------------------------------------------------------------------------------------------------------------------------------

WITH Numbers AS (
    SELECT TOP 500 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Num
    FROM sys.all_objects -- Generates a sequence of numbers
)
INSERT INTO Merchants (MerchantName, Industry, Location, CustomerID, IsActive)
SELECT 
    'Merchant ' + CAST(Num AS NVARCHAR(10)),
    CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'Retail' ELSE 'Food & Beverage' END AS Industry,
    'City ' + CAST(Num AS NVARCHAR(10)),
    c.CustomerID,  -- Ensure valid CustomerID exists in Customers table
    CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 1 ELSE 0 END AS IsActive  -- Randomly Active (1) or Inactive (0)
FROM Numbers n
JOIN Customers c ON c.CustomerID = 12199 + n.Num
WHERE c.CustomerID BETWEEN 12199 AND 12698;  -- Inserting only for customers within the range 12199-12698

-------------------------------------------------------------------------------------------------------------------------------------

-- Insert Loans
INSERT INTO Loans (CustomerID, LoanType, Amount, InterestRate, StartDate, EndDate, Status)
SELECT 
    c.CustomerID,
    CASE 
        WHEN ABS(CHECKSUM(NEWID())) % 4 = 0 THEN 'Business' 
        WHEN ABS(CHECKSUM(NEWID())) % 4 = 1 THEN 'Auto' 
        WHEN ABS(CHECKSUM(NEWID())) % 4 = 2 THEN 'Personal' 
        ELSE 'Mortgage' 
    END AS LoanType,
    ABS(CHECKSUM(NEWID())) % 50000 + 5000, -- Amount (Fixed LoanAmount issue)
    ABS(CHECKSUM(NEWID())) % 10 + 3,      -- InterestRate
    GETDATE(),                            -- StartDate
    DATEADD(MONTH, ABS(CHECKSUM(NEWID())) % 60 + 12, GETDATE()), -- EndDate
    'Active'  -- Status (Added default value)
FROM Customers c
WHERE c.CustomerID BETWEEN 12199 AND 12698;  -- Adjusted range to match your CustomerID range

----------------------------------------------------------------------------------------------------------------------------------------

-- Insert DebtCollection
INSERT INTO DebtCollection (CustomerID, AmountDue, DueDate, CollectorAssigned)
SELECT 
    c.CustomerID,
    ABS(CHECKSUM(NEWID())) % 10000 + 1000,  -- Random debt amount
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, GETDATE()),  -- Random due date within the past year
    'Agent_' + CAST(ABS(CHECKSUM(NEWID())) % 10 + 1 AS VARCHAR)  -- Random collector assignment
FROM Customers c
WHERE c.CustomerID BETWEEN 12199 AND 12698;  -- Adjusted range to match your CustomerID range

-----------------------------------------------------------------------------------------------------------------------------------------

-- 13. CreditScores Table (1,000 rows)
WITH Numbers AS (
    SELECT TOP (500) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Num
    FROM master.dbo.spt_values
)
INSERT INTO CreditScores (CustomerID, CreditScore, UpdatedAt)
SELECT 
    12198 + Num AS CustomerID,  -- Adjusted to start at 12199
    ABS(CHECKSUM(NEWID())) % 550 + 300 AS CreditScore, 
    GETDATE() AS UpdatedAt
FROM Numbers
WHERE NOT EXISTS (SELECT 1 FROM CreditScores WHERE CreditScores.CustomerID = 12198 + Numbers.Num); -- Ensure unique CustomerID


----------------------------------------------------------------------------------------------------------------------------------

--select * from Transactions

INSERT INTO Transactions (AccountID, Amount, TransactionType, Date, Currency, Status, ReferenceNo)
SELECT 
    a.AccountID,
    ABS(CHECKSUM(NEWID())) % 5000 + 10, -- Random transaction amount
    CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'Deposit' ELSE 'Withdrawal' END, -- Transaction type
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, GETDATE()), -- Random past date
    'USD', -- Default currency (Change if needed)
    'Completed', -- Default status (Adjust based on logic)
    'TXN' + CAST(ABS(CHECKSUM(NEWID())) % 1000000 AS NVARCHAR(10)) -- Random ReferenceNo
FROM Accounts a
WHERE a.AccountID BETWEEN 1 AND 5000;

----------------------------------------------------------------------------------------------------------------------------------

-- Insert CreditCardTransactions
INSERT INTO CreditCardTransactions (CardID, Merchant, Amount, Currency, Date, Status)
SELECT TOP (1000)
    cc.CardID,  
    'Merchant ' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS NVARCHAR(10)), 
    ABS(CHECKSUM(NEWID())) % 5000 + 10, -- Random transaction amount
    'USD', 
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, GETDATE()), -- Random past date
    CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'Completed' ELSE 'Pending' END -- Random status
FROM CreditCards cc
JOIN master.dbo.spt_values ON type = 'P' AND number BETWEEN 1 AND 1000;

----------------------------------------------------------------------------------------------------------------------------------

--select * from BillPayments
-- Insert BillPayments
INSERT INTO BillPayments (CustomerID, BillerName, Amount, Date, Status)
SELECT 
    c.CustomerID, 
    'Utility Company ' + CAST(ABS(CHECKSUM(NEWID())) % 10 AS NVARCHAR(2)), -- Random Biller
    ABS(CHECKSUM(NEWID())) % 1000 + 50, -- Random amount
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, GETDATE()), -- Random date in the past year
    'Completed'  -- Default status
FROM Customers c
WHERE c.CustomerID BETWEEN 12199 AND 12698;  -- Adjusted range to match your CustomerID

----------------------------------------------------------------------------------------------------------------------------------

--select * from MobileBankingTransactions
-- Insert MobileBankingTransactions


INSERT INTO MobileBankingTransactions 
    (CustomerID, DeviceID, AppVersion, TransactionType, Amount, Date)
SELECT 
    c.CustomerID, 
    'Device-' + CAST(ABS(CHECKSUM(NEWID())) % 1000 AS NVARCHAR(10)), -- Random Device ID
    'v' + CAST(ABS(CHECKSUM(NEWID())) % 10 + 1 AS NVARCHAR(2)), -- Random App Version
    CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'Transfer' ELSE 'Bill Payment' END, -- Random Transaction Type
    ABS(CHECKSUM(NEWID())) % 1000 + 20, -- Random Amount
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, GETDATE()) -- Random Date
  
FROM Customers c
WHERE c.CustomerID BETWEEN 12199 AND 12698;

----------------------------------------------------------------------------------------------------------------------------------

--select * from LoanPayments
-- Insert LoanPayments
INSERT INTO LoanPayments (LoanID, AmountPaid, PaymentDate, RemainingBalance)
SELECT 
    LoanID, 
    ABS(CHECKSUM(NEWID())) % 2000 + 100, 
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 30, GETDATE()),
    (ABS(CHECKSUM(NEWID())) % 50000)  -- Generating RemainingBalance randomly
FROM Loans;

----------------------------------------------------------------------------------------------------------------------------------

INSERT INTO Salaries (EmployeeID, BaseSalary, Bonus, Deductions, PaymentDate)
SELECT 
    e.EmployeeID,
    e.Salary AS BaseSalary, -- Using Salary from Employees as BaseSalary
    (e.Salary * (ABS(CHECKSUM(NEWID())) % 20) / 100.0) AS Bonus, -- Bonus up to 20% of BaseSalary
    (e.Salary * (ABS(CHECKSUM(NEWID())) % 10) / 100.0) AS Deductions, -- Deductions up to 10% of BaseSalary
    DATEADD(MONTH, -ABS(CHECKSUM(NEWID())) % 12, GETDATE()) AS PaymentDate -- Random payment date within last year
FROM Employees e;

----------------------------------------------------------------------------------------------------------------------------------

-- Insert EmployeeAttendance
INSERT INTO EmployeeAttendance (EmployeeID, CheckInTime, CheckOutTime)
SELECT 
    EmployeeID, 
    CAST(DATEADD(MINUTE, ABS(CHECKSUM(NEWID())) % 480, '08:00:00') AS TIME), -- Random check-in between 8:00 AM - 4:00 PM
    CAST(DATEADD(MINUTE, ABS(CHECKSUM(NEWID())) % 120 + 480, '08:00:00') AS TIME) -- Check-out time (8-10 hours later)
FROM Employees;

----------------------------------------------------------------------------------------------------------------------------------

-- Insert FraudDetection
INSERT INTO FraudDetection (CustomerID, TransactionID, RiskLevel, ReportedDate)
SELECT 
    c.CustomerID,
    ABS(CHECKSUM(NEWID())) % 5000 + 1,  -- Random TransactionID
    CASE 
        WHEN ABS(CHECKSUM(NEWID())) % 3 = 0 THEN 'Low' 
        WHEN ABS(CHECKSUM(NEWID())) % 3 = 1 THEN 'Medium' 
        ELSE 'High' 
    END, -- Random RiskLevel
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, GETDATE())  -- ReportedDate within the last year
FROM Customers c
WHERE c.CustomerID BETWEEN 12199 AND 12698;

----------------------------------------------------------------------------------------------------------------------------------

-- Insert AMLCases
INSERT INTO AMLCases (CustomerID, CaseType, Status, InvestigatorID)
SELECT 
    c.CustomerID,
    CASE 
        WHEN ABS(CHECKSUM(NEWID())) % 3 = 0 THEN 'Fraud' 
        WHEN ABS(CHECKSUM(NEWID())) % 3 = 1 THEN 'Money Laundering' 
        ELSE 'Terrorist Financing' 
    END,  -- Random CaseType
    CASE 
        WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'Under Investigation' 
        ELSE 'Closed' 
    END,  -- Random Status
    ABS(CHECKSUM(NEWID())) % 50 + 1  -- Random InvestigatorID (assuming 50 investigators)
FROM Customers c
WHERE c.CustomerID BETWEEN 12199 AND 12250;

----------------------------------------------------------------------------------------------------------------------------------

--select * from RegulatoryReports
-- Insert RegulatoryReports
SET IDENTITY_INSERT RegulatoryReports ON;

INSERT INTO RegulatoryReports (ReportID, ReportType, SubmissionDate)
SELECT 
    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + (SELECT ISNULL(MAX(ReportID), 0) FROM RegulatoryReports) AS ReportID, 
    CASE 
        WHEN ABS(CHECKSUM(NEWID())) % 3 = 0 THEN 'Quarterly' 
        ELSE 'Annual' 
    END,  -- Random ReportType
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, GETDATE()) -- Random past SubmissionDate
FROM master.dbo.spt_values
WHERE type = 'p' AND number BETWEEN 1 AND 20;

SET IDENTITY_INSERT RegulatoryReports OFF;

----------------------------------------------------------------------------------------------------------------------------------

-- Insert Claims
INSERT INTO Claims (PolicyID, ClaimAmount, Status, FiledDate)
SELECT 
    p.PolicyID,
    ABS(CHECKSUM(NEWID())) % 5000 + 500 AS ClaimAmount, -- Random Claim Amount (500 - 5500)
    CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'Approved' ELSE 'Pending' END AS Status, 
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 180, GETDATE()) AS FiledDate -- Random past 180 days
FROM Customers c
JOIN InsurancePolicies p ON p.CustomerID = c.CustomerID
WHERE c.CustomerID BETWEEN 12199 AND 12399;


----------------------------------------------------------------------------------------------------------------------------------

--select * from UserAccessLogs
-- Insert UserAccessLogs

INSERT INTO UserAccessLogs (UserID, ActionType, Timestamp)
SELECT
    UserID AS UserID, -- Use the correct column name from OnLineBankIngUsers
    CASE 
        WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'Login'
        ELSE 'Logout'
    END AS ActionType, -- Randomly assign 'Login' or 'Logout'
    DATEADD(HOUR, -ABS(CHECKSUM(NEWID())) % 24, GETDATE()) AS Timestamp
FROM OnLineBankIngUsers u;
select * from OnLineBankIngUsers

----------------------------------------------------------------------------------------------------------------------------------

-- Insert CyberSecurityIncidents
INSERT INTO CyberSecurityIncidents (AffectedSystem, ReportedDate, ResolutionStatus)
SELECT
    CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'Phishing' ELSE 'Data Breach' END AS AffectedSystem,
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, GETDATE()) AS ReportedDate,
    CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'Resolved' ELSE 'Investigating' END AS ResolutionStatus
FROM OnlineBankingUsers u
WHERE u.UserID BETWEEN 7002 AND 7052;  -- Adjusted for UserID range

----------------------------------------------------------------------------------------------------------------------------------

-- Insert MerchantTransactions  
INSERT INTO MerchantTransactions (MerchantID, TransactionAmount, TransactionDate, IsActive)
SELECT TOP (1000)
    m.MerchantID,  
    ABS(CHECKSUM(NEWID())) % 200 + 10,  -- Random transaction amount between 10 and 210  
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 30, GETDATE()),  -- Random transaction date in the last 30 days  
    1  -- Assuming all transactions are active  
FROM Merchants m  
JOIN Customers c ON c.CustomerID BETWEEN 12199 AND 12698
ORDER BY NEWID();  -- Randomize the selection


----------------------------------------------------------------------------------------------------------------------------------