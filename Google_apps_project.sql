-- shows table without duplicates

create view No_Duplicates as
with cte as (select *,
            row_number()  over (partition by app, Category,Rating, Reviews, Size, Installs, type,price,Content_Rating, Genres,
                Last_Updated, Current_Ver, Android_Ver) as rank
from googleplaystore)
select* from cte
where rank=1;

select count(app) from No_Duplicates;


-- Shows how many apps in each category

Select category, count(App) as num_of_apps from No_Duplicates
group by category;

-- Shows how many apps in each content Rating group
Select Content_Rating, count(Content_Rating) as num_of_apps from No_Duplicates
group by Content_Rating;

-- Shows how many apps in each type group
Select Type, count(Type) as num_of_apps from No_Duplicates
where type <> 'NaN'
group by type
;

-- shows how many content rating groups in each category

select category, Content_Rating,
       count(Content_Rating) over (partition by category,Content_Rating order by Category) as Num_of_app_per_cont
from No_Duplicates
;

-- find avg rating, reviews, installs per category
with cat as (
     Select nd.category,
        sum(case when gg.Sentiment = 'Positive' then 1 else 0 end) as num_of_positive,
        sum(case when gg.Sentiment = 'Negative' then 1 else 0 end) as  num_of_negative,
        sum(case when gg.Sentiment = 'Neutral' then   1 else 0 end) as num_of_neutral
    from googleplaystore_user_reviews gg
  join No_Duplicates  nd on gg.app=nd.app
 group by nd.category
)
    select t1.category, t1.Installs as most_freq_installs, round(avg(t2.Reviews),2) as avg_reviews, round(avg(t2.Rating),2) as avg_rating,
            c.num_of_positive, c.num_of_negative, c.num_of_neutral from
            (Select category, Installs  from
            (select category, Installs, count(installs) as frequency,
            rank() over (partition by category order by count(installs) desc) as rank from No_Duplicates
            group by category, Installs
            order by category,frequency desc)
            where rank =1) t1
join No_Duplicates t2
on t1.category = t2.category
join cat c on t2.category = c.category
group by t1.category;

-- find avg rating, reviews, installs per type  Compare avg rating of free and paid apps and which have more positive/negative reviews
with cte as (
     Select nd.type,
        sum(case when gg.Sentiment = 'Positive' then 1 else 0 end) as num_of_pos_reviews,
        sum(case when gg.Sentiment = 'Negative' then 1 else 0 end) as  num_of_neg_reviews,
        sum(case when gg.Sentiment = 'Neutral' then   1 else 0 end) as num_of_neutr_reviews
    from googleplaystore_user_reviews gg
    join No_Duplicates  nd on gg.app=nd.app
    group by nd.type
    )
    select t3.type, t3.Installs as most_freq_installs, round(avg(t4.Reviews),2) as avg_reviews, round(avg(t4.Rating),2) as avg_rating,
       c1.num_of_pos_reviews, c1.num_of_neg_reviews, c1.num_of_neutr_reviews from
            (Select type, Installs  from
                (select type, Installs, count(installs) as frequency,
                 rank() over (partition by type order by count(installs) desc) as rank from No_Duplicates
            group by type, Installs
            order by type,frequency desc)
            where rank =1) t3
join No_Duplicates t4
on t3.type = t4.type
 join cte c1 on t4.type =c1.type
where t3.type <>'NaN'
group by t3.type;

-- if there is a correlation between negative reviews and date of last update

select ndd.app, ndd.category, gur.sentiment,
       trim(substring(ndd.Last_Updated, CHARINDEX(' ', ndd.Last_Updated), length(ndd.last_updated) -CHARINDEX(', ', ndd.Last_Updated) -2), ',') as Upd_Day,
       substring(ndd.Last_Updated,1, CHARINDEX(' ', ndd.Last_Updated) -1) as Upd_Month,
       trim(substring(ndd.Last_Updated, CHARINDEX(' ', ndd.Last_Updated) +4, length(ndd.Last_Updated)), ' ') as Upd_Year
from No_Duplicates ndd
join googleplaystore_user_reviews gur on ndd.app=gur.app
where gur.Sentiment <> 'nan';

-- compare rating and number of installs, number of reviews, size

select App,
       Category,
       Rating,
       Reviews,
       Size,
       Installs,
       Type,
       Price,
       Content_Rating,
       Genres,
       trim(substring(Last_Updated, CHARINDEX(' ', Last_Updated), length(last_updated) -CHARINDEX(', ', Last_Updated) -2), ',') as Upd_Day,
       substring(Last_Updated,1, CHARINDEX(' ', Last_Updated) -1) as Upd_Month,
       trim(substring(Last_Updated, CHARINDEX(' ', Last_Updated) +4, length(Last_Updated)), ' ') as Upd_Year
       from No_Duplicates;


