--1. Write a query that displays the customer (Customer Name) who has performed the highest number of transactions in the last 3 months, and the total amount of this customer's transactions.   
 
 c.first_name || ' ' || c.last_name as Customer_name,
    sum(t.amount) as Amount 
from bank_customers c
join bank_accounts a
    on a.customer_id = c.customer_id
join bank_transactions t
    on t.account_id = a.account_id
where t.transaction_date >= add_months((select max(transaction_date) from bank_transactions), -3)
group by c.first_name, c.last_name
order by count(t.transaction_id) desc
fetch first 1 rows only;

--2. Show the number of withdrawals made from the card account for each customer in the last 1 year, and the total amount of these withdrawals.
    
	select C.first_name || ' ' || C.last_name as Customer_name,
    count(T.transaction_id) as Withdrawal_count,
    sum(T.amount) as Amount 
from bank_transactions T
join bank_accounts A
    on A.account_id = T.account_id
join bank_customers C
    on C.customer_id = A.customer_id
where T.transaction_date >= add_months((select max(transaction_date) from bank_transactions), -12)
    and upper(T.transaction_type) = 'WITHDRAWAL'
    and upper(A.account_type) = 'CARD ACCOUNT'
group by C.first_name, C.last_name;

--3. For each customer, determine the account type with the highest number of transactions performed in the last 6 months.
    
	select
    Customer_name, Account_type from
    (select
        C.first_name || ' ' || C.last_name as Customer_name,
        A.account_type as Account_type,
        count(T.transaction_id) as Transaction_count,
        rank() over (partition by C.first_name || ' ' || C.last_name order by count(T.transaction_id) desc) as RN
    from bank_customers C
    join bank_accounts A
        on A.customer_id = C.customer_id
    join bank_transactions T
        on T.account_id = A.account_id
    where T.transaction_date >= add_months((select max(transaction_date) from bank_transactions), -6)
    group by C.first_name, C.last_name, A.account_type) T
where RN = 1;

--4. Analyze the total amount of transactions performed by customers in the last 1 year related only to their deposit accounts.
    
	select C.first_name || ' ' || C.last_name as Customer_name,
    sum(T.amount) as Amount 
from bank_transactions T
join bank_accounts A
    on A.account_id = T.account_id
join bank_customers C
    on C.customer_id = A.customer_id
where T.transaction_date >= add_months((select max(transaction_date) from bank_transactions), -12)
    and upper(A.account_type) like 'DEPOSIT%'
group by C.first_name, C.last_name;

--5. For each customer, show the dates on which they performed the highest number of card transactions in the last 3 months.
  
  select Customer_name,
    Transaction_date,
    Transaction_count from
    (select 
        C.first_name || ' ' || C.last_name as Customer_name,
        trunc(T.transaction_date) as Transaction_date,
        count(T.transaction_id) as Transaction_count,
        rank() over(partition by C.first_name || ' ' || C.last_name order by count(T.transaction_id) desc) as Ran
    from bank_transactions T
    join bank_accounts A
        on A.account_id = T.account_id
    join bank_customers C
        on C.customer_id = A.customer_id
    where T.transaction_date >= add_months((select max(transaction_date) from bank_transactions), -3)
        and upper(A.account_type) = 'CARD ACCOUNT'
    group by C.first_name, C.last_name, trunc(T.transaction_date))
where Ran = 1;

--6. Retrieve the list of deposit and loan information for customers who have an active deposit.
  
  select
    C.customer_id,
    C.first_name || ' ' || C.last_name as Customer_name,
    D.deposit_id,
    D.deposit_type,
    D.deposit_amount,
    D.interest_rate as D_rate,
    D.start_date as D_st_date,
    D.end_date as D_end_date,
    L.loan_id,
    L.loan_type,
    L.loan_amount,
    L.interest_rate as L_rate,
    L.start_date as L_st_date,
    L.end_date as L_end_date
from bank_customers C
join deposits D
    on D.customer_id = C.customer_id
left join bank_loans L
    on C.customer_id = L.customer_id
where C.status = 'ACTIVE';

--7. Write a query to show the total balance and deposit amount for each customer for each month within the last 1 year.
 
 select
    C.first_name || ' ' || C.last_name as Customer_name,
    to_char(T.transaction_date, 'YYYY-MM') as Month,
    sum(T.amount) as Balance,
    sum(case when upper(A.account_type) = 'DEPOSIT ACCOUNT' then T.amount else 0 end) as Deposit_amount
from bank_customers C
join bank_accounts A
    on A.customer_id = C.customer_id
join bank_transactions T
    on T.account_id = A.account_id
where T.transaction_date >= add_months((select max(transaction_date) from bank_transactions), -12)
group by C.first_name, C.last_name, to_char(T.transaction_date, 'YYYY-MM');

