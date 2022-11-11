--as a first step, let's gather up the data that is needed for identifying the "total number of unique hackers who made at least one submission each day (starting on the first day of the contest)"
with base_submissions as
    (select 
    distinct hacker_id,
    submission_date,
    first_value(submission_date) over (order by submission_date) as first_sd,
    first_value(submission_date) over (partition by hacker_id order by submission_date) as first_sd_per_hacker,
    (datediff(day, (first_value(submission_date) over (partition by hacker_id order by submission_date)), submission_date)) + 1 as date_diff,
    dense_rank() over (partition by hacker_id order by submission_date asc) as dr,
    count(submission_id) over (partition by hacker_id, submission_date) as submissions
    from submissions),
    
--here we create a sample consisting only of the data about those hackers who pass the mentioned criteria
--also, it contains a field target_hacker_id_main that was used in my initial solution since the instruction is quite unclear (the part about "the hacker_id and name of the hacker who made the maximum number of submissions each day" - whether we need to gather those among the sampled hackers, as I did it here, or among all hackers, as the task itself suggest after all)
processed_submissions as
    (select *,
     last_value(hacker_id) over (partition by submission_date order by submissions asc, hacker_id desc rows between unbounded preceding and unbounded following) as target_hacker_id_main
    from base_submissions 
    where hacker_id in
        (select 
         distinct hacker_id 
         from base_submissions
         where first_sd = first_sd_per_hacker) --just considering the hackers that have submitted for the first time on the first day of the contest
    and date_diff = dr), --it's a bit hard to explain this step, but what we do here is we look for those hackers who kept submitting something during the next consecutive days
    
--in the pre-final step, we look for "the hacker_id and name of the hacker who made the maximum number of submissions each day" among ALL hackers that made submissions through the contest 
additional_data as
    (select 
    distinct submission_date,
    last_value(hacker_id) over (partition by submission_date order by submissions asc, hacker_id desc rows between unbounded preceding and unbounded following) as target_hacker_id_additional
    from base_submissions)
    
--finally, we can now display the results, yay
select 
ps.submission_date,
count(distinct ps.hacker_id) as count_hackers,
target_hacker_id_additional as hacker_id,
name
from processed_submissions ps
join additional_data ad on ps.submission_date = ad.submission_date
join hackers h on ad.target_hacker_id_additional = h.hacker_id
group by ps.submission_date, target_hacker_id_additional, name
order by ps.submission_date asc