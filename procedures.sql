USE [EmissionsDW]
GO

CREATE PROCEDURE [stg].[LoadDimension_DimEmissionType]
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [Emissions].[DimEmissionType] (EmissionType)
    SELECT DISTINCT S.EmissionType
    FROM [stg].[StagingEmissions] S
    LEFT JOIN [Emissions].[DimEmissionType] ET 
        ON S.EmissionType = ET.EmissionType
    WHERE ET.IDEmission IS NULL; 
END;
GO

CREATE PROCEDURE [stg].[LoadDimension_DimEmissionSource]
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [Emissions].[DimEmissionSource] (SourceName)
    SELECT DISTINCT S.SourceName
    FROM [stg].[StagingEmissions] S
    LEFT JOIN [Emissions].[DimEmissionSource] ES 
        ON S.SourceName = ES.SourceName
    WHERE ES.IDEmissionSource IS NULL; 
END;
GO

CREATE PROCEDURE [stg].[LoadDimension_DimCountry]
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [Emissions].[DimCountry] (CountryName)
    SELECT DISTINCT S.Country
    FROM [stg].[StagingEmissions] S
    LEFT JOIN [Emissions].[DimCountry] C 
        ON S.Country = C.CountryName
    WHERE C.IDCountry IS NULL; 
END;
GO

CREATE PROCEDURE [stg].[LoadDimension_DimCalendar]
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [Emissions].[DimCalendar] (Year)
    SELECT DISTINCT CAST(S.Year AS NVARCHAR(50))
    FROM [stg].[StagingEmissions] S
    LEFT JOIN [Emissions].[DimCalendar] DC 
        ON CAST(S.Year AS NVARCHAR(50)) = DC.Year
    WHERE DC.IDCalendar IS NULL; 
END;
GO

CREATE PROCEDURE [stg].[LoadDimension_FactEmissions]
AS
BEGIN
    SET NOCOUNT ON;

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