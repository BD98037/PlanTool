USE [SSATools]
GO
/****** Object:  StoredProcedure [dbo].[PlanTool_GMM_UpdateDataStep2]    Script Date: 05/01/2015 10:04:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[PlanTool_GMM_UpdateDataStep2]
@RegionID int =101196,
@Qrt Varchar(4) = 'Q2',
@AdjustBy int = 1
AS
set implicit_transactions off 

--step 2
Declare @TotalRMD int,@TotalNP int, @TotalNRN int,@NewTotalRMD int,@NewTotalNP int, @NewTotalNRN int

IF(@AdjustBy=0)
BEGIN

Select  @TotalRMD = SUM(PlanRMD) ,@TotalNP = SUM(PlanNP), @TotalNRN = SUM(PlanNRN),
		 @NewTotalRMD = SUM(NewPlanRMD) ,@NewTotalNP = SUM(NewPlanNP), @NewTotalNRN = SUM(NewPlanNRN)
	From dbo.PlanTool_GMM_PlanData WHere RegionID = @RegionID And Qrt = Right(@Qrt,1) And Isnull(AdjustedRMD,0) <>0
	
	
--Update the raw metrics
UPDATE dbo.PlanTool_GMM_PlanData
SET 
NewPlanNP = CASE WHEN ISNULL(AdjustedRMD,0) = 0 THEN PlanNP ELSE @TotalNP*(Convert(float,NewPlanNP)/Convert(float,@NewTotalNP)) END ,
NewPlanNRN =  CASE WHEN ISNULL(AdjustedRMD,0) = 0 THEN PlanNRN ELSE @TotalNRN*(Convert(float,NewPlanNRN)/Convert(float,@NewTotalNRN)) END,
NewPlanRMD = ISNULL(PlanRMD,0) + ISNULL(AdjustedRMD,0)

WHERE RegionID = @RegionID And Qrt = Right(@Qrt,1)
END

ELSE IF(@AdjustBy=1)
BEGIN

Select  @TotalRMD = SUM(PlanRMD) ,@TotalNP = SUM(PlanNP), @TotalNRN = SUM(PlanNRN),
		 @NewTotalRMD = SUM(NewPlanRMD) ,@NewTotalNP = SUM(NewPlanNP), @NewTotalNRN = SUM(NewPlanNRN)
	From dbo.PlanTool_GMM_PlanData WHere RegionID = @RegionID And Qrt = Right(@Qrt,1) And Isnull(AdjustedNRN,0) <>0
	
	
--Update the raw metrics	
UPDATE dbo.PlanTool_GMM_PlanData
SET 
NewPlanNP = CASE WHEN ISNULL(AdjustedNRN,0) = 0 THEN PlanNP ELSE  @TotalNP*(Convert(float,NewPlanNP)/Convert(float,@NewTotalNP)) END ,
NewPlanRMD =  CASE WHEN ISNULL(AdjustedNRN,0) = 0 THEN PlanRMD ELSE  @TotalRMD*(Convert(float,NewPlanRMD)/Convert(float,@NewTotalRMD)) END,
NewPlanNRN = ISNULL(PlanNRN,0) + ISNULL(AdjustedNRN,0)
WHERE RegionID = @RegionID And Qrt = Right(@Qrt,1)

END

--both RMD & NRN
ELSE IF(@AdjustBy=2)
BEGIN	
--Update the raw metrics	
UPDATE dbo.PlanTool_GMM_PlanData
SET 
NewPlanNP = CASE WHEN ISNULL(AdjustedNRN,0) = 0 AND ISNULL(AdjustedRMD,0) = 0 THEN PlanNP
							ELSE (ISNULL(AdjustedRMD,0) + ISNULL(PlanRMD,0)) / ABS(PlanRMP) END,
NewPlanRMD =  ISNULL(PlanRMD,0) + ISNULL(AdjustedRMD,0),
NewPlanNRN = ISNULL(PlanNRN,0) + ISNULL(AdjustedNRN,0)
WHERE RegionID = @RegionID And Qrt = Right(@Qrt,1)

END




--select * from dbo.PlanForecast where ChangedBy ='bdoan'