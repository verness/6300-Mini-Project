SELECT * FROM FAA.al_perf;
# 1) Find maximal departure delay in minutes for each airline. Sort results from smallest to largest maximum
# delay. Output airline names and values of the delay.
select l.Name as Airline_Name, max(a.DepDelayMinutes) as Max_DepDelay_Minutes
from al_perf as a
join L_AIRLINE_ID as l on a.DOT_ID_Reporting_Airline = l.ID
group by l.Name
order by Max_DepDelay_Minutes asc;
# returned 15 rows

# 2) Find maximal early departures in minutes for each airline. Sort results from largest to smallest. Output airline names
select l.Name as Airline_Name, min(a.DepDelay) as Max_Early_Dep
from al_perf as a
join L_AIRLINE_ID as l on a.DOT_ID_Reporting_Airline = l.ID
group by l.Name
order by Max_Early_Dep asc;
# returned 15 rows

# 3)Rank days of the week by the number of flights performed by all airlines on that day (1 is the busiest).
# Output the day of the week names, number of flights and ranks in the rank increasing order.
select w.Day, count(*) as Num_Flights, 
rank() over(order by count(*) desc) as Day_Rank
from al_perf as a
join L_WEEKDAYS as w on a.DayOfWeek = w.Code
group by w.Day
order by Day_Rank asc;
# returned 7 rows

# 4) Find the airport that has the highest average departure delay among all airports. Consider 0 minutes delay
# for flights that departed early. Output one line of results: the airport name, code, and average delay.
select l1.Name as Airport_Name, l2.Code as Airport_Code,
avg(case
when a.DepDelayMinutes < 0 then 0
else a.DepDelayMinutes
end) as Average_delay
from al_perf as a
join L_AIRPORT_ID as l1 on l1.ID = a.OriginAirportID
join L_AIRPORT as l2 on l1.Name = l2.Name
group by l1.Name, l2.Code
order by Average_delay desc
limit 1;

# 5) For each airline find an airport where it has the highest average departure delay. Output an airline name, a
# name of the airport that has the highest average delay, and the value of that average delay.
with Average_Delays as ( select l1.Name as Airline_Name, l2.Name as Airport_name, 
avg(case when a.DepDelayMinutes < 0 then 0 else a.DepDelayMinutes end) as Average_Delay 
from al_perf as a 
join L_AIRLINE_ID as l1 on a.DOT_ID_Reporting_Airline = l1.ID 
join L_AIRPORT_ID as l2 on a.OriginAirportID = l2.ID 
group by l1.Name, l2.Name ), 
ranked as ( select Airline_Name,Airport_name, Average_Delay, 
rank() over (partition by Airline_Name order by Average_Delay desc) as Delay_Rank 
from Average_Delays) 
select Airline_Name,Airport_name, Average_Delay as Highest_Average_Delay 
from ranked
where Delay_Rank = 1 
order by Airline_Name;
# returned 15 row

# 6a) Check if your dataset has any canceled flights.
select count(*) as Num_Canceled_flights
from al_perf
where Cancelled = 1;
# returned 1 row

# 6b) If it does, what was the most frequent reason for each departure airport? Output airport name,
# the most frequent reason, and the number of cancelations for that reason
select Airport_Name, Reason, Num_Cancelations
from (
select l1.Name as Airport_Name, l2.Reason, count(*) as Num_Cancelations,
row_number () over (partition by l1.Name
order by count(*) desc) as rn
from al_perf as a
join L_AIRPORT_ID as l1 on l1.ID = a.OriginAirportID
join L_CANCELATION as l2 on l2.Code = a.CancellationCode
where a.Cancelled = 1
group by l1.Name, l2.Reason) t
where rn = 1
order by Airport_Name;
# returned 190 row

# 7) Build a report that for each day output average number of flights over the preceding 3 days.
with daily_flights as (
select a.FlightDate as Flight_Date, w.Day as Day_of_Week, count(*) as Num_Flights
from al_perf as a
join L_WEEKDAYS as w on w.Code = a.DayOfWeek
group by a.FlightDate, w.Day)
Select Flight_Date, Day_of_Week, Num_Flights,
avg(Num_Flights) over (order by Flight_Date rows between 3 preceding and 1 preceding)
as Avg_Flights_Preceding_3_Days
from daily_flights
order by Flight_Date;
# returned 30 rows







