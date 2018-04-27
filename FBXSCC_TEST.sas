%LET FINAL_HH_IMPORT = 
"\\mktg-app01\E\cepps\FBXS\Files\2018_04_24\FBXS_CC_20180424FINAL_HH.txt";

PROC IMPORT 
	DATAFILE = &FINAL_HH_IMPORT. 
	DBMS = TAB 
	OUT = FINAL_HH 
	REPLACE;
RUN;

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_FINAL_HH AS 
   SELECT t1.cuStid, t1.BRANCH, t1.cfname1, t1.cmname1, t1.clname1,
		  t1.caddr1, t1.caddr2, t1.cCITY, t1.cSt, t1.cZIP, t1.SSn,
		  t1.amt_given1, t1.percent, t1.numpymnts, t1.CAMP_TYPE,
		  t1.orig_amtid, t1.fico, t1.DOB, t1.mla_StatuS,
		  t1.RISK_SEGMENT, t1.n_60_dpd, t1.ConPrOFile, t1.BrAcctNo, 
		  t1.cIFno, t1.campaign_id, t1.mgc, t1.month_Split,
		  t1.MADE_UNMADE, t1.fico_rANge_25pt, t1.STATE1, t1.teSt_code,
		  t1.POffDate, t1.Phone, t1.CellPhone
      FROM WORK.FINAL_HH t1
      WHERE t1.cSt = 'TX' AND t1.RISK_SEGMENT = 'A' AND t1.orig_amtid = 605;
QUIT;

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

		