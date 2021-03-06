USE [SSATools]
GO
/****** Object:  StoredProcedure [dbo].[UpLoadPlanForecast_GPG]    Script Date: 05/01/2015 10:07:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[UpLoadPlanForecast_GPG]
@FileLocation varchar(4000)='\\BEL-PFS-01\Hotel_Sales_Team\REPORTS\CURRENT\Other\BryanDoan\PlanForecast\2015\Q2\GPG\Raw\',
@FileName varchar(50) ='Q2 Fcst To Bryan.xlsx'
AS

/*
make sure the file location and the file name and the sheet name correct
*/

Declare @sql varchar(4000)
		
-- Drop temp tables if exist
IF OBJECT_ID('tempdb..##PlanDataGPG') IS NOT NULL
   DROP TABLE ##PlanDataGPG
   
   select @FileLocation + @FileName as filelink
   
SET @sql ='
SELECT * INTO ##PlanDataGPG
 FROM  OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
''EXCEL 12.0 XML;Database='+@FileLocation + @FileName+';HDR=YES'',
''SELECT * FROM [Data$] WHERE [RegionID] Is Not Null'')
'

select @sql
exec(@sql)

SELECT * FROM ##PlanDataGPG