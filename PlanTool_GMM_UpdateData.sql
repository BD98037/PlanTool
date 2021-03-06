USE [SSATools]
GO
/****** Object:  StoredProcedure [dbo].[PlanTool_GMM_UpdateData]    Script Date: 05/01/2015 10:03:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[PlanTool_GMM_UpdateData]
@UserEmail Varchar(80) = 'bdoan',
@MMAID int =93682,
@Qrt Varchar(4) = 'Q1',
@AdjustedRMD Varchar(20) = '-50000',
@AdjustedNRN Varchar(20) = '-50000',
@AdjustBy int = 0
AS
set implicit_transactions off 

IF(@AdjustBy=0) -- RMD
	BEGIN
		UPDATE dbo.PlanTool_GMM_PlanData
		SET AdjustedRMD = @AdjustedRMD
		WHERE MMAID = @MMAID AND Qrt = Right(@Qrt,1)

		--step 1
		UPDATE dbo.PlanTool_GMM_PlanData
		SET 
		NewPlanNP = CASE WHEN ISNULL(AdjustedRMD,0) = 0 THEN PlanNP ELSE (AdjustedRMD + ISNULL(PlanRMD,0)) / ABS(PlanRMP) END,
		NewPlanRMD = (ISNULL(AdjustedRMD,0) + ISNULL(PlanRMD,0)),
		NewPlanNRN = CASE WHEN ISNULL(AdjustedRMD,0) = 0 THEN PlanNRN ELSE ((ISNULL(AdjustedRMD,0) + ISNULL(PlanRMD,0)) / ABS(PlanRMP)) /ABS(PlanADR) END,
		ChangedBy = @UserEmail,
		ChangedDate = GETDATE(),
		AdjustMetric= @AdjustBy
		WHERE MMAID = @MMAID  AND Qrt = Right(@Qrt,1)
	END
ELSE IF(@AdjustBy=1) -- NRN
	BEGIN
		UPDATE dbo.PlanTool_GMM_PlanData
		SET AdjustedNRN = @AdjustedNRN
		WHERE MMAID = @MMAID AND Qrt = Right(@Qrt,1)

		UPDATE dbo.PlanTool_GMM_PlanData
		SET 
		NewPlanNP = CASE WHEN ISNULL(AdjustedNRN,0) = 0 THEN PlanNP ELSE (ISNULL(PlanNRN,0) + ISNULL(AdjustedNRN,0)) * ABS(CONVERT(FLOAT,PlanADR)) END,
		NewPlanRMD =  CASE WHEN ISNULL(AdjustedNRN,0) = 0 THEN PlanRMD ELSE (ISNULL(PlanNRN,0) + ISNULL(AdjustedNRN,0)) * ABS(PlanADR) * ABS(PlanRMP) END,
		NewPlanNRN =  (ISNULL(PlanNRN,0) + ISNULL(AdjustedNRN,0)),
		ChangedBy = @UserEmail,
		ChangedDate = GETDATE(),
		AdjustMetric= @AdjustBy
		WHERE MMAID = @MMAID AND Qrt = Right(@Qrt,1)
	END
ELSE IF(@AdjustBy=2) -- Both
	BEGIN
		UPDATE dbo.PlanTool_GMM_PlanData
		SET AdjustedNRN = @AdjustedNRN,
			AdjustedRMD = @AdjustedRMD
		WHERE MMAID = @MMAID AND Qrt = Right(@Qrt,1)

		UPDATE dbo.PlanTool_GMM_PlanData
		SET 
		NewPlanNP =CASE WHEN ISNULL(AdjustedNRN,0) = 0 AND ISNULL(AdjustedRMD,0) = 0 THEN PlanNP
							ELSE (ISNULL(AdjustedRMD,0) + ISNULL(PlanRMD,0)) / ABS(PlanRMP) END,
						 --WHEN ISNULL(AdjustedNRN,0) = 0 THEN (ISNULL(AdjustedRMD,0) + ISNULL(PlanRMD,0)) / ABS(PlanRMP) 
						 --ELSE (ISNULL(PlanNRN,0) + ISNULL(AdjustedNRN,0)) * ABS(PlanADR) END,
		NewPlanRMD =  (ISNULL(AdjustedRMD,0) + ISNULL(PlanRMD,0)),
		NewPlanNRN =  (ISNULL(PlanNRN,0) + ISNULL(AdjustedNRN,0)),
		ChangedBy = @UserEmail,
		ChangedDate = GETDATE(),
		AdjustMetric= @AdjustBy
		WHERE MMAID = @MMAID AND Qrt = Right(@Qrt,1)
	END

--select * from dbo.PlanForecast where ChangedBy ='bdoan'