--8. Show information about the customer who has the highest loan amount in the last 6 months, along with the loan amount.
  
  select C.first_name || ' ' || C.last_name as Customer_name,
       C.customer_id,
       L.loan_type,
       L.loan_amount,
       L.start_date,
       L.end_date
from customers C
join loans L on C.customer_id = L.customer_id
where L.start_date >= add_months(trunc(sysdate), -6)
  and L.loan_amount = (
        select max(L2.loan_amount)
        from loans L2
        where L2.start_date >= add_months(trunc(sysdate), -6));

--9. Show information about each customer's highest-value transaction in the last 6 months, including transaction type, date, and balance.

select * from (select
        C.first_name || ' ' || C.last_name as Customer_name,
        T.transaction_type,
        T.transaction_date,
        A.balance,
        T.amount,
        row_number() over (partition by C.customer_id order by T.amount desc) as Ran
    from 
        bank_customers C
    join bank_accounts A on A.customer_id = C.customer_id
    join bank_transactions T on T.account_id = A.account_id
    where 
        T.transaction_date >= add_months((select max(transaction_date) from bank_transactions), -6)) X
where Ran = 1;

--10. Which type of loans does the customer apply for most frequently, and what is the average interest rate offered to the customer for these loan types?  
   
   select Loan_type, Avg_interest_rate from 
    (select 
        Loan_type,
        count(loan_id) as Count,
        avg(interest_rate) as Avg_interest_rate 
    from bank_loans
    group by Loan_type
    order by Count desc
    fetch first 1 rows only);


--11. Show all accounts opened by each customer in the last 1 year and the total amount of transactions performed for these accounts.
    
	select C.first_name || ' ' || C.last_name as Customer_name,
       A.account_id,
       sum(T.amount) as Amount
from bank_customers C
join bank_accounts A
    on A.customer_id = C.customer_id
join bank_transactions T
    on T.account_id = A.account_id
where A.date_opened >= add_months((select max(date_opened) from bank_accounts), -6)
group by C.first_name, C.last_name, A.account_id;

--12. Write a query that shows the total balance and deposit amount for each customer for each month in the last 1 year:
    select C.first_name || ' ' || C.last_name as Customer_name,
       to_char(T.transaction_date, 'YYYY-MM') as Month,
       sum(A.balance) as Balance,
       sum(D.deposit_amount) as Deposit
from bank_customers C
join bank_accounts A
    on A.customer_id = C.customer_id
join bank_transactions T
    on T.account_id = A.account_id
join deposits D
    on D.customer_id = C.customer_id
where T.transaction_date >= add_months((select max(transaction_date) from bank_transactions), -12)
group by C.first_name, C.last_name, to_char(T.transaction_date, 'YYYY-MM');

--13. For each customer, find the account type with the highest deposit amount in the last 1 year and the opening date of this account.

    select
    D.customer_id,
    A.account_type,
    D.max_deposit,
    A.date_opened as Account_open_date
from 
    (select
        customer_id,
        max(deposit_amount) as max_deposit
    from deposits
    where start_date >= add_months((select max(start_date) from deposits), -12)
    group by customer_id
    ) D
join bank_accounts A
    on D.customer_id = A.customer_id;

--14. For each customer, determine the most active card type based on the number of card transactions in the last 3 months..

select 
    C.customer_id,
    C.first_name || ' ' || C.last_name as Customer_name,
    CR.card_type,
    count(T.transaction_id) as Transaction_count
from bank_customers C
join bank_accounts A on C.customer_id = A.customer_id
join bank_transactions T on T.account_id = A.account_id
join bank_cards CR on CR.customer_id = C.customer_id
where T.transaction_date >= add_months((select max(transaction_date) from bank_transactions), -3)
  and upper(A.account_type) = 'CARD ACCOUNT'
group by C.customer_id, C.first_name, C.last_name, CR.card_type;

select *
from (
    select K.*,
           row_number() over (partition by customer_id order by Transaction_count desc) as RN
    from K
)
where RN = 1;

--15. Calculate the total loan amounts by term for customers whose status is active.

(By term, it is meant the duration for which the loan is given (start_date and end_date). The term should be categorized as follows:
0-12 months
13-24 months
25-48 months
48+ months

select 
    case 
        when months_between(L.end_date, L.start_date) between 0 and 12 then '0-12 months'  
        when months_between(L.end_date, L.start_date) between 13 and 24 then '13-24 months'  
        when months_between(L.end_date, L.start_date) between 25 and 48 then '25-48 months'  
        else '48+ months'  
    end as Term_category,
    sum(L.loan_amount) as Loan_amount
from bank_customers C
join bank_loans L
    on C.customer_id = L.customer_id
where upper(C.status) = 'active'
group by
    (case 
        when months_between(L.end_date, L.start_date) between 0 and 12 then '0-12 months'  
        when months_between(L.end_date, L.start_date) between 13 and 24 then '13-24 months'  
        when months_between(L.end_date, L.start_date) between 25 and 48 then '25-48 months'  
        else '48+ months'  
    end);