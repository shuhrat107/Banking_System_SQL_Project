use BankingSystem

-- 1 Customers Table
CREATE TABLE Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    DOB DATE NOT NULL,
    Email NVARCHAR(100) UNIQUE,
    PhoneNumber NVARCHAR(20) UNIQUE,
    Address NVARCHAR(255),
    NationalID NVARCHAR(50) UNIQUE NOT NULL,
    TaxID NVARCHAR(50) UNIQUE NOT NULL,
    EmploymentStatus NVARCHAR(50),
    AnnualIncome DECIMAL(15,2),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1 -- 1 = Active, 0 = Inactive
);

--2 Branches Table
CREATE TABLE Branches (
    BranchID INT IDENTITY(1,1) PRIMARY KEY,
    BranchName NVARCHAR(100) NOT NULL,
    Address NVARCHAR(255),
    City NVARCHAR(100),
    State NVARCHAR(100),
    Country NVARCHAR(100),
    ManagerID INT,
    ContactNumber NVARCHAR(20) UNIQUE,
    IsActive BIT DEFAULT 1 -- 1 = Active, 0 = Inactive
);

--3 Accounts Table
CREATE TABLE Accounts (
    AccountID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    AccountType NVARCHAR(50) NOT NULL,
    Balance DECIMAL(18,2) DEFAULT 0,
    Currency NVARCHAR(10) DEFAULT 'USD',
    Status NVARCHAR(20) NOT NULL CHECK (Status IN ('Active', 'Closed')),
    BranchID INT NOT NULL,
    CreatedDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (BranchID) REFERENCES Branches(BranchID)
);

-- 4 Transactions Table
CREATE TABLE Transactions (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    AccountID INT NOT NULL,
    TransactionType NVARCHAR(50) NOT NULL,
    Amount DECIMAL(18,2) NOT NULL,
    Currency NVARCHAR(10) DEFAULT 'USD',
    Date DATETIME DEFAULT GETDATE(),
    Status NVARCHAR(20) NOT NULL CHECK (Status IN ('Completed', 'Pending', 'Failed')),
    ReferenceNo NVARCHAR(50) UNIQUE,
    FOREIGN KEY (AccountID) REFERENCES Accounts(AccountID)
);

-- 5 Employees Table
CREATE TABLE Employees (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    BranchID INT NOT NULL,
    FullName NVARCHAR(100) NOT NULL,
    Position NVARCHAR(50),
    Department NVARCHAR(50),
    Salary DECIMAL(18,2),
    HireDate DATE,
    Status NVARCHAR(20) NOT NULL CHECK (Status IN ('Active', 'Inactive')),
    FOREIGN KEY (BranchID) REFERENCES Branches(BranchID)
);

