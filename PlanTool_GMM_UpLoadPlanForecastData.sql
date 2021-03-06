USE [SSATools]
GO
/****** Object:  StoredProcedure [dbo].[PlanTool_GMM_UpLoadPlanForecastData]    Script Date: 05/01/2015 10:04:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[PlanTool_GMM_UpLoadPlanForecastData]
@FileLocation varchar(4000) ='\\BEL-PFS-01\Hotel_Sales_Team\REPORTS\CURRENT\Other\BryanDoan\PlanForecast\2015\Q2\'
,@FileName varchar(100) ='SSA file_Quarterly Regional_March Forecast.xlsx'
AS

Declare @sql varchar(4000)

-- Drop temp tables if exist
IF OBJECT_ID('tempdb..##PlanData') IS NOT NULL
  DROP TABLE ##PlanData
   
select @FileLocation+@FileName 
   
   
SET @sql ='
SELECT * INTO ##PlanData
 FROM  OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
''EXCEL 12.0 XML;Database='+@FileLocation +@FileName+';HDR=YES'',
''SELECT * FROM [PlanDataQ1$]'')
'

select @sql
exec(@sql)


--select * from ##PlanData where regionid is null

--Update POSaPK in case they are missing
UPDATE p
SET p.POSalePK = pos.posalepk
FROM ##PlanData p
JOIN Common.dbo.DimPOSales pos ON p.POSaName = pos.POSaName

-- Update RegionIDs in case they are missing
UPDATE p
SET p.RegionID = r.RegionID
FROM ##PlanData p
JOIN (SELECT DISTINCT RegionID, RegionName FROM KPI_GMM_VIP_Hierarchy) r
ON p.RegionName = r.RegionName
WHERE p.RegionID IS NULL

--- SUM all the values up in case duples in the file. You never know!
SELECT 
RegionID,
POSalePK,
MonthNumber,
SUM(RMD) RMD,
SUM(NRN) NRN,
SUM(NP) NP
INTO #PlanData
FROM ##PlanData
GROUP BY
RegionID,
POSalePK,
MonthNumber


SELECT
f.*,
CONVERT(FLOAT,f.FC_Factor)/CONVERT(FLOAT,r.FC_Factor) RMDf,
CONVERT(FLOAT,f.FC_Factor)/CONVERT(FLOAT,r.FC_Factor) NRNf
INTO #Factors
FROM  dbo.PlanTool_GMM_ForecastPro_Factors f 
JOIN (
SELECT 
RegionID,
FC_Month,
Metric,
SUM(CONVERT(FLOAT,FC_Factor)) FC_Factor
FROM dbo.PlanTool_GMM_ForecastPro_Factors 
GROUP BY RegionID,FC_Month,Metric
) r
ON r.RegionID = f.RegionID AND r.FC_Month = f.FC_Month AND f.Metric = r.Metric


TRUNCATE TABLE dbo.PlanTool_GMM_PlanDataStaging
INSERT INTO dbo.PlanTool_GMM_PlanDataStaging
SELECT 
DISTINCT
f.MMAID,
ISNULL(p.POSalePK,-1) POSalePK,
MonthNumber,
RMD * (CASE f.Metric WHEN 'RMD' THEN RMDf ELSE 0 END) RMD,
NRN * (CASE f.Metric WHEN 'NRN' THEN NRNf ELSE 0 END) NRN,
NP *  (CASE f.Metric WHEN 'RMD' THEN RMDf ELSE 0 END) NP
FROM   #PlanData p 
JOIN #Factors f ON p.RegionID = f.RegionID AND p.MonthNumber = f.FC_Month


/*
SELECT 
SuperRegionName,
RegionName,
SUM(PlanRMD) RMD,
SUM(PlanNRN) NRN,
SUM(PlanNP) NP
FROM dbo.PlanTool_GMM_PlanDataStaging p
JOIN (SELECT DISTINCT MMAID,SuperRegionName,RegionName FROM dbo.KPI_GMM_VIP_Hierarchy) h
ON p.MMAID = h.MMAID
WHERE p.Month BETWEEN 4 AND 6
GROUP BY SuperRegionName,RegionNAme
*/