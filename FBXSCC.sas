**********************************************************************;
*** IMPORT NEW CROSS SELL FILES. --------------------------------- ***;
*** INSTRUCTIONS HERE: R:\Production\MLA\Files for MLA Processing\ ***;
*** XSELL\XSELL TCI DECSION LENDER.txt --------------------------- ***;
*** CHANGE DATES IN THE LINES IMMEDIATELY BELOW ALONG WITH FILE    ***;
*** PATHS. FOR THE FILES PATHS, YOU WILL LIKELY NEED TO CREATE A   ***;
*** NEW FOLDER "CC" IN THE APPROPRIATE MONTH FILE. DO NOT CHANGE   ***;
*** THE ARGUMENT TO THE LEFT OF THE COMMA - ONLY CHANGE WHAT IS TO ***;
*** THE RIGHT OF THE COMMA. ALSO NOTE THE CHANGE TO "Odd" OR "Even"***; 
*** BASED ON WHAT IS NEEDED FOR THE CURRENT PULL. ---------------- ***;
**********************************************************************;

*** ASSIGN MACRO VARIABLES --------------------------------------- ***;
DATA 
	_NULL_;

	CALL SYMPUT ('yesterday','2018-04-01'); /* DAY BEFORE PULL */
	CALL SYMPUT ('_1monthago','2018-03-02'); /* 1 MONTH FROM PULL */
	CALL SYMPUT ('_16monthsago','2016-12-02'); /*16 MONTHS FROM PULL*/
	CALL SYMPUT('_3yrdate','2015-04-02'); /* 3 YEARS FROM PULL */
	CALL SYMPUT('_5yrdate','2013-04-02'); /* 5 YEARS FROM PULL */
	CALL SYMPUT ('_15monthsago','2017-01-02'); /*15 MONTHS FROM PULL*/

	*** ASSIGN ID MACRO VARIABLES -------------------------------- ***;
	CALL SYMPUT ('retail_id', 'RetailXS_5.0_2018');
	CALL SYMPUT ('auto_id', 'AutoXS_5.0_2018');
	CALL SYMPUT ('fb_id', 'FB_5.0_2018CC');

	*** ASSIGN ODD/EVEN MACRO VARIABLE --------------------------- ***;
	CALL SYMPUT ('odd_even', 'Odd'); 

	*** ASSIGN DATA FILE MACRO VARIABLE -------------------------- ***;
	CALL SYMPUT ('finalexportflagged', 
		'\\mktg-app01\E\Production\2018\04-April_2018\FBXSCC\FBXS_CC_.20180402flagged.txt');
	CALL SYMPUT ('finalexportdropped', 
		'\\mktg-app01\E\Production\2018\04-April_2018\FBXSCC\FBXS_CC_20180402final.txt');
	CALL SYMPUT ('exportMLA', 
		'\\mktg-app01\E\Production\MLA\MLA-Input files TO WEBSITE\FBCC_20180402.txt');
	CALL SYMPUT ('finalexportED', 
		'\\mktg-app01\E\Production\2018\04-April_2018\FBXSCC\FBXS_CC_20180402final_HH.csv');
	CALL SYMPUT ('finalexportHH', 
		'\\mktg-app01\E\Production\2018\04-April_2018\FBXSCC\FBXS_CC_20180402final_HH.txt');
RUN;

*** CHECK THAT MACRO VARIABLES WERE ASSIGNED CORRECTLY ----------- ***;
%PUT "&_15monthsago" "&_5yrdate" "&yesterday";

*** PULL IN ALL XS SOURCES AND MERGE, THEN PULL IN FB AND MERGE WITH *;
*** XS. ---------------------------------------------------------- ***;

*** IMPORT TCI3_5 DELIMITED DATA FILE AS TCI2 DATA TABLE --------- ***;
PROC IMPORT 
	DATAFILE = 
		"\\mktg-app01\E\Production\MLA\Files for MLA Processing\XSELL\TCI3_5.txt"
		DBMS = DLM OUT = TCI2 REPLACE;
	DELIMITER = '09'x;
	GUESSINGROWS = MAX;
RUN;

*** CREATE NEW DATASET `TCI3`. FORMAT `SSNO1`, `SSNO1_RT7`, AND    ***;
*** `APPLICATION NUMBER` AS CHAR WITH DESIGNATED LENGTHS AND STORE ***;
*** IN `TCI3` DATASET -------------------------------------------- ***;
DATA TCI3;
	SET TCI2;
	SSN = PUT(INPUT(SSNO1, BEST32.), Z9.);
	SS7 = PUT(INPUT(SSNO1_RT7, BEST32.), Z7.);
	APPNUM = STRIP(PUT('application number'n, 10.));
	DROP SSNO1 SSNO1_RT7 'application number'n;
	RENAME SSN = SSNO1 SS7 = SSNO1_RT7 APPNUM = 'application number'n;
RUN;

*** NEW TCI DATA - RETAIL AND AUTO ------------------------------- ***;
PROC IMPORT 
	DATAFILE = 
		"\\mktg-app01\E\Production\2018\04-April_2018\FBXSCC\XS_Mail_Pull.xlsx" 
		DBMS = XLSX OUT = NEWXS REPLACE;
	RANGE = "XS Mail Pull$A3:0";
	GETNAMES = YES;
RUN;

*** FORMAT THE `NEWXS` DATASET AND STORE AS `NEWXS2` ------------- ***;
DATA NEWXS2;
	SET NEWXS;

	*** CREATE `SOURCE` VARIABLE AND ASSIGN `LOAN TYPE = AUTO      ***;
	*** INDIRECT` AS `TCICENTRAL` OR `LOAN TYPE = RETAIL` AS       ***; 
	*** `TCIRETAIL` ---------------------------------------------- ***;
	IF 'loan type'n = "Auto Indirect" THEN SOURCE = "TCICentral";
	IF 'loan type'n = "Retail" THEN SOURCE = "TCIRetail";
	IF SOURCE NE "";

	*** SEPERATE `applicant address` VARIABLE INTO `ADR1`, `CITY`, ***; 
	*** `STATE`, AND `ZIP` VARIABLES WHEN `applicant address` DOES ***; 
	*** NOT CONTAIN THE STRING "Apt" ----------------------------- ***;
	IF FIND('applicant address'n, "Apt") = 0 THEN DO;
		ADR1 = SCAN('applicant address'n, 1, ",");
		CITY = SCAN('applicant address'n, 2, ",");
		STATE = SCAN('applicant address'n, 3, ",");
		ZIP = SCAN('applicant address'n, 4, ",");
	END;

	*** SEPERATE `applicant address` VARIABLE INTO `ADR1`, `ADR2`, ***;
	*** `CITY`, `STATE`, AND `ZIP` VARIABLES WHEN `applicant       ***;
	*** address` CONTAINS THE STRING "Apt" ----------------------- ***;
	IF FIND('applicant address'n, "Apt") GE 1 THEN DO;
		ADR1 = SCAN('applicant address'n, 1, ",");
		ADR2 = SCAN('applicant address'n, 2, ",");
		CITY = SCAN('applicant address'n, 3, ",");
		STATE = SCAN('applicant address'n, 4, ",");
		ZIP = SCAN('applicant address'n, 5, ",");
	END;

	*** FORMAT `applicant dob` AS YYMMDD10 AND STORE IN `DOB`      ***;
	*** VARIABLE. ------------------------------------------------ ***;
	DOB = PUT('applicant dob'n, YYMMDD10.);

	*** FORMAT `application date` AS MMDDYY10 -------------------- ***;
	'application date1'n = PUT('application date'n, MMDDYY10.);

	*** CONCATENATE "TCI" TO `Application Number` AND STORE AS     ***;
	*** `BRACCTNO` VARIABLE -------------------------------------- ***;
	BRACCTNO = CATS("TCI", 'Application Number'n);

	*** SUB-STRING THE LAST 7 DIGITS FROM THE `applicant ssn`      ***;
	*** VARIABLE AND STORE THEM IN `SSNO1_RT7` VARIABLE ---------- ***;
	SSNO1_RT7 = SUBSTRN('applicant ssn'n, MAX(1, 
		length('applicant ssn'n) - 6), 7);

	*** DROP THE VARIABLES `Application Date`, `Applicant Address`,***;
	*** `Applicant Address Zip`, `Applicant DOB`, `app. work phone`***;
	*** FROM NEWXS2 DATASET -------------------------------------- ***;
	DROP 'Application Date'n 'Applicant Address'n
		'Applicant Address Zip'n 'Applicant DOB'n 'app. work phone'n;

	*** RENAME THE `application date1`, `applicant email`,         ***;
	*** `Applicant Credit Score`, `Applicant First Name`,          ***;
	*** `Applicant Last Name`, `Applicant SSN`, `Applicant Middle  ***;
	*** Name`, `app. cell phone`, AND `app. home phone` VARIABLES  ***;
	RENAME 
		'application date1'n = 'application date'n
		'applicant email'n = EMAIL 
		'Applicant Credit Score'n = CRSCORE
		'Applicant First Name'n = FIRSTNAME
		'Applicant Last Name'n = LASTNAME 
		'Applicant SSN'n = SSNO1
		'Applicant Middle Name'n = MIDDLENAME 
		'app. cell phone'n = CELLPHONE 
		'app. home phone'n = PHONE;
