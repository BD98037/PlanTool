USE [SSATools]
GO
/****** Object:  StoredProcedure [dbo].[GetAdjustmentBy]    Script Date: 05/01/2015 11:20:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[GetAdjustmentBy] 
@AdjustBoth INT = 0
AS

SET NOCOUNT ON

IF(@AdjustBoth = 0)
	SELECT  -1 AS ID,'Select a Metric' as name
	UNION 
	SELECT 0 AS ID, 'RMD' AS Name
	UNION ALL
	SELECT 1 AS ID, 'NRN' AS Name
ELSE
	SELECT  -1 AS ID,'Select a Metric' as name
	UNION 
	SELECT 2 AS ID, 'Both RMD & NRN' AS Name

set ANSI_NULLS ON

set QUOTED_IDENTIFIER ON

