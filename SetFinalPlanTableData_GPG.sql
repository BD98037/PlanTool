USE [SSATools]
GO
/****** Object:  StoredProcedure [dbo].[SetFinalPlanTableData_GPG]    Script Date: 05/01/2015 10:07:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[SetFinalPlanTableData_GPG] 
AS 

-- Drop temp tables if exist
IF OBJECT_ID('tempdb..##PlanTableTempDailyGPG') IS NOT NULL
   DROP TABLE ##PlanTableTempDailyGPG
   
--allocate to final format: daily and posales
SELECT DISTINCT
     h.SuperRegionID
	,h.RegionID
	,p.ParentChainID
	,p.MonthNumber
	,d.bookingdate
    ,Convert(float,p.[RMD]) * (case when d.rmdregion>0 then convert(float,d.rmd)/convert(float,d.rmdregion) else 0 end) as PlanRMD
    ,Convert(float,p.[NP]) * (case when d.rmdregion>0 then convert(float,d.rmd)/convert(float,d.rmdregion) else 0 end) as PlanNP
    ,Convert(float,p.[NRN]) * (case when d.rmdregion>0 then convert(float,d.rmd)/convert(float,d.rmdregion) else 0 end) as PlanNRN
	,common.dbo.GetQtrBegin(GETDATE()) as snapshotDate	
INTO ##PlanTableTempDailyGPG 
FROM (SELECT DISTINCT RegionID,RegionName,SuperRegionID,SuperRegionName FROM KPI_GMM_VIP_Hierarchy) h	
INNER JOIN ##PlanDataGPG p -- this is the new p
ON h.RegionID = p.RegionID
JOIN dbo.DailyFactors_GPG d
on d.RegionID = p.[RegionID]
and Month = p.MonthNumber



	
/*	


select h.superregionname,h.regionname,monthnumber,parentchainName
	,sum(PlanNP) as PlanNB
    ,sum(PlanRMD) as PlanRMD
    ,sum([PLanNRN]) as PlanNRN
from  ##PlanTableTempDailyGPG p
JOIN (SELECT DISTINCT RegionID,RegionName,SuperRegionID,SuperRegionName FROM KPI_GMM_VIP_Hierarchy) h	
ON h.regionID = p.regionID
JOIN (SELECT DISTINCT ParentChainID,ParentChainName
			FROM [chc-sqlpsg12].Mirror.GPCMaster.DimHotelExpand WHERE MarketID > 0 and ExpediaID>0) pc
ON p.[ParentChainID] = pc.ParentChainID
where monthnumber >3
group by
h.superregionname,h.regionname,monthnumber,parentchainname
order by h.superregionname

DELETE FROM dbo.PlanTableParentChain WHERE Month>3

INSERT INTO dbo.PlanTableParentChain
SELECT 
SuperRegionID,
RegionID,
ParentChainID,
MonthNumber,
BookingDate,
PlanRMD,
PlanNP,
PlanNRN,
snapshotDate
FROM ##PlanTableTempDailyGPG 
WHERE MonthNumber>3
*/
