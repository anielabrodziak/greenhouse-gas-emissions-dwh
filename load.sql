USE [EmissionsDW]
GO

EXEC stg.LoadDimension_DimEmissionType;
EXEC stg.LoadDimension_DimEmissionSource;
EXEC stg.LoadDimension_DimCountry;
EXEC stg.LoadDimension_DimCalendar;
EXEC stg.LoadDimension_FactEmissions;