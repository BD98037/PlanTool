USE [SSATools]
GO
/****** Object:  StoredProcedure [dbo].[PlanTool_GMM_ConsolidatePlanData]    Script Date: 05/01/2015 09:54:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[PlanTool_GMM_ConsolidatePlanData] 
AS 

TRUNCATE TABLE GMM_PlanDataByMMA;



--get new MMAs
SELECT DISTINCT MMAID,RegionID
INTO #MMA
	FROM KPI_GMM_VIP_Hierarchy WHERE MMAID>0

--get new plan data
SELECT
p2.RegionID,
p2.MMAID,
p.Month,
p2.Qrt,
CASE WHEN ISNULL(NewPlanRMD,0) =0 THEN PlanRMD ELSE NewPlanRMD END * p.PlanRMDShare PlanRMD,
CASE WHEN ISNULL(NewPlanNP,0) =0 THEN PlanNP ELSE NewPlanNP END  * p.PlanNPShare   PlanNP,
CASE WHEN ISNULL(NewPlanNRN,0) =0 THEN PlanNRN ELSE NewPlanNRN END * p.PlanNRNShare PlanNRN
INTO #PlanData
FROM dbo.PlanTool_GMM_PlanData p2 -- this is the new p
JOIN dbo.PlanTool_GMM_MonthlyPlanDataShare p
ON p.MMAID = p2.MMAID
AND p2.Qrt = CASE WHEN p.Month IN (1,2,3) THEN 1 WHEN p.Month IN (4,5,6) THEN 2 WHEN p.Month IN (7,8,9) THEN 3 WHEN p.Month IN (10,11,12) THEN 4 END

-- get the original plan by posales by mma to calculate the posales share
SELECT
m.RegionID,
p.MMAID,
p.Month,
p.POSalePK,
SUM(p.PlanRMD) PlanRMD,
SUM(p.PlanNP) PlanNP,
SUM(p.PlanNRN) PlanNRN
INTO #OriginalPlanByPOSa
FROM PlanTool_GMM_PlanDataStaging p
JOIN #MMA m ON p.MMAID = m.MMAID
GROUP BY
m.RegionID,
p.MMAID,
p.POSalePK,
p.Month

-- get the original plan by mma to calculate the posales share
SELECT 
MMAID,
Month,
SUM(PlanRMD) PlanRMD,
SUM(PlanNP) PlanNP,
SUM(PlanNRN) PlanNRN
INTO #OriginalPlanByMMA
FROM #OriginalPlanByPOSa p
GROUP BY
MMAID,
Month

-- calculate the posales share
SELECT
m.RegionID,
n.MMAID,
n.Month,
o.POSalePK,
CASE WHEN n.PlanRMD = 0 THEN 0 ELSE o.PlanRMD/n.PlanRMD END PlanRMDShare,
CASE WHEN n.PlanNP = 0 THEN 0 ELSE o.PlanNP/n.PlanNP END PlanNPShare,
CASE WHEN n.PlanNRN = 0 THEN 0 ELSE o.PlanNRN/n.PlanNRN END PlanNRNShare
INTO #PlanbyPOSalesShare
FROM #OriginalPlanByMMA n
JOIN #OriginalPlanByPOSa o ON n.MMAID = o.MMAID AND n.Month = o.Month
JOIN #MMA m On n.MMAID = m.MMAID

-- get all available POSales
SELECT DISTINCT RegionID,POSalePK,Month 
INTO #AvailPOSa 
FROM #PlanbyPOSalesShare

-- get all available POSales count by Region
SELECT DISTINCT RegionID,COUNT(DISTINCT POSalePK) POSaCnt,Month 
INTO #POSalesCntByRegion
FROM #PlanbyPOSalesShare GROUP BY Month,RegionID

-- this is all available POSales including the non forecasted MMAs
SELECT
m.RegionID,m.MMAID,a.Month,a.POSalePK,
1.0/r.POSaCnt PlanRMDShare,
1.0/r.POSaCnt PlanNPShare,
1.0/r.POSaCnt PlanNRNShare
INTO #AvailPOSaShare
FROM #MMA m
JOIN #AvailPOSa a  ON m.RegionID = a.RegionID --AND a.Month = s.Month AND a.POSalePK = s.POSalePK
JOIN #POSalesCntByRegion r ON a.RegionID = r.RegionID AND a.Month = r.Month

--Compile the plan data by POSales
SELECT 
p.RegionID,
p.MMAID,
p.Month,
p.Qrt,
ISNULL(pos.POSalePK,apos.POSalePK) POSalePK,
p.PlanRMD*ISNULL(pos.PlanRMDShare,apos.PlanRMDShare) PlanRMD,
p.PlanNP*ISNULL(pos.PlanNPShare,apos.PlanRMDShare) PlanNP,
p.PlanNRN*ISNULL(pos.PlanNRNShare,apos.PlanRMDShare) PlanNRN
INTO #PlanDataByPOSa
FROM #PlanData p
LEFT JOIN #PlanbyPOSalesShare pos ON p.MMAID = pos.MMAID AND p.Month = pos.Month 
LEFT JOIN #AvailPOSaShare apos ON p.MMAID = apos.MMAID AND p.Month = apos.Month 

-- get original data for normalizing purposes
SELECT 
RegionID,
Month,
SUM(PlanRMD) PlanRMD,
SUM(PlanNP) PlanNP,
SUM(PlanNRN) PlanNRN
INTO #RegionalOriginalPlan
FROM #OriginalPlanByPOSa p
GROUP BY
RegionID,
Month

-- get new plan data for data normalize purposes
SELECT 
RegionID,
Month,
SUM(PlanRMD) PlanRMD,
SUM(PlanNP) PlanNP,
SUM(PlanNRN) PlanNRN
INTO #RegionalNewPlan
FROM #PlanDataByPOSa
GROUP BY
RegionID,
Month

-- calculate the vars
SELECT
n.RegionID,
n.Month,
CASE WHEN n.PlanRMD = 0 THEN 1 ELSE o.PlanRMD/n.PlanRMD END PlanRMDVar,
CASE WHEN n.PlanNP = 0 THEN 1 ELSE o.PlanNP/n.PlanNP END PlanNPVar,
CASE WHEN n.PlanNRN = 0 THEN 1 ELSE o.PlanNRN/n.PlanNRN END PlanNRNVar
INTO #OriginalAndNewVar
FROM #RegionalNewPlan n
JOIN #RegionalOriginalPlan o ON n.RegionID = o.RegionID AND n.Month = o.Month

-- normalize the data to match to the original
SELECT
p.MMAID,
p.Month,
p.Qrt,
p.POSalePK,
p.PlanRMD*PlanRMDVar PlanRMD,
p.PlanNP*PlanNPVar PlanNP,
p.PlanNRN*PlanNRNVar PlanNRN
INTO #NormalizedRegionalPlanData
FROM #PlanDataByPOSa p
JOIN #OriginalAndNewVar ps 
ON p.RegionID = ps.RegionID AND p.Month = ps.Month

-- get the new plan for normalizing at mma level
SELECT 
MMAID,
Qrt,
CASE WHEN ISNULL(NewPlanRMD,0) =0 THEN PlanRMD ELSE NewPlanRMD END PlanRMD,
CASE WHEN ISNULL(NewPlanNP,0) =0 THEN PlanNP ELSE NewPlanNP END PlanNP,
CASE WHEN ISNULL(NewPlanNRN,0) =0 THEN PlanNRN ELSE NewPlanNRN END PlanNRN
INTO #QuarterlyMMAbyPlanTool
FROM dbo.PlanTool_GMM_PlanData 

-- get the normalized plan for normalizing at mma level
SELECT 
MMAID,
Qrt,
SUM(PlanRMD) PlanRMD,
SUM(PlanNP) PlanNP,
SUM(PlanNRN) PlanNRN
INTO #QuarterlyMMANewPlan
FROM #NormalizedRegionalPlanData
GROUP BY
MMAID,
Qrt

-- calculate the vars at mma level
SELECT
n.MMAID,
n.Qrt,
CASE WHEN n.PlanRMD = 0 THEN 0 ELSE o.PlanRMD/n.PlanRMD END PlanRMDVar,
CASE WHEN n.PlanNP = 0 THEN 0 ELSE o.PlanNP/n.PlanNP END PlanNPVar,
CASE WHEN n.PlanNRN = 0 THEN 0 ELSE o.PlanNRN/n.PlanNRN END PlanNRNVar
INTO #PlanToolAndNewVar
FROM #QuarterlyMMANewPlan n
JOIN #QuarterlyMMAbyPlanTool o ON n.MMAID = o.MMAID AND n.Qrt = o.Qrt

-- normalize the data at mma level to match with what in the tool
INSERT INTO GMM_PlanDataByMMA
SELECT
p.MMAID,
p.Month,
p.POSalePK,
p.PlanRMD*PlanRMDVar PlanRMD,
p.PlanNP*PlanNPVar PlanNP,
p.PlanNRN*PlanNRNVar PlanNRN

FROM #NormalizedRegionalPlanData p
JOIN #PlanToolAndNewVar ps 
ON p.MMAID = ps.MMAID AND p.Qrt = ps.Qrt

