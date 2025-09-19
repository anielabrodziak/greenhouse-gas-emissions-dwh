USE [master]
GO

CREATE DATABASE EmissionsDW
GO

USE [master]
GO

ALTER DATABASE [EmissionsDW] SET RECOVERY SIMPLE WITH no_wait
GO

USE [EmissionsDW]
GO

CREATE SCHEMA [Emissions]
GO

CREATE SCHEMA [stg]
GO

/*
	Tworzenie wymiarów
-- TABELA EMISSIONTYPE -- 
*/

CREATE TABLE Emissions.DimEmissionType
(
    IDEmission INT IDENTITY(1,1) PRIMARY KEY NOT NULL,  -- Kolumna ID z automatycznym inkrementowaniem
    EmissionType NVARCHAR(50) NOT NULL,                 -- Kolumna typu emisji (np. CO2, CH4, N2O)
    EmissionDescription AS (                            -- Kolumna opisowa na podstawie typu emisji
        CASE
            WHEN EmissionType = 'CO2' THEN 'Carbon dioxide'
            WHEN EmissionType = 'CH4' THEN 'Methane'
            WHEN EmissionType = 'N2O' THEN 'Nitrous oxide'
            ELSE 'Unknown gas'
        END
    ) PERSISTED 
);
GO

-- Kompresja typu page
ALTER TABLE [Emissions].[DimEmissionType] REBUILD
WITH (data_compression = page);
GO

/*
-- TABELA EMISSIONSOURCE -- 
*/

CREATE TABLE Emissions.DimEmissionSource
(
	IDEmissionSource INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
	SourceName NVARCHAR(50) NOT NULL
);

-- Kompresja typu page
ALTER TABLE [Emissions].[DimEmissionSource] REBUILD
WITH (data_compression = page);
GO

/*
-- TABELA COUNTRY -- 
*/

CREATE TABLE Emissions.DimCountry
(
	IDCountry INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
	CountryName NVARCHAR(50) NOT NULL
);

-- Kompresja typu page
ALTER TABLE [Emissions].[DimCountry] REBUILD
WITH (data_compression = page);
GO

/*
-- TABELA CALENDAR -- 
*/

CREATE TABLE Emissions.DimCalendar
(
    IDCalendar INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    Year NVARCHAR(50) NOT NULL,
    Century AS (CASE 
                  WHEN TRY_CAST(Year AS INT) IS NULL THEN NULL
                  ELSE CONCAT FLOOR(CAST(Year AS INT) / 100) + 1
                END) PERSISTED,  
    IsLeap AS (CASE 
                 WHEN TRY_CAST(Year AS INT) IS NULL THEN NULL
                 WHEN (CAST(Year AS INT) % 4 = 0 AND CAST(Year AS INT) % 100 != 0) OR (CAST(Year AS INT) % 400 = 0) 
                 THEN 1 
                 ELSE 0 
               END) PERSISTED  
);

-- Kompresja typu page
ALTER TABLE [Emissions].[DimCalendar] REBUILD
WITH (data_compression = page);
GO

/*
	Tworzenie faktu
*/

CREATE TABLE [Emissions].[FactEmissions](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[IDEmission] INT REFERENCES [Emissions].[DimEmissionType](IDEmission),
	[IDEmissionSource] INT REFERENCES [Emissions].[DimEmissionSource](IDEmissionSource),
	[IDCountry] INT REFERENCES [Emissions].[DimCountry](IDCountry),
	[IDCalendar] INT REFERENCES [Emissions].[DimCalendar](IDCalendar),
	[EmissionRate] DECIMAL(10,4) NOT NULL
);

CREATE CLUSTERED COLUMNSTORE INDEX EmissionsIdx ON Emissions.FactEmissions;

-- TABELA StAGINGOWA -- 

CREATE TABLE [stg].[StagingEmissions] (
	EmissionType NVARCHAR(20),
	SourceName NVARCHAR(30),
	Country NVARCHAR(50),
	Year INT,
	EmissionAmount DECIMAL(12,4),
	ImportDate DATETIME DEFAULT GETDATE()
);
GO

-----------------------------------------------------
CREATE PROCEDURE [stg].[LoadDimension_DimEmissionType]
AS
BEGIN
    SET NOCOUNT ON;

    -- Wstaw nowe rekordy do wymiaru DimEmissionType
    INSERT INTO [Emissions].[DimEmissionType] (EmissionType)
    SELECT DISTINCT S.EmissionType
    FROM [stg].[StagingEmissions] S
    LEFT JOIN [Emissions].[DimEmissionType] ET 
        ON S.EmissionType = ET.EmissionType
    WHERE ET.IDEmission IS NULL; -- Rekord nie istnieje w wymiarze
END;
GO

CREATE PROCEDURE [stg].[LoadDimension_DimEmissionSource]
AS
BEGIN
    SET NOCOUNT ON;

    -- Wstaw nowe rekordy do wymiaru DimEmissionSource
    INSERT INTO [Emissions].[DimEmissionSource] (SourceName)
    SELECT DISTINCT S.SourceName
    FROM [stg].[StagingEmissions] S
    LEFT JOIN [Emissions].[DimEmissionSource] ES 
        ON S.SourceName = ES.SourceName
    WHERE ES.IDEmissionSource IS NULL; -- Rekord nie istnieje w wymiarze
END;
GO

CREATE PROCEDURE [stg].[LoadDimension_DimCountry]
AS
BEGIN
    SET NOCOUNT ON;

    -- Wstaw nowe rekordy do wymiaru DimCountry
    INSERT INTO [Emissions].[DimCountry] (CountryName)
    SELECT DISTINCT S.Country
    FROM [stg].[StagingEmissions] S
    LEFT JOIN [Emissions].[DimCountry] C 
        ON S.Country = C.CountryName
    WHERE C.IDCountry IS NULL; -- Rekord nie istnieje w wymiarze
END;
GO

CREATE PROCEDURE [stg].[LoadDimension_DimCalendar]
AS
BEGIN
    SET NOCOUNT ON;

    -- Wstaw nowe rekordy do wymiaru DimCalendar
    INSERT INTO [Emissions].[DimCalendar] (Year)
    SELECT DISTINCT CAST(S.Year AS NVARCHAR(50))
    FROM [stg].[StagingEmissions] S
    LEFT JOIN [Emissions].[DimCalendar] DC 
        ON CAST(S.Year AS NVARCHAR(50)) = DC.Year
    WHERE DC.IDCalendar IS NULL; -- Rekord nie istnieje w wymiarze
END;
GO

CREATE PROCEDURE [stg].[LoadDimension_FactEmissions]
AS
BEGIN
    SET NOCOUNT ON;

    -- Wstaw nowe rekordy do tabeli faktów
    INSERT INTO [Emissions].[FactEmissions] (
        IDEmission, IDEmissionSource, IDCountry, IDCalendar, EmissionRate
    )
    SELECT
        DET.IDEmission,
        DES.IDEmissionSource,
        DC.IDCountry,
        DCAL.IDCalendar,
        SE.EmissionAmount
    FROM
        [stg].[StagingEmissions] SE
    INNER JOIN [Emissions].[DimEmissionType] DET
        ON SE.EmissionType = DET.EmissionType
    INNER JOIN [Emissions].[DimEmissionSource] DES
        ON SE.SourceName = DES.SourceName
    INNER JOIN [Emissions].[DimCountry] DC
        ON SE.Country = DC.CountryName
    INNER JOIN [Emissions].[DimCalendar] DCAL
        ON CAST(SE.Year AS NVARCHAR(50)) = DCAL.Year;
END;
GO


