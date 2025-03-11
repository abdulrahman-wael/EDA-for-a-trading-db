-- the database used is a "modern version of Northwind traders" as its source website is saying: https://www.dofactory.com/sql/sample-database

-- this is an EDA (exploratory data analysis) project with the following targets
-- 1. for the database (what are the dimensions and measures)
-- 2. for the dimensions (what are the values of each dimension and the relation between values and dimensions)
-- 3. for the measures (what are the major metrics)
-- 4. basic analysis (magnitude, ranking)


-----------------------------------------------------------------
-- first step: exploring the tables and the columns to answer the question
-- what are the measures and dimensions
select * from "INFORMATION_SCHEMA".tables;
select * from "INFORMATION_SCHEMA".columns;

-- by LLM:
-- looks like we have the following tables and attributes:     (d = dimension, m = measure) 
    -- SUPPLIER(Id (d), CompanyName (d), ContactName (d), City (d), Country (d), Phone (d), Fax (d))
    -- CUSTOMER(Id (d), FirstName (d), LastName (d), City (d), Country (d), Phone (d))
    -- PRODUCT(Id (d), ProductName (d), SupplierId (d), UnitPrice (m), Package (d), IsDiscontinued (d))
    -- ORDER(Id (d), OrderDate (d), CustomerId (d), TotalAmount (m))
    -- ORDERITEM(Id (d), OrderId (d), ProductId (d), UnitPrice (m), Quantity (m))
-- there are only four measures: product(UnitPrice), order(TotalAmount), orderitem(UnitPrice), orderitem(Quantity)


-----------------------------------------------------------------
-- second step: exploring the dimensions to find the following
-- 1. (for each) unique values, cardinality
-- 2. relations between dimensions (like hierarchy)
-- 3. (for dates) min, max, intervals of date dimensions
-- IMPORTANT: make sure if the values are duplicates or not by (distinct), (group by)


-- 1. let's begin by exploring unique values, cardinalities of the dimensions we have
-- 1.SUPPLIER table ----------------
select count(id) from supplier
select count(distinct id) from supplier;
-- the number of IDs = 29
-- looks like there is no "id" duplicates which is good


select distinct companyName from supplier;
select count(distinct companyName) from supplier;
-- all the companies that the business work with are 29

select distinct contactName from supplier
select count(distinct contactName) from supplier
-- also the contactNames are 29

select distinct country from supplier
select count(distinct country) from supplier
-- only 16 countries

select distinct city from supplier
select count(distinct city) from supplier
-- number of cities = 29 ... this means that some countries have more than one city that supplies the business

select count(*) from (
    select distinct country, count(city) as num_of_cities from supplier
    group by country
    having count(city) > 1
) as target
-- by only querying the (target) query we can see all countries that have more than once supplier city
-- there are 9 of these countries

select count(distinct phone) as phones, count(distinct fax) as faxes
from supplier
-- the number of phones = number of contactNames which is typical
-- it's interesting that the number of fax is only 13 ... I think not all companies have a fax ... is that true?

