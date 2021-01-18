use  classicmodels;
select count(*) from (select distinct * from orderdetails) as a; /* checking the duplicated values)*/

select count(*) from orderdetails; /* Since the amount values and distinct values are same, no duplicated */

select * from orderdetails
where priceeach = 0 or quantityOrdered = 0; /* check if the purchase = 0*/
select * from orderdetails;

select productCode  , count(distinct customerNumber) as uni_buyer, sum(quantityOrdered*priceEach) as total,
sum(quantityOrdered) as total_quantity_order
from orderdetails o1 join orders o2 on o1.orderNumber = o2.orderNumber
where year(orderDate) = 2003
group by productCode
order by total_quantity_order desc limit 10; /* best top 10 sales product on 2003 year and total sales */

select a.customer_type,count(DISTINCT a.customerNumber) as  people_quantity,
count(a.orderNumber) as total_sales,
sum(a.priceEach*a.quantityOrdered)/count(DISTINCT a.customerNumber) avg_buyer_sales,
sum(a.quantityOrdered)/count(DISTINCT a.customerNumber) avg_buyer_quantity   
from 
(select orderNumber, customerNumber,quantityOrdered,priceEach,case 
when customernumber in  (select distinct  customerNumber from orders  where  year(orderDate)<2004 and customerNumber is not NULL order by customerNumber) then 'used_buyer' 
when customernumber not  in  (select distinct  customerNumber from orders  where  year(orderDate)<2004 and customerNumber is not NULL order by customerNumber) then 'new_buyer' 
end customer_type  
from orders join orderdetails using(ordernumber)  where year(orderDate)=2004) a   
group by customer_type ; /* 2004, the quantity, sales, and average between used_buyer and new_buyer */

SELECT sum(DATEDIFF(orderDate,pre_oder_date))/sum(if (row_num=2 ,1,0)) avg_period_time,
sum(if (row_num=2 ,1,0))/sum(if (pre_oder_date is null ,1,0)) rate_period_time
FROM  (SELECT   customerNumber,orderDate,ROW_NUMBER() over(partition by customerNumber) row_num ,lag(orderDate,1) over(partition by customerNumber) pre_oder_date 
FROM orders WHERE year(orderDate)=2004) as a ; /* The time of people who come back to buy a second time period and the average rate period time*/

SELECT sum(if(datediff(orderDate,pre_orderdate)<=30,1,0)) as people_quantity FROM
(select customerNumber,orderDate, lag(orderDate,1) over(partition by customerNumber order by orderDate ) pre_orderdate,row_number() over (partition by customerNumber order by orderDate) row_num 
from orders 
where customerNumber  not in    (select DISTINCT customerNumber from orders where year(orderDate)<2004) and  year(orderDate)=2004  
order by customerNumber) as a 
where row_num=2;

select customerNumber,tep_column,count(tep_column) continous 
FROM 	(SELECT *,month(orderDate)-rnk as  tep_column FROM 
	(SELECT *,row_number() over(PARTITION by customerNumber) as rnk FROM orders where year(orderDate)=2004) t1) t2
group by customerNumber,tep_column HAVING count(tep_column)>=3;

SELECT *,CASE 
    WHEN 2>=Recent and  Money<=100000 THEN  'ss_buyer'
    When 2>=Recent and  Money>100000 THEN  'bs_buyer'
    When 2<Recent<=4 and  Money<100000 THEN  'ss_target'
    When 2<Recent<=4 and  Money>100000 THEN  'bs_target'
    When 4<Recent and  Money<100000 THEN  'ss_target'
    When 4<Recent and  Money>100000 THEN  'bs_target'
END   category
FROM 
(SELECT a.customerNumber,Recent,Money,Frequency 
FROM 
(SELECT customerNumber, 12-month(recent_orderdate) Recent  FROM
(SELECT customerNumber,first_value(orderDate) over(partition by customerNumber order by orderDate desc ) recent_orderdate ,row_number()  over(partition by customerNumber)  rnk FROM orders WHERE year(orderDate)=2004 ) as t1  
WHERE rnk=1) as a  join 
(SELECT customerNumber,sum(quantityOrdered*priceEach) as Money,count(customerNumber) as Frequency FROM orders join orderdetails USING(orderNumber)
GROUP BY customerNumber) as b  on a.customerNumber=b.customerNumber) t2; /* RFM model to set up customer_type */