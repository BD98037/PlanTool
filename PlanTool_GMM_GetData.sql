USE [SSATools]
GO
/****** Object:  StoredProcedure [dbo].[PlanTool_GMM_GetData]    Script Date: 05/01/2015 10:01:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[PlanTool_GMM_GetData] 
@UserEmail Varchar(80) ='bdoan',
@RegionID INT =101740,
@Qrt Varchar(2) ='Q1',
@AdjustBy int = 1


AS

SET NOCOUNT ON

---if proceed even already adjusted once previously
CREATE TABLE #AlreadyAdjusted(AlreadyAdjustedValue Varchar(1))
INSERT INTO #AlreadyAdjusted
EXEC [dbo].[IsAlreadyAdjusted]
@RegionID,
@Qrt,
@AdjustBy

IF EXISTS (SELECT * FROM #AlreadyAdjusted WHERE AlreadyAdjustedValue ='Y')
BEGIN
UPDATE dbo.PlanTool_GMM_PlanData
SET 
AdjustedRMD = NULL,
AdjustedNRN =  NULL,
AdjustedNP = NULL,
NewPlanNP = NULL,
NewPlanNRN = NULL,
NewPlanRMD = NULL,
ChangedBy = @UserEmail,
ChangedDate = GETDATE(),
AdjustMetric= Null
WHERE RegionID = @RegionID AND Qrt=Right(@Qrt,1) --AND Adjustmetric = @AdjustBy
END

;
WITH PlanData
AS
(
-- Get GrandTotal
SELECT 
	   
	   s.[SuperRegionName]
      ,s.[SuperRegionID]
      ,s.[RegionName]
      ,s.[RegionID]
      ,'Grand Total' AMTName
      ,-1 AMTID
      ,' ' MMAName
      ,-1 MMAID
      ,[Qrt]
      --Original current quarter
      ,SUM(ISNULL([PlanNP],0)) PlanNP
      ,SUM(ISNULL([PlanRMD],0)) PlanRMD
      ,SUM(ISNULL([PlanNRN],0)) PlanNRN
      ,CASE WHEN SUM(ISNULL([PlanNRN],0)) = 0 THEN  NULL ELSE SUM(ISNULL(CAST([PlanNP]AS FLOAT),0))/SUM(ISNULL(CAST([PlanNRN]AS FLOAT),0)) END PlanADR
	  ,CASE WHEN SUM(ISNULL([PlanNP],0)) = 0 THEN NULL ELSE SUM(ISNULL([PlanRMD],0))/SUM(ISNULL([PlanNP],0)) END*100 PlanRMP
	  ,CASE WHEN SUM(ISNULL([lyActualNP],0)) = 0 THEN NULL ELSE (SUM(ISNULL([PlanNP],0))/SUM(ISNULL([lyActualNP],0)))-1 END*100 PlanNPYoY
	  ,CASE WHEN SUM(ISNULL([lyActualRMD],0)) = 0 THEN NULL ELSE (SUM(ISNULL([PlanRMD],0))/SUM(ISNULL([lyActualRMD],0)))-1 END*100 PlanRMDYoY
	  ,CASE WHEN SUM(ISNULL([lyActualNRN],0)) = 0 THEN NULL ELSE (SUM(ISNULL([PlanNRN],0))/SUM(ISNULL([lyActualNRN],0)))-1 END*100 PlanNRNYoY
	  ,CASE WHEN 
		CASE WHEN SUM(ISNULL([lyActualNRN],0)) = 0 THEN 0 ELSE SUM(ISNULL([lyActualNP],0))/SUM(ISNULL([lyActualNRN],0)) END = 0 THEN NULL 
	   ELSE 
			(CASE WHEN SUM(ISNULL([PlanNRN],0)) = 0 THEN  0 ELSE SUM(ISNULL([PlanNP],0))/SUM(ISNULL([PlanNRN],0)) END
			/
			CASE WHEN SUM(ISNULL([lyActualNRN],0)) = 0 THEN 0 ELSE SUM(ISNULL([lyActualNP],0))/SUM(ISNULL([lyActualNRN],0)) END)-1 END*100 PlanADRYoY
	  ,CASE WHEN CASE WHEN SUM(ISNULL([lyActualNP],0)) = 0 THEN 0 ELSE SUM(ISNULL([lyActualRMD],0))/SUM(ISNULL([lyActualNP],0)) END = 0 THEN NULL
	   ELSE
			(CASE WHEN SUM(ISNULL([PlanNP],0)) = 0 THEN NULL ELSE SUM(ISNULL([PlanRMD],0))/SUM(ISNULL([PlanNP],0)) END
			-
			CASE WHEN SUM(ISNULL([lyActualNP],0)) = 0 THEN NULL ELSE SUM(ISNULL([lyActualRMD],0))/SUM(ISNULL([lyActualNP],0)) END) END*10000 PlanRMPYoY
	 --New current quarter
      ,SUM(ISNULL([NewPlanNP],0)) NewPlanNP
      ,SUM(ISNULL([NewPlanRMD],0)) NewPlanRMD
      ,SUM(ISNULL([NewPlanNRN],0)) NewPlanNRN
      ,CASE WHEN SUM(ISNULL([NewPlanNRN],0)) = 0 THEN  NULL ELSE SUM(ISNULL(CAST([NewPlanNP] AS FLOAT),0))/SUM(ISNULL(CAST ([NewPlanNRN] AS FLOAT),0)) END NewPlanADR
	  ,CASE WHEN SUM(ISNULL([NewPlanNP],0)) = 0 THEN NULL ELSE SUM(ISNULL(CAST([NewPlanRMD] AS FLOAT),0))/SUM(ISNULL(CAST([NewPlanNP] AS FLOAT),0)) END*100 NewPlanRMP
	  ,CASE WHEN SUM(ISNULL([lyActualNP],0)) = 0 OR SUM(ISNULL([NewPlanNP],0)) = 0 THEN NULL ELSE (SUM(ISNULL([NewPlanNP],0))/SUM(ISNULL([lyActualNP],0)))-1 END*100 NewPlanNPYoY
	  ,CASE WHEN SUM(ISNULL([lyActualRMD],0)) = 0 OR SUM(ISNULL([NewPlanRMD],0)) = 0 THEN NULL ELSE (SUM(ISNULL([NewPlanRMD],0))/SUM(ISNULL([lyActualRMD],0)))-1 END*100 NewPlanRMDYoY
	  ,CASE WHEN SUM(ISNULL([lyActualNRN],0)) = 0 OR SUM(ISNULL([NewPlanNRN],0)) = 0 THEN NULL ELSE (SUM(ISNULL([NewPlanNRN],0))/SUM(ISNULL([lyActualNRN],0)))-1 END*100 NewPlanNRNYoY
	  ,CASE WHEN 
		CASE WHEN SUM(ISNULL([lyActualNRN],0)) = 0 THEN 0 ELSE SUM(ISNULL([lyActualNP],0))/SUM(ISNULL([lyActualNRN],0)) END = 0 
					OR CASE WHEN SUM(ISNULL([NewPlanNRN],0)) = 0 THEN  0 ELSE SUM(ISNULL([NewPlanNP],0))/SUM(ISNULL([NewPlanNRN],0))END= 0 THEN NULL 
	   ELSE 
			(CASE WHEN SUM(ISNULL([NewPlanNRN],0)) = 0 THEN  0 ELSE SUM(ISNULL([NewPlanNP],0))/SUM(ISNULL([NewPlanNRN],0)) END
			/
			CASE WHEN SUM(ISNULL([lyActualNRN],0)) = 0 THEN 0 ELSE SUM(ISNULL([lyActualNP],0))/SUM(ISNULL([lyActualNRN],0)) END)-1 END*100 NewPlanADRYoY
	  ,CASE WHEN CASE WHEN SUM(ISNULL([lyActualNP],0)) = 0 THEN 0 ELSE SUM(ISNULL(CAST([lyActualRMD] AS FLOAT),0))/SUM(ISNULL(CAST([lyActualNP] AS FLOAT),0)) END = 0 THEN NULL
	   ELSE
			(CASE WHEN SUM(ISNULL([NewPlanNP],0)) = 0 THEN NULL ELSE SUM(ISNULL(CAST([NewPlanRMD] AS FLOAT),0))/SUM(ISNULL(CAST([NewPlanNP] AS FLOAT),0)) END
			-
			CASE WHEN SUM(ISNULL([lyActualNP],0)) = 0 THEN NULL ELSE SUM(ISNULL(CAST([lyActualRMD] AS FLOAT),0))/SUM(ISNULL(CAST([lyActualNP] AS FLOAT),0)) END) END*10000 NewPlanRMPYoY
      --last quarter
      ,SUM(ISNULL([cyActualNPlq],0)) cyActualNPlq
      ,SUM(ISNULL([cyActualRMDlq],0)) cyActualRMDlq
      ,SUM(ISNULL([cyActualNRNlq],0)) cyActualNRNlq
      ,CASE WHEN SUM(ISNULL([cyActualNRNlq],0)) = 0 THEN NULL ELSE SUM(ISNULL([cyActualNPlq],0))/SUM(ISNULL([cyActualNRNlq],0)) END cyActualADRlq
      ,CASE WHEN SUM(ISNULL([cyActualNPlq],0)) = 0 THEN NULL ELSE SUM(ISNULL([cyActualRMDlq],0))/SUM(ISNULL([cyActualNPlq],0)) END cyActualRMPlq
      ,CASE WHEN SUM(ISNULL([lyActualNPlq],0)) = 0 THEN NULL ELSE (SUM(ISNULL([cyActualNPlq],0))/SUM(ISNULL([lyActualNPlq],0)))-1 END*100 ActualNPlqYoY
      ,CASE WHEN SUM(ISNULL([lyActualRMDlq],0)) = 0 THEN NULL ELSE (SUM(ISNULL([cyActualRMDlq],0))/SUM(ISNULL([lyActualRMDlq],0)))-1 END*100 ActualRMDlqYoY
      ,CASE WHEN SUM(ISNULL([lyActualNRNlq],0)) = 0 THEN NULL ELSE (SUM(ISNULL([cyActualNRNlq],0))/SUM(ISNULL([lyActualNRNlq],0))) -1 END*100 ActualNRNlqYoY
      ,CASE WHEN CASE WHEN SUM(ISNULL([cyActualNRNlq],0)) = 0 THEN 0 ELSE SUM(ISNULL([cyActualNPlq],0))/SUM(ISNULL([cyActualNRNlq],0)) END = 0 THEN NULL
	   ELSE 
			(CASE WHEN SUM(ISNULL([cyActualNRNlq],0)) = 0 THEN NULL ELSE SUM(ISNULL([cyActualNPlq],0))/SUM(ISNULL([cyActualNRNlq],0)) END
			/
			CASE WHEN SUM(ISNULL([lyActualNRNlq],0)) = 0 THEN NULL ELSE SUM(ISNULL([lyActualNPlq],0))/SUM(ISNULL([lyActualNRNlq],0)) END)-1 END*100 ActualADRlqYoY
      
      ,CASE WHEN CASE WHEN SUM(ISNULL([lyActualNPlq],0)) = 0 THEN 0 ELSE SUM(ISNULL([lyActualRMDlq],0))/SUM(ISNULL([lyActualNPlq],0)) END = 0 THEN NULL
       ELSE
			(CASE WHEN SUM(ISNULL([cyActualNPlq],0)) = 0 THEN NULL ELSE SUM(ISNULL([cyActualRMDlq],0))/SUM(ISNULL([cyActualNPlq],0)) END
			-
			CASE WHEN SUM(ISNULL([lyActualNPlq],0)) = 0 THEN NULL ELSE SUM(ISNULL([lyActualRMDlq],0))/SUM(ISNULL([lyActualNPlq],0)) END) END*10000 ActualRMPlqYoY
      
      ,SUM(ISNULL([lyActualNPlq],0)) lyActualNPlq
      ,SUM(ISNULL([lyActualRMDlq],0)) lyActualRMDlq
      ,SUM(ISNULL([lyActualNRNlq],0)) lyActualNRNlq

      --last month
      ,SUM(ISNULL([cyActualNPlm],0)) cyActualNPlm
      ,SUM(ISNULL([cyActualRMDlm],0)) cyActualRMDlm
      ,SUM(ISNULL([cyActualNRNlm],0)) cyActualNRNlm
      ,CASE WHEN SUM(ISNULL([cyActualNRNlm],0)) = 0 THEN NULL ELSE SUM(ISNULL([cyActualNPlm],0))/SUM(ISNULL([cyActualNRNlm],0)) END cyActualADRlm
      ,CASE WHEN SUM(ISNULL([cyActualNPlm],0)) = 0 THEN NULL ELSE SUM(ISNULL([cyActualRMDlm],0))/SUM(ISNULL([cyActualNPlm],0)) END cyActualRMPlm
      ,CASE WHEN SUM(ISNULL([lyActualNPlm],0)) = 0 THEN NULL ELSE (SUM(ISNULL([cyActualNPlm],0))/SUM(ISNULL([lyActualNPlm],0)))-1 END*100 ActualNPlmYoY
      ,CASE WHEN SUM(ISNULL([lyActualRMDlm],0)) = 0 THEN NULL ELSE (SUM(ISNULL([cyActualRMDlm],0))/SUM(ISNULL([lyActualRMDlm],0)))-1 END*100 ActualRMDlmYoY
      ,CASE WHEN SUM(ISNULL([lyActualNRNlm],0)) = 0 THEN NULL ELSE (SUM(ISNULL([cyActualNRNlm],0))/SUM(ISNULL([lyActualNRNlm],0))) -1 END*100 ActualNRNlmYoY
      ,CASE WHEN CASE WHEN SUM(ISNULL([cyActualNRNlm],0)) = 0 THEN 0 ELSE SUM(ISNULL([cyActualNPlm],0))/SUM(ISNULL([cyActualNRNlm],0)) END = 0 THEN NULL
	   ELSE 
			(CASE WHEN SUM(ISNULL([cyActualNRNlm],0)) = 0 THEN NULL ELSE SUM(ISNULL([cyActualNPlm],0))/SUM(ISNULL([cyActualNRNlm],0)) END
			/
			CASE WHEN SUM(ISNULL([lyActualNRNlm],0)) = 0 THEN NULL ELSE SUM(ISNULL([lyActualNPlm],0))/SUM(ISNULL([lyActualNRNlm],0)) END)-1 END*100 ActualADRlmYoY
      
      ,CASE WHEN CASE WHEN SUM(ISNULL([lyActualNPlm],0)) = 0 THEN 0 ELSE SUM(ISNULL([lyActualRMDlm],0))/SUM(ISNULL([lyActualNPlm],0)) END = 0 THEN NULL
       ELSE
			(CASE WHEN SUM(ISNULL([cyActualNPlm],0)) = 0 THEN NULL ELSE SUM(ISNULL([cyActualRMDlm],0))/SUM(ISNULL([cyActualNPlm],0)) END
			-
			CASE WHEN SUM(ISNULL([lyActualNPlm],0)) = 0 THEN NULL ELSE SUM(ISNULL([lyActualRMDlm],0))/SUM(ISNULL([lyActualNPlm],0)) END) END*10000 ActualRMPlmYoY
      
      
      ,SUM(ISNULL([lyActualNPlm],0)) lyActualNPlm
      ,SUM(ISNULL([lyActualRMDlm],0)) lyActualRMDlm
      ,SUM(ISNULL([lyActualNRNlm],0)) lyActualNRNlm
      ,'' [ChangedBy]
      ,'' [ChangedDate]
      ,'' [AdjustMetric]
      ,SUM(CASE @AdjustBy WHEN 0 THEN  AdjustedRMD ELSE  AdjustedNRN END) AS AdjustmentValue 
      ,SUM(AdjustedRMD) AdjustedRMD
      ,SUM(AdjustedNRN) AdjustedNRN
	  ,2 SortOrder
            
       FROM dbo.PlanTool_GMM_PlanData f
      JOIN (SELECT DISTINCT SuperRegionID,SuperRegionName,RegionID,RegionName,AMTID,AMTName,MMAID,MMAName FROM KPI_GMM_VIP_Hierarchy) s
      ON f.MMAID = s.MMAID
WHERE s.RegionID =@RegionID
AND Qrt = RIGHT(@Qrt,1) AND s.AMTID >0
GROUP BY
	   s.[SuperRegionName]
      ,s.[SuperRegionID]
      ,s.[RegionName]
      ,s.[RegionID]
      ,[Qrt]
      
UNION ALL

-- Get SubTotals
SELECT 
	   
	   s.[SuperRegionName]
      ,s.[SuperRegionID]
      ,s.[RegionName]
      ,s.[RegionID]
      ,'SubTotal' AMTName
      ,s.AMTID
      ,' ' MMAName
      ,0 MMAID
      ,[Qrt]
      --Original current quarter
      ,SUM(ISNULL([PlanNP],0)) PlanNP
      ,SUM(ISNULL([PlanRMD],0)) PlanRMD
      ,SUM(ISNULL([PlanNRN],0)) PlanNRN
      ,CASE WHEN SUM(ISNULL([PlanNRN],0)) = 0 THEN  NULL ELSE SUM(ISNULL([PlanNP],0))/SUM(ISNULL([PlanNRN],0)) END PlanADR
	  ,CASE WHEN SUM(ISNULL([PlanNP],0)) = 0 THEN NULL ELSE SUM(ISNULL([PlanRMD],0))/SUM(ISNULL([PlanNP],0)) END*100 PlanRMP
	  ,CASE WHEN SUM(ISNULL([lyActualNP],0)) = 0 THEN NULL ELSE (SUM(ISNULL([PlanNP],0))/SUM(ISNULL([lyActualNP],0)))-1 END*100 PlanNPYoY
	  ,CASE WHEN SUM(ISNULL([lyActualRMD],0)) = 0 THEN NULL ELSE (SUM(ISNULL([PlanRMD],0))/SUM(ISNULL([lyActualRMD],0)))-1 END*100 PlanRMDYoY
	  ,CASE WHEN SUM(ISNULL([lyActualNRN],0)) = 0 THEN NULL ELSE (SUM(ISNULL([PlanNRN],0))/SUM(ISNULL([lyActualNRN],0)))-1 END*100 PlanNRNYoY
	  ,CASE WHEN 
		CASE WHEN SUM(ISNULL([lyActualNRN],0)) = 0 THEN 0 ELSE SUM(ISNULL([lyActualNP],0))/SUM(ISNULL([lyActualNRN],0)) END = 0 THEN NULL 
	   ELSE 
			(CASE WHEN SUM(ISNULL([PlanNRN],0)) = 0 THEN  0 ELSE SUM(ISNULL([PlanNP],0))/SUM(ISNULL([PlanNRN],0)) END
			/
			CASE WHEN SUM(ISNULL([lyActualNRN],0)) = 0 THEN 0 ELSE SUM(ISNULL([lyActualNP],0))/SUM(ISNULL([lyActualNRN],0)) END)-1 END*100 PlanADRYoY
	  ,CASE WHEN CASE WHEN SUM(ISNULL([lyActualNP],0)) = 0 THEN 0 ELSE SUM(ISNULL([lyActualRMD],0))/SUM(ISNULL([lyActualNP],0)) END = 0 THEN NULL
	   ELSE
			(CASE WHEN SUM(ISNULL([PlanNP],0)) = 0 THEN NULL ELSE SUM(ISNULL([PlanRMD],0))/SUM(ISNULL([PlanNP],0)) END
			-
			CASE WHEN SUM(ISNULL([lyActualNP],0)) = 0 THEN NULL ELSE SUM(ISNULL([lyActualRMD],0))/SUM(ISNULL([lyActualNP],0)) END) END*10000 PlanRMPYoY
	 --New current quarter
	  ,SUM(ISNULL([NewPlanNP],0)) NewPlanNP
      ,SUM(ISNULL([NewPlanRMD],0)) NewPlanRMD
      ,SUM(ISNULL([NewPlanNRN],0)) NewPlanNRN
      ,CASE WHEN SUM(ISNULL([NewPlanNRN],0)) = 0 THEN  NULL ELSE SUM(ISNULL(CAST([NewPlanNP]AS FLOAT),0))/SUM(ISNULL(CAST([NewPlanNRN]AS FLOAT),0)) END NewPlanADR
	  ,CASE WHEN SUM(ISNULL([NewPlanNP],0)) = 0 THEN NULL ELSE SUM(ISNULL(CAST([NewPlanRMD] AS FLOAT),0))/SUM(ISNULL(CAST([NewPlanNP] AS FLOAT),0)) END*100 NewPlanRMP
	  ,CASE WHEN SUM(ISNULL([lyActualNP],0)) = 0 OR SUM(ISNULL([NewPlanNP],0)) = 0 THEN NULL ELSE (SUM(ISNULL([NewPlanNP],0))/SUM(ISNULL([lyActualNP],0)))-1 END*100 NewPlanNPYoY
	  ,CASE WHEN SUM(ISNULL([lyActualRMD],0)) = 0 OR SUM(ISNULL([NewPlanRMD],0)) = 0 THEN NULL ELSE (SUM(ISNULL([NewPlanRMD],0))/SUM(ISNULL([lyActualRMD],0)))-1 END*100 NewPlanRMDYoY
	  ,CASE WHEN SUM(ISNULL([lyActualNRN],0)) = 0 OR SUM(ISNULL([NewPlanNRN],0)) = 0 THEN NULL ELSE (SUM(ISNULL([NewPlanNRN],0))/SUM(ISNULL([lyActualNRN],0)))-1 END*100 NewPlanNRNYoY
	  ,CASE WHEN 
		CASE WHEN SUM(ISNULL([lyActualNRN],0)) = 0 THEN 0 ELSE SUM(ISNULL([lyActualNP],0))/SUM(ISNULL([lyActualNRN],0)) END = 0 
			OR CASE WHEN SUM(ISNULL([NewPlanNRN],0)) = 0 THEN  0 ELSE SUM(ISNULL([NewPlanNP],0))/SUM(ISNULL([NewPlanNRN],0))END= 0 THEN NULL 
	   ELSE 
			(CASE WHEN SUM(ISNULL([NewPlanNRN],0)) = 0 THEN  0 ELSE SUM(ISNULL([NewPlanNP],0))/SUM(ISNULL([NewPlanNRN],0)) END
			/
			CASE WHEN SUM(ISNULL([lyActualNRN],0)) = 0 THEN 0 ELSE SUM(ISNULL([lyActualNP],0))/SUM(ISNULL([lyActualNRN],0)) END)-1 END*100 NewPlanADRYoY
	  ,CASE WHEN CASE WHEN SUM(ISNULL([lyActualNP],0)) = 0 THEN 0 ELSE SUM(ISNULL(CAST([lyActualRMD] AS FLOAT),0))/SUM(ISNULL(CAST([lyActualNP] AS FLOAT),0)) END = 0 THEN NULL
	   ELSE
			(CASE WHEN SUM(ISNULL([NewPlanNP],0)) = 0 THEN NULL ELSE SUM(ISNULL(CAST([NewPlanRMD] AS FLOAT),0))/SUM(ISNULL(CAST([NewPlanNP] AS FLOAT),0)) END
			-
			CASE WHEN SUM(ISNULL([lyActualNP],0)) = 0 THEN NULL ELSE SUM(ISNULL(CAST([lyActualRMD] AS FLOAT),0))/SUM(ISNULL(CAST([lyActualNP] AS FLOAT),0)) END) END*10000 NewPlanRMPYoY
      --last quarter
      ,SUM(ISNULL([cyActualNPlq],0)) cyActualNPlq
      ,SUM(ISNULL([cyActualRMDlq],0)) cyActualRMDlq
      ,SUM(ISNULL([cyActualNRNlq],0)) cyActualNRNlq
      ,CASE WHEN SUM(ISNULL([cyActualNRNlq],0)) = 0 THEN NULL ELSE SUM(ISNULL([cyActualNPlq],0))/SUM(ISNULL([cyActualNRNlq],0)) END cyActualADRlq
      ,CASE WHEN SUM(ISNULL([cyActualNPlq],0)) = 0 THEN NULL ELSE SUM(ISNULL([cyActualRMDlq],0))/SUM(ISNULL([cyActualNPlq],0)) END cyActualRMPlq
      ,CASE WHEN SUM(ISNULL([lyActualNPlq],0)) = 0 THEN NULL ELSE (SUM(ISNULL([cyActualNPlq],0))/SUM(ISNULL([lyActualNPlq],0)))-1 END*100 ActualNPlqYoY
      ,CASE WHEN SUM(ISNULL([lyActualRMDlq],0)) = 0 THEN NULL ELSE (SUM(ISNULL([cyActualRMDlq],0))/SUM(ISNULL([lyActualRMDlq],0)))-1 END*100 ActualRMDlqYoY
      ,CASE WHEN SUM(ISNULL([lyActualNRNlq],0)) = 0 THEN NULL ELSE (SUM(ISNULL([cyActualNRNlq],0))/SUM(ISNULL([lyActualNRNlq],0))) -1 END*100 ActualNRNlqYoY
      ,CASE WHEN CASE WHEN SUM(ISNULL([cyActualNRNlq],0)) = 0 THEN 0 ELSE SUM(ISNULL([cyActualNPlq],0))/SUM(ISNULL([cyActualNRNlq],0)) END = 0 THEN NULL
	   ELSE 
			(CASE WHEN SUM(ISNULL([cyActualNRNlq],0)) = 0 THEN NULL ELSE SUM(ISNULL([cyActualNPlq],0))/SUM(ISNULL([cyActualNRNlq],0)) END
			/
			CASE WHEN SUM(ISNULL([lyActualNRNlq],0)) = 0 THEN NULL ELSE SUM(ISNULL([lyActualNPlq],0))/SUM(ISNULL([lyActualNRNlq],0)) END)-1 END*100 ActualADRlqYoY
      
      ,CASE WHEN CASE WHEN SUM(ISNULL([lyActualNPlq],0)) = 0 THEN 0 ELSE SUM(ISNULL([lyActualRMDlq],0))/SUM(ISNULL([lyActualNPlq],0)) END = 0 THEN NULL
       ELSE
			(CASE WHEN SUM(ISNULL([cyActualNPlq],0)) = 0 THEN NULL ELSE SUM(ISNULL([cyActualRMDlq],0))/SUM(ISNULL([cyActualNPlq],0)) END
			-
			CASE WHEN SUM(ISNULL([lyActualNPlq],0)) = 0 THEN NULL ELSE SUM(ISNULL([lyActualRMDlq],0))/SUM(ISNULL([lyActualNPlq],0)) END) END*10000 ActualRMPlqYoY
      
      ,SUM(ISNULL([lyActualNPlq],0)) lyActualNPlq
      ,SUM(ISNULL([lyActualRMDlq],0)) lyActualRMDlq
      ,SUM(ISNULL([lyActualNRNlq],0)) lyActualNRNlq

      --last month
      ,SUM(ISNULL([cyActualNPlm],0)) cyActualNPlm
      ,SUM(ISNULL([cyActualRMDlm],0)) cyActualRMDlm
      ,SUM(ISNULL([cyActualNRNlm],0)) cyActualNRNlm
      ,CASE WHEN SUM(ISNULL([cyActualNRNlm],0)) = 0 THEN NULL ELSE SUM(ISNULL([cyActualNPlm],0))/SUM(ISNULL([cyActualNRNlm],0)) END cyActualADRlm
      ,CASE WHEN SUM(ISNULL([cyActualNPlm],0)) = 0 THEN NULL ELSE SUM(ISNULL([cyActualRMDlm],0))/SUM(ISNULL([cyActualNPlm],0)) END cyActualRMPlm
      ,CASE WHEN SUM(ISNULL([lyActualNPlm],0)) = 0 THEN NULL ELSE (SUM(ISNULL([cyActualNPlm],0))/SUM(ISNULL([lyActualNPlm],0)))-1 END*100 ActualNPlmYoY
      ,CASE WHEN SUM(ISNULL([lyActualRMDlm],0)) = 0 THEN NULL ELSE (SUM(ISNULL([cyActualRMDlm],0))/SUM(ISNULL([lyActualRMDlm],0)))-1 END*100 ActualRMDlmYoY
      ,CASE WHEN SUM(ISNULL([lyActualNRNlm],0)) = 0 THEN NULL ELSE (SUM(ISNULL([cyActualNRNlm],0))/SUM(ISNULL([lyActualNRNlm],0))) -1 END*100 ActualNRNlmYoY
      ,CASE WHEN CASE WHEN SUM(ISNULL([cyActualNRNlm],0)) = 0 THEN 0 ELSE SUM(ISNULL([cyActualNPlm],0))/SUM(ISNULL([cyActualNRNlm],0)) END = 0 THEN NULL
	   ELSE 
			(CASE WHEN SUM(ISNULL([cyActualNRNlm],0)) = 0 THEN NULL ELSE SUM(ISNULL([cyActualNPlm],0))/SUM(ISNULL([cyActualNRNlm],0)) END
			/
			CASE WHEN SUM(ISNULL([lyActualNRNlm],0)) = 0 THEN NULL ELSE SUM(ISNULL([lyActualNPlm],0))/SUM(ISNULL([lyActualNRNlm],0)) END)-1 END*100 ActualADRlmYoY
      
      ,CASE WHEN CASE WHEN SUM(ISNULL([lyActualNPlm],0)) = 0 THEN 0 ELSE SUM(ISNULL([lyActualRMDlm],0))/SUM(ISNULL([lyActualNPlm],0)) END = 0 THEN NULL
       ELSE
			(CASE WHEN SUM(ISNULL([cyActualNPlm],0)) = 0 THEN NULL ELSE SUM(ISNULL([cyActualRMDlm],0))/SUM(ISNULL([cyActualNPlm],0)) END
			-
			CASE WHEN SUM(ISNULL([lyActualNPlm],0)) = 0 THEN NULL ELSE SUM(ISNULL([lyActualRMDlm],0))/SUM(ISNULL([lyActualNPlm],0)) END) END*10000 ActualRMPlmYoY
      
      
      ,SUM(ISNULL([lyActualNPlm],0)) lyActualNPlm
      ,SUM(ISNULL([lyActualRMDlm],0)) lyActualRMDlm
      ,SUM(ISNULL([lyActualNRNlm],0)) lyActualNRNlm
      ,'' [ChangedBy]
      ,'' [ChangedDate]
      ,'' [AdjustMetric]
      ,SUM(CASE @AdjustBy WHEN 0 THEN  AdjustedRMD ELSE  AdjustedNRN END) AS AdjustmentValue 
      ,SUM(AdjustedRMD) AdjustedRMD
      ,SUM(AdjustedNRN) AdjustedNRN
	  ,1 SortOrder
            
       FROM dbo.PlanTool_GMM_PlanData f
      JOIN (SELECT DISTINCT SuperRegionID,SuperRegionName,RegionID,RegionName,AMTID,AMTName,MMAID,MMAName FROM KPI_GMM_VIP_Hierarchy) s
      ON f.MMAID = s.MMAID
WHERE s.RegionID =@RegionID
AND Qrt = RIGHT(@Qrt,1) AND s.AMTID >0
GROUP BY
	   s.[SuperRegionName]
      ,s.[SuperRegionID]
      ,s.[RegionName]
      ,s.[RegionID]
      ,s.AMTID
      ,[Qrt]
      
UNION ALL
-- Get details by MMAs
SELECT 
	   s.[SuperRegionName]
      ,s.[SuperRegionID]
      ,s.[RegionName]
      ,s.[RegionID]
      ,s.AMTName
      ,s.AMTID
      ,s.MMAName MMAName
      ,s.MMAID MMAID
      ,[Qrt]
      --Original current quarter
      ,SUM(ISNULL([PlanNP],0)) PlanNP
      ,SUM(ISNULL([PlanRMD],0)) PlanRMD
      ,SUM(ISNULL([PlanNRN],0)) PlanNRN
      ,CASE WHEN SUM(ISNULL([PlanNRN],0)) = 0 THEN  NULL ELSE SUM(ISNULL(CAST([PlanNP] AS FLOAT),0))/SUM(ISNULL(CAST([PlanNRN] AS FLOAT),0)) END PlanADR
	  ,CASE WHEN SUM(ISNULL([PlanNP],0)) = 0 THEN NULL ELSE SUM(ISNULL([PlanRMD],0))/SUM(ISNULL([PlanNP],0)) END*100 PlanRMP
	  ,CASE WHEN SUM(ISNULL([lyActualNP],0)) = 0 THEN NULL ELSE (SUM(ISNULL([PlanNP],0))/SUM(ISNULL([lyActualNP],0)))-1 END*100 PlanNPYoY
	  ,CASE WHEN SUM(ISNULL([lyActualRMD],0)) = 0 THEN NULL ELSE (SUM(ISNULL([PlanRMD],0))/SUM(ISNULL([lyActualRMD],0)))-1 END*100 PlanRMDYoY
	  ,CASE WHEN SUM(ISNULL([lyActualNRN],0)) = 0 THEN NULL ELSE (SUM(ISNULL([PlanNRN],0))/SUM(ISNULL([lyActualNRN],0)))-1 END*100 PlanNRNYoY
	  ,CASE WHEN 
		CASE WHEN SUM(ISNULL([lyActualNRN],0)) = 0 THEN 0 ELSE SUM(ISNULL([lyActualNP],0))/SUM(ISNULL([lyActualNRN],0)) END = 0 THEN NULL 
	   ELSE 
			(CASE WHEN SUM(ISNULL([PlanNRN],0)) = 0 THEN  0 ELSE SUM(ISNULL([PlanNP],0))/SUM(ISNULL([PlanNRN],0)) END
			/
			CASE WHEN SUM(ISNULL([lyActualNRN],0)) = 0 THEN 0 ELSE SUM(ISNULL([lyActualNP],0))/SUM(ISNULL([lyActualNRN],0)) END)-1 END*100 PlanADRYoY
	  ,CASE WHEN CASE WHEN SUM(ISNULL([lyActualNP],0)) = 0 THEN 0 ELSE SUM(ISNULL([lyActualRMD],0))/SUM(ISNULL([lyActualNP],0)) END = 0 THEN NULL
	   ELSE
			(CASE WHEN SUM(ISNULL([PlanNP],0)) = 0 THEN NULL ELSE SUM(ISNULL([PlanRMD],0))/SUM(ISNULL([PlanNP],0)) END
			-
			CASE WHEN SUM(ISNULL([lyActualNP],0)) = 0 THEN NULL ELSE SUM(ISNULL([lyActualRMD],0))/SUM(ISNULL([lyActualNP],0)) END) END*10000 PlanRMPYoY
	 --New current quarter
	  ,SUM(ISNULL([NewPlanNP],0)) NewPlanNP
      ,SUM(ISNULL([NewPlanRMD],0)) NewPlanRMD
      ,SUM(ISNULL([NewPlanNRN],0)) NewPlanNRN
      ,CASE WHEN SUM(ISNULL([NewPlanNRN],0)) = 0 THEN  NULL ELSE SUM(ISNULL(CAST([NewPlanNP]AS FLOAT),0))/SUM(ISNULL(CAST([NewPlanNRN]AS FLOAT),0)) END NewPlanADR
	  ,CASE WHEN SUM(ISNULL([NewPlanNP],0)) = 0 THEN NULL ELSE SUM(ISNULL(CAST([NewPlanRMD] AS FLOAT),0))/SUM(ISNULL(CAST([NewPlanNP] AS FLOAT),0)) END*100 NewPlanRMP
	  ,CASE WHEN SUM(ISNULL([lyActualNP],0)) = 0 OR SUM(ISNULL([NewPlanNP],0)) = 0 THEN NULL ELSE (SUM(ISNULL([NewPlanNP],0))/SUM(ISNULL([lyActualNP],0)))-1 END*100 NewPlanNPYoY
	  ,CASE WHEN SUM(ISNULL([lyActualRMD],0)) = 0 OR SUM(ISNULL([NewPlanRMD],0)) = 0 THEN NULL ELSE (SUM(ISNULL([NewPlanRMD],0))/SUM(ISNULL([lyActualRMD],0)))-1 END*100 NewPlanRMDYoY
	  ,CASE WHEN SUM(ISNULL([lyActualNRN],0)) = 0 OR SUM(ISNULL([NewPlanNRN],0)) = 0 THEN NULL ELSE (SUM(ISNULL([NewPlanNRN],0))/SUM(ISNULL([lyActualNRN],0)))-1 END*100 NewPlanNRNYoY
	  ,CASE WHEN 
		CASE WHEN SUM(ISNULL([lyActualNRN],0)) = 0 THEN 0 ELSE SUM(ISNULL([lyActualNP],0))/SUM(ISNULL([lyActualNRN],0)) END = 0 
					OR CASE WHEN SUM(ISNULL([NewPlanNRN],0)) = 0 THEN  0 ELSE SUM(ISNULL([NewPlanNP],0))/SUM(ISNULL([NewPlanNRN],0))END= 0 THEN NULL 
	   ELSE 
			(CASE WHEN SUM(ISNULL([NewPlanNRN],0)) = 0 THEN  0 ELSE SUM(ISNULL([NewPlanNP],0))/SUM(ISNULL([NewPlanNRN],0)) END
			/
			CASE WHEN SUM(ISNULL([lyActualNRN],0)) = 0 THEN 0 ELSE SUM(ISNULL([lyActualNP],0))/SUM(ISNULL([lyActualNRN],0)) END)-1 END*100 NewPlanADRYoY
	  ,CASE WHEN CASE WHEN SUM(ISNULL([lyActualNP],0)) = 0 THEN 0 ELSE SUM(ISNULL(CAST([lyActualRMD] AS FLOAT),0))/SUM(ISNULL(CAST([lyActualNP] AS FLOAT),0)) END = 0 THEN NULL
	   ELSE
			(CASE WHEN SUM(ISNULL([NewPlanNP],0)) = 0 THEN NULL ELSE SUM(ISNULL(CAST([NewPlanRMD] AS FLOAT),0))/SUM(ISNULL(CAST([NewPlanNP] AS FLOAT),0)) END
			-
			CASE WHEN SUM(ISNULL([lyActualNP],0)) = 0 THEN NULL ELSE SUM(ISNULL(CAST([lyActualRMD] AS FLOAT),0))/SUM(ISNULL(CAST([lyActualNP] AS FLOAT),0)) END) END*10000 NewPlanRMPYoY
      --last quarter
      ,SUM(ISNULL([cyActualNPlq],0)) cyActualNPlq
      ,SUM(ISNULL([cyActualRMDlq],0)) cyActualRMDlq
      ,SUM(ISNULL([cyActualNRNlq],0)) cyActualNRNlq
      ,CASE WHEN SUM(ISNULL([cyActualNRNlq],0)) = 0 THEN NULL ELSE SUM(ISNULL([cyActualNPlq],0))/SUM(ISNULL([cyActualNRNlq],0)) END ActualADRlq
      ,CASE WHEN SUM(ISNULL([cyActualNPlq],0)) = 0 THEN NULL ELSE SUM(ISNULL([cyActualRMDlq],0))/SUM(ISNULL([cyActualNPlq],0)) END*100 ActualRMPlq
      ,CASE WHEN SUM(ISNULL([lyActualNPlq],0)) = 0 THEN NULL ELSE (SUM(ISNULL([cyActualNPlq],0))/SUM(ISNULL([lyActualNPlq],0)))-1 END*100 ActualNPlqYoY
      ,CASE WHEN SUM(ISNULL([lyActualRMDlq],0)) = 0 THEN NULL ELSE (SUM(ISNULL([cyActualRMDlq],0))/SUM(ISNULL([lyActualRMDlq],0)))-1 END*100 ActualRMDlqYoY
      ,CASE WHEN SUM(ISNULL([lyActualNRNlq],0)) = 0 THEN NULL ELSE (SUM(ISNULL([cyActualNRNlq],0))/SUM(ISNULL([lyActualNRNlq],0))) -1 END*100 ActualNRNlqYoY
      ,CASE WHEN CASE WHEN SUM(ISNULL([cyActualNRNlq],0)) = 0 THEN 0 ELSE SUM(ISNULL([cyActualNPlq],0))/SUM(ISNULL([cyActualNRNlq],0)) END = 0 THEN NULL
	   ELSE 
			(CASE WHEN SUM(ISNULL([cyActualNRNlq],0)) = 0 THEN NULL ELSE SUM(ISNULL([cyActualNPlq],0))/SUM(ISNULL([cyActualNRNlq],0)) END
			/
			CASE WHEN SUM(ISNULL([lyActualNRNlq],0)) = 0 THEN NULL ELSE SUM(ISNULL([lyActualNPlq],0))/SUM(ISNULL([lyActualNRNlq],0)) END)-1 END*100 ActualADRlqYoY
      
      ,CASE WHEN CASE WHEN SUM(ISNULL([lyActualNPlq],0)) = 0 THEN 0 ELSE SUM(ISNULL([lyActualRMDlq],0))/SUM(ISNULL([lyActualNPlq],0)) END = 0 THEN NULL
       ELSE
			(CASE WHEN SUM(ISNULL([cyActualNPlq],0)) = 0 THEN NULL ELSE SUM(ISNULL([cyActualRMDlq],0))/SUM(ISNULL([cyActualNPlq],0)) END
			-
			CASE WHEN SUM(ISNULL([lyActualNPlq],0)) = 0 THEN NULL ELSE SUM(ISNULL([lyActualRMDlq],0))/SUM(ISNULL([lyActualNPlq],0)) END) END*10000 ActualRMPlqYoY
      
      ,SUM(ISNULL([lyActualNPlq],0)) lyActualNPlq
      ,SUM(ISNULL([lyActualRMDlq],0)) lyActualRMDlq
      ,SUM(ISNULL([lyActualNRNlq],0)) lyActualNRNlq

      --last month
      ,SUM(ISNULL([cyActualNPlm],0)) cyActualNPlm
      ,SUM(ISNULL([cyActualRMDlm],0)) cyActualRMDlm
      ,SUM(ISNULL([cyActualNRNlm],0)) cyActualNRNlm
      ,CASE WHEN SUM(ISNULL([cyActualNRNlm],0)) = 0 THEN NULL ELSE SUM(ISNULL([cyActualNPlm],0))/SUM(ISNULL([cyActualNRNlm],0)) END ActualADRlm
      ,CASE WHEN SUM(ISNULL([cyActualNPlm],0)) = 0 THEN NULL ELSE SUM(ISNULL([cyActualRMDlm],0))/SUM(ISNULL([cyActualNPlm],0)) END*100 ActualRMPlm
      ,CASE WHEN SUM(ISNULL([lyActualNPlm],0)) = 0 THEN NULL ELSE (SUM(ISNULL([cyActualNPlm],0))/SUM(ISNULL([lyActualNPlm],0)))-1 END*100 ActualNPlmYoY
      ,CASE WHEN SUM(ISNULL([lyActualRMDlm],0)) = 0 THEN NULL ELSE (SUM(ISNULL([cyActualRMDlm],0))/SUM(ISNULL([lyActualRMDlm],0)))-1 END*100 ActualRMDlmYoY
      ,CASE WHEN SUM(ISNULL([lyActualNRNlm],0)) = 0 THEN NULL ELSE (SUM(ISNULL([cyActualNRNlm],0))/SUM(ISNULL([lyActualNRNlm],0))) -1 END*100 ActualNRNlmYoY
      ,CASE WHEN CASE WHEN SUM(ISNULL([cyActualNRNlm],0)) = 0 THEN 0 ELSE SUM(ISNULL([cyActualNPlm],0))/SUM(ISNULL([cyActualNRNlm],0)) END = 0 THEN NULL
	   ELSE 
			(CASE WHEN SUM(ISNULL([cyActualNRNlm],0)) = 0 THEN NULL ELSE SUM(ISNULL([cyActualNPlm],0))/SUM(ISNULL([cyActualNRNlm],0)) END
			/
			CASE WHEN SUM(ISNULL([lyActualNRNlm],0)) = 0 THEN NULL ELSE SUM(ISNULL([lyActualNPlm],0))/SUM(ISNULL([lyActualNRNlm],0)) END)-1 END*100 ActualADRlmYoY
      
      ,CASE WHEN CASE WHEN SUM(ISNULL([lyActualNPlm],0)) = 0 THEN 0 ELSE SUM(ISNULL([lyActualRMDlm],0))/SUM(ISNULL([lyActualNPlm],0)) END = 0 THEN NULL
       ELSE
			(CASE WHEN SUM(ISNULL([cyActualNPlm],0)) = 0 THEN NULL ELSE SUM(ISNULL([cyActualRMDlm],0))/SUM(ISNULL([cyActualNPlm],0)) END
			-
			CASE WHEN SUM(ISNULL([lyActualNPlm],0)) = 0 THEN NULL ELSE SUM(ISNULL([lyActualRMDlm],0))/SUM(ISNULL([lyActualNPlm],0)) END) END*10000 ActualRMPlmYoY
      
      
      ,SUM(ISNULL([lyActualNPlm],0)) lyActualNPlm
      ,SUM(ISNULL([lyActualRMDlm],0)) lyActualRMDlm
      ,SUM(ISNULL([lyActualNRNlm],0)) lyActualNRNlm
      ,'' [ChangedBy]
      ,'' [ChangedDate]
      ,'' [AdjustMetric]
      ,SUM(CASE @AdjustBy WHEN 0 THEN  AdjustedRMD ELSE  AdjustedNRN END) AS AdjustmentValue 
      ,SUM(AdjustedRMD) AdjustedRMD
      ,SUM(AdjustedNRN) AdjustedNRN
      ,1 SortOrder
            
      FROM dbo.PlanTool_GMM_PlanData f
      JOIN (SELECT DISTINCT SuperRegionID,SuperRegionName,RegionID,RegionName,AMTID,AMTName,MMAID,MMAName FROM KPI_GMM_VIP_Hierarchy) s
      ON f.MMAID = s.MMAID
WHERE s.RegionID =@RegionID
AND Qrt = RIGHT(@Qrt,1) AND s.AMTID >0
GROUP BY
	   s.[SuperRegionName]
      ,s.[SuperRegionID]
      ,s.[RegionName]
      ,s.[RegionID]
      ,s.AMTID
      ,s.AMTName
      ,s.MMAID
      ,s.MMAName
      ,[Qrt]
)

SELECT *,
CASE WHEN NewPlanADR IS NOT NULL THEN CASE WHEN (1-(PlanADR/NewPlanADR))*100 BETWEEN -5 AND 5 THEN 'Gray' ELSE 'Red' END END ADRHighlight,
(1-(CONVERT(Float,PlanADR)/CONVERT(Float,NewPlanADR)))*100 ADRTest,
CASE WHEN NewPlanRMP IS NOT NULL THEN CASE WHEN (1-(PlanRMP/NewPlanRMP))*100 BETWEEN -100 AND 100 THEN 'Gray' ELSE 'Red' END END RMPHighlight

 FROM PlanData ORDER BY SortOrder,AMTID,AMTName,MMAName,PlanRMD DESC



/*
select * FROM dbo.PlanTool_GMM_PlanData f
      JOIN (SELECT DISTINCT SuperRegionID,SuperRegionName,RegionID,RegionName,AMTID,AMTName,MMaID,MMAName FROM sip_hierrachy) s
      ON f.MMAID = s.MMAID where Qrt ='1' 
      and RegionName ='california'
*/
