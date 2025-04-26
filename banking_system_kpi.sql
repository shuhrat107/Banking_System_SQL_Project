SELECT TOP 3 
    c.CustomerID, 
    c.FullName, 
    SUM(a.Balance) AS TotalBalance
FROM Customers c
JOIN Accounts a ON c.CustomerID = a.CustomerID
GROUP BY c.CustomerID, c.FullName
ORDER BY TotalBalance DESC;




INSERT INTO Loans (CustomerID, LoanType, Amount, InterestRate, StartDate, EndDate, Status)
SELECT 
    l.CustomerID,
    CASE 
        WHEN ABS(CHECKSUM(NEWID())) % 4 = 0 THEN 'Business' 
        WHEN ABS(CHECKSUM(NEWID())) % 4 = 1 THEN 'Auto' 
        WHEN ABS(CHECKSUM(NEWID())) % 4 = 2 THEN 'Personal' 
        ELSE 'Mortgage' 
    END,
    ABS(CHECKSUM(NEWID())) % 50000 + 5000, -- Random amount
    ABS(CHECKSUM(NEWID())) % 10 + 3,      -- Random interest rate
    GETDATE(),                            -- Start date
    DATEADD(MONTH, ABS(CHECKSUM(NEWID())) % 60 + 12, GETDATE()), -- End date
    'Active' 
FROM Loans l
WHERE l.CustomerID IN (SELECT TOP 5 CustomerID FROM Loans)
ORDER BY NEWID();

INSERT INTO Loans (CustomerID, LoanType, Amount, InterestRate, StartDate, EndDate, Status)
SELECT 
    l.CustomerID,
    CASE 
        WHEN ABS(CHECKSUM(NEWID())) % 4 = 0 THEN 'Business' 
        WHEN ABS(CHECKSUM(NEWID())) % 4 = 1 THEN 'Auto' 
        WHEN ABS(CHECKSUM(NEWID())) % 4 = 2 THEN 'Personal' 
        ELSE 'Mortgage' 
    END,
    ABS(CHECKSUM(NEWID())) % 50000 + 5000, -- Random amount
    ABS(CHECKSUM(NEWID())) % 10 + 3,      -- Random interest rate
    DATEADD(MONTH, -ABS(CHECKSUM(NEWID())) % 60, GETDATE()), -- Past start date
    DATEADD(MONTH, -ABS(CHECKSUM(NEWID())) % 12, GETDATE()), -- Past end date (loan has ended)
    'Inactive'  -- Loan is marked as inactive
FROM Loans l
WHERE l.CustomerID IN (SELECT TOP 5 CustomerID FROM Loans)
ORDER BY NEWID();



SELECT 
    l.CustomerID, 
    c.FullName, 
    COUNT(l.LoanID) AS ActiveLoanCount
FROM Loans l
JOIN Customers c ON l.CustomerID = c.CustomerID
WHERE l.Status = 'Active'
GROUP BY l.CustomerID, c.FullName
HAVING COUNT(l.LoanID) > 1
ORDER BY ActiveLoanCount DESC;


SELECT 
    t.TransactionID,
    t.AccountID,
    t.TransactionType,
    t.Amount,
    t.Currency,
    t.Date,
    t.Status,
    t.ReferenceNo,
    f.FraudID,
    f.CustomerID,
    f.RiskLevel,
    f.ReportedDate
FROM Transactions t
JOIN FraudDetection f ON t.TransactionID = f.TransactionID
ORDER BY f.ReportedDate DESC;

SELECT 
    a.BranchID, 
    SUM(l.Amount) AS TotalLoanAmount
FROM Loans l
JOIN Accounts a ON l.CustomerID = a.CustomerID
GROUP BY a.BranchID
ORDER BY TotalLoanAmount DESC;


-- •	Total Loan Amount Issued Per Branch

UPDATE Accounts
SET BranchID = FLOOR(RAND(CHECKSUM(NEWID())) * 50) + 1;

SELECT a.BranchID, SUM(l.Amount) AS TotalLoanAmount
FROM Loans l
JOIN Accounts a ON l.CustomerID = a.CustomerID
GROUP BY a.BranchID
ORDER BY a.BranchID;





--•	Customers who made multiple large transactions (above $10,000) within a short time frame (less than 1 hour apart)

INSERT INTO Transactions (AccountID, TransactionType, Amount, Currency, [Date], Status, ReferenceNo)
VALUES 
-- Customer 12199 (3 transactions within 1 hour)
(31, 'Deposit', 15000, 'USD', '2025-03-02 10:00:00', 'Completed', 'TXN99871'),
(31, 'Deposit', 12000, 'USD', '2025-03-02 10:30:00', 'Completed', 'TXN99872'),
(31, 'Deposit', 13000, 'USD', '2025-03-02 10:45:00', 'Completed', 'TXN99873'),

