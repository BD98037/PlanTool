USE [SSATools]
GO
/****** Object:  StoredProcedure [dbo].[PlanTool_GMM_SetData]    Script Date: 05/01/2015 10:02:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[PlanTool_GMM_SetData]
AS

/*
Run these sprocs on chc12 first
[dbo].[SetSIP_DailyProductionByHotel]
[dbo].[GMM_SetAggregatedActualsForPlanTool]
[dbo].[GMM_SetMonthlyActualsForPlanToolReporting]
*/

TRUNCATE TABLE dbo.PlanTool_GMM_PlanData
INSERT INTO dbo.PlanTool_GMM_PlanData
SELECT
m.RegionID,
m.AMTID,
m.MMAID,
Qrt,
--Current Quarter
SUM(convert(float,t.PlanNP)) AS PlanNP,
SUM(convert(float,t.PlanRMD)) AS PlanRMD,
SUM(convert(float,t.PlanNRN)) AS PlanNRN,
CASE WHEN SUM(convert(float,t.PlanNRN)) = 0 THEN 0 ELSE SUM(convert(float,t.PlanNP))/ SUM(convert(float,t.PlanNRN)) END AS PlanADR,
CASE WHEN SUM(convert(float,t.PlanNP)) = 0 THEN 0 ELSE SUM(convert(float,t.PlanRMD)) / SUM(convert(float,t.PlanNP)) END AS PlanRMP,
NULL  AS AdjustedNP,
NULL  AS AdjustedRMD,
NULL  AS AdjustedNRN,
NULL  AS NewPlanNP,
NULL  AS NewPlanRMD,
NULL  AS NewPlanNRN,
ISNULL(SUM(convert(float,p.LYACTUALNP)),0) AS lyActualNP,
ISNULL(SUM(convert(float,p.LYACTUALRMD)),0) AS lyActualRMD,
ISNULL(SUM(convert(float,p.LYACTUALNRN)),0) As lyActualNRN,
--Last Quarter
ISNULL(SUM(convert(float,p.CYACTUALNPlq)),0) AS cyActualNPlq,
ISNULL(SUM(convert(float,p.CYACTUALRMDlq)),0) AS cyActualRMDlq,
ISNULL(SUM(convert(float,p.CYACTUALNRNlq)),0) As cyActualNRNlq,
ISNULL(SUM(convert(float,p.LYACTUALNPlq)),0) AS lyActualNPlq,
ISNULL(SUM(convert(float,p.LYACTUALRMDlq)),0) AS lyActualRMDlq,
ISNULL(SUM(convert(float,p.LYACTUALNRNlq)),0) As lyActualNRNlq,
--Last Month
ISNULL(SUM(convert(float,p.CYACTUALNPlm)),0) AS cyActualNPlm,
ISNULL(SUM(convert(float,p.CYACTUALRMDlm)),0) AS cyActualRMDlm,
ISNULL(SUM(convert(float,p.CYACTUALNRNlm)),0) As cyActualNRNlm,
ISNULL(SUM(convert(float,p.LYACTUALNPlm)),0) AS lyActualNPlm,
ISNULL(SUM(convert(float,p.LYACTUALRMDlm)),0) AS lyActualRMDlm,
ISNULL(SUM(convert(float,p.LYACTUALNRNlm)),0) As lyActualNRNlm,
'Admin' As ChangedBy,
GETDATE() As ChangedDate,
NULL As AdjustMetric,
QrtBeginDate,
LastQrtBeginDate,
LastMonthBeginDate

FROM (SELECT DISTINCT MMAID,AMTID,RegionID,SuperRegionID FROM KPI_GMM_VIP_Hierarchy WHERE ISNULL(RegionID,0)>0 AND MMAID>0) m 
LEFT JOIN dbo.vPlanTool_GMM_AggregatedActualsForPlanTool p 
on m.MMAID = p.MMAID 
LEFT JOIN (SELECT CASE WHEN Month IN (1,2,3) THEN 1 
					WHEN Month IN (4,5,6) THEN 2
					WHEN Month IN (7,8,9) THEN 3
					WHEN Month IN (10,11,12) THEN 4 END Qrt,
			 MMAID,
			 SUM(convert(float,PlanRMD)) As PlanRMD, SUM(convert(float,PlanNP)) As PlanNP, SUM(convert(float,PlanNRN)) As PlanNRN 
			FROM dbo.PlanTool_GMM_PlanDataStaging
			GROUP BY
			CASE WHEN Month IN (1,2,3) THEN 1 
					WHEN Month IN (4,5,6) THEN 2
					WHEN Month IN (7,8,9) THEN 3
					WHEN Month IN (10,11,12) THEN 4 END,
					MMAID) t -- newly plan
on p.MMAID = t.MMAID

GROUP BY 
m.RegionID,
m.AMTID,
m.MMAID,
t.Qrt,
QrtBeginDate,
LastQrtBeginDate,
LastMonthBeginDate

UPDATE dbo.PlanTool_GMM_PlanData
SET Qrt = (SELECT MIN(Qrt) Qrt FROM dbo.PlanTool_GMM_PlanData)
WHERE Qrt IS NULL

UPDATE p
SET PlanADR = CASE WHEN ISNULL(PlanADR,0) = 0 THEN r.PlanNP/r.PlanNRN ELSE p.PlanADR END,
	PlanRMP = CASE WHEN ISNULL(PlanRMP,0) = 0 THEN r.PlanRMD/r.PlanNP ELSE p.PlanRMP END
FROM dbo.PlanTool_GMM_PlanData p
JOIN
(SELECT AMTID,Qrt,SUM(PlanNP) PlanNP,SUM(PlanRMD) PlanRMD,SUM(PlanNRN) PlanNRN
	FROM dbo.PlanTool_GMM_PlanData
	GROUP BY AMTID,Qrt) r
ON p.AMTID = r.AMTID AND p.Qrt = r.Qrt

		
/*
SELECT 
SuperRegionName,
RegionNAme,
sum(planrmd) RMD,Sum(PlanNRN), SUM(PlanNP) NP
FROM (SELECT DISTINCT MMAID,AMTID,RegionID,SuperRegionID,RegionName,SuperRegionName FROM KPI_GMM_VIP_Hierarchy) m 
JOIN dbo.PlanTool_GMM_PlanData p 
on m.MMAID = p.MMAID 
WHERE  qrt=2
GROUP BY 
SuperRegionName,
RegionNAme
order by 2
*/

