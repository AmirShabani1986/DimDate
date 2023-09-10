-- Script created by Amir Shabani
-- Contact: amirshabani99@gmail.com

USE [DataBaseName]
--
DECLARE @FromDate DATE ='1998-01-01'
DECLARE @ToDate DATE='2030-01-01'
--
--Check Necessary Schema 
---------------------------------------------------------------- Check Schema STG
IF NOT EXISTS(SELECT TOP 1 *  FROM sys.schemas WHERE name='STG')
	BEGIN 
		DECLARE @TSQLCommand1 VARCHAR(MAX)
		SET @TSQLCommand1='CREATE SCHEMA [STG]'
		EXECUTE(@TSQLCommand1)
	END
ELSE 
	BEGIN 
		PRINT ('01 - Schema STG is checked')
	END
---------------------------------------------------------------- Check Schema Dim
IF NOT EXISTS(SELECT TOP 1 *  FROM sys.schemas WHERE name='Dim')
	BEGIN 
		DECLARE @TSQLCommand2 VARCHAR(MAX)
		SET @TSQLCommand2='CREATE SCHEMA [Dim]'
		EXECUTE(@TSQLCommand2)
	END
ELSE 
	BEGIN 
		PRINT ('02 - Schema Dim is checked')
	END


--CleanUp
------------------------------------ Table STG.DimDateSolar
IF NOT EXISTS (
				SELECT TOP 1 * FROM SYS.tables
				WHERE name ='DimDateSolar' AND schema_id=SCHEMA_ID('STG'))
	BEGIN 
			create table STG.DimDateSolar
			(
			DateKey                 int not null,
			FullDate                date not null,
			DayNumberOfWeek         tinyint not null,
			DayNameOfWeek           nvarchar(10) not null,
			WeekDayType             nvarchar(7) not null,
			DayNumberOfMonth        tinyint not null,
			DayNumberOfYear         smallint not null,
			WeekNumberOfYear        tinyint not null,
			MonthNameOfYear         nvarchar(10) not null,
			MonthNumberOfYear       tinyint not null,
			QuarterNumberCalendar   tinyint not null,
			QuarterNameCalendar     nchar(2) not null,
			SemesterNumberCalendar  tinyint not null,
			SemesterNameCalendar    nvarchar(15) not null,
			YearCalendar            smallint not null,
			MonthNumberFiscal       tinyint not null,
			QuarterNumberFiscal     tinyint not null,
			QuarterNameFiscal       nchar(2) not null,
			SemesterNumberFiscal    tinyint not null,
			SemesterNameFiscal      nvarchar(15) not null,
			YearFiscal              smallint not null
 			constraint PK_DimDate primary key clustered  
			(DateKey asc) ) 
	END
ELSE 
	IF EXISTS (SELECT TOP 1 * FROM STG.DimDateSolar)
		BEGIN 
			TRUNCATE TABLE STG.DimDateSolar
			PRINT('     Table STG.DimDateSolar has been Truncated')
		END 
	ELSE 

	BEGIN 
		PRINT ('03 - Table DimDateSolar is Checked')
	END

------------------------------------ Function UDF_Gregorian_To_Persian
IF NOT EXISTS ( SELECT 1
			FROM    Information_schema.Routines
			WHERE   Specific_schema = 'dbo'
					AND specific_name = 'UDF_Gregorian_To_Persian'
					AND Routine_Type = 'FUNCTION' ) 
	BEGIN 
		DECLARE @TSQLCommand4 VARCHAR(MAX)
		SET @TSQLCommand4='
							CREATE FUNCTION [dbo].[UDF_Gregorian_To_Persian] (@date datetime)
					Returns nvarchar(50)
					AS 
					Begin
						Declare @depoch as bigint
						Declare @cycle  as bigint
						Declare @cyear  as bigint
						Declare @ycycle as bigint
						Declare @aux1 as bigint
						Declare @aux2 as bigint
						Declare @yday as bigint
						Declare @Jofst  as Numeric(18,2)
						Declare @jdn bigint

						Declare @iYear   As Integer
						Declare @iMonth  As Integer
						Declare @iDay    As Integer

						Set @Jofst=2415020.5
						Set @jdn=Round(Cast(@date as int)+ @Jofst,0)

						Set @depoch = @jdn - [dbo].[UDF_Persian_To_Julian](475, 1, 1) 
						Set @cycle = Cast(@depoch / 1029983 as int) 
						Set @cyear = @depoch%1029983 

						If @cyear = 1029982
						   Begin
							 Set @ycycle = 2820 
						   End
						Else
						   Begin
							Set @aux1 = Cast(@cyear / 366 as int) 
							Set @aux2 = @cyear%366 
							Set @ycycle = Cast(((2134 * @aux1) + (2816 * @aux2) + 2815) / 1028522 as int) + @aux1 + 1 
						  End

						Set @iYear = @ycycle + (2820 * @cycle) + 474 

						If @iYear <= 0
						  Begin 
							Set @iYear = @iYear - 1 
						  End
						Set @yday = (@jdn - [dbo].[UDF_Persian_To_Julian](@iYear, 1, 1)) + 1 
						If @yday <= 186 
						   Begin
							 Set @iMonth = CEILING(Convert(Numeric(18,4),@yday) / 31) 
						   End
						Else
						   Begin
							  Set @iMonth = CEILING((Convert(Numeric(18,4),@yday) - 6) / 30)  
						   End
						   Set @iDay = (@jdn - [dbo].[UDF_Persian_To_Julian](@iYear, @iMonth, 1)) + 1 

						  Return Convert(nvarchar(50),@iDay) + ''-'' +   Convert(nvarchar(50),@iMonth) +''-'' + Convert(nvarchar(50),@iYear)
					End
		'
		EXECUTE(@TSQLCommand4)
	END