-- Customer 12200 (2 transactions within 1 hour)
(32, 'Withdrawal', 11000, 'USD', '2025-03-03 14:15:00', 'Completed', 'TXN99874'),
(32, 'Withdrawal', 10500, 'USD', '2025-03-03 14:45:00', 'Completed', 'TXN99875'),

-- Customer 12201 (3 transactions within 1 hour)
(33, 'Deposit', 14000, 'USD', '2025-03-04 09:10:00', 'Completed', 'TXN99876'),
(33, 'Deposit', 16000, 'USD', '2025-03-04 09:35:00', 'Completed', 'TXN99877'),
(33, 'Deposit', 12000, 'USD', '2025-03-04 09:50:00', 'Completed', 'TXN99878'),

-- Customer 12202 (2 transactions within 1 hour)
(34, 'Withdrawal', 18000, 'USD', '2025-03-05 13:20:00', 'Completed', 'TXN99879'),
(34, 'Withdrawal', 12500, 'USD', '2025-03-05 13:50:00', 'Completed', 'TXN99880'),

-- Customer 12203 (3 transactions within 1 hour)
(35, 'Deposit', 19000, 'USD', '2025-03-06 11:00:00', 'Completed', 'TXN99881'),
(35, 'Deposit', 17000, 'USD', '2025-03-06 11:25:00', 'Completed', 'TXN99882'),
(35, 'Deposit', 15000, 'USD', '2025-03-06 11:50:00', 'Completed', 'TXN99883'),

-- Customer 12204 (2 transactions within 1 hour)
(36, 'Withdrawal', 15500, 'USD', '2025-03-07 15:05:00', 'Completed', 'TXN99884'),
(36, 'Withdrawal', 14000, 'USD', '2025-03-07 15:50:00', 'Completed', 'TXN99885');




WITH TransactionCTE AS (
    SELECT 
        A.CustomerID,
        T.TransactionID,
        T.Amount,
        T.[Date] AS TransactionDate,
        LAG(T.[Date]) OVER (PARTITION BY A.CustomerID ORDER BY T.[Date]) AS PrevTransactionDate
    FROM Transactions T
    JOIN Accounts A ON T.AccountID = A.AccountID
    WHERE T.Amount > 10000  -- Only large transactions
)
SELECT 
    CustomerID,
    COUNT(TransactionID) AS LargeTransactionCount
FROM TransactionCTE
WHERE PrevTransactionDate IS NOT NULL
AND DATEDIFF(MINUTE, PrevTransactionDate, TransactionDate) < 60  -- Transactions within 1 hour
GROUP BY CustomerID
HAVING COUNT(TransactionID) > 1  -- More than one large transaction
ORDER BY LargeTransactionCount DESC;







--•	Customers who have made transactions from different countries within 10 minutes, a common red flag for fraud.

UPDATE Branches
SET Country = CASE 
    WHEN BranchID BETWEEN 1 AND 2 THEN 'USA'
    WHEN BranchID BETWEEN 3 AND 4 THEN 'Canada'
    WHEN BranchID BETWEEN 5 AND 6 THEN 'Mexico'
    WHEN BranchID BETWEEN 7 AND 8 THEN 'UK'
    WHEN BranchID BETWEEN 9 AND 10 THEN 'Germany'
    WHEN BranchID BETWEEN 11 AND 12 THEN 'France'
    WHEN BranchID BETWEEN 13 AND 14 THEN 'Italy'
    WHEN BranchID BETWEEN 15 AND 16 THEN 'Spain'
    WHEN BranchID BETWEEN 17 AND 18 THEN 'Australia'
    WHEN BranchID BETWEEN 19 AND 20 THEN 'Japan'
    WHEN BranchID BETWEEN 21 AND 22 THEN 'China'
    WHEN BranchID BETWEEN 23 AND 24 THEN 'India'
    WHEN BranchID BETWEEN 25 AND 26 THEN 'Brazil'
    WHEN BranchID BETWEEN 27 AND 28 THEN 'Argentina'
    WHEN BranchID BETWEEN 29 AND 30 THEN 'Russia'
    WHEN BranchID BETWEEN 31 AND 32 THEN 'South Africa'
    WHEN BranchID BETWEEN 33 AND 34 THEN 'UAE'
    WHEN BranchID BETWEEN 35 AND 36 THEN 'Saudi Arabia'
    WHEN BranchID BETWEEN 37 AND 38 THEN 'Turkey'
    WHEN BranchID BETWEEN 39 AND 40 THEN 'Singapore'
    WHEN BranchID BETWEEN 41 AND 42 THEN 'South Korea'
    WHEN BranchID BETWEEN 43 AND 44 THEN 'Netherlands'
    WHEN BranchID BETWEEN 45 AND 46 THEN 'Sweden'
    WHEN BranchID BETWEEN 47 AND 48 THEN 'Switzerland'
    WHEN BranchID BETWEEN 49 AND 50 THEN 'Indonesia'
    ELSE Country
