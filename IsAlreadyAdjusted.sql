USE [SSATools]
GO
/****** Object:  StoredProcedure [dbo].[IsAlreadyAdjusted]    Script Date: 05/01/2015 11:20:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[IsAlreadyAdjusted]
@RegionID int =101740,
@Qrt Varchar(4) ='Q1',
@AdjustBy int =1

AS

SET NOCOUNT ON

Declare @AdjustMetric int 

SELECT Top 1 @AdjustMetric =convert(int,AdjustMetric )
FROM dbo.PlanTool_GMM_PlanData
WHERE RegionID = @RegionID And Qrt = Right(@Qrt,1)  And AdjustMetric in (0,1,2)

IF(ISNULL(@AdjustMetric,3) <>3 AND @AdjustMetric<>@AdjustBy AND @AdjustBy>=0)
SELECT 'Y' AlreadyAdjustedValue
--ELSE SELECT 'N' AlreadyAdjustedValue
	
	

		