RUN;

*** CONCATENATE `TCI3` AND `NEWXS2` DATASETS INTO `TCI` ---------- ***;
DATA TCI;

	*** SET LENGTH FOR `ADR1`, `CITY`, `STATE`, `ZIP`,             ***;
	*** `MIDDLENAME`, `SOURCE`, AND `BRACCTNO` VARIABLES --------- ***;
	LENGTH 
		ADR1 $40 
		CITY $25 
		STATE $4 
		ZIP $10 
		MIDDLENAME $25 
		SOURCE $11
		BRACCTNO $15;
	SET TCI3 NEWXS2; /* CONCATENATE */
	SSNO1 = STRIP(SSNO1); /* STRIP WHITE SPACE FROM `SSNO1` */
	DOB = COMPRESS(DOB, "-"); /* REMOVE HYPHEN FROM `DOB` */
	FORMAT _CHARACTER_; /* SET CHAR FORMAT TO SAS DEFAULT */
RUN;

*** READ IN DATA FROM `dw.vw_loan_NLS` TABLE. SUBSET FOR RELEVANT  ***;
*** VARIABLES. FILTER TO ISOLATE XS LOANS. STORE AS `XS_L` DATASET ***;
DATA XS_L;
	
	*** SUBSET `dw.vw_loan_NLS` USING RELEVANT VARIABLES --------- ***;
	SET dw.vw_loan_NLS (
		KEEP = OWNST PURCD CIFNO BRACCTNO ID SSNO1 OWNBR SSNO1_RT7 
			SSNO2 LNAMT NETLOANAMOUNT FINCHG LOANTYPE ENTDATE LOANDATE 
			CLASSID CLASSTRANSLATION XNO_TRUEDUEDATE FIRSTPYDATE SRCD 
			POCD POFFDATE PLCD PLDATE PLAMT BNKRPTDATE BNKRPTCHAPTER
			CONPROFILE1 DATEPAIDLAST APRATE CRSCORE CURBAL);
	
	*** FILTER DATA. REMOVE NULLS FROM `CIFNO`. FILTER FOR         ***;
	*** `ENTDATE` FROM A YEAR AGO UNTIL MOST RECENT. KEEP ONLY     ***;
	*** NULLS FROM `POCD`. KEEP ONLY NULLS FROM `PLCD`. KEEP ONLY  ***;
    *** NULLS FROM `PLDATE`. KEEP ONLY NULLS FROM `POFFDATE`. KEEP ***;
	*** ONLY NULLS FROM `BNKRPTDATE`. KEEP RELEVANT `CLASSID`S and ***;
	*** `OWNST`S ------------------------------------------------- ***;
	WHERE CIFNO NE "" & 
		ENTDATE >= "&_15monthsago" & 
		POCD = "" & 
		PLCD = "" & 
		PLDATE = "" & 
		POFFDATE = ""  & 
		BNKRPTDATE = "" & 
		CLASSID in (10,19,20,31,34) & 
		OWNST in ("AL", "GA", "NC", "NM", "OK", "SC", "TN", "TX", "VA");
	
	*** CREATE `SS7BRSTATE` VARIABLE ----------------------------- ***;
	SS7BRSTATE = CATS(SSNO1_RT7, SUBSTR(OWNBR, 1, 2)); 
RUN;

*** READ IN DATA FROM `dw.vw_borrower_nls` TABLE. SUBSET FOR       ***;
*** RELEVANT VARIABLES. FILTER TO ISOLATE XS LOANS. STORE AS       ***; 
*** `BORRNLS` DATASET -------------------------------------------- ***;
DATA BORRNLS;

	*** SET LENGTH FOR `FIRSTNAME`, `MIDDLENAME`, `LASTNAME` ----- ***;
	LENGTH FIRSTNAME $20 MIDDLENAME $20 LASTNAME $30;

	*** SUBSET `dw.vw_borrower_nls` USING RELEVANT VARIABLES ----- ***;
	SET dw.vw_borrower_nls (
		KEEP = RMC_UPDATED PHONE CELLPHONE CIFNO SSNO SSNO_RT7  FNAME 
			LNAME ADR1 ADR2 CITY STATE ZIP BRNO AGE CONFIDENTIAL
			SOLICIT CEASEANDDESIST CREDITSCORE);
	WHERE CIFNO NOT =: "B"; /* REMOVE `CIFNO`S THAT BEGIN WITH "B" */
	
	*** STRIP WHITE SPACE FROM `FNAME`, `LNAME`, `ADR1`, `ADR2`,   ***;
	*** `CITY`, `STATE`, `ZIP` ----------------------------------- ***;
	FNAME = STRIP(FNAME);
	LNAME = STRIP(LNAME);
	ADR1 = STRIP(ADR1);
	ADR2 = STRIP(ADR2);
	CITY = STRIP(CITY);
	STATE = STRIP(STATE);
	ZIP = STRIP(ZIP);
	
	*** FIND ALL INSTANCES OF "JR" IN `FNAME`. REMOVE "JR" FROM    ***;
	*** STRING AND STORE AS `FIRSTNAME`. STORE ALL OCCURENCES OF   ***;
	*** "JR" IN NEW VARIABLE, `SUFFIX` --------------------------- ***;
	IF FIND(FNAME, "JR") GE 1 THEN DO;
		FIRSTNAME = COMPRESS(FNAME, "JR");
		SUFFIX = "JR";
	END;
	
	*** FIND ALL INSTANCES OF "SR" IN `FNAME`. REMOVE "SR" FROM    ***;
	*** STRING AND STORE AS `FIRSTNAME`. STORE ALL OCCURENCES OF   ***;
	*** "SR" IN NEW VARIABLE, `SUFFIX` --------------------------- ***;
	IF FIND(FNAME, "SR") GE 1 THEN DO;
		FIRSTNAME = COMPRESS(FNAME, "SR");
		SUFFIX = "SR";
	END;
	
	*** IF `SUFFIX` IS NULL, TAKE 1ST WORD IN `FNAME` AND STORE AS ***;
	*** `FIRSTNAME`. TAKE 2ND, 3RD, AND 4TH WORDS IN `FNAME` AND   ***;
	*** STORE AS `MIDDLENAME` ------------------------------------ ***;
	IF SUFFIX = "" THEN DO;
		FIRSTNAME = SCAN(FNAME, 1, 1);
		MIDDLENAME = CATX(" ", SCAN(FNAME, 2, " "), 
			SCAN(FNAME, 3, " "), SCAN(FNAME, 4, " "));
	END;
	NWORDS = COUNTW(FNAME, " "); /* COUNT # OF WORDS IN `FNAME` */
	
	*** IF MORE THAN 2 WORDS IN `FNAME`, TAKE 1ST WORD AND STORE IN***; 
	*** `FIRSTNAME`, AND TAKE SECOND WORD AND ADD TO `MIDDLENAME`  ***;
	IF NWORDS > 2 & SUFFIX NE "" THEN DO;
		FIRSTNAME = SCAN(FNAME, 1, " ");
		MIDDLENAME = SCAN(FNAME, 2, " ");
	END;
	DOB = COMPRESS(AGE, "-"); /* REMOVE HYPHEN, STORE `AGE` AS `DOB` */
	LASTNAME = LNAME; /* STORE `LNAME` AS `LASTNAME` */
	DROP FNAME LNAME NWORDS AGE; /* DROP VARIABLES FROM TABLE */
	IF CIFNO NE ""; /* FILTER SET OF NULL `CIFNO`S */

	*** STORE `SSNO` AS `SSNO1`. *STORE `SSNO_RT7` AS `SSNO1_RT7`  ***;
	SSNO1 = SSNO;
	SSNO1_RT7 = SSNO_RT7;
RUN;

*** SPLIT: GROUP BY `CIFNO` - APPLY: FIND MAX `ENTDATE` PER `CIFNO`***:
*** - COMBINE: STORE RECORDS WITH MAX `ENTDATE` PER `CIFNO` IN     ***;
*** `XS_LDEDUPED` TABLE ------------------------------------------ ***;
PROC SQL;
	CREATE TABLE XS_LDEDUPED AS
	SELECT *
	FROM XS_L
	GROUP BY CIFNO
	HAVING ENTDATE = MAX(ENTDATE);
QUIT;

*** REMOVE RECORDS WITH DUPLICATE `CIFNO` FROM `XS_LDEDUPED` ----- ***;
PROC SORT 
	DATA = XS_LDEDUPED NODUPKEY; 
	BY CIFNO; 
RUN;

*** SORT `BORRNLS` BY `CIFNO` DEFAULT ASCENDING THEN BY            ***;
*** `RMC_UPDATED` DESCENDING ------------------------------------- ***;
PROC SORT 
	DATA = BORRNLS; 
	BY CIFNO DESCENDING RMC_UPDATED; 
RUN;

*** REMOVE RECORDS WITH DUPLICATE `CIFNO` FROM `BORRNLS` --------- ***;
PROC SORT 
	DATA = BORRNLS OUT = BORRNLS2 NODUPKEY; 
	BY CIFNO; 
RUN;

*** MERGE `XS_LDEDUPED` AND `BORRNLS2` BY `CIFNO` AS `LOANNLSXS` - ***;
DATA LOANNLSXS;
	MERGE XS_LDEDUPED(IN = x) BORRNLS2(IN = y);
	BY CIFNO;
	IF x AND y;
