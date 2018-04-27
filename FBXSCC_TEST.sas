%LET FINAL_HH_IMPORT = 
"\\mktg-app01\E\cepps\FBXS\Files\2018_04_24\FBXS_CC_20180424FINAL_HH.txt";

PROC IMPORT 
	DATAFILE = &FINAL_HH_IMPORT. 
	DBMS = TAB 
	OUT = FINAL_HH 
	REPLACE;
RUN;

PROC SURVEYSELECT 
	DATA = FINAL_HH SAMPRATE = 0.50 SEED = 3617 
		OUT = TEST_SAMPLE OUTALL METHOD = SRS NOPRINT;
	STRATA cSt;
RUN;

DATA TEST_SAMPLE;
	SET TEST_SAMPLE;
	IF branch = "1019" THEN branch = "1004";
	IF Selected = 1 & cSt = 'TX' & RISK_SEGMENT = 'A' & 
	   orig_amtid = 605 THEN DO;
		orig_amtid = 605;
		amt_given1 = 2400.00;
		percent = 0.32100;
		numpymnts = 36;
	END;
RUN;

PROC SQL;
	CREATE TABLE FINAL_HH_TEST AS
	SELECT custid, branch, cfname1, cmname1, clname1, caddr1, caddr2,
		   ccity, cst, czip, ssn, amt_given1, percent, numpymnts,
		   camp_type, orig_amtid, fico, DOB, mla_status, Risk_Segment,
		   n_60_dpd, ConProfile, BrAcctNo, cifno, campaign_id, mgc,
		   month_split, Made_Unmade, fico_range_25pt, state1, 
		   test_code, POffDate, Phone, CellPhone
	FROM TEST_SAMPLE;
QUIT;
RUN;

		