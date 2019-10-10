
**********************************************************************;
*** IMPORT NEW CROSS SELL FILES. --------------------------------- ***;
*** INSTRUCTIONS HERE: R:\Production\MLA\FILES FOR MLA PROCeSSINg\ ***;
*** XSELL\XSELL TCI DECSION LENDER.txt --------------------------- ***;
*** CHANGE DATES IN THE LINES IMMEDIATELY BELOW ALONG WITH FILE    ***;
*** PATHS. FOR THE FILES PATHS, YOU WILL LIKELY NEED TO CREATE A   ***;
*** NEW FOLDER "CC" IN THE APPROPRIATE MONTH FILE. DO NOT CHANGE   ***;
*** THE ARGUMENT TO THE LEFT OF THE COMMA - ONLY CHANGE WHAT IS TO ***;
*** THE RIGHT OF THE COMMA. ALSO NOTE THE CHANGE TO "ODD" OR "EVEN"***; 
*** BASED ON WHAT IS NEEDED FOR THE CURRENT PULL. ---------------- ***;
**********************************************************************;

*** ASSIGN MACRO VARIABLES --------------------------------------- ***;
DATA 
	_NULL_;

	*** ASSIGN ID MACRO VARIABLES -------------------------------- ***;
	CALL SYMPUT ('TUD_ID', 'MOCC_10.1_2019');

	*** ASSIGN DATA FILE MACRO VARIABLE -------------------------- ***;
	
	CALL SYMPUT ('FINALEXPORTFLAGGED', 
		'\\mktg-app01\E\Production\2019\10_OCTOBER_2019\FBXSCC\MOCC_20190916FLAGGED.txt');
	CALL SYMPUT ('FINALEXPORTDROPPED', 
		'\\mktg-app01\E\Production\2019\10_OCTOBER_2019\FBXSCC\MOCC_20190916FINAL.txt');
	CALL SYMPUT ('EXPORTMLA', 
		'\\mktg-app01\E\Production\MLA\MLA-INPUT FILES TO WEBSITE\MOCC_20190916.txt');
	CALL SYMPUT ('FINALEXPORTED', 
		'\\mktg-app01\E\Production\2019\10_OCTOBER_2019\FBXSCC\MOCC_20190916FINAL_HH.cSv');
	CALL SYMPUT ('FINALEXPORTHH', 
		'\\mktg-app01\E\Production\2019\10_OCTOBER_2019\FBXSCC\MOCC_20190916FINAL_HH.txt');
RUN;

Proc SQL;
	Create Table AppTableQuery as
	SELECT A.AppType, A.task_refno, A.CustomerElig, A.CustomerEligDate,
		   A.CreditDenial, A.CreditDenialDate, A.CreditApproval, 
		   A.LoanNumber, A.StatusCodes, A.TaskStatus, A.LoanStatus, 
		   A.CreditScore, A.ApplicationEnterDate, A.AmountRequested, 
		   A.SmallApprovedAmount, A.LargeApprovedAmount, 
		   A.ReasonDeclined, A.FreeIncome, A.CustomerType, A.Branch, 
		   A.state, A.DTI, A.HousingStatus, A.FinalLoanAmount, 
		   A.acctrefno, A.ApplicationEnterDateOnly, A.BookDate, 
		   A.RiskRank_Small, A.RiskRank_Large, A.CustomScore, 
		   A.Monthlygrossincome, A.Cifno, A.firstname, A.lastname, 
		   A.street_address1, A.city, A.zip, A.ssn, A.dob
	FROM DW.vw_AppData A
	where A.ApplicationEnterDateOnly BETWEEN 
		  '2019-07-16' AND '2019-07-16';
RUN;

PROC SORT;  
	BY CIFNO;
RUN;

Proc SQL;
	Create Table TradesAndBk as
	SELECT
		p.Cifno,
		p.ReportDate,
		p.TotalTradeLines, 
		b.DateFiled,
		b.DateReported
	FROM
		NLSPROD.creditprofile  p
		INNER JOIN (
			SELECT 
				Cifno, 
				MAX(ReportDate) AS MaxReportDate 
			FROM NLSPROD.creditprofile 
			GROUP BY Cifno) md 
			ON p.Cifno = md.Cifno AND p.ReportDate = MaxReportDate
		LEFT JOIN NLSPROD.creditbankruptcy b 
			ON p.CreditProfileID = b.CreditProfileID;
