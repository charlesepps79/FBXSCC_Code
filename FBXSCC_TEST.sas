%LET FINAL_HH_IMPORT = 
"\\mktg-app01\E\cepps\FBXS\Files\2018_04_24\FBXS_CC_20180424FINAL_HH.txt";
%LET FINAL_EXPORT_HH = 
"\\mktg-app01\E\cepps\FBXS\Files\2018_04_24\FBXS_CC_20180424FINAL_HH_TEST.txt";

%LET VARLIST = branch $4 cfname1 $16 cmname1 $14 clname1 $22 caddr1 $40
			   caddr2 $40 ccity $25 cst $3 czip $10 ssn $7 camp_type $2
			   fico 8 Risk_Segment $7 ConProfile $12 BrAcctNo $25
			   cifno $25 POffDate $10 Phone $40 CellPhone $13;
%LET FORMATLIST = amt_given1 DOLLAR10.2;

DATA FINAL_HH;
	SET WORK.FBXS_CC_20180424FINAL_HH;
	IF CST = 'NC' AND MADE_UNMADE = 'UNMADE' THEN DELETE;
RUN;

PROC SURVEYSELECT 
	DATA = FINAL_HH SAMPRATE = 0.50 SEED = 3617 
		OUT = TEST_SAMPLE OUTALL METHOD = SRS NOPRINT;
	STRATA cSt;
RUN;

DATA TEST_SAMPLE;
	SET TEST_SAMPLE;
	IF RISK_SEGMENT = "AL" THEN DO; 
		branch = "1004";
		RISK_SEGMENT = 'A';
		orig_amtid = 614;
		amt_given1 = 2000.00;
		percent = 0.44992;
		numpymnts = 24;
	END;
		
	IF Selected = 1 & orig_amtid = 605 THEN DO;
		orig_amtid = 617;
		amt_given1 = 1350.00;
		percent = 0.48;
		numpymnts = 18;
	END;

	IF Selected = 1 & orig_amtid = 606 THEN DO;
		orig_amtid = 618;
		amt_given1 = 1350.00;
		percent = 0.48;
		numpymnts = 18;
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

PROC EXPORT 
	DATA = FINAL_HH_TEST OUTFILE = &FINAL_EXPORT_HH  DBMS = TAB;
RUN;


		