USE BANK;

--NEXT DATA TRANSFORMATION
/*
 CONVERT 2021 TXN_YEAR TO 2022
 CONVERT 2020 TXN_YEAR TO 2021
 CONVERT 2018 TXN_YEAR TO 2020
 CONVERT 2017 TXN_YEAR TO 2019
 CONVERT 2016 TXN_YEAR TO 2018


*/

-- RUN THIS COMMAND EVERYONE
SELECT * FROM TRANSACTIONS WHERE BANK IS NULL AND YEAR(DATE) = '2016';

SELECT YEAR(DATE) AS TXN_YEAR, COUNT(*) AS TOT_TXNS
FROM TRANSACTIONS
WHERE BANK IS NULL
GROUP BY 1
ORDER BY 2 DESC;













SELECT * FROM DISTRICT;
SELECT * FROM ACCOUNT;
SELECT * FROM card ;

UPDATE CARD
SET ISSUED = DATEADD(YEAR,1 , ISSUED)
WHERE YEAR(ISSUED) = 2021;

select YEAR(ISSUED),COUNT(*) AS TOTAL
FROM CARD
GROUP BY 1
ORDER BY 1;

DELETE FROM transactions WHERE year(date) = 2019;

SELECT * FROM TRANSACTIONS where YEAR(DATE) = 2022 ;

UPDATE TRANSACTIONS
SET BANK = 'Sky Bank' WHERE BANK IS NULL AND YEAR(DATE) = 2018;



SELECT * FROM DISPOSITION;
SELECT * FROM CARD;
SELECT * FROM ORDER_LIST;
SELECT * FROM LOAN;
SELECT * FROM CLIENT;
SELECT * FROM ACCOUNT;

SELECT DISTINCT YEAR(DATE) FROM ACCOUNT ORDER BY 1 ;
SELECT DISTINCT YEAR(DATE) FROM TRANSACTIONS ORDER BY 1;


-----FINDING MALE ,FEMALE 
SELECT 
SUM(CASE WHEN SEX = 'Male' THEN 1 END) AS MALE_CLIENT ,
SUM(CASE WHEN SEX = 'Female' THEN 1 END) AS FEMALE_CLIENT 
FROM CLIENT ;


-----FINDING MALE FEMALE %
SELECT 
SUM(CASE WHEN SEX = 'Male' THEN 1 ELSE 0 END)/COUNT(*)*100.0 AS MALE_PERC ,
SUM(CASE WHEN SEX = 'Female' THEN 1 ELSE 0 END)/COUNT(*)*100.0 AS FEMALE_PERC 
FROM CLIENT ;

-----ADDING AGE COLUMN TO THE CLIENT TABLE
ALTER TABLE CLIENT
ADD COLUMN AGE INT;

UPDATE CLIENT
SET AGE = DATEDIFF('YEAR',BIRTH_DATE,'2022-12-19');

---1.What is the demographic profile of the bank's clients and how does it vary across districts?

create or replace table czec_demographic_data_kpi as
SELECT  C.DISTRICT_ID,D.DISTRICT_NAME,D.AVERAGE_SALARY,
ROUND(AVG(C.AGE),0) AS AVG_AGE,
SUM(CASE WHEN SEX = 'Male' THEN 1 ELSE 0 END) AS MALE_CLIENT ,
SUM(CASE WHEN SEX = 'Female' THEN 1 ELSE 0 END) AS FEMALE_CLIENT ,
ROUND((FEMALE_CLIENT/MALE_CLIENT)*100,2) AS MALE_FEMALE_RATIO_PERC,
COUNT(*)AS TOTAL_CLIENT
FROM CLIENT C
INNER JOIN DISTRICT D ON C.DISTRICT_ID = D.DISTRICT_CODE
GROUP BY 1,2,3
ORDER BY 1;



--2. How the banks have performed obver the years.Give their detailed analysis month wise?
SELECT * FROM ACC_LATEST_TXNS_WITH_BALANCE ;

SELECT LATEST_TXN_DATE,COUNT(*) AS TOT_TXNS
FROM ACC_LATEST_TXNS_WITH_BALANCE
GROUP BY 1
ORDER BY 2 DESC;

--ASSUMING EVERY LAST MONTH CUSTOMER ACCOUNT IS GETTING TXNCTED

