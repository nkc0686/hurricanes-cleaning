USE HurricanesDB;
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
  BEGIN TRAN;

  /* ===================== 0) Fresh stage ===================== */
  IF OBJECT_ID('dbo.Hurricanes_Stage','U') IS NOT NULL
    DROP TABLE dbo.Hurricanes_Stage;

  -- maps for TRANSLATE (same length both sides)
  DECLARE @WS_FROM nchar(4) = NCHAR(194) + NCHAR(160) + NCHAR(8239) + NCHAR(8201); -- Â, NBSP, narrow NBSP, thin space
  DECLARE @WS_TO   nchar(4) = N'    ';                                              -- 4 normal spaces
  DECLARE @Q_FROM  nchar(4) = NCHAR(8216) + NCHAR(8217) + NCHAR(8220) + NCHAR(8221); -- ‘ ’ “ ”
  DECLARE @Q_TO    nchar(4) = N'''' + N'''' + N'"' + N'"';                           -- ' ' " "

  SELECT
    RowID            = TRY_CAST(RowID AS int),
    Name             = TRIM(TRANSLATE(Name,       @WS_FROM, @WS_TO)),
    Duration         = TRIM(TRANSLATE(Duration,   @WS_FROM, @WS_TO)),
    Wind_speed       = TRIM(TRANSLATE(Wind_speed, @WS_FROM, @WS_TO)),
    Pressure         = TRIM(TRANSLATE(Pressure,   @WS_FROM, @WS_TO)),
    Areas_affected   = NULLIF(TRIM(TRANSLATE(Areas_affected, @WS_FROM, @WS_TO)), N''),
    Damage,
    REF,
    Deaths_int       = TRY_CAST(NULLIF(Deaths,'Unknown') AS int),
    Category_int     = TRY_CAST(Category AS int),
    Ref_clean        = NULLIF(REPLACE(REPLACE(REPLACE(CAST(REF AS nvarchar(4000)),'[',''),']',''), '][', ','), ''),
    Name_clean       = NULLIF(TRIM(TRANSLATE(TRANSLATE(Name, @WS_FROM, @WS_TO), @Q_FROM, @Q_TO)), N''),
    Name_key         = NULLIF(LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                          TRIM(TRANSLATE(Name,@WS_FROM,@WS_TO)),' ',''),'-',''),'''',''),'.',''),'"',''),'(',''),')',''),',','')) ,N''),
    StartDate        = CAST(NULL AS date),
    EndDate          = CAST(NULL AS date),
    WindSpeed_mph    = CAST(NULL AS int),
    WindSpeed_kmh    = CAST(NULL AS int),
    Pressure_hPa     = CAST(NULL AS int),
    Pressure_inHg    = CAST(NULL AS decimal(6,2)),
    Damage_USD       = CAST(NULL AS bigint)
  INTO dbo.Hurricanes_Stage
  FROM dbo.Hurricanes;

  -- placeholders -> NULL (case-insens)
  UPDATE s
  SET Areas_affected = NULL
  FROM dbo.Hurricanes_Stage s
  WHERE UPPER(s.Areas_affected) IN (N'NONE', N'NO LAND AREAS', N'UNKNOWN');

  /* ===================== 1) Dates ===================== */
  SET DATEFORMAT mdy;

  ;WITH Dur AS (
    SELECT RowID,
           NormDur = TRIM(TRANSLATE(REPLACE(REPLACE(Duration,N'†',''),N' L',''), N'–—', N'--'))
    FROM dbo.Hurricanes_Stage
  ),
  P AS (
    SELECT RowID, NormDur,
           dash_pos   = NULLIF(CHARINDEX('-', NormDur),0),
           year_end   = RIGHT(NormDur,4),
           month_txt  = CASE WHEN CHARINDEX(' ', NormDur) > 0 THEN LEFT(NormDur, CHARINDEX(' ', NormDur) - 1) END,
           left_part  = LTRIM(RTRIM(CASE WHEN CHARINDEX('-',NormDur)>0 THEN LEFT(NormDur, CHARINDEX('-',NormDur)-1) ELSE NormDur END)),
           right_full = LTRIM(RTRIM(CASE WHEN CHARINDEX('-',NormDur)>0 THEN SUBSTRING(NormDur, CHARINDEX('-',NormDur)+1, LEN(NormDur)) ELSE NormDur END))
    FROM Dur
  )
  UPDATE s
  SET StartDate = COALESCE(TRY_CONVERT(date,
                        CASE
                          WHEN dash_pos IS NULL THEN NormDur
                          WHEN PATINDEX('%[0-9][0-9][0-9][0-9]%', left_part) > 0 THEN left_part
                          ELSE CONCAT(left_part, ', ', year_end)
                        END), s.StartDate),
      EndDate   = COALESCE(TRY_CONVERT(date,
                        CASE
                          WHEN dash_pos IS NULL THEN NormDur
                          WHEN PATINDEX('%[A-Za-z]%', right_full) > 0
                            THEN CASE WHEN PATINDEX('%[0-9][0-9][0-9][0-9]%', right_full) > 0
                                      THEN right_full ELSE CONCAT(right_full, ', ', year_end) END
                          ELSE CONCAT(month_txt, ' ', right_full)
                        END), s.EndDate)
  FROM dbo.Hurricanes_Stage s
  JOIN P ON P.RowID = s.RowID
  WHERE s.StartDate IS NULL OR s.EndDate IS NULL;

  -- dd-MMM-yy single-day (two hyphens, no comma)
  ;WITH Dur AS (
    SELECT RowID,
           NormDur = TRIM(TRANSLATE(REPLACE(REPLACE(Duration,N'†',''),N' L',''), N'–—', N'--'))
    FROM dbo.Hurricanes_Stage
  ),
  OnlyDash3 AS (
    SELECT RowID, NormDur
    FROM Dur
    WHERE (LEN(NormDur) - LEN(REPLACE(NormDur,'-',''))) = 2
      AND NormDur NOT LIKE '%,%'
  ),
  Parts AS (
    SELECT RowID,
           d  = LEFT(NormDur, CHARINDEX('-',NormDur)-1),
           m  = SUBSTRING(NormDur, CHARINDEX('-',NormDur)+1,
                          CHARINDEX('-',NormDur, CHARINDEX('-',NormDur)+1) - (CHARINDEX('-',NormDur)+1)),
           yy = RIGHT(NormDur, LEN(NormDur) - CHARINDEX('-',NormDur, CHARINDEX('-',NormDur)+1))
    FROM OnlyDash3
  )
  UPDATE s
  SET StartDate = COALESCE(TRY_CONVERT(date, CONCAT(d,' ',m,' ',
                           CASE WHEN TRY_CONVERT(int,yy) >= 50 THEN 1900+TRY_CONVERT(int,yy)
                                ELSE 2000+TRY_CONVERT(int,yy) END), 106), s.StartDate),
      EndDate   = COALESCE(TRY_CONVERT(date, CONCAT(d,' ',m,' ',
                           CASE WHEN TRY_CONVERT(int,yy) >= 50 THEN 1900+TRY_CONVERT(int,yy)
                                ELSE 2000+TRY_CONVERT(int,yy) END), 106), s.EndDate)
  FROM dbo.Hurricanes_Stage s
  JOIN Parts ON Parts.RowID = s.RowID
  WHERE s.StartDate IS NULL OR s.EndDate IS NULL;

  /* ===================== 2) Wind ===================== */
  UPDATE s
  SET WindSpeed_mph = COALESCE(
        TRY_CONVERT(int, LEFT(Wind_speed, PATINDEX('%[^0-9]%', Wind_speed + ' ') - 1)),
        WindSpeed_mph),
      WindSpeed_kmh = CASE
        WHEN WindSpeed_mph IS NOT NULL
          THEN CAST(ROUND((1.0 * WindSpeed_mph * 1.60934)/5.0, 0)*5 AS int)
        WHEN CHARINDEX('km/h', LOWER(Wind_speed)) > 0 AND CHARINDEX('(', Wind_speed) > 0
          THEN TRY_CONVERT(int, TRIM(SUBSTRING(
                 Wind_speed,
                 CHARINDEX('(', Wind_speed)+1,
                 CHARINDEX('km/h', LOWER(Wind_speed)) - (CHARINDEX('(', Wind_speed)+1))))
        ELSE WindSpeed_kmh
      END
  FROM dbo.Hurricanes_Stage s;

  /* ===================== 3) Pressure ===================== */
  UPDATE s
  SET Pressure_hPa = CASE
        WHEN PATINDEX('%hpa%', LOWER(Pressure)) > 0
          THEN TRY_CONVERT(int, REPLACE(LEFT(Pressure, PATINDEX('%hpa%', LOWER(Pressure)) - 1), ',', ''))
      END,
      Pressure_inHg = CASE
        WHEN CHARINDEX('(', Pressure) > 0 AND PATINDEX('%inhg%', LOWER(Pressure)) > 0
          THEN TRY_CONVERT(decimal(6,2), TRIM(SUBSTRING(
                 Pressure,
                 CHARINDEX('(', Pressure)+1,
                 PATINDEX('%inhg%', LOWER(Pressure)) - (CHARINDEX('(', Pressure)+1))))
      END
  FROM dbo.Hurricanes_Stage s;

  /* ===================== 4) Damage USD ===================== */
  ;WITH N AS (
    SELECT RowID, dmg_raw = LOWER(CONVERT(nvarchar(4000), ISNULL(Damage,'')))
    FROM dbo.Hurricanes_Stage
  ),
  N2 AS (
    SELECT RowID,
           dmg = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(dmg_raw,'us$','$'),' usd',' $'),',',''),N'—',' ')))
    FROM N
  ),
  C AS (
    SELECT RowID,
           Damage_USD_new =
             CASE
               WHEN dmg IN ('','unknown','none','minimal','negligible','moderate','heavy') THEN NULL
               WHEN CHARINDEX('[', dmg) > 0 THEN NULL
               WHEN dmg LIKE '%billion%' THEN
                 TRY_CONVERT(bigint, ROUND(TRY_CONVERT(decimal(20,6),
                   REPLACE(REPLACE(REPLACE(dmg,'billion',''),'$',''),' ','')) * 1000000000, 0))
               WHEN dmg LIKE '%million%' THEN
                 TRY_CONVERT(bigint, ROUND(TRY_CONVERT(decimal(20,6),
                   REPLACE(REPLACE(REPLACE(dmg,'million',''),'$',''),' ','')) * 1000000, 0))
               WHEN dmg LIKE '%thousand%' OR PATINDEX('%[0-9][ ]*k%', dmg) > 0 THEN
                 TRY_CONVERT(bigint, ROUND(TRY_CONVERT(decimal(20,6),
                   REPLACE(REPLACE(REPLACE(REPLACE(dmg,'thousand',''),'$',''),'k',''),' ','')) * 1000, 0))
               WHEN REPLACE(REPLACE(dmg,'$',''),' ','') LIKE '%[0-9][0-9][0-9][0-9]%'
                 THEN TRY_CONVERT(bigint, REPLACE(REPLACE(dmg,'$',''),' ',''))
               ELSE NULL
             END
    FROM N2
  )
  UPDATE s
  SET Damage_USD = CASE WHEN c.Damage_USD_new IS NOT NULL AND c.Damage_USD_new < 1000 THEN NULL
                        ELSE c.Damage_USD_new END
  FROM dbo.Hurricanes_Stage s
  JOIN C ON C.RowID = s.RowID;

  COMMIT;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK;
  THROW;
END CATCH;
GO

/* ===================== 5) Final view ===================== */
CREATE OR ALTER VIEW dbo.Hurricanes_Final AS
SELECT
  RowID,
  Name              = COALESCE(Name_clean, Name),
  StartDate, EndDate,
  WindSpeed_mph, WindSpeed_kmh,
  Pressure_hPa, Pressure_inHg,
  Areas_affected,
  Deaths = Deaths_int,
  Damage_USD,
  Category_raw = Category_int,
  Category_derived = CASE
    WHEN WindSpeed_mph IS NULL THEN NULL
    WHEN WindSpeed_mph >= 157 THEN 5
    WHEN WindSpeed_mph >= 130 THEN 4
    WHEN WindSpeed_mph >= 111 THEN 3
    WHEN WindSpeed_mph >=  96 THEN 2
    WHEN WindSpeed_mph >=  74 THEN 1
    ELSE 0
  END,
  Category = COALESCE(Category_int,
    CASE
      WHEN WindSpeed_mph IS NULL THEN NULL
      WHEN WindSpeed_mph >= 157 THEN 5
      WHEN WindSpeed_mph >= 130 THEN 4
      WHEN WindSpeed_mph >= 111 THEN 3
      WHEN WindSpeed_mph >=  96 THEN 2
      WHEN WindSpeed_mph >=  74 THEN 1
      ELSE 0
    END)
FROM dbo.Hurricanes_Stage;
GO
SELECT
  RowID,
  Name,
  StartDate = CONVERT(varchar(10), StartDate, 23),
  EndDate   = CONVERT(varchar(10), EndDate,   23),
  WindSpeed_mph, WindSpeed_kmh,
  Pressure_hPa, Pressure_inHg,
  Areas_affected,
  Deaths,
  Damage_USD,
  Category_raw,
  Category_derived,
  Category
FROM dbo.Hurricanes_Final
ORDER BY TRY_CAST(RowID AS int);