USE [SSATools]
GO
/****** Object:  StoredProcedure [dbo].[PlanTool_GMM_GetDeadLine]    Script Date: 05/01/2015 10:01:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[PlanTool_GMM_GetDeadLine]
AS

SELECT
'Plan Adjustment Deadline: The Tool has been closed!' DeadLine,
1 ToolClose