-- 6 CreditCards Table
CREATE TABLE CreditCards (
    CardID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    CardNumber NVARCHAR(20) UNIQUE NOT NULL,
    CardType NVARCHAR(50),
    CVV NVARCHAR(10) NOT NULL,
    ExpiryDate DATE NOT NULL,
    Limit DECIMAL(18,2) NOT NULL,
    Status NVARCHAR(20) NOT NULL CHECK (Status IN ('Active', 'Blocked', 'Expired')),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

--7 CreditCardTransactions Table
CREATE TABLE CreditCardTransactions (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    CardID INT NOT NULL,
    Merchant NVARCHAR(255),
    Amount DECIMAL(18,2) NOT NULL,
    Currency NVARCHAR(10) DEFAULT 'USD',
    Date DATETIME DEFAULT GETDATE(),
    Status NVARCHAR(20) NOT NULL CHECK (Status IN ('Completed', 'Pending', 'Failed')),
    FOREIGN KEY (CardID) REFERENCES CreditCards(CardID)
);

-- 8 OnlineBankingUsers Table
CREATE TABLE OnlineBankingUsers (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    Username NVARCHAR(50) UNIQUE NOT NULL,
    PasswordHash NVARCHAR(255) NOT NULL,
    LastLogin DATETIME,
    IsActive BIT DEFAULT 1, -- 1 = Active, 0 = Inactive
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

-- 9 BillPayments Table
CREATE TABLE BillPayments (
    PaymentID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    BillerName NVARCHAR(255) NOT NULL,
    Amount DECIMAL(18,2) NOT NULL,
    Date DATETIME DEFAULT GETDATE(),
    Status NVARCHAR(20) NOT NULL CHECK (Status IN ('Completed', 'Pending', 'Failed')),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);
-- 1. MobileBankingTransactions Table
CREATE TABLE MobileBankingTransactions (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    DeviceID NVARCHAR(100),
    AppVersion NVARCHAR(50),
    TransactionType NVARCHAR(50) NOT NULL,
    Amount DECIMAL(18,2) NOT NULL,
    Date DATETIME DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1, -- 1 = Active, 0 = Inactive
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON DELETE NO ACTION
);

-- 2. Loans Table
CREATE TABLE Loans (
    LoanID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT FOREIGN KEY REFERENCES Customers(CustomerID) ON DELETE NO ACTION, 
    LoanType NVARCHAR(50) CHECK (LoanType IN ('Mortgage', 'Personal', 'Auto', 'Business')),
    Amount DECIMAL(18,2),
    InterestRate DECIMAL(5,2),
    StartDate DATE,
    EndDate DATE,
    Status NVARCHAR(50)
);

-- 3. LoanPayments Table
CREATE TABLE LoanPayments (
    PaymentID INT IDENTITY(1,1) PRIMARY KEY,
    LoanID INT FOREIGN KEY REFERENCES Loans(LoanID) ON DELETE CASCADE, 
    AmountPaid DECIMAL(18,2),
    PaymentDate DATE,
    RemainingBalance DECIMAL(18,2)
);

-- 4. CreditScores Table
CREATE TABLE CreditScores (
    CustomerID INT PRIMARY KEY FOREIGN KEY REFERENCES Customers(CustomerID) ON DELETE NO ACTION,
    CreditScore INT CHECK (CreditScore BETWEEN 300 AND 850),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- 5. DebtCollection Table
CREATE TABLE DebtCollection (
    DebtID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT FOREIGN KEY REFERENCES Customers(CustomerID) ON DELETE NO ACTION,
    AmountDue DECIMAL(18,2),
    DueDate DATE,
    CollectorAssigned NVARCHAR(255)
);

-- 6. KYC Table
CREATE TABLE KYC (
    KYCID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT FOREIGN KEY REFERENCES Customers(CustomerID) ON DELETE CASCADE,
    DocumentType NVARCHAR(50),
    DocumentNumber NVARCHAR(100) UNIQUE,
    VerifiedBy NVARCHAR(255)
);

-- 7. FraudDetection Table
CREATE TABLE FraudDetection (
    FraudID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT FOREIGN KEY REFERENCES Customers(CustomerID) ON DELETE NO ACTION,
    TransactionID INT,
    RiskLevel NVARCHAR(50),
    ReportedDate DATETIME DEFAULT GETDATE()
);

-- 8. AMLCases Table
CREATE TABLE AMLCases (
    CaseID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT FOREIGN KEY REFERENCES Customers(CustomerID) ON DELETE NO ACTION,
    CaseType NVARCHAR(255),
    Status NVARCHAR(50),
    InvestigatorID INT
);

-- 9. RegulatoryReports Table
CREATE TABLE RegulatoryReports (
    ReportID INT IDENTITY(1,1) PRIMARY KEY,
    ReportType NVARCHAR(255),
    SubmissionDate DATE
);

-- 10. EmployeeAttendance Table
CREATE TABLE EmployeeAttendance (
    AttendanceID INT PRIMARY KEY IDENTITY(1,1),
    EmployeeID INT NOT NULL,
    CheckInTime DATETIME NOT NULL,
    CheckOutTime DATETIME NOT NULL,
    TotalHours AS DATEDIFF(HOUR, CheckInTime, CheckOutTime) PERSISTED,
    FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID) ON DELETE CASCADE
);


-- 4. ForeignExchange Table
CREATE TABLE ForeignExchange (
    FXID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL,
    CurrencyPair VARCHAR(10) NOT NULL,
    ExchangeRate DECIMAL(10,4) NOT NULL,
    AmountExchanged DECIMAL(15,2) NOT NULL,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON DELETE NO ACTION
);

-- 5. InsurancePolicies Table
CREATE TABLE InsurancePolicies (
    PolicyID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL,
    InsuranceType VARCHAR(50) NOT NULL,
    PremiumAmount DECIMAL(15,2) NOT NULL,
    CoverageAmount DECIMAL(15,2) NOT NULL,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON DELETE NO ACTION
);



-- 6. Claims Table
CREATE TABLE Claims (
    ClaimID INT PRIMARY KEY IDENTITY(1,1),
    PolicyID INT NOT NULL,
    ClaimAmount DECIMAL(15,2) NOT NULL,
    Status VARCHAR(20) CHECK (Status IN ('Pending', 'Approved', 'Rejected')) NOT NULL,
    FiledDate DATE NOT NULL,
    FOREIGN KEY (PolicyID) REFERENCES InsurancePolicies(PolicyID) ON DELETE CASCADE
);

-- 7. UserAccessLogs Table
CREATE TABLE UserAccessLogs (
    LogID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT NOT NULL,
    ActionType VARCHAR(50) NOT NULL,
    Timestamp DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (UserID) REFERENCES OnlineBankingUsers(UserID) ON DELETE CASCADE
);

-- 8. CyberSecurityIncidents Table
CREATE TABLE CyberSecurityIncidents (
    IncidentID INT PRIMARY KEY IDENTITY(1,1),
    AffectedSystem VARCHAR(100) NOT NULL,
    ReportedDate DATE NOT NULL,
    ResolutionStatus VARCHAR(50) CHECK (ResolutionStatus IN ('Open', 'Resolved', 'Investigating')) NOT NULL
);

-- 9. Merchants Table
CREATE TABLE Merchants (
    MerchantID INT PRIMARY KEY IDENTITY(1,1),
    MerchantName VARCHAR(100) NOT NULL,
    Industry VARCHAR(50) NOT NULL,
    Location VARCHAR(100) NOT NULL,
    CustomerID INT NOT NULL,
    IsActive BIT DEFAULT 1, -- 1 = Active, 0 = Inactive
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON DELETE NO ACTION
);

-- 10. MerchantTransactions Table
CREATE TABLE MerchantTransactions (
    TransactionID INT PRIMARY KEY IDENTITY(1,1),
    MerchantID INT NOT NULL,
    TransactionAmount DECIMAL(15,2) NOT NULL,
    TransactionDate DATETIME DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1, -- 1 = Active, 0 = Inactive
    FOREIGN KEY (MerchantID) REFERENCES Merchants(MerchantID) ON DELETE NO ACTION
);