END;


INSERT INTO Transactions (AccountID, TransactionType, Amount, Currency, Date, Status, ReferenceNo)
VALUES
    (920, 'Deposit', 13250.00, 'USD', '2025-02-09T13:11:17', 'Completed', 'TXN903213'),
    (921, 'Withdrawal', 52134.00, 'USD', '2024-09-30T12:47:17', 'Completed', 'TXN548903'),
    (922, 'Deposit', 45324.00, 'USD', '2024-09-10T13:31:17', 'Completed', 'TXN987424'),
    (923, 'Withdrawal', 36700.00, 'USD', '2024-05-10T12:49:17', 'Completed', 'TXN237981'),
    (924, 'Deposit', 42500.00, 'USD', '2024-05-15T12:38:17', 'Completed', 'TXN673422');

	


UPDATE Branches
SET Country = CASE 
    WHEN BranchID % 25 = 0 THEN 'United States'
    WHEN BranchID % 25 = 1 THEN 'Canada'
    WHEN BranchID % 25 = 2 THEN 'United Kingdom'
    WHEN BranchID % 25 = 3 THEN 'Germany'
    WHEN BranchID % 25 = 4 THEN 'France'
    WHEN BranchID % 25 = 5 THEN 'Italy'
    WHEN BranchID % 25 = 6 THEN 'Spain'
    WHEN BranchID % 25 = 7 THEN 'Netherlands'
    WHEN BranchID % 25 = 8 THEN 'Switzerland'
    WHEN BranchID % 25 = 9 THEN 'Australia'
    WHEN BranchID % 25 = 10 THEN 'Japan'
    WHEN BranchID % 25 = 11 THEN 'China'
    WHEN BranchID % 25 = 12 THEN 'India'
    WHEN BranchID % 25 = 13 THEN 'Brazil'
    WHEN BranchID % 25 = 14 THEN 'Mexico'
    WHEN BranchID % 25 = 15 THEN 'South Africa'
    WHEN BranchID % 25 = 16 THEN 'Russia'
    WHEN BranchID % 25 = 17 THEN 'Turkey'
    WHEN BranchID % 25 = 18 THEN 'UAE'
    WHEN BranchID % 25 = 19 THEN 'Singapore'
    WHEN BranchID % 25 = 20 THEN 'South Korea'
    WHEN BranchID % 25 = 21 THEN 'Argentina'
    WHEN BranchID % 25 = 22 THEN 'Saudi Arabia'
    WHEN BranchID % 25 = 23 THEN 'Indonesia'
    ELSE 'Vietnam'
END;







	WITH TransactionCTE AS (
    SELECT 
        T.TransactionID,
        T.AccountID,
        A.CustomerID,
        B.Country,
        T.Date AS TransactionDate,
        LAG(T.Date) OVER (PARTITION BY A.CustomerID ORDER BY T.Date) AS PrevTransactionDate,
        LAG(B.Country) OVER (PARTITION BY A.CustomerID ORDER BY T.Date) AS PrevCountry
    FROM Transactions T
    JOIN Accounts A ON T.AccountID = A.AccountID
    JOIN Branches B ON A.BranchID = B.BranchID
)
SELECT 
    CustomerID,
    COUNT(TransactionID) AS FraudulentTransactionCount
FROM TransactionCTE
WHERE PrevTransactionDate IS NOT NULL
AND DATEDIFF(MINUTE, PrevTransactionDate, TransactionDate) < 10
AND Country <> PrevCountry  -- Different countries
GROUP BY CustomerID
HAVING COUNT(TransactionID) > 1 
ORDER BY FraudulentTransactionCount DESC;

INSERT INTO Transactions (AccountID, TransactionType, Amount, Currency, Date, Status, ReferenceNo)
VALUES 
    (920, 'Deposit', 5000, 'USD', '2024-10-14T12:00:00', 'Completed', 'TXN2001'),
    (921, 'Withdrawal', 7000, 'USD', '2024-10-14T12:05:00', 'Completed', 'TXN2002'),  
    (922, 'Deposit', 6000, 'USD', '2024-10-14T12:07:00', 'Completed', 'TXN2003');



 

