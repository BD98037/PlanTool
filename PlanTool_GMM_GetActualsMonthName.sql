USE [SSATools]
GO
/****** Object:  StoredProcedure [dbo].[PlanTool_GMM_GetActualsMonthName]    Script Date: 05/01/2015 10:00:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[PlanTool_GMM_GetActualsMonthName]
AS
SELECT TOP 1  
'Q'+ CONVERT(Varchar(1),DATEPART(Quarter,QrtBeginDate)) + ' ' + CONVERT(Varchar(4),YEAR(QrtBeginDate)) QrtBeginDate,
'Q'+ CONVERT(Varchar(1),DATEPART(Quarter,LastQrtBeginDate)) + ' ' + CONVERT(Varchar(4),YEAR(LastQrtBeginDate)) LastQrtBeginDate,
DATENAME(MONTH,LastMonthBeginDate) + ' ' + CONVERT(Varchar(4),YEAR(LastMonthBeginDate)) LastMonthBeginDate

FROM dbo.vPlanTool_GMM_AggregatedActualsForPlanTool