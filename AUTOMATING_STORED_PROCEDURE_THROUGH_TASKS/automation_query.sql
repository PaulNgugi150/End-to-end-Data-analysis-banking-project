
----------------------------------------------------------STORE PROCEDURE-------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE CREAT_OR_REPLACE_ACC_LATEST()
RETURNS STRING
LANGUAGE SQL
AS
$$
  CREATE OR REPLACE TABLE ACC_LATEST_TXNS_WITH_BALANCE 
AS(
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
ORDER BY TXN.ACCOUNT_ID,LTD.TXN_YEAR,LTD.TXN_MONTH);
$$;

SHOW PROCEDURES;


CREATE OR REPLACE PROCEDURE CREATE_OR_REPLACE_BANKINGKPI()
RETURNS STRING
LANGUAGE SQL
AS
$$
  CREATE OR REPLACE TABLE BANKING_KPI AS(
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
ORDER BY 1,2,3,4);
$$;  

CALL CREAT_OR_REPLACE_ACC_LATEST();
CALL CREATE_OR_REPLACE_BANKINGKPI();  
  
  

CREATE OR REPLACE TASK  ACC_LATEST_TXNS_WITH_BALANCE
WAREHOUSE = COMPUTE_WH
SCHEDULE =  '1 MINUTE'
AS CALL CREAT_OR_REPLACE_ACC_LATEST();
  
CREATE OR REPLACE TASK  BANKING_KPI
WAREHOUSE = COMPUTE_WH
SCHEDULE =  '2 MINUTE'
AS CALL CREATE_OR_REPLACE_BANKINGKPI();  
  
SHOW TASKS;  
  
ALTER TASK ACC_LATEST_TXNS_WITH_BALANCE  RESUME;
ALTER TASK ACC_LATEST_TXNS_WITH_BALANCE SUSPEND;  
ALTER TASK  BANKING_KPI RESUME;
ALTER TASK BANKING_KPI SUSPEND;    

  
DROP TASK IF EXISTS ACC_LATEST_TXNS_WITH_BALANCE;
DROP TASK IF EXISTS  BANKING_KPI; 
  
DROP TABLE  ACC_LATEST_TXNS_WITH_BALANCE;
DROP TABLE  BANKING_KPI;  
  
SELECT * FROM ACC_LATEST_TXNS_WITH_BALANCE;
SELECT * FROM BANKING_KPI;  
