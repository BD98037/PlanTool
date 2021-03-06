USE [SSATools]
GO
/****** Object:  StoredProcedure [dbo].[PlanTool_GMM_SetMonthlyActualsData]    Script Date: 05/01/2015 10:03:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

ALTER PROC [dbo].[PlanTool_GMM_SetMonthlyActualsData]

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

--Put into the final table
TRUNCATE TABLE dbo.PlanTool_GMM_MonthlyActualsData 
INSERT INTO dbo.PlanTool_GMM_MonthlyActualsData

SELECT
m.BookingMonth,
m.MMAID,
m.lyACTUALRMD,
m.lyACTUALNP,
m.lyACTUALNRN ,
m.[lyActualRMDRegion],
m.[lyActualNPRegion],
m.[lyActualNRNRegion],
r.RegionID
FROM [CHC-SQLPSG12].SSATOOLS.dbo.PlanTool_GMM_MonthlyActualsData m
JOIN (SELECT DISTINCT MMAID,RegionID,SuperRegionID FROM SSATools.dbo.KPI_GMM_VIP_Hierarchy) r
on m.MMAID = r.MMAID