CREATE OR REPLACE TABLE ACC_LATEST_TXNS_WITH_BALANCE 
AS
SELECT LTD.*,TXN.BALANCE
FROM TRANSACTIONS AS TXN
INNER JOIN 
(
   SELECT ACCOUNT_ID,YEAR(DATE) AS TXN_YEAR,
   MONTH(DATE) AS TXN_MONTH,
   MAX(DATE) AS LATEST_TXN_DATE
   FROM TRANSACTIONS
   GROUP BY 1,2,3
   ORDER BY 1,2,3

) AS LTD ON TXN.ACCOUNT_ID = LTD.ACCOUNT_ID AND TXN.DATE = LTD.LATEST_TXN_DATE
WHERE TXN.TYPE = 'Credit' -- this is the assumptions am having : month end txn data is credit
ORDER BY TXN.ACCOUNT_ID,LTD.TXN_YEAR,LTD.TXN_MONTH;

select * from ACC_LATEST_TXNS_WITH_BALANCE;
-------------------------------------------------------------------------------------------
CREATE OR REPLACE TABLE BANKING_KPI AS
SELECT  ALWB.TXN_YEAR , ALWB.TXN_MONTH,T.BANK,A.ACCOUNT_TYPE,

COUNT(DISTINCT ALWB.ACCOUNT_ID) AS TOT_ACCOUNT, 
COUNT(DISTINCT T.TRANS_ID) AS TOT_TXNS,
COUNT(CASE WHEN T.TYPE = 'Credit' THEN 1 END) AS DEPOSIT_COUNT ,
COUNT(CASE WHEN T.TYPE = 'Withdrawal' THEN 1 END) AS WITHDRAWAL_COUNT,

SUM(ALWB.BALANCE) AS TOT_BALANCE,

ROUND((DEPOSIT_COUNT / TOT_TXNS) * 100,2)  AS DEPOSIT_PERC ,
ROUND((WITHDRAWAL_COUNT / TOT_TXNS) * 100,2) AS WITHDRAWAL_PERC ,
NVL(TOT_BALANCE / TOT_ACCOUNT,0) AS AVG_BALANCE,

ROUND(TOT_TXNS/TOT_ACCOUNT,0) AS TPA

FROM TRANSACTIONS AS T
INNER JOIN  ACC_LATEST_TXNS_WITH_BALANCE AS ALWB ON T.ACCOUNT_ID = ALWB.ACCOUNT_ID
LEFT OUTER JOIN  ACCOUNT AS A ON T.ACCOUNT_ID = A.ACCOUNT_ID
GROUP BY 1,2,3,4
ORDER BY 1,2,3,4;
----------------------------------------------------------------------------------------------------------
select TXN_YEAR,COUNT(*) AS TOTAL
FROM BANKING_KPI
GROUP BY 1
ORDER BY 2 DESC;

SELECT * FROM BANKING_KPI
ORDER BY txn_year,BANK;

SELECT * FROM TRANSACTIONS
WHERE ACCOUNT_ID = 1
ORDER BY DATE;

SELECT * FROM BANKING_KPI
where txn_year =2019;

select TXN_YEAR AS TXN_YEAR,BANK,
SUM(AVG_BALANCE) AS TOT_AVG_BALANCE

from BANKING_KPI
GROUP BY 1,2
ORDER BY TOT_AVG_BALANCE DESC;

SELECT * FROM TRANSACTIONS
WHERE BANK = 'Sky Bank' AND ACCOUNT_ID = 7745
ORDER BY DATE ,BANK;

SELECT * FROM TRANSACTIONS
WHERE ACCOUNT_ID = 1 AND YEAR(DATE) = 2019 AND MONTH(DATE) = 7;




SELECT * FROM ACC_LATEST_TXNS_WITH_BALANCE ;

select * from loan;

SELECT DISTINCT STATUS,SUM(AMOUNT)
FROM LOAN
GROUP BY 1
ORDER BY 1;



----------------------------------------------------------------------------------------------

--NVL(TOT_DEPOSIT_AMOUNT,0)-NVL(TOT_WITHDRAWAL_AMOUNT,0) AS TOT_BALANCE,
NVL((TOT_DEPOSIT_AMOUNT/DEPOSIT_COUNT),0) AS AVG_DEPOSIT_AMOUNT, 
NVL((TOT_WITHDRAWAL_AMOUNT/WITHDRAWAL_COUNT),0) AS AVG_WITHDRAWAL_AMOUNT
--NVL((TOT_BALANCE / TOT_ACCOUNT),0) AS AVG_BALANCE