RUN;

PROC SORT nodupkey;  
	BY CIFNO;
RUN;

DATA appsTradesAndBk; 
	MERGE AppTableQuery(IN = INAPPS) TradesAndBk(IN = INTRADES);  
	BY CIFNO;  
	IF INAPPS;
RUN;

DATA APPS(
	KEEP = BRANCH firstname lastname street_address1 city zip ssn dob
		   TASK_REFNO TASKSTATUS CUSTOMERELIG CREDITAPPROVAL 
		   CUSTOMERTYPE LOANNUMBER ApplicationEnterDateonly APPYR APPMM 
		   APPDAY ApplicationEnterDate FREEINCOME MONTHLYGROSSINCOME 
		   DTI_RATIO DTI CREDITSCORE CUSTOMSCORE CUSTOM_SCORE 
		   REASONDECLINED HOUSINGSTATUS RISKRANK_SMALL RISKRANK_LARGE 
		   STATE METHOD REASON Cifno TotalTradeLines DateFiled 
		   DateReported);
   *set MDRIVE.TEMPAPPS_20190706; *0615;  *0419; 	
	set appsTradesAndBk;  *08;

	*** EXCLUSIONS ----------------------------------------------- ***;
	IF TASKSTATUS = 'VOIDED' then DELETE;

	*** MITCH SAYS THESE ARE ONLY LEADS, NOT APPS ---------------- ***;
	IF TASKSTATUS in ('NEW LEAD' 'LEAD INACTIVE') 
		then delete; 

	DTI_RATIO = DTI * 1;
	CUSTOM_SCORE = CUSTOMSCORE * 1;
	*** CREATE WATERFALL OF EXCLUSION REASONS... ----------------- ***;
	REASON = '99. KEEP THE APPLICATION';

	IF CUSTOMERTYPE = 'PB' 
		THEN REASON = '1. PB APP'; 
	ELSE 
	IF LOANNUMBER NE '' 
		THEN REASON = '2. BOOKED LOAN'; 
   *ELSE
	If CUSTOMERELIG NE 'ELIGIBLE' 
		THEN REASON = '3. NOT SYSTEM ELIGIBLE'; 
	ELSE 
	If substr(CREDITAPPROVAL, 1, 6) = 'DENIED' 
		THEN REASON = '3. CR APPRVL = DENIED'; 
	ELSE 
	if taskstatus = 'DENIED' 
		THEN REASON = '4. TASK STATUS = DENIED'; 
	ELSE 
	IF riskrank_small = 'FAIL' 
		THEN REASON = '5. RISK RANK FAIL'; 
   *ELSE 
	IF riskrank_small IN ('WEAK' 'FAIL') 
		THEN REASON = '6. RISK RANK WEAK/FAIL'; 
   *ELSE 
	If CUSTOMERELIG NE 'ELIGIBLE' and (CUSTOM_SCORE < 240 or 
									   CREDITSCORE < 575 )   
		THEN REASON = '7. INELIG, FICO OR CUST LOW'; 
	ELSE 
	if taskstatus NOT IN ('CANCELED', 'WITHDRAWN') 
		THEN REASON = '6. NOT WITHDR or CANCELED'; 
	ELSE
	IF CREDITAPPROVAL NE 'APPROVED' 
		THEN REASON = '8. NOT BR APPROVED OR DENIED'; 

	If  SUBSTR(REASON, 1, 2) IN ('8.' '99') AND 
		CUSTOMERELIG NE 'ELIGIBLE' 
		THEN DO;
  		if CUSTOM_SCORE ge 270 AND CREDITSCORE ge 575 
			THEN REASON = '9. INELIG, MAYBE';
  		else 
		if CUSTOM_SCORE ge 240 AND CREDITSCORE ge 600    
			THEN REASON = '9. INELIG, MAYBE';
  		else reason = '7. INELIGIBLE, LOW SCORE';
	END;

	*** FORMAT SOME FIELDS (CONVERT FROM CHARACTER TO NUMERIC OR   ***;
	*** TRIM EXTRA CHARACTERS, MAKE DATE FIELDS DATE FORMAT FOR    ***;
	*** DATE MATH ETC). MAKE RISK RANKS SORTABLE ----------------- ***;
	IF reasondeclined = '' 
		THEN reasondeclined = 'MISSING';

	APPYR = SUBSTR(ApplicationEnterDateonly, 1, 4);    
	APPMM = SUBSTR(ApplicationEnterDateonly, 6, 2);    
	APPDAY = SUBSTR(ApplicationEnterDateonly, 9, 2);   
	ApplicationEnterDate = MDY(APPMM, APPDAY, APPYR);

   *IF '30jun2019'd < ApplicationEnterDate < '01aug2019'd;
	IF '08jul2019'd < ApplicationEnterDate < '09aug2019'd;

	*** CLEAN UP SOME BAD STATE FORMATS -------------------------- ***;
	IF STATE IN ('AL' 'OK' 'NM' 'NC' 'GA' 'TN' 'MO' 'WI' 'SC' 'TX' 'VA' 
				 'WI') 
		THEN STATE = STATE;  
	ELSE DO;
  		IF STATE IN ('AL.' 'ALA') 
			THEN STATE = 'AL'; 
		ELSE 
  		IF STATE = 'AZ' 
			THEN STATE = 'NM'; 
		ELSE 
  		IF STATE = 'FL' 
			THEN STATE = 'GA'; 
		ELSE 
  		IF SUBSTR(STATE, 1, 1) = 'G' 
			THEN STATE = 'GA'; 
		ELSE 
  		IF STATE = 'KS' 
			THEN STATE = 'MO'; 
		ELSE 
  		IF STATE  ='TEX' 
			THEN STATE = 'TX'; 
		ELSE 
  		IF STATE = 'TX.' 
			THEN STATE = 'TX'; 
		ELSE 
  		IF STATE = 'WI.' 
			THEN STATE = 'WI';
		IF STATE = 'MOU' 
			THEN STATE = 'MO';
  		ELSE STATE = '??';
	END;
	IF STATE = '??' THEN DELETE;
	CIFNO_1 = input(Cifno, 15.);
	DROP APPYR APPMM APPDAY CUSTOMSCORE DTI 
		 ApplicationEnterDate;