ELSE 
	BEGIN 
		PRINT ('04 - Function UDF_Gregorian_To_Persian is checked')
	END
------------------------------------ Function UDF_Persian_To_Julian
IF NOT EXISTS ( SELECT 1
			FROM    Information_schema.Routines
			WHERE   Specific_schema = 'dbo'
					AND specific_name = 'UDF_Persian_To_Julian'
					AND Routine_Type = 'FUNCTION' ) 
	BEGIN 
		DECLARE @TSQLCommand5 VARCHAR(MAX)
		SET @TSQLCommand5='
		CREATE FUNCTION [dbo].[UDF_Persian_To_Julian](@iYear int,@iMonth int,@iDay int)
		RETURNS bigint
		AS
		Begin

		Declare @PERSIAN_EPOCH  as int
		Declare @epbase as bigint
		Declare @epyear as bigint
		Declare @mdays as bigint
		Declare @Jofst  as Numeric(18,2)
		Declare @jdn bigint

		Set @PERSIAN_EPOCH=1948321
		Set @Jofst=2415020.5

		If @iYear>=0 
			Begin
				Set @epbase=@iyear-474 
			End
		Else
			Begin
				Set @epbase = @iYear - 473 
			End
			set @epyear=474 + (@epbase%2820) 
		If @iMonth<=7
			Begin
				Set @mdays=(Convert(bigint,(@iMonth) - 1) * 31)
			End
		Else
			Begin
				Set @mdays=(Convert(bigint,(@iMonth) - 1) * 30+6)
			End
			Set @jdn =Convert(int,@iday) + @mdays+ Cast(((@epyear * 682) - 110) / 2816 as int)  + (@epyear - 1) * 365 + Cast(@epbase / 2820 as int) * 1029983 + (@PERSIAN_EPOCH - 1) 
			RETURN @jdn
		End'
		EXECUTE(@TSQLCommand5)
	END
ELSE 
	BEGIN 
		PRINT ('05 - Function UDF_Persian_To_Julian is checked')
	END

------------------------------------ Function UDF_Julian_To_Gregorian
IF NOT EXISTS ( SELECT 1
			FROM    Information_schema.Routines
			WHERE   Specific_schema = 'dbo'
					AND specific_name = 'UDF_Julian_To_Gregorian'
					AND Routine_Type = 'FUNCTION' ) 
	BEGIN 
		DECLARE @TSQLCommand6 VARCHAR(MAX)
		SET @TSQLCommand6='
		CREATE FUNCTION [dbo].[UDF_Julian_To_Gregorian] (@jdn bigint)
		Returns nvarchar(11)
		AS
		Begin
			Declare @Jofst  as Numeric(18,2)
			Set @Jofst=2415020.5
			Return Convert(nvarchar(11),Convert(datetime,(@jdn- @Jofst),113),110)
		End		'
		EXECUTE(@TSQLCommand6)
	END
ELSE 
	BEGIN 
		PRINT ('06 - Function UDF_Julian_To_Gregorian is checked')
	END

