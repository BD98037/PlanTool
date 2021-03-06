USE [SSATools]
GO
/****** Object:  StoredProcedure [dbo].[PlanTool_GMM_rptGetPlanMarketAdjustments]    Script Date: 05/01/2015 10:02:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[PlanTool_GMM_rptGetPlanMarketAdjustments] @Regions Varchar(4000),@Qrt Varchar(2) 

--[dbo].[GetPlanMarketAdjustments] 101740,'Q1'

AS 

CREATE TABLE #Regions (RegionID int)

INSERT INTO #Regions(RegionID)
SELECT [STR] AS ID  FROM Common.dbo.charlist_to_table(@Regions,Default)

SELECT
s.*,
PlanRMD OriginalRMD,
AdjustedRMD AS AdjustmentRMD,
NewPlanRMD NewRMD,
PlanNRN OriginalNRN,
AdjustedNRN AS AdjustmentNRN,
NewPlanNRN NewNRN,
PlanNP OriginalNP,
AdjustedNP AS AdjustmentNP,
NewPlanNP NewNP,
CASE AdjustMetric WHEN 0 THEN 'RMD' WHEN 1 THEN 'NRN' WHEN 2 THEN 'Both RMD & NRN' ELSE 'No Adjustment' END AdjustedMetric,
CASE WHEN AdjustMetric IS NOT NULL THEN ChangedBy END ChangedBy,
CASE WHEN AdjustMetric IS NOT NULL THEN ChangedDate END ChangedDate

FROM dbo.PlanTool_GMM_PlanData p
JOIN (SELECT DISTINCT
	   [MMAID]
      ,[MMAName]
      ,[AMTID]
      ,[AMTName]
      ,[RegionID]
      ,NULL [SMTID]
      ,NULL [SMTName]
      ,[SuperRegionID]
      ,[SuperRegionName]
      ,[RegionName]
  FROM dbo.KPI_GMM_VIP_Hierarchy) s
ON p.MMAID = s.MMAID
JOIN #Regions r
ON s.RegionID = r.RegionID
WHERE Qrt = RIGHT(@Qrt,1)

