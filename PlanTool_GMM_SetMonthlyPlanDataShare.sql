USE [SSATools]
GO
/****** Object:  StoredProcedure [dbo].[PlanTool_GMM_SetMonthlyPlanDataShare]    Script Date: 05/01/2015 10:03:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[PlanTool_GMM_SetMonthlyPlanDataShare] 

AS 


SELECT DISTINCT Month,
			CASE WHEN Month IN (1,2,3) THEN 1 WHEN Month IN (4,5,6) THEN 2 WHEN Month IN (7,8,9) THEN 3 WHEN Month IN (10,11,12) THEN 4 END Qrt,
			1.0/3.0 PlanRMDShare,
			1.0/3.0 PlanNPShare,
			1.0/3.0 PlanNRNShare
INTO #AvailableMonths			
	FROM dbo.PlanTool_GMM_PlanDataStaging

SELECT DISTINCT 
h.MMAID,h.RegionID,
Month,
PlanRMDShare,
PlanNPShare,
PlanNRNShare
INTO #MMAs
	FROM KPI_GMM_VIP_Hierarchy h
	CROSS JOIN #AvailableMonths
	WHERE h.MMAID>0

TRUNCATE TABLE dbo.PlanTool_GMM_MonthlyPlanDataShare
INSERT INTO dbo.PlanTool_GMM_MonthlyPlanDataShare

SELECT
h.MMAID,
--p.posalepk,
h.Month,
CASE WHEN ISNULL(ps.PlanRMD,0) = 0 THEN h.PlanRMDShare ELSE p.PlanRMD/ps.PlanRMD END  PlanRMDShare,
CASE WHEN ISNULL(ps.PlanNP,0) = 0 THEN  h.PlanNPShare ELSE p.PlanNP/ps.PlanNP END   PlanNPShare,
CASE WHEN ISNULL(ps.PlanNRN,0) = 0 THEN h.PlanNRNShare ELSE p.PlanNRN/ps.PlanNRN END PlanNRNShare	

FROM #MMAs h
LEFT JOIN (SELECT MMAID,Month
					,SUM(PlanRMD) as PlanRMD,SUM(PlanNP) as PlanNP
						,SUM(PlanNRN) as PlanNRN FROM  dbo.PlanTool_GMM_PlanDataStaging 
						Group by MMAID,Month
						) p ON h.MMAID = p.MMAID AND h.Month = p.Month-- this is the original total by month

LEFT JOIN (SELECT MMAID
					,CASE WHEN Month IN (1,2,3) THEN 'Q1' WHEN Month IN (4,5,6) THEN 'Q2' WHEN Month IN (7,8,9) THEN 'Q3' WHEN Month IN (10,11,12) THEN 'Q4' END AS Qrt,
							SUM(PlanRMD) as PlanRMD,SUM(PlanNP) as PlanNP,SUM(PlanNRN) as PlanNRN 
					FROM  dbo.PlanTool_GMM_PlanDataStaging 
					Group By MMAID
							,CASE WHEN Month IN (1,2,3) THEN 'Q1' WHEN Month IN (4,5,6) THEN 'Q2' WHEN Month IN (7,8,9) THEN 'Q3' WHEN Month IN (10,11,12) THEN 'Q4' END
										) ps -- this is the original total by quarter
ON p.MMAID = ps.MMAID 
AND ps.Qrt = CASE WHEN p.Month IN (1,2,3) THEN 'Q1' WHEN p.Month IN (4,5,6) THEN 'Q2' WHEN p.Month IN (7,8,9) THEN 'Q3' WHEN p.Month IN (10,11,12) THEN 'Q4' END