RUN;

*** FIND NLS LOANS NOT IN `vw_loan_nls` AND FLAG BAD `SSN`S ------ ***;
DATA LOANEXTRAXS;
	***Subset `dw.vw_loan` using relevant variables -------------- ***;
	SET dw.vw_loan (
		KEEP = OWNST PURCD BRACCTNO ID SSNO1 OWNBR SSNO1_RT7 SSNO2
			NETLOANAMOUNT LNAMT FINCHG LOANTYPE ENTDATE LOANDATE
			CLASSID CLASSTRANSLATION XNO_TRUEDUEDATE FIRSTPYDATE SRCD
			POCD POFFDATE PLCD PLDATE PLAMT BNKRPTDATE BNKRPTCHAPTER
			CONPROFILE1 DATEPAIDLAST APRATE CRSCORE CURBAL);

	*** FILTER `ENTDATE`S GREATER OR EQUAL TO "&_15monthsago",     ***;
	*** `POCD`S THAT ARE NULL, `PLCD`S THAT ARE NULL, `PLDATE`S    ***;
	*** THAT ARE NULL, `POFFDATE`S THAT ARE NULL, AND              ***;
	*** `BNKRPTDATE`S THAT ARE NULL. ----------------------------- ***;
	WHERE ENTDATE >= "&_15monthsago" & 
		  POCD = "" & 
		  PLCD = "" & 
		  PLDATE = "" & POFFDATE = "" & 
		  BNKRPTDATE = "" & 

		  /* FILTER FOR THE FOLLOWING `CLASSID`S: 
		  		`10` RETAIL: SALES FINANCE - FURNITURE CONTRACTS
		  			(PRECOMPUTE)
		  		`19` AUTO-D: SALES FINANCE - SET YOUR OWN PARAMETER
		  		`20` AUTO-I: SALES FINANCE - AUTO (INTEREST BEARING)
		  		`31` RETAIL: SALES FINANCE - FURNITURE CONTRACTS
		  			(INTEREST BEARING)
				`34` AUTO-I: SALES FINANCE - SET YOUR OWN PARAMETER
		  			(INTEREST BEARING) */
		  CLASSID IN (10, 19, 20, 31, 34) & 

		  /* FILTER FOR THE FOLLOWING `OWNST`S: "NC", "VA", "NM", "SC",
		  	 "OK", "TX" */
		  OWNST IN ("AL", "GA", "NC", "NM", "OK", "SC", "TN", "TX", "VA");

	*** CONCATENATE `SSNO1_RT7` WITH THE FIRST 2 NUMBERS IN        ***;
	*** `OWNBR` AND STORE IN NEW VARIABLE, `SS7BRSTATE` ---------- ***;
	SS7BRSTATE = CATS(SSNO1_RT7, SUBSTR(OWNBR, 1, 2));

	*** FLAG BAD `SSNO1`S THAT BEGIN WITH "99" OR "98" AS          ***;
	*** `BADSSN`S ------------------------------------------------ ***;
	IF SSNO1 =: "99" THEN BADSSN = "X";
	IF SSNO1 =: "98" THEN BADSSN = "X";
RUN;

*** EXTRACT `BRACCTNO` FROM `XS_L` AND STORE IN NEW TABLE          ***;
*** `LOAN1_2XS` -------------------------------------------------- ***;
DATA LOAN1_2XS;
	SET XS_L;
	KEEP BRACCTNO;
RUN;

*** SORT `LOAN1_2XS` BY `BRACCTNO` ------------------------------- ***;
PROC SORT 
	DATA = LOAN1_2XS; 
	BY BRACCTNO; 
RUN;

*** SORT `LOANEXTRAXS` BY `BRACCTNO`***;
PROC SORT 
	DATA = LOANEXTRAXS; 
	BY BRACCTNO; 
RUN;

*** MERGE `LOANEXTRAXS` AND `LOAN1_2XS` BY `BRACCTNO` AS           ***;
*** `LOANEXTRA2XS` ----------------------------------------------- ***;
DATA LOANEXTRA2XS;
	MERGE LOANEXTRAXS(IN = x) LOAN1_2XS(IN = y);
	BY BRACCTNO;
	IF x AND NOT y;
RUN;

/*Create `loanparadataXS` table from `dw.vw_loan` and flag bad SSNs*/
data loanparadataXS;
	set dw.vw_loan(

		/*Subset `dw.vw_loan` using relevant variables*/
		keep= purcd bracctno xno_availcredit xno_tduepoff id ownbr
			ownst SSNo1 ssno2 ssno1_rt7 LnAmt FinChg LoanType EntDate
			LoanDate ClassID ClassTranslation XNO_TrueDueDate
			FirstPyDate SrCD pocd POffDate plcd PlDate PlAmt BnkrptDate
			BnkrptChapter DatePaidLast APRate CrScore NetLoanAmount
			XNO_AvailCredit XNO_TDuePOff CurBal conprofile1);

	/*Filter `entdate`s greater or equal to "&_15monthsago", `plcd`s that
		are NULL, `pocd`s that are NULL, `poffdate`s that are NULL,
		`pldate`s that are NULL, and `bnkrptdate`s that are NULL. */
	where entdate >= "&_15monthsago" & plcd="" & pocd="" & poffdate="" &
		pldate="" & bnkrptdate="" & 

		/*Filter for the following `ownst`s: "NC", "VA", "NM", "SC",
			"OK", "TX"*/
		ownst not in ("AL", "GA", "NC", "NM", "OK", "SC", "TN", "TX", "VA") & 

		/*Filter for the following `classid`s: 
			`10` Retail: Sales Finance - Furniture Contracts 
				(Precompute)
			`19` Auto-D: Sales Finance - Set your own parameter
			`20` Auto-I: Sales Finance - Auto (Interest Bearing)
			`31` Retail: Sales Finance - Furniture Contracts
				(Interest Bearing)
			`34` Auto-I: Sales Finance - Set your own parameter
				(Interest Bearing)*/
		classid in (10,19,20,31,34);
	
	/*Concatenate `ssno1_rt7` with the first 2 numbers in `ownbr` and
		store in new variable, `ss7brstate`*/
	ss7brstate=cats(ssno1_rt7,substr(ownbr,1,2));
	
	/*Flag bad `ssno1`s that begin with "99" or "98" as `BadSSN`s*/
	if ssno1=: "99" then BadSSN="X";
	if ssno1=: "98" then BadSSN="X"; 
run;

/*To create a table of records not in `vw_Loan_NLS`, concatenate
	`loanparadataxs` and `loanextra2xs` tables and store in `set1xs`*/
data set1xs;
	set loanparadataxs loanextra2xs;
run;

data BorrParadata;
	length firstname $20 middlename $20 lastname $30;
	set dw.vw_borrower (keep= rmc_updated phone cellphone cifno ssno ssno_rt7  FName LName Adr1 Adr2 City State zip BrNo age Confidential Solicit CeaseandDesist CreditScore);
	FName=strip(fname);
	LName=strip(lname);
	Adr1=strip(Adr1);
	Adr2=strip(adr2);
	City=strip(city);
	State=strip(state);
	Zip=strip(zip);
	if find(fname,"JR") ge 1 then do;
		firstname=compress(fname,"JR");
		suffix="JR";
	end;
	if find(fname,"SR") ge 1 then do;
		firstname=compress(fname,"SR");
		suffix="SR";
	end;
	if suffix = "" then do;
		firstname=scan(fname,1,1);
		middlename=catx(" ",scan(fname,2," "),scan(fname,3," "),scan(fname,4," "));
	end;
	nwords=countw(fname," ");
	if nwords>2 & suffix ne "" then do;
		firstname=scan(fname,1," ");
		middlename=scan(fname,2," ");
	end;
	DOB=compress(age,"-");
	ss7brstate=cats(ssno_rt7,substr(brno,1,2));
	lastname=lname;
	if ssno=: "99" then BadSSN="X";  *Flag bad ssns;
	if ssno=: "98" then BadSSN="X"; 
	drop nwords fname lname age;
	ssno1=ssno;
	ssno1_rt7=ssno_rt7;
run;

data goodssn_lxs badssn_lxs;
	set set1xs;
	if badssn="X" then output badssn_lxs;
	else output goodssn_lxs;
run;

data goodssn_b badssn_b;
	set borrparadata;
	if badssn="X" then output badssn_b;
	else output goodssn_b;
run;

proc sql;
	create table goodssn_lxs as
	select *
	from goodssn_lxs
	group by ssno1
	having entdate = max(entdate);
quit;

proc sort 
	data=goodssn_lxs nodupkey; 
	by ssno1; 
run;

proc sort 
	data=goodssn_b; 
	by ssno1 descending rmc_updated; 
run;

proc sort 
	data=goodssn_b nodupkey; 
	by ssno1; 
run;

data mergedgoodssnxs;
	merge goodssn_lxs(in=x) goodssn_b(in=y);
	by ssno1;
	if x and y;
run;

proc sql;
	create table badssn_lxs as
	select *
	from badssn_lxs
	group by ss7brstate
	having entdate = max(entdate);
quit;

proc sort 
	data=badssn_lxs nodupkey; 
	by ss7brstate; 
run;

proc sort 
	data=badssn_b; 
	by ss7brstate descending rmc_updated; 
