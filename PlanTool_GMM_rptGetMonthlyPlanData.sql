USE [SSATools]
GO
/****** Object:  StoredProcedure [dbo].[PlanTool_GMM_rptGetMonthlyPlanData]    Script Date: 05/01/2015 10:02:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[PlanTool_GMM_rptGetMonthlyPlanData] 
@RegionID int,
@Qrt Varchar(2) 
--[dbo].[PlanTool_GMM_rptGetMonthlyPlanData] 101740,'Q2'

AS 

SELECT DISTINCT MMAID,superregionid,superregionname,regionname,regionid,MMAName,AMTID,AMTName
INTO #MMAs
FROM dbo.KPI_GMM_VIP_Hierarchy where RegionID = @RegionID

SELECT
m.SuperRegionName,
m.RegionName,
m.MMAName,
m.AMTID,
m.AMTName,
m.SuperRegionID,
m.RegionID,
m.MMAID,
p.Month,
p2.Qrt,
CASE WHEN ISNULL(NewPlanRMD,0) =0 THEN PlanRMD ELSE NewPlanRMD END * PlanRMDShare PlanRMD,
CASE WHEN ISNULL(NewPlanNP,0) =0 THEN PlanNP ELSE NewPlanNP END  * PlanNPShare   PlanNP,
CASE WHEN ISNULL(NewPlanNRN,0) =0 THEN PlanNRN ELSE NewPlanNRN END * PlanNRNShare PlanNRN,
pt.ActualRMD AS LyActualRMD,
pt.ActualNRN AS LyActualNRN,
pt.ActualNP AS LyActualNB
INTO #DatabyMMA
FROM dbo.PlanTool_GMM_PlanData p2 -- this is the new p
INNER JOIN dbo.PlanTool_GMM_MonthlyPlanDataShare p
ON p.MMAID = p2.MMAID
AND p2.Qrt = CASE WHEN p.Month IN (1,2,3) THEN 1 WHEN p.Month IN (4,5,6) THEN 2 WHEN p.Month IN (7,8,9) THEN 3 WHEN p.Month IN (10,11,12) THEN 4 END
INNER JOIN #MMAs m
ON p.MMAID = m.MMAID
INNER JOIN dbo.PlanTool_GMM_MonthlyActualsData pt
ON pt.MMAID = p.MMAID
AND MONTH(convert(datetime,pt.Bookingmonth)) = p.Month --AND YEAR(convert(datetime,pt.Bookingmonth)) = YEAR(getdate())
WHERE Qrt=Right(@Qrt,1)


-- get new plan data for data normalize purposes
SELECT 
m.RegionID,
Month,
SUM(PlanRMD) PlanRMD,
SUM(PlanNP) PlanNP,
SUM(PlanNRN) PlanNRN
INTO #RegionalOriginalPlan
FROM PlanTool_GMM_PlanDataStaging p
JOIN #MMAs m ON p.MMAID = m.MMAID
GROUP BY
m.RegionID,
Month

-- get new plan data for data normalize purposes
SELECT 
RegionID,
Month,
SUM(PlanRMD) PlanRMD,
SUM(PlanNP) PlanNP,
SUM(PlanNRN) PlanNRN
INTO #RegionalNewPlan
FROM #DatabyMMA
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
p.SuperRegionName,
p.RegionName,
p.MMAName,
p.AMTID,
p.AMTName,
p.SuperRegionID,
p.RegionID,
p.MMAID,
p.Month,
p.Qrt,
p.LyActualRMD,
p.LyActualNRN,
p.LyActualNB,
p.PlanRMD*PlanRMDVar PlanRMD,
p.PlanNP*PlanNPVar PlanNP,
p.PlanNRN*PlanNRNVar PlanNRN
INTO #NormalizedRegionalPlanData
FROM #DatabyMMA p
JOIN #OriginalAndNewVar ps 
ON p.RegionID = ps.RegionID AND p.Month = ps.Month


--get the normalized plan for normalizing at mma level
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

-- get the new plan for normalizing at mma level
SELECT 
MMAID,
Qrt,
CASE WHEN ISNULL(NewPlanRMD,0) =0 THEN PlanRMD ELSE NewPlanRMD END PlanRMD,
CASE WHEN ISNULL(NewPlanNP,0) =0 THEN PlanNP ELSE NewPlanNP END PlanNP,
CASE WHEN ISNULL(NewPlanNRN,0) =0 THEN PlanNRN ELSE NewPlanNRN END PlanNRN
INTO #QuarterlyMMAbyPlanTool
FROM dbo.PlanTool_GMM_PlanData 

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
SELECT
p.SuperRegionName,
p.RegionName,
p.MMAName,
p.AMTID,
p.AMTName,
p.SuperRegionID,
p.RegionID,
p.MMAID,
p.Month,
p.Qrt,
p.LyActualRMD,
p.LyActualNRN,
p.LyActualNB,
p.PlanRMD*PlanRMDVar PlanRMD,
p.PlanNP*PlanNPVar PlanNP,
p.PlanNRN*PlanNRNVar PlanNRN

FROM #NormalizedRegionalPlanData p
JOIN #PlanToolAndNewVar ps 
ON p.MMAID = ps.MMAID AND p.Qrt = ps.Qrt
