CREATE DATABASE bank_db;
GO

use bank_db;
GO

CREATE TABLE Bank
(
	BankId INT NOT NULL,
	BankName NVARCHAR(30) NOT NULL,
	CONSTRAINT PK_BankId PRIMARY KEY(BankId)
);
GO

CREATE TABLE City
(
	CityId INT NOT NULL IDENTITY(1,1),
	CityName NVARCHAR(30) NOT NULL,
	CONSTRAINT PK_CityId PRIMARY KEY(CityId)
);
GO

CREATE TABLE Branch
(
	BranchId INT NOT NULL IDENTITY(1,1),
	BankId INT FOREIGN KEY REFERENCES Bank(BankId),
	CityId INT FOREIGN KEY REFERENCES City(CityId),
	BranchAddress NVARCHAR(30) NOT NULL,
	CONSTRAINT PK_BranchId PRIMARY KEY(BranchId)
);
GO

CREATE TABLE Client
(
	ClientId INT NOT NULL IDENTITY(1,1),
	ClientName NVARCHAR(50) NOT NULL,
	ClientPhone NVARCHAR(20) NOT NULL,
	ClientAddress NVARCHAR(30) NOT NULL,
	CONSTRAINT PK_ClientId PRIMARY KEY(ClientId)
);
GO

CREATE TABLE Account
(
	AccountId INT NOT NULL IDENTITY(1,1),
	CurrentBalance INT NOT NULL,
	CONSTRAINT PK_AccountId PRIMARY KEY(AccountId),
	ClientId INT FOREIGN KEY REFERENCES Client(ClientId),
	BankId INT FOREIGN KEY REFERENCES Bank(BankId),
	CONSTRAINT UQ_AccountId UNIQUE(ClientId, BankId),
);
GO

CREATE TABLE [Status]
(
	StatusId INT NOT NULL,
	SocialStatus NVARCHAR(30) NOT NULL,
	CONSTRAINT PK_StatusId PRIMARY KEY(StatusId)
);
GO

CREATE TABLE ClientStatus
(
	ClientId INT UNIQUE FOREIGN KEY REFERENCES Client(ClientId),
	StatusId INT FOREIGN KEY REFERENCES [Status](StatusId)
);
GO

CREATE TABLE [Card]
(
	CardId INT NOT NULL IDENTITY(1,1),
	CardNumber NVARCHAR(20) NOT NULL,
	CardTerm DATE NOT NULL,
	CardCode INT NOT NULL,
	CardBalance INT NOT NULL,
	AccountId INT FOREIGN KEY REFERENCES Account(AccountId),
	CONSTRAINT PK_CardId PRIMARY KEY(CardId)
);
GO

AlTER TABLE Client
	ADD ClientAge INT DEFAULT 18;
GO

-- Task 1

INSERT INTO City VALUES
('Brest'),
('Vitebsk'),
('Gomel'),
('Grodno'),
('Minsk'),
('Mogilev');

INSERT INTO Bank VALUES
(1, 'Sberbank'),
(2, 'Belarusbank'),
(3, 'Belinvestbank'),
(4, 'Alfabank'),
(5, 'MTBank');

INSERT INTO Branch VALUES
(1, 2, 'st. Oktyabrskaya, 33'),
(2, 3, 'st. Pushkinskaya, 21b'),
(4, 1, 'st. Mirnaya, 71'),
(2, 2, 'st. Orlovskaya, 19'),
(5, 4, 'st. Suvorova, 25b');

INSERT INTO [Status] VALUES
(1, 'Adult'),
(2, 'Student'),
(3, 'Pensioner'),
(4, 'Disabled');

INSERT INTO Client VALUES
('Ivanov I. I.', '+375294239003', 'st. Pushkina, 17', 22),
('Petrov P. P.', '+375336382947', 'st. Pionerskaya, 22', 42),
('Stepanov S. S.', '+375293842048', 'st. Sovetskaya, 56', 35),
('Pushkin A. S.', '+375449048515', 'st. Leninskaya, 81a', 18),
('Katushkin V. V.', '+375294932923', 'st. Moskovskaya, 223', 67);

INSERT INTO ClientStatus VALUES
(1, 1),
(2, 1),
(3, 1),
(4, 2),
(5, 3);

INSERT INTO Account VALUES
(400, 1, 2),
(350, 1, 1),
(700, 3, 3),
(530, 4, 1),
(220, 2, 4);

INSERT INTO [Card] VALUES
('1234 5678 9101 1121', '2025-07-12', 729, 70, 1),
('6372 8723 9249 1191', '2024-03-12', 373, 100, 1),
('8329 1032 8123 9183', '2026-08-12', 803, 220, 6),
('4140 0942 9320 9381', '2025-05-12', 419, 200, 4),
('7148 0538 7480 0471', '2026-07-12', 381, 300, 5);

-- Task 2

SELECT *
FROM Bank
JOIN Branch ON Bank.BankId = Branch.BankId
JOIN City ON City.CityId = Branch.CityId
WHERE City.CityName = 'Brest';

SELECT *
FROM Bank, Branch, City
WHERE City.CityName = 'Brest' AND
	Bank.BankId = Branch.BankId AND
	City.CityId = Branch.CityId;

-- Task 3