------------------------------------ Function UDFMake1numTo2Num
IF NOT EXISTS ( SELECT 1
			FROM    Information_schema.Routines
			WHERE   Specific_schema = 'dbo'
					AND specific_name = 'UDFMake1numTo2Num'
					AND Routine_Type = 'FUNCTION' ) 
	BEGIN 
		DECLARE @TSQLCommand7 VARCHAR(MAX)
		SET @TSQLCommand7='
							CREATE FUNCTION [dbo].[UDFMake1numTo2Num](@StrMyNum NVARCHAR(2))
								RETURNS NVARCHAR(2)
							AS
							BEGIN
								DECLARE @MyNunInStr NVARCHAR(10)
								SET @MyNunInStr = @StrMyNum
								IF LEN(@MyNunInStr) < 2 
								BEGIN
								 SET @MyNunInStr = ''0'' + @MyNunInStr
								END
							RETURN @MyNunInStr
							END 
		'
		EXECUTE(@TSQLCommand7)
	END
ELSE 
	BEGIN 
		PRINT ('07 - Function UDFMake1numTo2Num is checked')
	END
------------------------------------ Function UDF_ReverseShamsiDate
IF NOT EXISTS ( SELECT 1
			FROM    Information_schema.Routines
			WHERE   Specific_schema = 'dbo'
					AND specific_name = 'UDF_ReverseShamsiDate'
					AND Routine_Type = 'FUNCTION' ) 
	BEGIN 
		DECLARE @TSQLCommand8 VARCHAR(MAX)
		SET @TSQLCommand8='
							CREATE FUNCTION [dbo].[UDF_ReverseShamsiDate](@StrDateShamsi NVARCHAR(10), @Seperator CHAR(1))
							RETURNS NVARCHAR(10)
							AS
							BEGIN
								DECLARE @StrDayOfMotn NVARCHAR(10)
								DECLARE @StrMothOfYear NVARCHAR(10)
								DECLARE @StrYearOfYear NVARCHAR(10)
    
									SET @StrDayOfMotn = dbo.UDFMake1numTo2Num(REPLACE(SUBSTRING(@StrDateShamsi , 1 , ((SELECT CHARINDEX(''-'' , @StrDateShamsi , 0)))), ''-'' , ''''))
									SET  @StrMothOfYear = dbo.UDFMake1numTo2Num(REPLACE(SUBSTRING(@StrDateShamsi , ((CHARINDEX(''-'' , @StrDateShamsi , 0)  )) , 3) , ''-'' , ''''))
									SET @StrYearOfYear = RIGHT(@StrDateShamsi , 4)

								return (@StrYearOfYear + @Seperator + @StrMothOfYear + @Seperator + @StrDayOfMotn)
							END
		
		'
		EXECUTE(@TSQLCommand8)
	END
ELSE 
	BEGIN 
		PRINT ('08 - Function UDF_ReverseShamsiDate is checked')
	END

------------------------------------Function MakeDateShamsiToMiladi
IF NOT EXISTS ( SELECT 1
			FROM    Information_schema.Routines
			WHERE   Specific_schema = 'dbo'
					AND specific_name = 'MakeDateShamsiToMiladi'
					AND Routine_Type = 'FUNCTION' ) 
	BEGIN 
		DECLARE @TSQLCommand9 VARCHAR(MAX)
		SET @TSQLCommand9='
		
						CREATE FUNCTION [dbo].[MakeDateShamsiToMiladi](@InputShamsiDateString nvarchar(10))
						RETURNS datetime
						AS
						BEGIN
							declare @InputShamsiDateString1 nvarchar(10)
							declare @yearm int
							declare @monthm int
							declare @daym int
							set @yearm = CONVERT(int , SUBSTRING(@InputShamsiDateString , 1 , 4))
							set @monthm = CONVERT(int , SUBSTRING(@InputShamsiDateString , 6 , 2))
							set @daym = CONVERT(int , SUBSTRING(@InputShamsiDateString , 9 , 2))
							return (select dbo.[UDF_Julian_To_Gregorian](dbo.[UDF_Persian_To_Julian](@yearm,@monthm ,@daym )))
						END
		'
		EXECUTE(@TSQLCommand9)
	END
ELSE 
	BEGIN 
		PRINT ('09 - Function MakeDateShamsiToMiladi is checked')
	END


------------------------------------Function MakeCompleteShamsiDate

IF NOT EXISTS ( SELECT 1
			FROM    Information_schema.Routines
			WHERE   Specific_schema = 'dbo'
					AND specific_name = 'MakeCompleteShamsiDate'
					AND Routine_Type = 'FUNCTION' ) 
	BEGIN 
		DECLARE @TSQLCommand10 VARCHAR(MAX)
		SET @TSQLCommand10='
						CREATE FUNCTION [dbo].[MakeCompleteShamsiDate](@InputMiladiDate DateTime , @MySeperatorChar char(1))
						RETURNS NVARCHAR(10)
						AS
						BEGIN
							return (select dbo.UDF_ReverseShamsiDate(dbo.UDF_Gregorian_To_Persian(@InputMiladiDate), @MySeperatorChar) AS ShamsiDateOfLog)
						END
		'
		EXECUTE(@TSQLCommand10)
	END
ELSE 
	BEGIN 
		PRINT ('10 - Function MakeCompleteShamsiDate is checked')
	END

	---
--IF NOT EXISTS ( SELECT 1
--			FROM    Information_schema.Routines
--			WHERE   Specific_schema = 'dbo'
--					AND specific_name = 'UDF_Gregorian_To_Persian'
--					AND Routine_Type = 'FUNCTION' ) 
--	BEGIN 
--		DECLARE @TSQLCommand3 VARCHAR(MAX)
--		SET @TSQLCommand3=''
--	END
--ELSE 
--	BEGIN 
--		PRINT ('Function UDF_Gregorian_To_Persian is checked')
--	END

--
------------------------------------Function [dbo].[PubSolarWeekOfYear]
IF NOT EXISTS ( SELECT 1
			FROM    Information_schema.Routines
			WHERE   Specific_schema = 'dbo'
					AND specific_name = 'PubSolarWeekOfYear'
					AND Routine_Type = 'FUNCTION' ) 
	BEGIN 
		DECLARE @TSQLCommand20 VARCHAR(MAX)
		SET @TSQLCommand20='
							CREATE FUNCTION [dbo].[PubSolarWeekOfYear](@dt int)
							RETURNS int AS 
							BEGIN
								if @dt=0 Return 0
								Return (dbo.PubSolarDayOfYear(@dt)+dbo.PubSolarDayOfWeek(dbo.PubGetYear(@dt)*10000+101)-1)/7+1
							END
		'
		EXECUTE(@TSQLCommand20)
	END
ELSE 
	BEGIN 
		PRINT ('20 - Function PubSolarWeekOfYear is checked')
	END
------------------------------------Function [dbo].[PubSolarDayOfYear]
IF NOT EXISTS ( SELECT 1
			FROM    Information_schema.Routines
			WHERE   Specific_schema = 'dbo'
					AND specific_name = 'PubSolarDayOfYear'
					AND Routine_Type = 'FUNCTION' ) 
	BEGIN 
		DECLARE @TSQLCommand21 VARCHAR(MAX)
		SET @TSQLCommand21='
							CREATE FUNCTION [dbo].[PubSolarDayOfYear](@dt int)
								RETURNS int AS 
								BEGIN
									declare @d int 
									set @d = dbo.PubGetYear(@dt) * 10000 + 101
									set @d = dbo.PubSolarToDay(@dt) - dbo.PubSolarToDay(@d) + 1
									return @d
								END
		'
		EXECUTE(@TSQLCommand21)
	END
ELSE 
	BEGIN 
		PRINT ('21 - Function PubSolarDayOfYear is checked')
	END
------------------------------------Function [dbo].[PubGetYear]
IF NOT EXISTS ( SELECT 1
			FROM    Information_schema.Routines
			WHERE   Specific_schema = 'dbo'
					AND specific_name = 'PubGetYear'
					AND Routine_Type = 'FUNCTION' ) 
	BEGIN 
		DECLARE @TSQLCommand22 VARCHAR(MAX)
		SET @TSQLCommand22='
							CREATE FUNCTION [dbo].[PubGetYear](@dt int)
								RETURNS int AS 
								BEGIN
									return @dt / 10000 
								END
		'
		EXECUTE(@TSQLCommand22)
	END
ELSE 
	BEGIN 
		PRINT ('22 - Function PubGetYear is checked')
	END
------------------------------------Function [dbo].[PubSolarToDay]
IF NOT EXISTS ( SELECT 1
			FROM    Information_schema.Routines
			WHERE   Specific_schema = 'dbo'
					AND specific_name = 'PubSolarToDay'
					AND Routine_Type = 'FUNCTION' ) 
	BEGIN 
		DECLARE @TSQLCommand23 VARCHAR(MAX)
		SET @TSQLCommand23='
						Create FUNCTION [dbo].[PubSolarToDay](@dt int)
						RETURNS int AS 
						BEGIN
							declare @y int, @m int, @d int, @tmp int, @i int

							set @y = @dt / 10000 
							set @m = (@dt - @y * 10000) / 100
							set @d = @dt % 100
							set @y = @y - 1
							set @tmp = @y * 365
							if @m - 1 <= 6 
								set @tmp = @tmp + ((@m - 1) * 31)
							else
							begin
								set @tmp = @tmp + (6 * 31)
								set @tmp = @tmp + ((@m - 7) * 30)
							end
							set @tmp = @tmp + @d
							set @i = @y / 33
							set @tmp = @tmp + (@i * 8)
							set @y = @y - (@i * 33)
							if (@y >= 1) and (@y <= 20)
								set @tmp = @tmp + ((@y - 1) / 4) + 1
							else
								if @y = 21
									set @tmp = @tmp + 5
								else
									if @y >= 22
										set @tmp = @tmp + ((@y - 22) / 4) + 6
							return @tmp
						END
		'
		EXECUTE(@TSQLCommand23)
	END
ELSE 
	BEGIN 
		PRINT ('23 - Function PubSolarToDay is checked')
	END
------------------------------------Function [dbo].[PubSolarDayOfWeek]
IF NOT EXISTS ( SELECT 1
			FROM    Information_schema.Routines
			WHERE   Specific_schema = 'dbo'
					AND specific_name = 'PubSolarDayOfWeek'
					AND Routine_Type = 'FUNCTION' ) 
	BEGIN 
		DECLARE @TSQLCommand24 VARCHAR(MAX)
		SET @TSQLCommand24='
							CREATE FUNCTION [dbo].[PubSolarDayOfWeek](@dt int)
								RETURNS int AS 
								BEGIN
									declare @d int 
									set @d = (dbo.PubSolarToDay(@dt) % 7) + 4
									if @d >= 7 set @d = @d - 7
									return @d
								END
		'
		EXECUTE(@TSQLCommand24)
	END
ELSE 
	BEGIN 
		PRINT ('24 - Function PubSolarDayOfWeek is checked')
	END
------------------------------------Function [dbo].[PubSolarWeekOfMonth]
IF NOT EXISTS ( SELECT 1
			FROM    Information_schema.Routines
			WHERE   Specific_schema = 'dbo'
					AND specific_name = 'PubSolarWeekOfMonth'
					AND Routine_Type = 'FUNCTION' ) 
	BEGIN 
		DECLARE @TSQLCommand25 VARCHAR(MAX)
		SET @TSQLCommand25='
							CREATE FUNCTION [dbo].[PubSolarWeekOfMonth](@dt int)
								RETURNS int AS 
								BEGIN
									if @dt=0 Return 0
									Return (dbo.PubGetDay(@dt)+dbo.PubSolarDayOfWeek(dbo.PubSolarStartMonth(@dt))-1)/7+1
								END
		'
		EXECUTE(@TSQLCommand25)
	END
ELSE 
	BEGIN 
		PRINT ('25 - Function PubSolarWeekOfMonth is checked')
	END
------------------------------------Function [dbo].[PubGetDay]
IF NOT EXISTS ( SELECT 1
			FROM    Information_schema.Routines
			WHERE   Specific_schema = 'dbo'
					AND specific_name = 'PubGetDay'
					AND Routine_Type = 'FUNCTION' ) 
	BEGIN 
		DECLARE @TSQLCommand26 VARCHAR(MAX)
		SET @TSQLCommand26='
							Create FUNCTION [dbo].[PubGetDay](@dt int)
								RETURNS int AS 
								BEGIN
									return @dt % 100
								END
		'
		EXECUTE(@TSQLCommand26)
	END
ELSE 
	BEGIN 
		PRINT ('26 - Function PubGetDay is checked')
	END
--------------------------------
------------------------------------Function [dbo].[PubSolarStartMonth]
IF NOT EXISTS ( SELECT 1
			FROM    Information_schema.Routines
			WHERE   Specific_schema = 'dbo'
					AND specific_name = 'PubSolarStartMonth'
					AND Routine_Type = 'FUNCTION' ) 
	BEGIN 
		DECLARE @TSQLCommand27 VARCHAR(MAX)
		SET @TSQLCommand27='
							CREATE FUNCTION [dbo].[PubSolarStartMonth](@dt int)
								RETURNS int AS 
								BEGIN
									if(@dt=0) return 0
									return (@dt / 100)*100+01 
								END
		'
		EXECUTE(@TSQLCommand27)
	END
ELSE 
	BEGIN 
		PRINT ('27 - Function PubSolarStartMonth is checked')
	END
/**********************************************************************************/


--Fill DimDateSolar

declare @DateCalendarStart  datetime,
        @DateCalendarEnd    datetime,
        @FiscalCounter      datetime,
        @FiscalMonthOffset  int;
 
set @DateCalendarStart = @FromDate;
set @DateCalendarEnd = @ToDate;
 
-- Set this to the number of months to add or extract to the current date to get the beginning 
-- of the Fiscal Year. Example: If the Fiscal Year begins July 1, assign the value of 6 
-- to the @FiscalMonthOffset variable. Negative values are also allowed, thus if your 
-- 2012 Fiscal Year begins in July of 2011, assign a value of -6.
set @FiscalMonthOffset = 6;
 
with DateDimension  
as
(
    select  @DateCalendarStart as DateCalendarValue,
            dateadd(m, @FiscalMonthOffset, @DateCalendarStart) as FiscalCounter
                 
    union all
     
    select  DateCalendarValue + 1,
            dateadd(m, @FiscalMonthOffset, (DateCalendarValue + 1)) as FiscalCounter
    from    DateDimension 
    where   DateCalendarValue + 1 < = @DateCalendarEnd
)
 
insert into STG.DimDateSolar (DateKey, FullDate, DayNumberOfWeek, DayNameOfWeek, WeekDayType, 
                        DayNumberOfMonth, DayNumberOfYear, WeekNumberOfYear, MonthNameOfYear, 
                        MonthNumberOfYear, QuarterNumberCalendar, QuarterNameCalendar, SemesterNumberCalendar, 
                        SemesterNameCalendar, YearCalendar, MonthNumberFiscal, QuarterNumberFiscal, 
                        QuarterNameFiscal, SemesterNumberFiscal, SemesterNameFiscal, YearFiscal)
 
select  cast(convert(varchar(25), DateCalendarValue, 112) as int) as 'DateKey',
        cast(DateCalendarValue as date) as 'FullDate',
        datepart(weekday, DateCalendarValue) as 'DayNumberOfWeek',
        datename(weekday, DateCalendarValue) as 'DayNameOfWeek',
        case datename(dw, DateCalendarValue)
            when 'Saturday' then 'Weekend'
            when 'Sunday' then 'Weekend'
        else 'Weekday'
        end as 'WeekDayType',
        datepart(day, DateCalendarValue) as'DayNumberOfMonth',
        datepart(dayofyear, DateCalendarValue) as 'DayNumberOfYear',
        datepart(week, DateCalendarValue) as 'WeekNumberOfYear',
        datename(month, DateCalendarValue) as 'MonthNameOfYear',
        datepart(month, DateCalendarValue) as 'MonthNumberOfYear',
        datepart(quarter, DateCalendarValue) as 'QuarterNumberCalendar',
        'Q' + cast(datepart(quarter, DateCalendarValue) as nvarchar) as 'QuarterNameCalendar',
        case
            when datepart(month, DateCalendarValue) <= 6 then 1
            when datepart(month, DateCalendarValue) > 6 then 2
        end as 'SemesterNumberCalendar',
        case
            when datepart(month, DateCalendarValue) < = 6 then 'First Semester'
            when datepart(month, DateCalendarValue) > 6 then 'Second Semester' 
        end as 'SemesterNameCalendar',
        datepart(year, DateCalendarValue) as 'YearCalendar',
        datepart(month, FiscalCounter) as 'MonthNumberFiscal',
        datepart(quarter, FiscalCounter) as 'QuarterNumberFiscal',
        'Q' + cast(datepart(quarter, FiscalCounter) as nvarchar) as 'QuarterNameFiscal',  
        case
            when datepart(month, FiscalCounter) < = 6 then 1
            when datepart(month, FiscalCounter) > 6 then 2 
        end as 'SemesterNumberFiscal',  
        case
            when datepart(month, FiscalCounter) < = 6 then 'First Semester'
            when  datepart(month, FiscalCounter) > 6 then 'Second Semester'
        end as 'SemesterNameFiscal',            
        datepart(year, FiscalCounter) as 'YearFiscal'
from    DateDimension
order by
        DateCalendarValue
option (maxrecursion 0);

GO

--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
 --------------------------------------------------------Create And Check Dim.DimDate

DECLARE @a INT
------------------Check IF Table Dim.DimDate Exists
IF  EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES
           WHERE TABLE_NAME = N'DimDate' AND TABLE_SCHEMA= N'Dim')  
 BEGIN
------------------Check IF Table Dim.DimDate Has Data in it then truncate 
  IF EXISTS (SELECT TOP 1 * FROM Dim.DimDate)
	 BEGIN 
		TRUNCATE TABLE Dim.DimDate

	END
  ELSE 
	BEGIN
            PRINT('DimDate has been checked')
	END
  END 
ELSE
 BEGIN 
 ------------------Create Dim.DimDate
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	CREATE TABLE [DIM].[DimDate](
		[DateSk] [INT] IDENTITY(1,1) NOT NULL,
		[CFullDate] [DATETIME2](7) NOT NULL,
		[CDateTXT1] [VARCHAR](8) NOT NULL,
		[CDateTXT2] [VARCHAR](10) NOT NULL,
		[CYear] [SMALLINT] NOT NULL,
		[CMonth] [SMALLINT] NOT NULL,
		[CMonthName] [NVARCHAR](10) NOT NULL,
		[CDayOFWeek] [SMALLINT] NOT NULL,
		[CDayOFWeekName] [NVARCHAR](10) NOT NULL,
		[CDayOFYear] [SMALLINT] NOT NULL,
		[CISHoliday] [TINYINT] NOT NULL,
		[CHolidayDesc] [NVARCHAR](50) NULL,
		[SDate] [INT] NOT NULL,
		[SDateTXT1] NVARCHAR(8) NOT NULL,
		[SDateTXT2] NVARCHAR(10) NOT NULL,
		[SYear] [CHAR](4) NOT NULL,
		[SMonth] [SMALLINT] NOT NULL,
		[SMonthName] [NVARCHAR](10) NOT NULL,
		[SDayOFMonth] [SMALLINT] NOT NULL,
		SDayOFMonthTXT [NVARCHAR](2) NOT NULL,
		SWeekOfYear SMALLINT,
		SWeekOfMonth SMALLINT,
		[SDayOfWeek] [SMALLINT] NOT NULL,
		[SDayOfWeekName] [NVARCHAR](10) NOT NULL,
		[SDayOfYear] [SMALLINT] NOT NULL,
		[SSeassonNumber] SMALLINT NOT NULL,
		[SSeassonName] [NVARCHAR](15) NOT NULL,
		[SISHoliday] [TINYINT] NOT NULL,
		[SISHolidayTXT] CHAR(1) NOT NULL,
		[SHolidayDesc] [NVARCHAR](50) NULL,
		[CMonthNumberFiscal] [TINYINT] NOT NULL,
		[CQuarterNumberFiscal] [TINYINT] NOT NULL,
		[CQuarterNameFiscal] [NCHAR](2) NOT NULL,
		[CSemesterNumberFiscal] [TINYINT] NOT NULL,
		[CSemesterNameFiscal] [NVARCHAR](15) NOT NULL,
		[CYearFiscal] [SMALLINT] NOT NULL,
	 CONSTRAINT [PK_DimDate] PRIMARY KEY CLUSTERED 
	(
		[DateSk] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END 



	INSERT INTO Dim.DimDate
	(	
	    CFullDate,
	    CDateTXT1,
		CDateTXT2,
	    CYear,
	    CMonth,
	    CMonthName,
	    CDayOFWeek,
	    CDayOFWeekName,
	    CDayOFYear,
	    CISHoliday,
	    CHolidayDesc,
	    SDate,
		SDateTXT1,
	    SDateTXT2,
		SYear,
	    SMonth,
	    SMonthName,
		SDayOFMonth,
		SDayOFMonthTXT,
		SWeekOfYear,
		SWeekOfMonth,
	    SDayOfWeek,
	    SDayOfWeekName,
	    SDayOfYear,
	    SSeassonNumber,
		SSeassonName,
		SISHoliday,
		SISHolidayTXT,
		SHolidayDesc,
	    CMonthNumberFiscal,
	    CQuarterNumberFiscal,
	    CQuarterNameFiscal,
	    CSemesterNumberFiscal,
	    CSemesterNameFiscal,
	    CYearFiscal
	)
SELECT	
		FullDate AS FullDate,
		Datekey AS CDateTXT1,
		CONVERT(DATE,CONVERT(VARCHAR(10),DateKey),111) AS CDateTXT2,
		YearCalendar AS 'CYear',
		MonthNumberOfYear AS 'CMonth',
		MonthNameOfYear AS 'CMonthName',
		DayNumberOfWeek AS 'CDayOFWeek',
		DayNameOfWeek AS 'SDayNameofWeek',
		DayNumberOfYear AS 'CDayOFYear',
		CIsHoliday=0,
		CHolidayDesc=N'',
		REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ','') 'SDate',
		CONVERT(NVARCHAR(8),REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ','')) 'SDateTXT1',
		REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ','-') 'SDateTXT2',
		SUBSTRING(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ',''),1,4) AS 'SYear',
		SUBSTRING(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ',''),5,2) AS 'SMonth',

		CASE	WHEN SUBSTRING(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ',''),5,2)=1 THEN N'فروردین'
				WHEN SUBSTRING(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ',''),5,2)=2 THEN N'اردیبهشت'
				WHEN SUBSTRING(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ',''),5,2)=3 THEN N'خرداد'
				WHEN SUBSTRING(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ',''),5,2)=4 THEN N'تیر'
				WHEN SUBSTRING(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ',''),5,2)=5 THEN N'مرداد'
				WHEN SUBSTRING(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ',''),5,2)=6 THEN N'شهریور'
				WHEN SUBSTRING(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ',''),5,2)=7 THEN N'مهر'
				WHEN SUBSTRING(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ',''),5,2)=8 THEN N'آبان'
				WHEN SUBSTRING(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ',''),5,2)=9 THEN N'آذر'
				WHEN SUBSTRING(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ',''),5,2)=10 THEN N'دی'
				WHEN SUBSTRING(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ',''),5,2)=11 THEN N'بهمن'
				WHEN SUBSTRING(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ',''),5,2)=12 THEN N'اسفند'
				ELSE 'N/A' END AS 'SMonthName',
		Convert(smallint,SUBSTRING(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ',''),7,2)) AS 'SDayOFMonth',
		Convert(NVARCHAR(2),SUBSTRING(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ',''),7,2)) AS 'SDayOFMonthTXT',
		 dbo.PubSolarWeekOfYear(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ','')) AS 'SWeekOfYear',
		 dbo.PubSolarWeekOfMonth(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ','')) AS 'SWeekOfMonth',
		CASE	WHEN DayNameOfWeek='Saturday' THEN 1
				WHEN DayNameOfWeek='Sunday' THEN 2
				WHEN DayNameOfWeek='Monday' THEN 3
				WHEN DayNameOfWeek='Tuesday' THEN 4
				WHEN DayNameOfWeek='Wednesday' THEN 5
				WHEN DayNameOfWeek='Thursday' THEN 6
				WHEN DayNameOfWeek='Friday' THEN 7
				ELSE 0 END AS 'SDayNameofWeek',
		CASE	WHEN DayNameOfWeek='Saturday' THEN N'شنبه'
				WHEN DayNameOfWeek='Sunday' THEN N'یکشنبه'
				WHEN DayNameOfWeek='Monday' THEN N'دوشنبه'
				WHEN DayNameOfWeek='Tuesday' THEN N'سه شنبه'
				WHEN DayNameOfWeek='Wednesday' THEN N'چهارشنبه'
				WHEN DayNameOfWeek='Thursday' THEN N'پنجشنبه'
				WHEN DayNameOfWeek='Friday' THEN N'جمعه'
				ELSE 'N/A'END AS 'SDayNameofWeek',
		ROW_NUMBER() OVER (PARTITION BY SUBSTRING(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ',''),1,4)
							ORDER BY SUBSTRING(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ',''),1,4)) AS 'SDayOfYear',
		CASE	WHEN SUBSTRING(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ',''),5,2)<4 THEN 1
				WHEN SUBSTRING(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ',''),5,2)<7 THEN 2
				WHEN SUBSTRING(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ',''),5,2)<10 THEN 3
				WHEN SUBSTRING(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ',''),5,2)<=12 THEN 4
				ELSE 0 END 'SSeasonNumber',
		CASE	WHEN SUBSTRING(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ',''),5,2)<4 THEN N'بهار'
				WHEN SUBSTRING(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ',''),5,2)<7 THEN N'تابستان'
				WHEN SUBSTRING(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ',''),5,2)<10 THEN N'پاییز'
				WHEN SUBSTRING(REPLACE([dbo].[MakeCompleteShamsiDate](FullDate , ''),' ',''),5,2)<=12 THEN N'زمستان'
				ELSE 'N/A' END 'SSeasonName',
		SISHoliday=0,
		[SISHolidayTXT]=0,
		SHolidayDesc='',
		QuarterNumberCalendar,QuarterNumberFiscal,QuarterNameFiscal,SemesterNumberFiscal,SemesterNameFiscal,YearFiscal
FROM STG.DimDateSolar



SELECT * FROM Dim.DimDate






