----------------------------------------------------------------------------------------------------
-- Data exploarationn Analysis DEA
-- -------------------------------------------------------------------------------------------------------
-- Checking the user profiles table 
-- Checking the total columns of the table 


select *
from workspace.default.bright_tv_user_profile
limit 15;

-- ID Count for users

select COUNT(DISTINCT UserID) as Total_Users 
from workspace.default.bright_tv_user_profile;

--Total users = 5375 

---------------------------------------------------------------------------------------------------------
-- Checking Provinces of Subscribers
--------------------------------------------------------------------------------------------------------

select DISTINCT (Province) as Provinces 
from workspace.default.bright_tv_user_profile;

--Total of 9 Provinces with 1 None Record ,

-------------------------------------------------------------------------------------------
-- Checking different races of subscibers in the Bright TV 
-------------------------------------------------------------------------------------------

select DISTINCT(Race) as Differennt_Races
from workspace.default.bright_tv_user_profile;

-- Output for races 
-- Different Races 
--White
-- Black 
-- Coloured 
-- Other 
-- Indian_asian

-----------------------------------------------------------------------------------------------------------------------------
-- Checking different genders in the data set 
---------------------------------------------------------------------------------------------------------------------------

select DISTINCT(Gender) as Gender
from workspace.default.bright_tv_user_profile;

----------------------------------------------------------------------------------------------------------------------------
-- Checking different age in the user profile
---------------------------------------------------------------------------------------------------------------------------

select Min(Age) as Lowest_Age 
from workspace.default.bright_tv_user_profile

select Max(Age) as Highest_Age
from workspace.default.bright_tv_user_profile;

--------------------------------------------------------------------------------------------------------------------------
-- Data Exploration Analysis for Viwership table 
--------------------------------------------------------------------------------------------------------------------------
-- checking columns of the data set 

select * 
from workspace.default.bright_tv_viewership
limit 15;

-- duplicate identified for user id column 

-- Checking different chanels of the TV 

select Channel2,
       COUNT(DISTINCT userID0) As View_count,
from workspace.default.bright_tv_viewership
group by Channel2
order by count(distinct userID0) DESC;

--checking dates

select min(RecordDate2) as Minimum_Date 
from workspace.default.bright_tv_viewership;

select Max(RecordDate2) as Highest_Date
from workspace.default.bright_tv_viewership;

-- Changing Time Formats 

select RecordDate2,
       from_utc_timestamp(RecordDate2, 'Africa/Johannesburg') as RecordDate_SA
from workspace.default.bright_tv_viewership;

-- checking duration

SELECT Channel2,
    COUNT(DISTINCT UserID0) AS ViewCount,
    SUM(
        HOUR(`Duration 2`)*3600 + 
        MINUTE(`Duration 2`)*60 + 
        SECOND(`Duration 2`)
    ) AS TotalDurationSeconds,
    FROM_UNIXTIME(
        SUM(
            HOUR(`Duration 2`)*3600 + 
            MINUTE(`Duration 2`)*60 + 
            SECOND(`Duration 2`)
        ), 
        'HH:mm:ss'
    ) AS TotalDuration_HMS
FROM workspace.default.bright_tv_viewership
GROUP BY channel2;


-- Checking joins, combining two diffrent tables  
-- -- FULL OUTER JOIN 

SELECT A.UserID0,
       A.Channel2,
       A.RecordDate2,
       A.`Duration 2`,
       B.UserID,
       B.Gender,
       B.Age,
       B.Province,
       B.Race
FROM `workspace`.`default`.`bright_tv_viewership` AS A
FULL OUTER JOIN workspace.default.bright_tv_user_profile AS B
ON A.UserID0 = B.UserID;

-- FULL OUTER JOIN REMOVING DUPLICATES ID, NONE

SELECT A.UserID0,
       A.Channel2,
       A.RecordDate2,
       A.`Duration 2`,
       B.UserID,
    IF(Race IS NULL OR Race = 'None', 'Unknown', Race) AS Race,
    IF(Gender IS NULL OR Gender = 'None', 'Unknown', Gender) AS Gender,
    IF(Province IS NULL OR Province = 'None', 'Unknown', Province) AS Province,

    COALESCE(Age, 0) AS Age,
    COALESCE(UserID0, UserId) AS UserID

FROM `workspace`.`default`.`bright_tv_viewership` AS A
FULL OUTER JOIN workspace.default.bright_tv_user_profile AS B
ON A.UserID0 = B.UserID;


-- Time buckets case statments 

select  `Duration 2`,
       RecordDate2,
       Channel2,
       count(UserID0) as View_Counts,
CASE 
          WHEN date_format(`Duration 2`, 'HH:mm:ss') BETWEEN '00:00:00' AND '11:59:59' THEN '01. Morning'
          WHEN date_format(`Duration 2`, 'HH:mm:ss') BETWEEN '12:00:00' AND '16:59:59' THEN '02. Afternoon'
          WHEN date_format(`Duration 2`, 'HH:mm:ss') >= '17:00:00' THEN '03. Evening'
     END AS Time_Buckets
