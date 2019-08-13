%LET FINAL_HH_IMPORT = 
"\\mktg-app01\E\Production\2019\08_AUGUST_2019\FBXSCC\FBXS_CC_20190726FINAL_HH.txt";
%LET FINAL_EXPORT_HH = 
"\\mktg-app01\E\Production\2019\08_AUGUST_2019\FBXSCC\FBXS_CC_20190726FINAL_HH_TEST.txt";

%LET VARLIST = branch $4 cfname1 $16 cmname1 $14 clname1 $22 caddr1 $40
			   caddr2 $40 ccity $25 cst $3 czip $10 ssn $7 camp_type $2
			   fico 8 Risk_Segment $7 ConProfile $12 BrAcctNo $25
			   cifno $25 POffDate $10 Phone $40 CellPhone $13;
%LET FORMATLIST = amt_given1 DOLLAR10.2;

DATA FINAL_HH;
	SET FINALHH5;
	IF CST = 'NC' AND MADE_UNMADE = 'UNMADE' THEN DELETE;
	NEW_DOB = INPUT(DOB, 8.);
	DROP DOB;
   	RENAME NEW_DOB = DOB;
RUN;

PROC SORT 
	DATA = FINAL_HH;
	BY orig_amtid;
RUN;

PROC SURVEYSELECT 
	DATA = FINAL_HH SAMPRATE = 0.50 SEED = 3617 
		OUT = TEST_SAMPLE OUTALL METHOD = SRS NOPRINT;
	STRATA orig_amtid;
RUN;

DATA TEST_SAMPLE;
	SET TEST_SAMPLE;
		
	IF Selected = 1 & orig_amtid = 623 THEN DO;
		orig_amtid = 617;
		Risk_Segment = 'AT';
		amt_given1 = 1350.00;
		percent = 0.48;
		numpymnts = 18;
	END;

	IF Selected = 1 & orig_amtid = 624 THEN DO;
		orig_amtid = 618;
		Risk_Segment = 'XT';
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


		