run;

proc sort 
	data=badssn_b nodupkey; 
	by ss7brstate; 
run;

data mergedbadssnxs;
	merge badssn_lxs(in=x) badssn_b(in=y);
	by ss7brstate;
	if x and y;
run;

DATA ssns;
	set mergedgoodssnxs mergedbadssnxs;
run;

proc sort 
	data=ssns nodupkey; 
	by bracctno; 
run;

proc sort 
	data=loannlsXS nodupkey; 
	by bracctno; 
run;

data paradata;
	merge loannlsXS(in=x) ssns(in=y);
	by bracctno;
	if not x and y;
run;

data xs; *stack all DW XS loans;
	set loannlsXS paradata;
run; 

*Merge XS from our dw with info from TCI sites to identify made applications and to ID unmade applications;
proc sort 
	data=XS;
	by ssno1_rt7;
run;

proc sort 
	data=tci;
	by ssno1_rt7;
run;

data tci2mades;
	set tci;
	drop bracctno;
run;

data mades;
	merge XS(in=x) tci2mades(in=y);
	by ssno1_rt7;
	if x=1;
run;

data unmades;
	merge XS(in=x) tci(in=y);
	by ssno1_rt7;
	if x=0 and y=1;
	made_unmade="UNMADE";
run;

data unmades;
set unmades;
rename 'Date Submitted'n = date_submitted;
application_date = input(strip('application date'n),mmddyy10.);
format application_date mmddyy10.;
run;

data unmades2;
	set unmades (
	where=(intnx('month',today(),-6,'b') <=application_date OR application_date=.));
run;

data unmades;
	set unmades2 (
	where=(intnx('month',today(),-6,'b') <=date_submitted OR date_submitted=.));
run;

data mades2;  *for matched, keep only info from loan and borrower tables;
	set mades;
	made_unmade="MADE";
run;

/*
data mades2;  *for matched, keep only info from loan and borrower tables;
	set mades (
		keep=purcd bracctno netloanamount ssno1 id ownbr ssno1_rt7
			ss7brstate ssno2 LnAmt FinChg LoanType EntDate LoanDate
			ClassID ClassTranslation SrCD pocd POffDate plcd PlDate
			PlAmt BnkrptDate BnkrptChapter ConProfile1 DatePaidLast
			APRate CrScore CurBal Adr1 Adr2 City State zip dob
			Confidential Solicit CeaseandDesist CreditScore firstname
			middlename lastname ss7brstate phone cellphone);
	made_unmade="MADE";
run;
*/

data XStot; *Append mades and unmades for full XS universe;
	set unmades mades2;
run;

data xstot;
	set xstot;
	if ss7brstate = "" then ss7brstate=cats(ssno1_rt7,
		substr(ownbr,1,2));
	if crscore <625 then Risk_Segment="624 and below";
	if 625<=crscore<650 then Risk_Segment="625-649";
	if 650<=crscore<851 then Risk_Segment="650-850";
	if classid in (10, 21, 31) then source_2="RETAIL";
	if source="TCIRetail" then source_2="RETAIL";
	if classid in (13, 14, 19, 20, 32, 34, 40, 41, 45, 68, 69, 72, 75,
		78, 79, 80, 88, 89, 90) then source_2="AUTO";
	if source = "TCICentral" then source_2="AUTO";
run;
data xs_total;
	length offer_segment $20;
	set xstot;
	state=strip(state);
	if crscore = 0 then BadFico_Flag="X";
	if crscore = . then BadFico_Flag="X";
	if crscore > 725 then BadFico_Flag="X";
	if state="NC" & source_2="AUTO" & made_unmade="UNMADE" 
		then NCAutoUn_Flag="X";
	if state="NC" & source_2="AUTO" & made_unmade="MADE" 
		then offer_segment="ITA";
	if state in ("GA", "VA") then offer_segment="ITA";
	if state in ("SC","TX","TN","AL","OK","NM") & source_2="AUTO" 
		then offer_segment="ITA";
	if state in ("SC","NC","TX","TN","AL","OK","NM") & 
		source_2="RETAIL" & Risk_Segment="624 and below" 
		then offer_segment="ITA";
run;

*Dedupe XS;
data xs_total;
	set xs_total;
	if offer_segment ne "ITA"; *drop ITA's;
	camp_type="XS";
run;

*Step 1:  Pull in data for FBs;
data loan_pull; *from loan table for FB;
	set dw.vw_loan_nls (
		keep= purcd cifno bracctno id ownbr ownst ssno1_rt7 ssno1 ssno2
			netloanamount LnAmt FinChg ssno1_rt7 LoanType EntDate
			LoanDate ClassID ClassTranslation XNO_TrueDueDate
			FirstPyDate SrCD pocd POffDate plcd PlDate PlAmt BnkrptDate
			BnkrptChapter DatePaidLast APRate CrScore CurBal);
	where POffDate between "&_15monthsago" and "&yesterday" & pocd="13" & 
		ownst in ("AL", "GA", "NC", "NM", "OK", "SC", "TN", "TX", "VA"); *paid out loans;
	ss7brstate=cats(ssno1_rt7,substr(ownbr,1,2));
run;

proc sql;
	create table loan1nlsfb as
	select *
	from loan_pull
	group by cifno
	having entdate = max(entdate);
quit;

proc sort 
	data=loan1nlsfb;
	by cifno;
run;

data loannlsfb;
	merge loan1nlsfb(in=x) borrnls2(in=y);
	by cifno;
	if x and y;
run;

data loanextrafb; *find NLS loans not in vw_loan_nls;
	set dw.vw_loan(
		keep= purcd bracctno xno_availcredit xno_tduepoff id ownbr
			ownst SSNo1 ssno2 ssno1_rt7 LnAmt FinChg LoanType EntDate
			LoanDate ClassID ClassTranslation XNO_TrueDueDate
			FirstPyDate SrCD pocd POffDate plcd PlDate PlAmt BnkrptDate
			BnkrptChapter DatePaidLast APRate CrScore NetLoanAmount
			XNO_AvailCredit XNO_TDuePOff CurBal conprofile1);
	where POffDate between "&_15monthsago" and "&yesterday" & pocd="13" & 
		ownst in ("AL", "GA", "NC", "NM", "OK", "SC", "TN", "TX", "VA");
	ss7brstate=cats(ssno1_rt7,substr(ownbr,1,2));
	if ssno1=: "99" then BadSSN="X";  *Flag bad ssns;
	if ssno1=: "98" then BadSSN="X";
run;

data loan1_2fb;
	set loan_pull;
	keep BrAcctNo;
run;

proc sort 
	data=loan1_2fb;
	by bracctno;
run;

proc sort 
	data=loanextrafb;
	by BrAcctNo;
run;

data loanextra2fb;
	merge loanextrafb(in=x) loan1_2fb(in=y);
	by bracctno;
	if x and not y;
run;

data loanparadatafb; 
	set dw.vw_loan(
		keep= purcd bracctno xno_availcredit xno_tduepoff id ownbr
			ownst SSNo1 ssno2 ssno1_rt7 LnAmt FinChg LoanType EntDate
			LoanDate ClassID ClassTranslation XNO_TrueDueDate
			FirstPyDate SrCD pocd POffDate plcd PlDate PlAmt BnkrptDate
			BnkrptChapter DatePaidLast APRate CrScore NetLoanAmount
			XNO_AvailCredit XNO_TDuePOff CurBal conprofile1);
	where POffDate between "&_15monthsago" and "&yesterday" & pocd="13" & 
		ownst not in ("AL", "GA", "NC", "NM", "OK", "SC", "TN", "TX", "VA");
	ss7brstate=cats(ssno1_rt7,substr(ownbr,1,2));
	if ssno1=: "99" then BadSSN="X";  *Flag bad ssns;
	if ssno1=: "98" then BadSSN="X"; 
run;

data set1fb;
	set loanparadatafb loanextra2fb;
run;

data goodssn_lfb badssn_lfb;
	set set1fb;
	if badssn="X" 
		then output badssn_lfb;
	else output goodssn_lfb;
run;

proc sql;
	create table goodssn_lfb as
	select *
	from goodssn_lfb
	group by ssno1
	having entdate = max(entdate);
quit;

proc sort 
	data=goodssn_lfb nodupkey; 
	by ssno1; 
run;

proc sort 
	data=goodssn_b; 
	by ssno1; 
run;

data mergedgoodssnfb;
	merge goodssn_lfb(in=x) goodssn_b(in=y);
	by ssno1;
	if x and y;
run;

proc sql;
	create table badssn_lfb as
	select *
	from badssn_lfb
	group by ss7brstate
	having entdate = max(entdate);
quit;

proc sort 
	data=badssn_lfb nodupkey; 
	by ss7brstate; 
run;

proc sort 
	data=badssn_b; 
	by ss7brstate; 
run;

data mergedbadssnfb;
	merge badssn_lfb(in=x) badssn_b(in=y);
	by ss7brstate;
	if x and y;
run;

DATA ssns;
	set mergedgoodssnfb mergedbadssnfb;
run;

proc sort 
	data=ssns nodupkey; 
	by bracctno; 
run;

proc sort 
	data=loannlsfb nodupkey; 
	by bracctno; 
run;

