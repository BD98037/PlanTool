USE [SSATools]
GO
/****** Object:  StoredProcedure [dbo].[PlanTool_GMM_LoadForecastProFactors]    Script Date: 05/01/2015 10:02:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[PlanTool_GMM_LoadForecastProFactors]
AS

DECLARE @SQL varchar(2000),@PathFileName varchar(200)

/*
CREATE TABLE PlanTool_GMM_ForecastPro_Factors(
	Metric Varchar(20),
	SuperRegionID Varchar(80),
	RegionID Varchar(80),
	RegionName Varchar(80),
	AMTID Varchar(80),
	AMTName Varchar(80),
	MMAName Varchar(80),
	MMAID Varchar(80),
	FC_Year Varchar(20),
	FC_Month Varchar(20),
	FC_Factor Varchar(80)
) 
*/

  SET @PathFileName ='\\BEL-PFS-01\Hotel_Sales_Team\REPORTS\CURRENT\Other\BryanDoan\PlanForecast\2015\Q2\AP_SIP_FORECAST_DATA.txt'
  
  SET @SQL = 'BULK INSERT PlanTool_GMM_ForecastPro_Factors FROM "'+@PathFileName+'" WITH (FIELDTERMINATOR = ''|'')'
  
--Execute BULK INSERT statement
  TRUNCATE TABLE PlanTool_GMM_ForecastPro_Factors
  INSERT INTO PlanTool_GMM_ForecastPro_Factors
  EXEC (@SQL)
  
  DELETE FROM PlanTool_GMM_ForecastPro_Factors WHERE Metric ='ITEMID0_METRIC'
  
--remove the first and last extra quotes
UPDATE PlanTool_GMM_ForecastPro_Factors
set Metric = REPLACE(Metric,'"',''),
	RegionID = REPLACE(RegionID,'"',''),
	FC_Factor = REPLACE(FC_Factor,'|','')

/*
  select MMAID,fc_year,COUNT(*) from PlanTool_GMM_ForecastPro_Factors 
  where metric = 'NRN' and fc_year ='2015' group by mmaid,fc_year
  having COUNT(*)<10
  
  select * from PlanTool_GMM_ForecastPro_Factors  where mmaid =1700431
  and fc_year =2015 and metric = 'NRN' order by fc_month
  */
  