SELECT Client.ClientName, [Card].CardBalance, Bank.BankName
FROM [Card]
JOIN Account ON [Card].AccountId = Account.AccountId
JOIN Client ON Client.ClientId = Account.ClientId
JOIN Bank ON Bank.BankId = Account.BankId

-- Task 4

SELECT Account.AccountId,
	Account.CurrentBalance,
	[Card].CardId,
	[Card].CardBalance, 
	Account.CurrentBalance - (SELECT SUM(CardBalance) 
								FROM [Card] 
								WHERE Account.AccountId = [Card].AccountId) AS Difference
FROM Account
JOIN [Card] ON Account.AccountId = [Card].AccountId
WHERE Account.CurrentBalance <> [Card].CardBalance

-- Task 5 (GROUP BY)

SELECT [Status].SocialStatus,
	COUNT([Card].CardId) AS CountOfCards
FROM [Status]
LEFT JOIN ClientStatus ON [Status].StatusId = ClientStatus.StatusId
LEFT JOIN Client ON Client.ClientId = ClientStatus.ClientId
LEFT JOIN Account ON Client.ClientId = Account.ClientId
LEFT JOIN [Card] ON [Card].AccountId = Account.AccountId
GROUP BY SocialStatus

-- Task 5 (Subquery) is not ready

SELECT [Status].SocialStatus,
		(SELECT COUNT(CardId)
						FROM [Card]
						WHERE [Card].AccountId = Account.AccountId) AS CountOfCards
FROM [Status]
LEFT JOIN ClientStatus ON [Status].StatusId = ClientStatus.StatusId
LEFT JOIN Client ON Client.ClientId = ClientStatus.ClientId
LEFT JOIN Account ON Client.ClientId = Account.ClientId
LEFT JOIN [Card] ON [Card].AccountId = Account.AccountId

-- Task 6

CREATE PROCEDURE PutMoney
	@StatusId INT
AS
BEGIN TRY
  IF @StatusId <> 2 OR
  (SELECT COUNT(*)
	FROM [Status]
	LEFT JOIN ClientStatus ON [Status].StatusId = ClientStatus.StatusId
	LEFT JOIN Client ON Client.ClientId = ClientStatus.ClientId
	LEFT JOIN Account ON Client.ClientId = Account.ClientId
	WHERE [Status].StatusId = @StatusId AND
	Account.ClientId IS NULL) > 0
		THROW 51000, 'StatusId does not exist/ no linked accounts', 1;

	UPDATE Account
	SET CurrentBalance = CurrentBalance + 10
	WHERE ClientId IN (SELECT ClientId
					FROM  Client
					WHERE ClientId IN (SELECT ClientId
									FROM ClientStatus
									WHERE StatusId IN (SELECT StatusId
													FROM Status
													WHERE StatusId = @StatusId)))
END TRY
BEGIN CATCH
	SELECT ERROR_MESSAGE() AS [Description of error]
END CATCH

SELECT *
FROM Account

EXEC PutMoney 2

SELECT *
FROM Account

-- Task 7

SELECT Account.AccountId,
	Account.CurrentBalance,
	[Card].CardId,
	[Card].CardBalance,
	Account.CurrentBalance - (SELECT SUM(CardBalance) 
								FROM [Card] 
								WHERE Account.AccountId = [Card].AccountId) AS AvailableFunds
FROM Account
JOIN [Card] ON Account.AccountId = [Card].AccountId

-- Task 8

CREATE PROCEDURE TransferToCard
	@CardId INT,
	@Sum INT
AS
BEGIN TRY
BEGIN TRANSACTION
IF (SELECT COUNT(*)
	FROM [Card]
	WHERE CardId = @CardId) = 0 OR
	(SELECT Account.CurrentBalance - (SELECT SUM(CardBalance) 
								FROM [Card] 
								WHERE Account.AccountId = [Card].AccountId)
	FROM Account
	JOIN [Card] ON Account.AccountId = [Card].AccountId
	WHERE [Card].CardId = @CardId) < @Sum
		THROW 51000, 'CardId does not exist/ sum of account is less', 1;
UPDATE [Card]
SET CardBalance = CardBalance + @Sum
WHERE CardId = @CardId
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION
    SELECT ERROR_MESSAGE() AS [Description of error]
RETURN
END CATCH
COMMIT TRANSACTION

DROP PROCEDURE TransferToCard

SELECT *
FROM [Card]

EXEC TransferToCard 1, 200

SELECT *
FROM [Card]

-- Task 9

CREATE TRIGGER CheckBalance
ON Account
FOR UPDATE
AS
DECLARE @Id INT, @OldBalance INT, @NewBalance INT, @Difference INT;
SET @Id = (SELECT AccountId FROM INSERTED);
SET @OldBalance = (SELECT CurrentBalance FROM DELETED);
SET @NewBalance = (SELECT CurrentBalance FROM INSERTED);
IF ((SELECT DISTINCT Account.CurrentBalance - (SELECT SUM(CardBalance) 
								FROM [Card] 
								WHERE Account.AccountId = [Card].AccountId)
	FROM Account
	JOIN [Card] ON Account.AccountId = [Card].AccountId
	WHERE [Card].AccountId = @Id) + (@OldBalance - @NewBalance)) < (@OldBalance - @NewBalance)
BEGIN
PRINT 'Cannot change the value to less than the amount of the card balance.'
ROLLBACK TRANSACTION
END
