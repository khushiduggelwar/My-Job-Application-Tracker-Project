create table Job_application(
Application_id serial primary key,
Job_id varchar(100),
Company_name varchar(100),
Job_title varchar(200),
Application_link text,
Date_applied date,
Place_of_job varchar(100),
Experience_required varchar(100),
Referred_person varchar(100),
Contact_person varchar(150),
Contact_person_details varchar(150),
Status varchar(100)
);

select * from Job_application;

SELECT COUNT(*) FROM job_application;

select column_name, data_type
from information_schema.columns
where table_name = 'job_application';

SELECT COUNT(*)
FROM job_application
WHERE company_name IS NULL;

select count(*) from job_application where job_title is null;

select count(*) from job_application where date_applied is null;

select count(*) from job_application where status is null;

select status from Job_application;

--check status distribution
select status, count(*) as applications
from job_application
group by status
order by applications desc;

update job_application set status='Not Selected' where status ='Not selected';
update job_application set status='Not Selected' where 
status ='Not Shortlisted' or status ='Not shortlisted';

--check companies applied to
select Company_name, count(*) as applications
from job_application
group by Company_name
order by applications desc;

UPDATE job_application
SET company_name = TRIM(company_name);

update job_application 
set Company_name ='Wipro' where Company_name='Wipro ';

update job_application 
set Company_name='PwC' where Company_name IN ('Pwc','PWC');

update job_application 
set Company_name ='Double tick' where Company_name='Double tick.io';

update job_application 
set Company_name ='HP' where Company_name='Hp';

update job_application 
set Company_name ='Crownstack' where Company_name='Crown Stack';

--total applications 
select count(*) as total_applications from job_application;

--applications by status
select status, count(*) as applications
from job_application
group by status 
order by applications desc;

--top 10 companies applied to
select company_name, count(*) as applications
from job_application
group by company_name
order by applications desc
limit 10;

--most applied job titles
select job_title, count(*) as applications 
from job_application
group by job_title
order by applications desc;

--applications by month
select date_trunc('month', date_applied) as month,
count(*) as applications
from job_application
where date_applied is not null
group by month
order by applications desc;
-- or good format applications by month
SELECT
TO_CHAR(date_applied,'Mon YYYY') AS month,
COUNT(*) AS applications
FROM job_application
WHERE date_applied IS NOT NULL
GROUP BY TO_CHAR(date_applied,'Mon YYYY'),
DATE_TRUNC('month',date_applied)
ORDER BY DATE_TRUNC('month',date_applied);

--application by location
select place_of_job, count(*) as applications
from job_application
group by place_of_job
order by applications desc;

update job_application set place_of_job = 'Hyderabad' where place_of_job = 'Hyderbad';

update job_application set place_of_job ='Bengaluru' where place_of_job in('Bangalore','bengaluru');

update job_application set place_of_job = 'India' where place_of_job is null;

update job_application set place_of_job = 'Pune' where place_of_job = 'pune';

update job_application set place_of_job = 'Chennai' where place_of_job = 'chennai';

update job_application set place_of_job = 'Remote' where place_of_job = 'remote';

update job_application set place_of_job = 'Gurugram' where place_of_job = 'Gurgoan';

update job_application set place_of_job ='Mumbai' where place_of_job in('Andheri, Mumbai','Navi Mumbai');

update job_application set place_of_job = 'Hyderabad,Bengaluru' where place_of_job = 'Hyderabad/Bangalore';

update job_application set place_of_job = 'Bengaluru, Mumbai' where place_of_job = 'Mumbai/bangalore';

update job_application set status = 'No Reply' where status = 'Follow up';
--response rate
select round(sum(case
	when status in ('Not Selected', 'Rejected in Technical Round', 'Replied Position is closed', 'Follow up')
	then 1 else 0 end)  * 100.0/Count(*),2) as response_rate
	from job_application;

--no response rate
select round(sum(case
	when status ='No Reply' then 1
	else 0 end) * 100.0/count(*),2) as no_response
from job_application;

--rejection rate
select round(sum(
	case when status in ('Rejected in Technical Round', 'Not Selected') then 1
	else 0 end) * 100.0/ count(*),2) as rejection_rate
from job_application;

-- month-by-month trend
select month, applications,
lag(applications) over(order by month) as previous_month,
applications - lag(applications) over(order by month) as growth
from(
select date_trunc('month',date_applied) as month,
	count(*) as applications
from job_application
where date_applied is not null
group by month) t
order by month;

--Rolling 7-Day Application Count
WITH daily AS (
    SELECT
        date_applied,
        COUNT(*) AS applications
    FROM job_application
    WHERE date_applied IS NOT NULL
    GROUP BY date_applied
)

SELECT
    d1.date_applied,
    d1.applications,
    SUM(d2.applications) AS rolling_7_day
FROM daily d1
JOIN daily d2
    ON d2.date_applied BETWEEN d1.date_applied - INTERVAL '6 days'
                           AND d1.date_applied
GROUP BY
    d1.date_applied,
    d1.applications
ORDER BY d1.date_applied;

--average applications per week
select round(avg(applications),2) from(select date_trunc('week',date_applied) as week,
count(*) as applications 
from job_application 
where date_applied is not null
group by week) t;

--Longest streak of consecutive application days
with dates as(
	select distinct date_applied 
	from job_application
	where job_id is not null
),
numbered as(
	select date_applied,
	row_number() over(order by date_applied) as rn
	from dates
),
groups as(
select date_applied,
	date_applied - rn::int as grp
	from numbered
),
streaks as(
select grp,
	count(*) as streax_count
	from groups
	group by grp
)
select max(streax_count) as longest_streax
	from streaks;
	
--to see the dates of the longest streak
WITH dates AS (
    SELECT DISTINCT date_applied
    FROM job_application
    WHERE date_applied IS NOT NULL
),

numbered AS (
    SELECT
        date_applied,
        ROW_NUMBER() OVER (ORDER BY date_applied) AS rn
    FROM dates
),

groups AS (
    SELECT
        date_applied,
        date_applied - rn::int AS grp
    FROM numbered
),

streaks AS (
    SELECT
        grp,
        MIN(date_applied) AS streak_start,
        MAX(date_applied) AS streak_end,
        COUNT(*) AS streak_count
    FROM groups
    GROUP BY grp
)

SELECT
    streak_start,
    streak_end,
    streak_count
FROM streaks
ORDER BY streak_count DESC
LIMIT 1;

--Top Companies by Response Rate
select company_name,
	count(*) as total_applications,
	round(sum(case
	when status != 'No Reply'
	then 1 else 0 end)*100.0/count(*),2) as response_rate
from job_application
group by company_name
order by response_rate desc, total_applications desc;

--Cumulative Applications (Running Total)
with cte as(
	select date_applied, count(*) as applications
	from job_application
	where date_applied is not null
	group by date_applied
)
select date_applied, applications,
	sum(applications) over(order by date_applied) as cumulative_applications
	from cte;