from workspace.default.bright_tv_viewership
group by Channel2, `Duration 2`, RecordDate2;


-- Dates and Day name, Month name classification 

select RecordDate2,
    CAST(RecordDate2 AS DATE) AS RecordDate,
    DATE_FORMAT(RecordDate2, 'HH:mm:ss') AS RecordTime,
       dayname(RecordDate2) As Day_Name,
       Monthname(RecordDate2) As Month_Name,
       Dayofmonth(RecordDate2) As Day_Of_Month,

       CASE 
           WHEN Day_Name IN ('Sun', 'Sat') THEN 'weekend'
           ELSE 'Weekday'
       END AS Day_Classification
FROM workspace.default.bright_tv_viewership;

----------------------------------------------------------------------------------------------------------------------------------------------------
--RUNNING THE BIG QUERY, FEATURE BUILDING, FINAL AGGREGATED DATA
-----------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 

-- Separation of dates and time
    CAST(A.RecordDate2 AS DATE) AS RecordDate,
    DATE_FORMAT(A.RecordDate2, 'HH:mm:ss') AS RecordTime,

-- Day Name functions and Month Functions
    dayname(A.RecordDate2) As Day_Name,
    Monthname(A.RecordDate2) As Month_Name,
    Dayofmonth(A.RecordDate2) As Day_Of_Month,
    A.RecordDate2,

-- Changing of time zones from UTC to SA Johannesburg 
    from_utc_timestamp(A.RecordDate2, 'Africa/Johannesburg') as RecordDate_SA,

-- Day Classifications buckets/ case statements 
    CASE 
        WHEN dayname(A.RecordDate2) IN ('Sun', 'Sat') THEN 'weekend'
        ELSE 'Weekday'
    END AS Day_Classification,

-- Count ID's 
    A.Channel2,
    COUNT(DISTINCT A.UserID0) AS ViewCount,
    COUNT(A.UserID0) AS Total_Number_Of_Profiles, 
    COUNT(DISTINCT A.Channel2) AS Total_Channels,

-- Time Buckets
    CASE 
        WHEN date_format(A.RecordDate2, 'HH:mm:ss') BETWEEN '00:00:00' AND '11:59:59' THEN '01. Morning'
        WHEN date_format(A.RecordDate2, 'HH:mm:ss') BETWEEN '12:00:00' AND '16:59:59' THEN '02. Afternoon'
        WHEN date_format(A.RecordDate2, 'HH:mm:ss') >= '17:00:00' THEN '03. Evening'
    END AS Time_Buckets,

-- Engagement Buckets for Content/ Channel Consumption
    date_format(A.`duration 2`, 'HH:mm:ss') AS DURATION,
    CASE
        WHEN date_format(A.`duration 2`, 'HH:mm:ss') BETWEEN '00:00:00' AND '00:30:59' THEN 'Low Consumption'
        WHEN date_format(A.`duration 2`, 'HH:mm:ss') BETWEEN '00:31:00' AND '02:59:59' THEN 'Medium Consumption'
        WHEN date_format(A.`duration 2`, 'HH:mm:ss') > '03:00:00' THEN 'High Consumption'
        ELSE 'High High Consumption'
    END AS EngangementBuckets,

-- Age classification/ buckets 
  CASE
        WHEN B.Age BETWEEN 0 AND 12 THEN 'Children'
        WHEN B.Age BETWEEN 13 AND 19 THEN 'Teenagers'
        WHEN B.Age BETWEEN 20 AND 39 THEN 'Youth'
        WHEN B.Age BETWEEN 40 AND 59 THEN 'Adults'
        ELSE 'Older Adults'
    END AS Age_Classification,

-- Removal of Nulls in the output 
    A.UserID0,
    IF(B.Race IS NULL OR B.Race = 'None', 'Unknown', B.Race) AS Race,
    IF(B.Gender IS NULL OR B.Gender = 'None', 'Unknown', B.Gender) AS Gender,
    IF(B.Province IS NULL OR B.Province = 'None', 'Unknown', B.Province) AS Province,
    COALESCE(B.Age, 0) AS Age,
    COALESCE(A.UserID0, B.UserId) AS UserID

FROM `workspace`.`default`.`bright_tv_viewership` AS A
LEFT JOIN workspace.default.bright_tv_user_profile AS B
ON A.UserID0 = B.UserID

-- Group By statements 
GROUP BY B.Age,
         B.Race,
         A.Channel2,
         A.RecordDate2,
         dayname(A.RecordDate2),
         Monthname(A.RecordDate2),
         Dayofmonth(A.RecordDate2),
         B.Gender,
         B.Province,
         A.`Duration 2`,
         A.UserID0,
         B.UserId,
         from_utc_timestamp(A.RecordDate2, 'Africa/Johannesburg')