select count(companyName) from supplier
where fax is null
-- the number of companies with no fax = 16 .. which when added up to 13 gives 29 (total companies number
    -- which means that the assumption is true

select distinct city, country from supplier;
select count(distinct concat(city, '_', country)) from supplier
-- the number of combinations of city, country = 29
-- this means that for each company there is only one city and one contactNumber

-- to sum up: there is 29 of every dimension except the fax ... some rows have it = null


-- 2.Customer table ----------------

select count(id) from customer
select count(distinct id) from customer
-- no duplicate ids which is great (91 items)

with names as (
    select distinct firstname, lastname from Customer
)
select count(*) from names;
-- number of unique names = 91 also ... 
    -- so for each id there is only one valid name

select distinct city from Customer;
select count (city) from Customer;
select count (distinct city) from Customer;
-- notice the difference? (91, 69) .. it's not that big ... meaning that almost only one customer comes from each city

select distinct country from Customer;
select count (distinct country) from Customer
-- the number of countries the customers are coming from: 21


with city_country_relation as 
(
    select city, country from Customer
    group by city, country
    order by 1,2
)
select count(*) from city_country_relation
-- number of valid combinations: 69 (same as the number of distinct cities)

select count(Phone) from customer
select count(distinct Phone) from customer
-- the number of phone numbers = number of customers = 91


-- PRODUCT table ----------------

select count(id) from product
select count(distinct id) from product
-- the data has no duplicates (78 item)

select count(productName) from product
select count(distinct productName) from product
-- (78 item)

select count(distinct supplierId) from product
select count(supplierId) from product
-- no NULLS but unique suppliers are only 29

select count(package) from product
select count(distinct package) from product
-- no NULLS but unique packages are 70

select count(isdiscontinued) as disconinued from product
where isdiscontinued = 'true'
-- only 8 products are discontinued (not sold anymore) .. the rest (70) are not
-- but it would be better to make this a truly boolean column


-- ORDER table ----------------

select count(id) from "order";
select count(distinct id) from "order"
-- that's correct data (830 unique records)

select 
    min(orderdate) as first_date, 
    max(orderdate) as last_date,
    datediff("day", min(orderdate), max(orderdate)) as 'duration in days',
    datediff("month", min(orderdate), max(orderdate)) as 'duration in months'
from "order"
-- the orders started in 2012 and ended in 2014 for approximately 1 year and 10 months

select count(customerid) from "order"
select count(distinct customerid) from "order"
-- no NULLS and total number of distinct customers is 89 
    -- that's not great as the total number of unique customers we have in the customer table is 91 .. two customers recorded didn't order anything
    -- this maybe a system bug or the business is ok with it

select concat(c.firstname, ' ', c.lastname) as customer_name
from customer c left join "order" o on c.id = o.customerid
where o.customerid is null
-- Diego Roel
-- Marie Bertrand
-- these two customers didn't order anything


-- ORDERITEM table ----------------

select count(id) from orderitem;
select count(distinct id) from orderitem
-- unique 2155 values

select count(orderid) from orderitem
select count(distinct orderid) from orderitem
-- no NULLS and all 830 orders are linked to this table correctly

select count(productID) from orderitem
select count(distinct productID) from orderitem
-- no NULLS and there are 77 here
    -- the total number of products in the product table are 78 .. which means that one product is not ordered at all


-- let's make sure that the logical link between the two tables (order, orderitem) is valid
select o.id, sum(oi.quantity * oi.unitprice) as orderitems_profit, sum(o.totalamount) as order_profit
from orderitem oi left join "order" o on oi.orderid = o.id
group by o.id
having sum(oi.quantity * oi.unitprice) != sum(o.totalamount)
-- that's bad ... most of the orders (in the table "order") have a "totalamount" field that is not matching the product "quantity * unitprice" for all the items of that order (in the table "orderitem")
    -- 693 orders are not matching out of 830 !

-----------------------------------------------------------------
-- third step: measures -> find metrics (highest aggregated values) from them to answer business questions
-- IMPORTANT: it's better to show all important metrics in one big query (report)

-- let's get an overview for the measures we have
SELECT 'product(UnitPrice)' as measure_name, sum(UnitPrice) as summation, avg(UnitPrice) as average, max(UnitPrice) as maximum, min(UnitPrice) as minimum
from product
UNION 
SELECT 'order(TotalAmount)' as measure_name, sum(totalamount) as summation, avg(totalamount) as average, max(totalamount) as maximum, min(totalamount) as minimum
from "order"
UNION
select 'orderitem(UnitPrice)' as measure_name, sum(UnitPrice) as summation, avg(UnitPrice) as average, max(UnitPrice) as maximum, min(UnitPrice) as minimum
from orderitem
UNION 
select 'orderitem(Quantity)' as measure_name, sum(quantity) as summation, avg(quantity) as average, max(quantity) as maximum, min(quantity) as minimum
from orderitem


-- these are some metrics that we can derive from the previous measures
    -- you will notice that all these questions are already answered before but let's aggregate them all together in one view

-- by LLM:
-- What is the total revenue?
-- What is the average order value?
-- How many unique customers placed orders?
-- What is the average product price?
-- How many orders have been placed?


select 'total_revenue' as metric_name, SUM(TotalAmount) as amount from "order"
UNION
select 'average_order_value' as metric_name, AVG(TotalAmount) as amount from "order"
UNION
select 'number_of_unique_customers' as metric_name, COUNT(distinct customerID) as amount from "order"
UNION
select 'average_product_price' as metric_name, AVG(UnitPrice) as amount from product
UNION
select 'number_of_orders' as metric_name, count(id) as amount from "order";


-----------------------------------------------------------------
-- fourth step: let's answer some cool business questions

-- by LLM:
-- Which city/country has the most customers?
-- Which supplier provides the most products?
-- Which month/season generates the highest revenue?
-- Which categories of products (based on package) are most popular?
-- Who are the top 5 customers by spending?
-- What are the top 5 selling products?
-- Which suppliers contribute the most to revenue?
-- Which customers have placed the most orders?


-- notice that these questions are "ranking analysis"


-- Which city/country has the most customers?
select city, count(id) as amount from customer
group by city
order by count(id) desc;
select country, count(id) as amount from customer
group by country
order by count(id) desc;
-- the city with the most customers = London (6)
-- the country with the most customers = USA (13)


-- Which supplier provides the most products?
select s.CompanyName, count(p.id) as amount
from product p left join supplier s on s.id = p.supplierid
group by CompanyName
order by count(p.id) DESC
-- notice how we used LEFT JOIN here ... the product table to the supplier table to not miss any product in the resulting table
-- the supplier with the most products is "Pavlova, Ltd.", "Plutzer Lebensmittelgroßmärkte AG" (5 products)


-- Which month/season generates the highest revenue?
select MONTH(OrderDate) as month, sum(totalamount) as amount from "order"
group by MONTH(OrderDate)
order by amount DESC
-- looks like it's April (190329.95 in total)


-- Which categories of products (based on package) are most popular?
select p.package, count(oi.id) as amount
from orderitem oi left join product p on oi.productid = p.id
group by p.package
order by amount DESC
-- the winner by far is "24 - 12 oz bottles" (109 items) .. which is more than the next most popular package with (36 items)!


-- Who are the top 5 customers by spending?
select top 5 concat(c.firstname,' ' ,c.lastname) as customer_name, sum(o.totalamount) as amount
from "order" o left join customer c on c.id = o.customerid
group by c.firstname, c.lastname
order by amount DESC
-- Horst Kloss  117483.39
-- Jose Pavarotti  115673.39
-- Roland Mendel  113236.68
-- Patricia McKenna  57317.39
-- Paula Wilson  52245.9


-- Which customers have placed the most orders?
select top 5 concat(c.firstname,' ' ,c.lastname) as customer_name, count(o.id) as amount
from "order" o left join customer c on c.id = o.customerid
group by c.firstname, c.lastname
order by amount DESC
-- Jose Pavarotti  31
-- Roland Mendel  30
-- Horst Kloss  28
-- Maria Larsson  19
-- Patricia McKenna  19

-- Maria Larsson is the only customer that is in the top 5 customers who placed orders but not in the top spending ones 



-- What are the top 5 selling products?
-- actually there are two ways to answer this: the most sold in quantity, the ones that generated the most revenue (AKA quality)
-- in terms of quantity: 
select top 5 p.productname, sum(oi.quantity) as amount
from orderitem oi left join product p on oi.productid = p.id
group by p.productname, p.id
order by amount DESC
-- Camembert Pierrot   1577
-- Raclette Courdavault  1496
-- Gorgonzola Telino  1397
-- Gnocchi di nonna Alice   1263
-- Pavlova  1158

-- in terms of quality
select top 5 p.productname, sum(oi.unitprice * oi.quantity) as amount
from orderitem oi left join product p on oi.productid = p.id
group by p.productname, p.id
order by amount DESC
-- Côte de Blaye  149984.2
-- Thüringer Rostbratwurst    87736.4
-- Raclette Courdavault  76296
-- Camembert Pierrot  50286
-- Tarte au sucre  49827.9

-- notice how the first two products here got the most revenue to the company while they didn't show up in the (quantity) query above
-- also notice that although (Raclette Courdavault) was sold less than (Camembert Pierrot) it's getting more revenue to the company


-- Which suppliers contribute the most to revenue?
select s.companyname, sum(oi.unitprice * oi.quantity) as amount
from orderitem oi
    left join product p on oi.productid = p.id
    left join supplier s on p.supplierid = s.id
group by s.companyname, s.id
order by amount DESC
-- Aux joyeux ecclésiastiques  163135
-- Plutzer Lebensmittelgroßmärkte AG  155946.55
-- Gai pâturage  126582
-- Pavlova, Ltd.  115386.05
-- G'day, Mate  69636.6


