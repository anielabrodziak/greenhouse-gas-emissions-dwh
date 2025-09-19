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
    IDEmission INT IDENTITY(1,1) PRIMARY KEY NOT NULL,  
    EmissionType NVARCHAR(50) NOT NULL,                 
    EmissionDescription AS (                            
        CASE
            WHEN EmissionType = 'CO2' THEN 'Carbon dioxide'
            WHEN EmissionType = 'CH4' THEN 'Methane'
            WHEN EmissionType = 'N2O' THEN 'Nitrous oxide'
            ELSE 'Unknown gas'
        END
    ) PERSISTED 
);
GO


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

-- TABELA STAGINGOWA -- 

CREATE TABLE [stg].[StagingEmissions] (
	EmissionType NVARCHAR(20),
	SourceName NVARCHAR(30),
	Country NVARCHAR(50),
	Year INT,
	EmissionAmount DECIMAL(12,4),
	ImportDate DATETIME DEFAULT GETDATE()
);
GO