data paradata;
	merge loannlsfb(in=x) ssns(in=y);
	by bracctno;
	if not x and y;
run;

data fb;
	set loannlsfb paradata;
	camp_type="FB";
run; 

*Append XS to FB;
data merged_l_b_xs_fb;
	set fb xs_total;
run;

proc sort 
	data=merged_l_b_xs_fb out=merged_l_b_xs_fb2 nodupkey;
	by bracctno;
run;

*Pull in information for statflags;
data Statflags;
	set dw.vw_loan (keep= ownbr ssno1_rt7 EntDate StatFlags);
	where EntDate > "&_3yrdate" & statflags ne "";
run;

proc sql; *identifying bad statflags;
	create table statflags2 as

	select * 
	from statflags 
	where statflags 
	contains "4"
	union

	select * 
	from statflags 
	where statflags 
	contains "5"
 	union

	select * 
	from statflags 
	where statflags 
	contains "6"
 	union 

	select * 
	from statflags 
	where statflags 
	contains "7"
 	union

	select * 
	from statflags 
	where statflags 
	contains "A"
 	union 

	select * 
	from statflags 
	where statflags 
	contains "B"
 	union

	select * 
	from statflags 
	where statflags 
	contains "C"
 	union

	select * 
	from statflags 
	where statflags 
	contains "D"
	union

	select * 
	from statflags 
	where statflags 
	contains "I"
 	union

	select * 
	from statflags 
	where statflags 
	contains "J"
 	union 

	select * 
	from statflags 
	where statflags 
	contains "L"
  	union 

	select * 
	from statflags 
	where statflags 
	contains "P"
  	union 

	select * 
	from statflags 
	where statflags 
	contains "R"
	union 

	select * 
	from statflags 
	where statflags 
	contains "V"
	union 

	select * 
	from statflags 
	where statflags 
	contains "W"
	union 

	select * 
	from statflags 
	where statflags 
	contains "X"
	union 

	select * 
	from statflags 
	where statflags 
contains "S";
 quit;
data statflags2; *tagging bad statflags;
 set statflags2;
 statfl_flag="X";
ss7brstate=cats(ssno1_rt7,substr(ownbr,1,2));
drop entdate ownbr ssno1_rt7;
rename statflags=statflags_old;
 run;
proc sort data=statflags2 nodupkey;
by ss7brstate;
run;
proc sort data=merged_l_b_xs_fb2;
by ss7brstate;
run;
data Merged_L_B2; *Merge file with statflag flags;
merge merged_l_b_xs_fb2(in=x) statflags2;
by ss7brstate;
if x=1;
run;




*Flag bankruptcies in past 5 years;
data bk5yrdrops;
set dw.vw_loan (keep= entdate ssno1_rt7 OwnBr bnkrptdate BnkrptChapter);
where EntDate > "&_5yrdate";
run;
data bk5yrdrops;
set bk5yrdrops;
where BnkrptChapter>0 | bnkrptdate ne "";
run;
data bk5yrdrops;
set bk5yrdrops;
bk5_flag = "X";
ss7brstate=cats(ssno1_rt7,substr(ownbr,1,2));
drop BnkrptDate entdate ssno1_rt7 ownbr BnkrptChapter;
run;
proc sort data=bk5yrdrops nodupkey;
by ss7brstate;
run;
proc sort data=merged_l_b2;
by ss7brstate;
run;
data Merged_L_B2;
merge Merged_L_B2(in=x) bk5yrdrops;
by ss7brstate;
if x;
run;


data merged_l_b2;
set merged_l_b2;
if bnkrptdate ne "" then bk5_flag="X";
if bnkrptchapter not in (0,.) then bk5_flag="X";
run;



*Flag bad TRW status;
data trwstatus_fl; *find from 5 years back;
set dw.vw_loan (keep= ownbr ssno1_rt7 EntDate trwstatus);
where entdate > "&_5yrdate" & TrwStatus ne "";
run;
data trwstatus_fl; *flag for bad trw's;
set trwstatus_fl;
TRW_flag = "X";
ss7brstate=cats(ssno1_rt7,substr(ownbr,1,2));
drop entdate ssno1_rt7 ownbr;
run;
proc sort data=trwstatus_fl nodupkey;
by ss7brstate;
run;
proc sort data=merged_l_b2;
by ss7brstate;
run;
data Merged_L_B2; *merge pull with trw flags;
merge Merged_L_B2(in=x) trwstatus_fl;
by ss7brstate;
if x;
run;


*Identify bad PO Codes;
data po_codes_3yr;
set dw.vw_loan (keep=EntDate pocd ssno1_rt7 ownbr);
where EntDate > "&_3yrdate" & pocd in ("49", "50", "61", "62", "63", "64", "66", "68", "93", "97");
run;
data po_codes_3yr;
set po_codes_3yr;
BadPOcode_flag = "X";
ss7brstate=cats(ssno1_rt7,substr(ownbr,1,2));
drop entdate pocd ssno1_rt7 ownbr;
run;
proc sort data=po_codes_3yr nodupkey;
by ss7brstate;
run;
proc sort data=merged_l_b2;
by ss7brstate;
run;
data merged_l_b2;
merge merged_l_b2(in=x) po_codes_3yr;
by ss7brstate;
if x;
run;

data PO_codes_forever;
set dw.vw_loan (keep=EntDate pocd ssno1_rt7 ownbr);
where pocd in ("21", "94", "95", "96");
run;
data po_codes_forever;
set po_codes_forever;
Deceased_flag = "X";
ss7brstate=cats(ssno1_rt7,substr(ownbr,1,2));
drop entdate pocd ssno1_rt7 ownbr;
run;
proc sort data=po_codes_forever nodupkey;
by ss7brstate;
run;
data merged_l_b2;
merge merged_l_b2(in=x) po_codes_forever;
by ss7brstate;
if x;
run;


data con1yr_fl; *find from 2 years back;
set dw.vw_loan (keep= ownbr ssno1_rt7 EntDate conprofile1);
where entdate > "&_15monthsago" & conprofile1 ne "";
data con1yr_fl; *flag for con5 ;
set con1yr_fl;
_60=countc(conprofile1,"2");
_90=countc(conprofile1,"3");
_120a=countc(conprofile1,"4");
_120b=countc(conprofile1,"5");
_120c=countc(conprofile1,"6");
_120d=countc(conprofile1,"7");
_120e=countc(conprofile1,"8");
_90plus=sum(_90,_120a,_120b,_120c,_120d,_120e);
if _60>1 | _90plus>0 then con1yr_flag="X";
ss7brstate=cats(ssno1_rt7,substr(ownbr,1,2));
drop entdate ssno1_rt7 ownbr conprofile1;
run;
data con1yr_fl_2;
set con1yr_fl;
if con1yr_flag="X";
run;
proc sort data=con1yr_fl_2 nodupkey;
by ss7brstate;
run;
proc sort data=merged_l_b2;
by ss7brstate;
run;
data Merged_L_B2; *merge pull with con5 flags;
merge Merged_L_B2(in=x) con1yr_fl_2;
by ss7brstate;
if x;
run;


*Identify if customer currently has an open loan for FB;
data openloans;
set dw.vw_loan (keep= ssno2 ssno1_rt7 pocd plcd poffdate pldate bnkrptdate);
where pocd = "" & plcd="" & poffdate="" & pldate="" & bnkrptdate="";
run;
data ssno2s;
set openloans;
if ssno2 ne "";
ssno1_rt7=substr(ssno2,max(1,length(ssno2)-6));
run;

data openloans1;
set openloans ssno2s;
run;
data openloans1;
set openloans1;
Open_flag = "X";
drop pocd plcd poffdate pldate bnkrptdate ssno2;
run;
proc sort data=openloans1 nodupkey;
by ssno1_rt7;
run;
proc sort data=merged_l_b2;
by ssno1_rt7;
run;
data merged_l_b2;
merge merged_l_b2(in=x) openloans1;
by ssno1_rt7;
if x;
run;
data merged_l_b2;
set merged_l_b2;
if camp_type="XS" then open_flag="";
run;



*Identify if customer currently has an open loan for XS unmade;
data openloansxs;
set dw.vw_loan (keep= ssno2 ssno1_rt7 pocd plcd poffdate pldate bnkrptdate);
where pocd = "" & plcd="" & poffdate="" & pldate="" & bnkrptdate="";
run;
data ssno2s2;
set openloansxs;
if ssno2 ne "";
ssno1_rt7=substr(ssno2,max(1,length(ssno2)-6));
run;
data openloans1xs;
set openloansxs ssno2s2;
run;
data openloans1xs;
set openloans1xs;
Open_flag = "X";
drop pocd plcd poffdate pldate bnkrptdate ssno2;
run;
proc sort data=openloans1xs nodupkey;
by ssno1_rt7;
run;
data unmadesdrop merged_l_b3;
set merged_l_b2;
if made_unmade="UNMADE" then output unmadesdrop;
else output merged_l_b3;
run;
proc sort data=unmadesdrop;
by ssno1_rt7;
run;
data unmadesdrop;
merge unmadesdrop(in=x) openloans1xs;
by ssno1_rt7;
if x;
run;

data merged_l_b2;
set merged_l_b3 unmadesdrop;
run;


