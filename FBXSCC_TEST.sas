%LET FINAL_HH_IMPORT = 
"\\mktg-app01\E\Production\2019\11_NOVEMBER_2019\FBXSCC\FBXS_CC_20191101FINAL_HH.txt";
%LET FINAL_EXPORT_HH = 
"\\mktg-app01\E\Production\2019\11_NOVEMBER_2019\FBXSCC\FBXS_CC_20191101FINAL_HH_TEST.txt";

%LET VARLIST = branch $4 cfname1 $16 cmname1 $14 clname1 $22 caddr1 $40
			   caddr2 $40 ccity $25 cst $3 czip $10 ssn $7 camp_type $2
			   fico 8 Risk_Segment $7 ConProfile $12 BrAcctNo $25
			   cifno $25 POffDate $10 Phone $40 CellPhone $13;
%LET FORMATLIST = amt_given1 DOLLAR10.2;

data _null_;
	call symput("importfile",
		"WORK.FBXS_CC_20191101FINAL_HH");
run;

data FINAL_HH;
	*** BranchNumber as string, checknumber as string ------------ ***;
	set &importfile; 
	if length(SSN) lt 7 then SSN = cats(repeat('0',7-1-length(SSN)),SSN);
run;

/*
DATA FINAL_HH;
	SET FINALHH5;
	IF CST = 'NC' AND MADE_UNMADE = 'UNMADE' THEN DELETE;
	NEW_DOB = INPUT(DOB, 8.);
	DROP DOB;
   	RENAME NEW_DOB = DOB;
RUN;
*/
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
	/*	
	IF Selected = 1 & orig_amtid = 229 THEN DO;
		orig_amtid = 702;
		Risk_Segment = 'AT';
		amt_given1 = 1500.00;
		percent = 0.46340;
		numpymnts = 18;
	END;

	IF Selected = 1 & orig_amtid = 703 THEN DO;
		orig_amtid = 495;
		Risk_Segment = '650-850';
		amt_given1 = 1410.00;
		percent = 0.48112;
		numpymnts = 15;
	END;

	IF Selected = 1 & orig_amtid = 646 THEN DO;
		orig_amtid = 700;
		Risk_Segment = 'AB';
		amt_given1 = 1400.00;
		percent = 0.66860;
		numpymnts = 18;
	END;

	IF Selected = 1 & orig_amtid = 701 THEN DO;
		orig_amtid = 647;
		Risk_Segment = '625-649';
		amt_given1 = 1300.00;
		percent = 0.69913;
		numpymnts = 18;
	END;

	IF cst = 'GA' & risk_segment = 'A' THEN DO;
		orig_amtid = 767;
		amt_given1 = 1400.00;
		percent = 0.4078;
		numpymnts = 15;
	END;
	*/

	IF Selected = 1 & orig_amtid = 708 THEN DO;
		orig_amtid = 726;
		Risk_Segment = 'AB';
		amt_given1 = 1800.00;
		percent = 0.30000;
		numpymnts = 20;
	END;

	IF Selected = 1 & orig_amtid = 704 THEN DO;
		orig_amtid = 800;
		Risk_Segment = 'AB';
		amt_given1 = 1800.00;
		percent = 0.6498;
		numpymnts = 22;
	END;

	IF Selected = 1 & orig_amtid = 745 THEN DO;
		orig_amtid = 727;
		Risk_Segment = 'AB';
		amt_given1 = 1800.00;
		percent = 0.35950;
		numpymnts = 20;
	END;
RUN;

/*
DATA TEST_SAMPLE;
	SET TEST_SAMPLE;
	new_ssn = put(ssn, 9.);
	new_ssn = SUBSTR(new_ssn,3);
	drop ssn;
	rename new_ssn=ssn;
RUN;
*/

PROC SQL;
	CREATE TABLE FINAL_HH_TEST AS
	SELECT custid, branch, cfname1, cmname1, clname1, caddr1, caddr2,
		   ccity, cst, czip, ssn, amt_given1, percent, numpymnts,
		   camp_type, orig_amtid, fico, DOB, mla_status, Risk_Segment,
		   n_60_dpd, ConProfile, BrAcctNo, cifno, campaign_id, mgc,
		   month_split, Made_Unmade, fico_range_25pt, state1, 
		   test_code, POffDate, Phone, CellPhone, suffix
	FROM TEST_SAMPLE;
QUIT;
RUN;

PROC EXPORT 
	DATA = FINAL_HH_TEST OUTFILE = &FINAL_EXPORT_HH  DBMS = TAB;
RUN;

PROC EXPORT 
	DATA = FINAL_HH OUTFILE = &FINAL_EXPORT_HH  DBMS = TAB;
RUN;