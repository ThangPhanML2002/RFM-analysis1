use phanquocthang

SELEct * from customer_transaction_d78 

drop table tbl78 

CREATE temporary TABLE tbl78 AS (
select * from(
select 
c2.CustomerID,
c1.created_date,
count(*),
ROUND(SUM(c2.gmv)/ count(*),2) AS average_order_value,
SUM(c2.gmv) AS total_order_value,
round(SUM(c2.gmv) /ceil(DATEDIFF('2022-09-02', c1.created_date) / 30),2) AS n_GMV_per_month,
ceil(DATEDIFF('2022-09-02', c1.created_date) / 30) as Months_Customer_Lifetime,
ROUND(COUNT(*)/ ceil(DATEDIFF('2022-09-02', c1.created_date) / 30), 2) AS n_FREQUENCY_per_month,
DATEDIFF('2022-09-02', c2.Purchase_Date) AS days_from_latest_purchase
from customer_registered_d78 c1
JOIN customer_transaction_d78 c2 ON c1.id = c2.CustomerID
GROUP BY 
c2.CustomerID) t1
where n_FREQUENCY_per_month > 0
)

select * from tbl78 

set @x = null

select count(*) into @x from tbl78 

select @x


select *, concat(recency_point, frequency_point, money_point) as RFM, 
CASE
    WHEN CONCAT(recency_point, frequency_point, money_point) IN ('444', '443', '434', '433', '344', '343', '334', '333') THEN 'VIP Customers'
    WHEN CONCAT(recency_point, frequency_point, money_point) IN ('144', '143', '134', '133', '244', '243', '234', '233') THEN 'At-Risk VIP Customers'
    WHEN CONCAT(recency_point, frequency_point, money_point) IN ('441', '442', '431', '432', '341', '342', '331', '332') THEN 'Regular Loyal Customers'
    WHEN CONCAT(recency_point, frequency_point, money_point) IN ('141', '142', '131', '132', '241', '242', '231', '232') THEN 'At-Risk Regular Customers'
    WHEN CONCAT(recency_point, frequency_point, money_point) IN ('414', '413', '424', '423', '314', '313', '324', '323') THEN 'Occasional VIP Customers'
    WHEN CONCAT(recency_point, frequency_point, money_point) IN ('114', '113', '124', '123', '214', '213', '224', '223') THEN 'At-Risk Occasional VIP Customers'
    WHEN CONCAT(recency_point, frequency_point, money_point) IN ('411', '412', '421', '422', '311', '312', '321', '322') THEN 'New or Casual Customers'
    WHEN CONCAT(recency_point, frequency_point, money_point) IN ('111', '112', '121', '122', '211', '212', '221', '222') THEN 'Lost Customers'
end as cus_cluster
from(
SELECT CustomerID , days_from_latest_purchase, n_FREQUENCY_per_month, n_GMV_per_month,
average_order_value, total_order_value, Months_Customer_Lifetime,
recency_point, frequency_point, money_point
FROM (
    SELECT *, 
    CASE
        WHEN m1 <= ROUND(@x/4, 0) THEN 1
        WHEN ROUND(@x/4, 0) < m1 AND m1 <= ROUND(@x/2, 0) THEN 2
        WHEN ROUND(@x/2, 0) < m1 AND m1 <= ROUND(3*@x/4, 0) THEN 3
        ELSE 4
    END AS money_point,
    CASE
        WHEN f1 <= ROUND(@x/4, 0) THEN 1
        WHEN ROUND(@x/4, 0) < f1 AND f1 <= ROUND(@x/2, 0) THEN 2
        WHEN ROUND(@x/2, 0) < f1 AND f1 <= ROUND(3*@x/4, 0) THEN 3
        ELSE 4
    END AS frequency_point,
    CASE
        WHEN r1 <= ROUND(@x/4, 0) THEN 1
        WHEN ROUND(@x/4, 0) < r1 AND r1 <= ROUND(@x/2, 0) THEN 2
        WHEN ROUND(@x/2, 0) < r1 AND r1 <= ROUND(3*@x/4, 0) THEN 3
        ELSE 4
    END AS recency_point
    FROM (
        SELECT *, 
        ROW_NUMBER() OVER (ORDER BY n_GMV_per_month) m1,  
        ROW_NUMBER() OVER (ORDER BY n_FREQUENCY_per_month) f1,
        ROW_NUMBER() OVER (ORDER BY days_from_latest_purchase DESC) r1
        FROM tbl78
    ) t1
) ftbl ) ftbl1