data openloans2;
set dw.vw_loan (keep= ownbr ssno2 ssno1_rt7 pocd plcd poffdate pldate bnkrptdate);
where pocd = "" & plcd="" & poffdate="" & pldate="" & bnkrptdate="";
run;
data ssno2s;
set openloansxs;
if ssno2 ne "";
ssno1_rt7=substr(ssno2,max(1,length(ssno2)-6));
run;
data openloans3;
set openloans2 ssno2s;
run;
data openloans4;
set openloans3;
Open_flag2 = "X";
drop pocd ssno2 OwnBr plcd poffdate pldate bnkrptdate;
run;
proc sort data=openloans4;
by ssno1_rt7;
run;
data one_open mult_open;
set openloans4;
by ssno1_rt7;
if first.ssno1_rt7 and last.ssno1_rt7 then output one_open;
else output mult_open;
run;
proc sort data=mult_open nodupkey;
by ssno1_rt7;
run;
proc sort data=merged_l_b2;
by ssno1_rt7;
run;
data merged_l_b2;
merge merged_l_b2(in=x) mult_open;
by ssno1_rt7;
if x;
run;

data openloansxs2;
set dw.vw_loan (keep= classtranslation ssno2 ssno1_rt7 pocd plcd poffdate pldate bnkrptdate);
where pocd = "" & plcd="" & poffdate="" & pldate="" & bnkrptdate="" & ClassTranslation not in ("Retail","Auto-I","Auto-D");
run;
data ssno2s2;
set openloansxs;
if ssno2 ne "";
ssno1_rt7=substr(ssno2,max(1,length(ssno2)-6));
run;
data openloans1xs;
set openloansxs2 ssno2s2;
run;
data openloans1xs2;
set openloans1xs;
Open_flag3 = "X";
drop pocd plcd poffdate pldate bnkrptdate ssno2;
run;
proc sort data=openloans1xs2 nodupkey;
by ssno1_rt7;
run;
data xspersonaldrop merged_l_b4;
set merged_l_b2;
if camp_type="XS" then output xspersonaldrop;
else output merged_l_b4;
run;
proc sort data=xspersonaldrop;
by ssno1_rt7;
run;
data xspersonaldrop;
merge xspersonaldrop(in=x) openloans1xs2;
by ssno1_rt7;
if x;
run;

data merged_l_b2;
set merged_l_b4 xspersonaldrop;
run;

data merged_l_b2;
set merged_l_b2;
if open_flag3="X" then open_flag2="X";
run;



*flag null DOB;
*Find states outside of footprint;
*Flag DNS DNH;
*Flag nonmatching branch state and borrower state;
*Flag bad ssns ;
*Flag incomplete info;
*Flag Bad Branches;