RUN;

PROC FREQ;
	TABLES REASON;
RUN;

proc freq;  
	tables creditapproval taskstatus riskrank_small reasondeclined; 
	WHERE SUBSTR(REASON, 1, 2) = '9.';
RUN;

proc freq;
	tables reasondeclined * riskrank_small / NOCOL NOROW NOPERCENT; 
	WHERE SUBSTR(REASON, 1, 2) = '9.';
RUN;

DATA KEEPERS;
	format BRANCH firstname lastname street_address1 city zip ssn dob
		   task_refno ApplicationEnterDateOnly taskstatus housingstatus 
		   customertype reasondeclined creditscore custom_score 
		   riskrank_small riskrank_large freeincome monthlygrossincome 
		   dti_ratio customerelig creditapproval STATE Cifno 
		   TotalTradeLines DateFiled DateReported LOANNUMBER;
	SET APPS;
	WHERE SUBSTR(REASON, 1, 2) IN ('8.' '99');
	DROP LOANNUMBER APPYR APPMM APPDAY METHOD ApplicationEnterDate DTI 
		 CUSTOMSCORE REASON;
RUN;

PROC SORT;  
	BY ApplicationEnterDateonly;
RUN;

*** THESE NEED TO BE CHECKED AGAINST NLS FIELDS TO SEE IF THEY     ***;
*** HAVE > TRADE AND DON'T HAVE A RECENT BK ---------------------- ***;
DATA INELIG;   
	format BRANCH firstname lastname street_address1 city zip ssn dob
		   task_refno ApplicationEnterDateOnly taskstatus housingstatus 
		   customertype reasondeclined creditscore custom_score 
		   riskrank_small riskrank_large freeincome monthlygrossincome 
		   dti_ratio customerelig creditapproval STATE Cifno 
		   TotalTradeLines DateFiled DateReported LOANNUMBER;
	SET APPS;
	WHERE SUBSTR(REASON, 1, 2) = '9.'; 
	IF  TotalTradeLines < 2 THEN DELETE;
	IF DateFiled NE '.' AND DateFiled < '20Aug2017'd then delete;
