SELECT --TOP (1)
[transaction_id]
      ,[city]
      ,[transaction_date]
      ,[card_type]
      ,[exp_type]
      ,[gender]
      ,[amount]
  FROM [NamSQL].[dbo].[credit_card_transcations]

  
--1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
select *  from (
select city,spends, rank() over (order by spends desc ) rn,round((spends*100)/totat_credit_card_spend,2) as percent_Spent
from (
SELECT city, sum(amount) as spends, 
(select  sum([amount]) total_credit_card_Spend from [NamSQL].[dbo].[credit_card_transcations]) as totat_credit_card_spend
From [NamSQL].[dbo].[credit_card_transcations]
group by city 
)a
)b where b.rn<=5

--using CTE
with CTE1 as (
select city , sum(amount) as total_spend
from [NamSQL].[dbo].[credit_card_transcations]
group by city )
,total_spent as 
(select sum(cast(amount as bigint)) as total_amount from [NamSQL].[dbo].[credit_card_transcations])
select top 5 CTE1.*,total_amount,round((total_spend *100)/total_amount,2) as percentage_contribution
from CTE1, total_spent
order by total_spend desc


--2- write a query to print highest spend month and amount spent in that month for each card type
with cte1 as (
select card_type, 
datepart(year,transaction_date) yt,
datepart(month,transaction_date) mt --datepart([transaction_date], month),[card_type], 
,sum([amount]) total_Spend
From [NamSQL].[dbo].[credit_card_transcations]
group by card_type, datepart(year,transaction_date),datepart(month,transaction_date)
--order by card_type, total_Spend desc
)
select * from (
select *, rank() over (partition by card_type order by total_Spend desc) as rn
from cte1 )A where A.rn=1
where rn=1

--3- write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)


with CTE1 as (
select * , sum(amount) over (partition by card_type order by transaction_id, transaction_date) as total_sales
From [NamSQL].[dbo].[credit_card_transcations]
)
select * from (select * , rank() over (partition by card_type order by total_sales ) as rn from CTE1 
where total_sales >=1000000) a where rn =1


--4- write a query to find city which had lowest percentage spend for gold card type

with CTE1 as
(
select city, card_type, sum(amount) amount,
sum(case when card_type = 'Gold' then amount end) as gold_amount
from [NamSQL].[dbo].[credit_card_transcations]  
group by city, card_type
)
select top 1
city, sum(gold_amount )/sum(amount) as gold_ratio
from CTE1
group by city 
having sum(gold_amount) is not null
order by gold_ratio

--5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)


with cte1 as (
select city ,exp_type , sum(amount) as total_amount
From [NamSQL].[dbo].[credit_card_transcations]
group by city, exp_type
--order by city , exp_type
)
select A.city, 
min(case when rn_asc=1 then exp_type  end) as lowest_expense_type
,maX(case when rn_desc =1 then exp_type end )as highest_expense_type from (
select *
,rank() over (partition by city order by total_amount desc ) rn_desc
,rank() over (partition by city order by total_amount ) rn_asc
from cte1)A
group by A.city




--6- write a query to find percentage contribution of spends by females for each expense type
select exp_type 
,sum(case when gender = 'F' then amount else 0 end )*1.0/sum(amount) as percentage_female_contribution
From [NamSQL].[dbo].[credit_card_transcations]
group by exp_type
order by exp_type


--7- which card and expense type combination saw highest month over month  growth in Jan-2014
with CTE as (
select card_type, exp_type,datepart(year, transaction_date) yt, datepart(month, transaction_date) mt
,sum(amount) as total_spend
From [NamSQL].[dbo].[credit_card_transcations]
group by card_type, exp_type,datepart(year, transaction_date) , datepart(month, transaction_date) 
)
select top 1 * , (total_spend-prev_month_spend)as mom_growth from (
select *
,lag(total_spend) over (partition by card_type, exp_type order by yt, mt) as prev_month_spend
from CTE
) A
where prev_month_spend is not null  and yt=2014 and mt=1
order by mom_growth desc

--8- during weekends which city has highest total spend to total no of transcations ratio 
select top 1 city, sum(amount)*1.0/count(1) as ratio
From [NamSQL].[dbo].[credit_card_transcations]
where datepart(weekday, transaction_date) in (1,7)
group by city 
order by ratio desc

--Note filteration on int is faster than string 
-- second option is datename(weekday, transaction) in ('saturday','sunday')

--9- which city took least number of days to reach its 500th transaction after the first transaction in that city
with cte as (
select *,
row_number()  over (partition by city order by transaction_date,transaction_id) rn
From [NamSQL].[dbo].[credit_card_transcations]
)
select top 1 city, datediff(day,min(transaction_date), max(transaction_date)) as datediff1
from cte 
where rn =1 or rn =500
group by city
having count(1)=2
order by datediff1