data Merged_L_B2;
set merged_l_b2;
Adr1=strip(Adr1);
Adr2=strip(adr2);
City=strip(city);
State=strip(state);
Zip=strip(zip);
confidential=strip(confidential);
solicit=strip(solicit);
firstname=compress(firstname,'1234567890!@#$^&*()''"%');
lastname=compress(lastname,'1234567890!@#$^&*()''"%');
if index(firstname,"""") > 0 then name_deleteflag="X";
if index(lastname,"""") > 0 then name_deleteflag="X";
if index(firstname,"''") > 0 then name_deleteflag="X";
if index(lastname,"''") > 0 then name_deleteflag="X";
if adr1="" then adr1=adr2;
if adr1="" then MissingInfo_flag = "X";   *flag incomplete info;
if state="" then MissingInfo_flag = "X";   *flag incomplete info;
if Firstname="" then MissingInfo_flag = "X";   *flag incomplete info;
if Lastname="" then MissingInfo_flag = "X";   *flag incomplete info;
if dob="" then NullDOB_flag = "X";  *flag incomplete DOB;
if ownbr in ("600" , "9000" , "198" , "1", "0001" , "0198" , "0600") then BadBranch_flag="X";
if substr(ownbr,3,2)="99" then BadBranch_flag="X";
if state not in ("AL", "GA", "NC", "NM", "OK", "SC", "TN", "TX", "VA") then OOS_flag = "X"; *Find states outside of footprint;
if confidential = "Y" then DNS_DNH_flag = "X";  *Flag Confidential;
if solicit = "N" then DNS_DNH_flag = "X";  *Flag DNS;
if ceaseanddesist = "Y" then DNS_DNH_flag = "X";  *Flag CandD;
if ssno1="" then ssno1=ssno;
if ssno1=: "99" then BadSSN_flag="X";  *Flag bad ssns;
if ssno1=: "98" then BadSSN_flag="X";  *Flag bad ssns;
con_recent3=substr(conprofile1,1,3);
con_recent4to6=substr(conprofile1,4,3);
con_recent6=substr(conprofile1,1,6);
_30_recent3=countc(con_recent3,"1");
_30_recent4to6=countc(con_recent4to6,"1");
_30_recent6=countc(con_recent6,"1");
_60_recent6=countc(con_recent6,"2");
_30=countc(conprofile1,"1");
_60=countc(conprofile1,"2");
_90=countc(conprofile1,"3");
_120a=countc(conprofile1,"4");
_120b=countc(conprofile1,"5");
_120c=countc(conprofile1,"6");
_120d=countc(conprofile1,"7");
_120e=countc(conprofile1,"8");
_90plus=sum(_90,_120a,_120b,_120c,_120d,_120e);
if _30>3 | _60>1 | _90plus>0 | _60_recent6>0 | _30_recent3>1 | _30_recent6>2 then conprofile_flag="X";
_9s=countc(conprofile1,"9");
if _9s>10 then lessthan2_flag = "X";
XNO_TrueDueDate2=input(substr(XNO_TrueDueDate,6,2)||'/'||substr(XNO_TrueDueDate,9,2)||'/'||substr(XNO_TrueDueDate,1,4),mmddyy10.);
FirstPyDate2=input(substr(FirstPyDate,6,2)||'/'||substr(FirstPyDate,9,2)||'/'||substr(FirstPyDate,1,4),mmddyy10.);
Pmt_days=XNO_TrueDueDate2-FirstPyDate2;
if pmt_days<60 then lessthan2_flag="X";
if pmt_days = . & _9s <10 then lessthan2_flag="";
if pmt_days>=60 & _9s >=10 then lessthan2_flag="";
if PlAmt>0 then PlAmt_flag="X";
if camp_type="FB" then do;
if ownst ne state then State_Mismatch_flag = "X"; *Flag nonmatching branch state and borrower state;
lessthan2_flag=""; *Make sure FB flag is set to null;
end;
if purcd in ("011","020") then dlqren_flag="X";
if brno = "0251" then brno="0580";
if brno = "0252" then brno="0683";
if brno = "0253" then brno="0581";
if brno = "0254" then brno="0582";
if brno = "0255" then brno="0583";
if brno = "0256" then brno="1103";
if brno = "0302" then brno="0133";
/*if brno = "1019" then brno="1004";*/
if brno = "1016" then brno="1008";
if brno = "0877" then brno="0806";
if brno = "0159" then brno="0132";
if brno = "0152" then brno="0115";
if brno = "0885" then brno="0802";
if zip=:"29659" & brno="0152" then brno="0121";
if zip=:"36264" & brno="0877" then brno="0870";
if brno = "1003" and zip=:"87112" then brno="1013";
if brno = "0872" then brno="0807";
if brno = "0102" then brno="0303";
run;




*pull and merge dlq info for fb's;
proc format;
   value cdfmt
   1 = 'Current'
   2 = '1-29cd'
   3 = '30-59cd'
   4 = '60-89cd'
   5 = '90-119cd'
   6 = '120-149cd'
   7 = '150-179cd'
   8 = '180+cd'
   other=' ';
run;
data temp;   
   set dw.vw_loan(keep=bracctno srcd entdate poffdate pocd classtranslation lnamt conprofile1 
                       brtrffg ssno1_rt7 where=(pocd='13' and poffdate > "&_15monthsago"));
   entdt = input(substr(entdate,6,2)||'/'||substr(entdate,9,2)||'/'||substr(entdate,1,4),mmddyy10.);
   podt = input(substr(poffdate,6,2)||'/'||substr(poffdate,9,2)||'/'||substr(poffdate,1,4),mmddyy10.);
   if poffdate > "&yesterday" then delete; 													
   if put(entdt,yymmn6.) = put(podt,yymmn6.) then delete;    
   drop poffdate entdate pocd srcd;
run; 
proc sort nodupkey; by bracctno; run;
data atb;
   set dw.atb_data(keep=bracctno age2 yearmonth);    
   poacctno = bracctno*1;   
   atbdt = input(substr(yearmonth,6,2)||'/'||substr(yearmonth,9,2)||'/'||substr(yearmonth,1,4),mmddyy10.);   
   if age2 =: '1' then age2 = '1.Current';   
   keep atbdt age2 bracctno;
run;
proc sort nodupkey; by bracctno atbdt; run;
data temp;     
   merge temp(in=a) atb(in=b);
   by bracctno;
   if a;  
   cd = substr(age2,1,1)*1;   
   age = intck('month',atbdt,podt); 
   if      age = 1 then delq1 = cd;
   else if age = 2 then delq2 = cd;
   else if age = 3 then delq3 = cd;
   else if age = 4 then delq4 = cd;
   else if age = 5 then delq5 = cd;
   else if age = 6 then delq6 = cd;
   else if age = 7 then delq7 = cd;
   else if age = 8 then delq8 = cd;
   else if age = 9 then delq9 = cd;
   else if age =10 then delq10= cd;
   else if age =11 then delq11= cd;
   else if age =12 then delq12= cd;
   else delete;
    if cd>3 then cd60 = 1; *if cd is greater than 30-59 days late, set cd60 to 1;
   if cd>2 then cd30 = 1; *if cd is greater than 1-29 days late, set cd30 to 1;
      if age<4 then do;
		if cd>2 then recent3=1; *note 30-59s in last six months;
		end;
		else if 3<age<7 then do;
		if cd>2 then recent4to6=1; *note 30-59s from 7 to 12 months ago;
		end;
   if age<7 then do;
		if cd>2 then recent6=1; *note 30-59s in last six months;
		if cd>3 then recent6_60=1;
		end;
		else if 6<age<13 then do;
		if cd>2 then first6=1; *note 30-59s from 7 to 12 months ago;
		if cd>3 then first6_60=1;
		end;
		keep classtranslation bracctno delq1-delq12 cd cd30 cd60 age2 atbdt age recent3 recent4to6 recent6_60 first6_60 first6 recent6;
run;
data temp2;
set temp;
last12=sum(recent6,first6); *count the number of 30-59s in the last year when fb had open loan;
last12_60=sum(recent6_60,first6_60);
run;
proc summary data=temp2 nway missing;
   class classtranslation bracctno;
   var delq1-delq12 recent6 last12 first6 recent6_60 last12_60 first6_60 recent3 recent4to6 cd60 cd30;
   output out=finalfb(drop=_type_ _freq_) sum=;
run; 
data fbdlq;
   set finalfb;
   times30 = cd30;
   if times30 = . then times30 = 0;
   if recent6 = . then recent6=0;
   if first6 = . then first6=0;
   if last12 = . then last12=0;
   if recent6_60= . then recent6_60=0;
   if first6_60 = . then first6_60=0;
   if last12_60 = . then last12_60=0;
   if recent3 = . then recent3 = 0;
   if recent4to6=. then recent4to6=0;
   drop cd30;
   format delq1-delq12 cdfmt.;
run;

proc sort data=fbdlq nodupkey;
 by BrAcctNo;
 run;
 data fb;
 set merged_l_b2;
 if camp_type="FB";
 run;
proc sort data=fb; *sort to merge;
by BrAcctNo;
run;
data fbwithdlq; *merge pull and dql information;
merge fb(in=x) fbdlq(in=y);
by bracctno;
if x=1;
run;



*****************************************;


*Step 14:  pull and merge dlq info for xs's;
data atb; 
   set dw.atb_data(keep=bracctno age2 yearmonth where=(yearmonth between "&_16monthsago" and "&yesterday"));   
   atbdt = input(substr(yearmonth,6,2)||'/'||substr(yearmonth,9,2)||'/'||substr(yearmonth,1,4),mmddyy10.);     
   age = intck('month',atbdt,"&sysdate"d);
cd = substr(age2,1,1)*1;   
 *i.e. for age=1: this is most recent month. Fill delq1, which is delq for month 1, with delq status (cd);
   if      age = 1 then delq1 = cd;
   else if age = 2 then delq2 = cd;
   else if age = 3 then delq3 = cd;
   else if age = 4 then delq4 = cd;
   else if age = 5 then delq5 = cd;
   else if age = 6 then delq6 = cd;
   else if age = 7 then delq7 = cd;
   else if age = 8 then delq8 = cd;
   else if age = 9 then delq9 = cd;
   else if age =10 then delq10= cd;
   else if age =11 then delq11= cd;
   else if age =12 then delq12= cd;
   if cd>3 then cd60 = 1; *if cd is greater than 30-59 days late, set cd60 to 1;
   if cd>2 then cd30 = 1; *if cd is greater than 1-29 days late, set cd30 to 1;
      if age<4 then do;
		if cd>2 then recent3=1; *note 30-59s in last six months;
		end;
		else if 3<age<7 then do;
		if cd>2 then recent4to6=1; *note 30-59s from 7 to 12 months ago;
		end;
   if age<7 then do;
		if cd>2 then recent6=1; *note 30-59s in last six months;
		if cd>3 then recent6_60=1;
		end;
		else if 6<age<13 then do;
		if cd>2 then first6=1; *note 30-59s from 7 to 12 months ago;
		if cd>3 then first6_60=1;
		end;
		keep bracctno delq1-delq12 cd cd30 cd60 age2 atbdt age recent3 recent4to6 recent6_60 first6_60 first6 recent6;
run;
data atb2;
set atb;
last12=sum(recent6,first6); *count the number of 30-59s in the last year;
last12_60=sum(recent6_60,first6_60);
run;
*count cd30, cd60,recent6,first6 by bracctno (*recall loan potentially counted for each month);
proc summary data=atb2 nway missing;
   class bracctno;
   var delq1-delq12 recent6 last12 first6 recent6_60 last12_60 first6_60 recent3 recent4to6 cd60 cd30;
   output out=finalxs(drop=_type_ _freq_) sum=;
run; 
data atb4; *create new counter variables;
   set finalxs;
   times30 = cd30;
   if times30 = . then times30 = 0;
   if recent6 = . then recent6=0;
   if first6 = . then first6=0;
   if last12 = . then last12=0;
   if recent6_60= . then recent6_60=0;
   if first6_60 = . then first6_60=0;
   if last12_60 = . then last12_60=0;
   if recent3 = . then recent3 = 0;
   if recent4to6=. then recent4to6=0;
   drop cd30;
   format delq1-delq12 cdfmt.;
run;
proc sort data=atb4 nodupkey; by bracctno; run; *sort to merge;
data xsdlq; set atb4; drop null; *dropping the null column (not nulls in dataset); run;

data xs;
set merged_l_b2;
if camp_type="XS";
run;
proc sort data=xs; *sort to merge;
by BrAcctNo;
run;
data xswithdlq; *merge pull and dql information;
merge xs(in=x) xsdlq(in=y);
by bracctno;
if x=1;
run;

data merged_l_b2;
set fbwithdlq xswithdlq;
run;



*Apply all delinquency related flags;
data merged_l_b2; *flag for bad dlqatb;
set merged_l_b2;
if recent3>1 or recent6>2 or last12 > 3 or last12_60 > 1 or recent6_60 >0 then DLQ_Flag="X";
if camp_type="XS" & last12_60>0 then dlq_flag="X";
if ownbr ="0537" then Harvey="Beaumont Drop";
if brno ="0537" then Harvey="Beaumont Drop";
run;

proc sort data=merged_l_b2 out= deduped nodupkey;
by BrAcctNo;
run;

*Export Flagged File;
proc export data=deduped outfile="&finalexportflagged" dbms=tab; 
run;


 *Create final file for drops;
 data final; set deduped; run;


 data Waterfall;
 length Criteria $50 Count 8.;
 infile datalines dlm="," truncover;
 input Criteria $ Count;
 datalines;
TCI Data,
XS Total,
FB total,
XS + FB Total,		
Delete cust in Bad Branches,	
Delete cust with Missing Info,	
Delete cust Outside of Footprint,	
Delete where State/OwnSt Mismatch,
Delete FB With Open Loan,
Delete Any Customer with >1 Loan,
Delete cust with Bad POCODE,
Delete Deceased,
Delete if Less than Two Payments Made,	
Delete for ATB Delinquency,	
Delete for Conprofile Delinquency,
Delete for 5 Yr. Conprofile Delinquency,
Delete for Bankruptcy (5yr),
Delete for Statflag (5yr),
Delete for TRW Status (5yr),
Delete if DNS or DNH,
Delete cust with Null Date of Birth,
Delete cust with Bad SSN,
Delete NC Auto Unmades,	
Delete XS Bad FICOs,	
Delete Delinquent Renewal,
Delete PLAmt greater than $0,	
Heavy Harvey exclusions (27 Branches),	
;
run;

PROC SQL; *COUNT OBS; 
	CREATE TABLE COUNT AS SELECT COUNT(*) AS COUNT FROM TCI; 
QUIT;

PROC SQL; *COUNT OBS; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM XS_TOTAL; 
QUIT;

PROC SQL; *COUNT OBS; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FB; quit;

PROC SQL; *Count obs; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM MERGED_L_B_XS_FB2; 
QUIT;

DATA FINAL; 
	SET FINAL; 
	IF BADBRANCH_FLAG = ""; run;

PROC SQL; *Count obs; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL; 
	IF MISSINGINFO_FLAG = ""; 
RUN;

PROC SQL; *Count obs; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT; 

DATA FINAL; 
	SET FINAL; 
	IF OOS_FLAG = ""; 
RUN;

PROC SQL; *Count obs; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT; 

DATA FINAL; 
	SET FINAL; 
	IF STATE_MISMATCH_FLAG = ""; 
RUN;

PROC SQL; *Count obs; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL; 
	IF OPEN_FLAG = ""; 
RUN;

PROC SQL; *Count obs; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL; 
	IF OPEN_FLAG2 = ""; 
RUN;

PROC SQL; *Count obs; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL; 
	IF BADPOCODE_FLAG = ""; 
RUN;

PROC SQL; *Count obs; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT; 

DATA FINAL;
	SET FINAL; 
	IF DECEASED_FLAG = ""; 
RUN;

PROC SQL; *Count obs;
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL; 
	IF LESSTHAN2_FLAG = ""; 
RUN; 

PROC SQL; *Count obs; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT; 

DATA FINAL; 
	SET FINAL; 
	IF DLQ_FLAG = ""; 
RUN;

PROC SQL; *Count obs; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL; 
	IF CONPROFILE_FLAG = ""; 
RUN;

PROC SQL; *Count obs; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL; 
	IF CON1YR_FLAG = ""; 
RUN;

PROC SQL; *Count obs; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT; 

DATA FINAL; 
	SET FINAL; 
	IF BK5_FLAG = ""; 
RUN;

PROC SQL; *Count obs; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT; 

DATA FINAL; 
	SET FINAL; 
	IF STATFL_FLAG = ""; 
RUN;

PROC SQL; *Count obs; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT; 

DATA FINAL; 
	SET FINAL; 
	IF TRW_FLAG = ""; 
RUN;

PROC SQL; *Count obs; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT; 

DATA FINAL; 
	SET FINAL; 
	IF DNS_DNH_FLAG = ""; 
RUN;

PROC SQL; *Count obs; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT; 

DATA FINAL; 
	SET FINAL; 
	IF NULLDOB_FLAG = ""; 
RUN;

PROC SQL; *Count obs; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL; 
	IF BADSSN_FLAG = ""; 
RUN;

PROC SQL; *Count obs; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL; 
	IF NCAUTOUN_FLAG = ""; 
RUN;

PROC SQL; *Count obs; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL; 
	IF BADFICO_FLAG = ""; 
RUN;

PROC SQL; *Count obs; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL; 
	IF DLQREN_FLAG = ""; 
RUN;

PROC SQL; *Count obs; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL; 
	IF PlAmt_FLAG = ""; 
RUN;

PROC SQL; *Count obs; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL; 
	IF HARVEY = ""; 
RUN;

PROC SQL; *Count obs; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

proc print data=count noobs;  *Print Final Count Table;
run;
proc print data=waterfall;  *Print Waterfall;
run;


data final;
length month_split $6;
set final;
if substr(ssno1,9,1) in (1,3,5,7,9) then month_split="Odd";
else month_split="Even";
run;


*Export Final File;
proc export data=final outfile="&finalexportdropped" dbms=tab replace; run;


*Send to DOD;
data mla;
set final;
keep ssno1 dob lastname firstname middlename bracctno;
run;

DATA MLA;
	SET MLA;
	IDENTIFIER = "S";
RUN;

proc datasets;
modify mla;
rename dob ="Date of Birth"n 
	   ssno1="Social Security Number (SSN)"n 
	   lastname="Last Name"n 
	   firstname="First Name"n 
	   middlename="Middle Name"n 
	   bracctno="Customer Record ID"n
	   IDENTIFIER = "Person Identifier Code"n;
run;
data finalmla;
length "Social Security Number (SSN)"n $ 9 
	   "Date of Birth"n $ 8 
	   "Last Name"n $ 26 
	   "First Name"n $20 
	   "Middle Name"n $ 20  
	   "Customer Record ID"n $ 28
	   "Person Identifier Code"n $ 1;
set mla;
run;

proc print data=finalmla (obs=10); run;
proc contents data=finalmla; run;



data _null_;
 set finalmla;
 file "&exportMLA";
 put @1 "Social Security Number (SSN)"n 
	 @10 "Date of Birth"n 
	 @ 18 "Last Name"n 
	 @ 44 "First Name"n 
	 @ 64 "Middle Name"n 
	 @ 84 "Customer Record ID"n
	 @ 112 "Person Identifier Code"n;
 run;




*Step 2: When file is returned from DOD, run code below;
filename mla1 "\\mktg-app01\E\Production\MLA\MLA-Output files FROM WEBSITE\MLA_4_4_FBCC_20180402.txt";  *do not change file name;
data mla1;
infile mla1;
input ssno1 $ 1-9 dob $ 10-17 lastname $ 18-43 firstname $ 44-63 middlename $ 64-83  bracctno $ 84-120 mla_dod $121-145;
mla_status=substr(mla_dod,1,1);
run;
proc print data=mla1 (obs=10);
run;


data fbccfinal; set final; run;

proc sort data=fbccfinal; by BrAcctNo; run;
proc sort data=mla1; by BrAcctNo; run;

data finalhh;
merge fbccfinal(in=x) mla1;
by bracctno;
if x;
rename crscore=fico;
run;

*Count for Waterfall;
proc freq data=finalhh;
table mla_status/nocum nopercent;
run;


data finalhh2;
length fico_range_25pt $10 campaign_id $25 Made_Unmade $15 cifno $20 custid $20 mgc $20 state1 $5 test_code $20;
set finalhh;
if mla_status="N";
if fico=0 then fico_range_25pt= "0";
if 0<fico<500 then fico_range_25pt="<500";
if 500<=fico<=524 then fico_range_25pt= "500-524";
if 525<=fico<=549 then fico_range_25pt= "525-549";
if 550<=fico<=574 then fico_range_25pt= "550-574";
if 575<=fico<=599 then fico_range_25pt= "575-599";
if 600<=fico<=624 then fico_range_25pt= "600-624";
if 625<=fico<=649 then fico_range_25pt= "625-649";
if 650<=fico<=674 then fico_range_25pt= "650-674";
if 675<=fico<=699 then fico_range_25pt= "675-699";
if 700<=fico<=724 then fico_range_25pt= "700-724";
if 725<=fico<=749 then fico_range_25pt= "725-749";
if 750<=fico<=774 then fico_range_25pt= "750-774";
if 775<=fico<=799 then fico_range_25pt= "775-799";
if 800<=fico<=824 then fico_range_25pt= "800-824";
if 825<=fico<=849 then fico_range_25pt= "825-849";
if 850<=fico<=874 then fico_range_25pt= "850-874";
if 875<=fico<=899 then fico_range_25pt= "875-899";
if 975<=fico<=999 then fico_range_25pt= "975-999";
if fico="" then fico_range_25pt= "";
if source_2 = "RETAIL" then CAMPAIGN_id = "&retail_id";
if source_2 = "AUTO" then CAMPAIGN_id = "&auto_id";
if camp_type="FB" then CAMPAIGN_id = "&fb_id";
if poffdate > "&_1monthago" then RecentPyout="Yes";
else RecentPyout="No";
if month_split="&odd_even" | RecentPyout="Yes";
custid=strip(_n_);
if camp_type="FB" then do;
if lnamt >= 1500 & times30 = 0 then risk_segment = "A";
if lnamt >= 1500 & first6 > 0 then risk_segment = "A and B";
if lnamt >= 1500 & first6 = . & times30 ne 0 then risk_segment = "A and B";
if lnamt >= 1500 & times30 ne 0 then risk_segment = "A and B";
if lnamt < 1500 then risk_segment="A and B";
if ownbr="1019" then risk_segment="AL";
end;
run;
data finalhh2;
set finalhh2;
rename brno=branch firstname=cfname1 middlename=cmname1 lastname=clname1 adr1=caddr1 adr2=caddr2
city=ccity state=cst zip=czip ssno1_rt7=ssn cd60=n_60_dpd conprofile1=ConProfile;
run;




proc import 
	datafile="\\mktg-app01\E\Production\2018\04-April_2018\FBXSCC\FBXSCC_Offers - 20180402.xlsx" 
		dbms=excel 
		out=offers 
		replace; 
run;

data offers;
	set offers;
	risk_segment=strip(risk_segment);
run;

proc sort 
	data=finalhh2; 
	by cst risk_segment; 
run;

proc sort 
	data=offers; 
	by cst risk_segment; 
run;

data finalhh4;
	merge finalhh2(in=x) offers;
	by cst risk_segment;
	if x;
	format amt_given1 dollar10.2;
	rename apr=percent;
run;

*if risk_segment="Test" then test_code="Rate_Test";
*else test_code="Control";


proc sql;
create table finalhh5 as
select custid, branch, cfname1,	cmname1, clname1, caddr1, caddr2, ccity, cst, czip,	ssn, amt_given1, percent,	numpymnts, camp_type, orig_amtid, fico, dob, mla_status, risk_segment, n_60_dpd, conprofile, bracctno, cifno, campaign_id, mgc, month_split, made_unmade, fico_range_25pt, state1, test_code, poffdate, phone, cellphone
from finalhh4;
quit;
run;


proc export data=finalhh5 outfile="&finalexportHH"  dbms=tab;
 run;

 proc export data=finalhh5 outfile="&finalexportED" dbms=csv;
 run;




data check;
set finalhh5;
if amt_given1="";
run;

proc freq data=finalhh5;
tables Risk_Segment;
run;

proc freq data=finalhh5;
tables month_split;
run;





 
/*
DATA notest test;
set finalhh2;
if cst = "AL" & risk_segment="A" then output test;
else output notest;
run;
proc surveyselect data=test out=test2 outall rate=.5 method=srs;
run;
data finalhh3;
set notest test2;
if selected=1 then risk_segment="Test";
if selected=0 then risk_segment="A";
risk_segment=strip(risk_segment);
run;
proc freq data=finalhh3;
tables Risk_Segment;
run;
 proc freq data=finalhh5;
tables test_code;
run;
*/