RUN;

DATA FINAL_MOCC;
	LENGTH CUSTID $20 MIDDLENAME $25 CADDR2 $25;
	SET KEEPERS INELIG;
	CUSTID = STRIP(_N_);
	camp_type = 'MOCC';
	DOB_1 = put(datepart(DOB),yymmddd10.);
	DOB = DOB_1;
	DROP DOB;
	RENAME STATE = CST
		   LOANNUMBER = BRACCTNO
		   DOB_1 = DOB;
RUN;

PROC IMPORT 
	DATAFILE = 
	"\\mktg-app01\E\Production\Master Files and Instructions\FBXSCC_Offers -20190916.xlSx" 
	DBMS = EXCEL OUT = OFFERS REPLACE; 
RUN;

DATA OFFERS;
	SET OFFERS;
	RISK_SEGMENT = STRIP(RISK_SEGMENT);
RUN;

PROC SORT 
	DATA = FINAL_MOCC; 
	BY CST camp_type; 
RUN;

PROC SORT 
	DATA = OFFERS; 
	BY CST camp_type; 
RUN;

DATA FINAL_MOCC2;
	MERGE FINAL_MOCC(IN = x) OFFERS;
	BY CST camp_type;
	IF x;
	FORMAT AMT_GIVEN1 DOllar10.2;
	SSNO1_A = compress(SSN,"1234567890" , "ki");
	SSNO1 = put(input(SSNO1_A,best9.),z9.);
	RENAME APR = PERCENT;
RUN;

*** SEND TO DOD -------------------------------------------------- ***;
DATA MLA;
	SET FINAL_MOCC2;
	KEEP SSNO1 DOB LASTNAME FIRSTNAME MIDDLENAME BRACCTNO SSNO1_A;
	LASTNAME = compress(LASTNAME,"ABCDEFGHIJKLMNOPQRSTUVWXYZ " , "kis");
	MIDDLENAME = compress(MIDDLENAME,"ABCDEFGHIJKLMNOPQRSTUVWXYZ " , "kis");
	FIRSTNAME = compress(FIRSTNAME,"ABCDEFGHIJKLMNOPQRSTUVWXYZ " , "kis");
	SSNO1_A = compress(SSNO1,"1234567890" , "ki");
	SSNO1 = put(input(SSNO1_A,best9.),z9.);
	DOB = compress(DOB,"1234567890 " , "kis");
	if DOB = ' ' then delete;
RUN;

DATA MLA;
	SET MLA;
	IDENTIFIER = "S";
RUN;

PROC DATASETS;
	MODIFY MLA;
	RENAME DOB = "Date of Birth"n 
		   SSNO1 = "Social Security Number (SSN)"n
		   LASTNAME = "Last NAME"n 
		   FIRSTNAME = "First NAME"n 
		   MIDDLENAME = "Middle NAME"n 
		   BRACCTNO = "Customer Record ID"n
		   IDENTIFIER = "Person Identifier CODE"n;
RUN;

DATA FINALMLA;
	LENGTH "Social Security Number (SSN)"n $ 9 
		   "Date of Birth"n $ 8
		   "Last NAME"n $ 26
		   "First NAME"n $20
		   "Middle NAME"n $ 20
		   "Customer Record ID"n $ 28
		   "Person Identifier CODE"n $ 1;
	SET MLA;
RUN;

PROC PRINT 
	DATA = FINALMLA(OBS = 10);
RUN;

PROC CONTENTS
	DATA = FINALMLA;
RUN;

DATA _NULL_;
	SET FINALMLA;
	FILE "\\mktg-app01\E\Production\MLA\MLA-INput files TO WEBSITE\MOCC_20190916.txt";
	PUT @ 1 "Social Security Number (SSN)"n 
		@ 10 "Date of Birth"n 
		@ 18 "Last NAME"n 
		@ 44 "First NAME"n 
		@ 64 "Middle NAME"n 
		@ 84 "Customer Record ID"n
		@ 112 "Person Identifier CODE"n;
RUN;

*** STEP 2: WHEN FILE IS RETURNED FROM DOD, RUN CODE BELOW         ***;
*** DO NOT CHANGE FILE NAME -------------------------------------- ***;
FILENAME MLA1
"\\mktg-app01\E\Production\MLA\MLA-Output files FROM WEBSITE\MLA_5_0_MOCC_20190821.txt";

DATA MLA1;
	INFILE MLA1;
	INPUT SSNO1 $ 1-9 DOB $ 10-17 LASTNAME $ 18-43 FIRSTNAME $ 44-63
		  MIDDLENAME $ 64-83  BRACCTNO $ 84-111 PI_CODE $ 112-120 
		  MLA_DOD $121-145;
	MLA_STATUS = SUBSTR(MLA_DOD, 1, 1);
RUN;

PROC PRINT 
	DATA = MLA1(OBS = 10);
RUN;

DATA MOCCFINAL; 
	SET FINAL_MOCC2; 
RUN;

PROC SORT 
	DATA = MOCCFINAL; 
	BY SSNO1; 
RUN;

PROC SORT 
	DATA = MLA1; 
	BY SSNO1; 
RUN;

DATA FINALHH;
	MERGE MOCCFINAL(IN = x) MLA1;
	BY SSNO1;
	IF x;
	RENAME CreditScore = FICO;
RUN;

*** COUNT FOR WATERFALL ------------------------------------------ ***;
PROC FREQ 
	DATA = FINALHH;
	TABLE MLA_STATUS / NOCUM NOPERCENT;
RUN;

DATA FINALHH1;
	LENGTH FICO_RANGE_25PT $10 CAMPAIGN_ID $25 MADE_UNMADE $15
		   CUSTID $20 MGC $20 STATE1 $5 TEST_CODE $20;
	SET FINALHH;
	IF MLA_STATUS = "N";
	IF FICO = 0 THEN FICO_RANGE_25PT = "0";
	IF 0 < FICO < 500 THEN FICO_RANGE_25PT = "<500";
	IF 500 <= FICO <= 524 THEN FICO_RANGE_25PT = "500-524";
	IF 525 <= FICO <= 549 THEN FICO_RANGE_25PT = "525-549";
	IF 550 <= FICO <= 574 THEN FICO_RANGE_25PT = "550-574";
	IF 575 <= FICO <= 599 THEN FICO_RANGE_25PT = "575-599";
	IF 600 <= FICO <= 624 THEN FICO_RANGE_25PT = "600-624";
	IF 625 <= FICO <= 649 THEN FICO_RANGE_25PT = "625-649";
	IF 650 <= FICO <= 674 THEN FICO_RANGE_25PT = "650-674";
	IF 675 <= FICO <= 699 THEN FICO_RANGE_25PT = "675-699";
	IF 700 <= FICO <= 724 THEN FICO_RANGE_25PT = "700-724";
	IF 725 <= FICO <= 749 THEN FICO_RANGE_25PT = "725-749";
	IF 750 <= FICO <= 774 THEN FICO_RANGE_25PT = "750-774";
	IF 775 <= FICO <= 799 THEN FICO_RANGE_25PT = "775-799";
	IF 800 <= FICO <= 824 THEN FICO_RANGE_25PT = "800-824";
	IF 825 <= FICO <= 849 THEN FICO_RANGE_25PT = "825-849";
	IF 850 <= FICO <= 874 THEN FICO_RANGE_25PT = "850-874";
	IF 875 <= FICO <= 899 THEN FICO_RANGE_25PT = "875-899";
	IF 975 <= FICO <= 999 THEN FICO_RANGE_25PT = "975-999";
	IF FICO = "" THEN FICO_RANGE_25PT = "";
	IF CAMP_TYPE = "MOCC" THEN CAMPAIGN_ID = "&TUD_ID";
	SSNO1_RT7 = substr(SSNO1, 3, 9);
	CD60 = '';
	CONPROFILE1 = '';
RUN;

**********************************************************************;
********************************* TEST *******************************;
**********************************************************************;

*** IDENTIFY IF CUSTOMER CURRENTLY HAS AN OPEN LOAN FOR MOCC ----- ***;
DATA OPENLOANS;
	SET dw.vw_loan(
		KEEP = SSNO1 SSNO2 SSNO1_RT7 POCD PLCD POFFDATE PLDATE 
			   BNKRPTDATE);
	WHERE POCD = "" & 
		  PLCD = "" & 
		  POFFDATE = "" & 
		  PLDATE = "" & 
		  BNKRPTDATE = "";
RUN;

DATA SSNO2S;
	SET OPENLOANS;
	IF SSNO2 NE "";
	SSNO1 = SSNO2;
RUN;

DATA OPENLOANS1;
	SET OPENLOANS SSNO2S;
RUN;

DATA OPENLOANS1;
	SET OPENLOANS1;
	OPEN_FLAG = "X";
	DROP POCD PLCD POFFDATE PLDATE BNKRPTDATE SSNO2;
RUN;

PROC SORT 
	DATA = OPENLOANS1 NODUPKEY;
	BY SSNO1;
RUN;

PROC SORT 
	DATA = FINALHH1;
	BY SSNO1;
RUN;

DATA FINALHH1;
	MERGE FINALHH1(IN = x) OPENLOANS1;
	BY SSNO1;
	IF x;
	*IF customerelig = "" THEN DELETE;
	*IF OPEN_FLAG = "X" THEN DELETE;
RUN;

*** EXPORT FINAL FILE -------------------------------------------- ***;
PROC EXPORT 
	DATA = FINALHH1 OUTFILE = "&FINALEXPORTDROPPED" DBMS = TAB REPLACE;
RUN;

**********************************************************************;
********************************* TEST *******************************;
**********************************************************************;

DATA FINALHH2;
	SET FINALHH1;
	RENAME BRANCH = BRANCH
		   FIRSTNAME = CFNAME1
		   MIDDLENAME = CMNAME1
		   LASTNAME = CLNAME1
		   street_address1 = CADDR1 
		   CADDR2 = CADDR2
		   city = CCITY 
		   state = CST 
		   zip = CZIP 
		   SSNO1_RT7 = SSN 
		   CD60 = N_60_DPD 
		   CONPROFILE1 = CONPROFILE;
		   CELLPHONE = '';
		   MONTH_SPLIT = '';
		   PHONE = '';
		   POFFDATE = '';
		   SUFFIX = '';
		   IF OPEN_FLAG = "X" THEN DELETE;
RUN;

*** IF RISK_SEGMENT = "TEST" THEN TEST_CODE = "RATE_TEST"          ***;
*** ELSE TEST_CODE = "Control" ----------------------------------- ***;

PROC Sql;
	CREATE TABLE FINALHH5 aS
	Select CUSTID, BRANCH, CFNAME1,	CMNAME1, CLNAME1, CADDR1, CADDR2,
		   CCITY, CST, CZIP, SSN, AMT_GIVEN1, PERCENT, numpymntS,
		   CAMP_TYPE, ORig_amtid, FICO, DOB, MLA_STATUS, RISK_SEGMENT, 
		   N_60_DPD, CONPROFILE, BRACCTNO, CIFNO, CAMPAIGN_ID, MGC,
		   MONTH_SPLIT, MADE_UNMADE, FICO_RANGE_25PT, STATE1,
		   TEST_CODE, POFFDATE, phoNE, cellphoNE, SUFFIX
	FROM FINALHH2;
QUIT;
RUN;

PROC EXPORT 
	DATA = FINALHH5 OUTFILE = "&FINALEXPORTHH"  DBMS = TAB;
RUN;

PROC EXPORT 
	DATA = FINALHH5 OUTFILE = "&FINALEXPORTED" DBMS = cSv;
RUN;

DATA check;
	SET FINALHH5;
	IF AMT_GIVEN1 = "";
RUN;

PROC FREQ 
	DATA = FINALHH5;
	TABLES RISK_SEGMENT;
RUN;

PROC FREQ 
	DATA = FINALHH5;
	TABLES MONTH_SPLIT;
RUN;