/*%LET FINAL_HH_IMPORT = 
"\\mktg-app01\E\Production\2022\01_January_2022\FBXSCC\FBXS_CC_20211210FINAL_JQ.txt";

%LET FINAL_EXPORT_HH = 
"\\mktg-app01\E\Production\2022\01_January_2022\FBXSCC\FBXS_CC_20211210FINAL_JQ_TEST.txt";*/

%LET VARLIST = branch $4 cfname1 $16 cmname1 $14 clname1 $22 caddr1 $40
			   caddr2 $40 ccity $25 cst $3 czip $10 ssn $7 camp_type $2
			   fico 8 Risk_Segment $7 ConProfile $12 BrAcctNo $25
			   cifno $25 POffDate $10 Phone $40 CellPhone $13;
%LET FORMATLIST = amt_given1 DOLLAR10.2;

***** In the imported file change SSN to string ****;

data _null_;
	call symput("importfile",
		"WORK.FBXS_CC_20220520FINAL_JQ"); 
		
run;

data FINAL_HH;
	*** BranchNumber as string, checknumber as string ------------ ***;
	set &importfile; 
	if length(SSN) lt 7 then SSN = cats(repeat('0',7-1-length(SSN)),SSN);
    IF CAMP_TYPE = "XS" AND orig_amtid = 662
		THEN DELETE;
	

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
/*
PROC SURVEYSELECT 
	DATA = FINAL_HH SAMPRATE = 0.50 SEED = 3617 
		OUT = TEST_SAMPLE OUTALL METHOD = SRS NOPRINT;
	STRATA orig_amtid;
RUN;
*/
/*
DATA TEST_SAMPLE;
	SET TEST_SAMPLE;
		
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
	
	IF Selected = 1 & orig_amtid = 708 THEN DO;
		orig_amtid = 726;
		Risk_Segment = 'AB';
		amt_given1 = 1800.00;
		percent = 0.30000;
		numpymnts = 20;
	END;

	IF Selected = 1 & orig_amtid = 745 THEN DO;
		orig_amtid = 727;
		Risk_Segment = 'AB';
		amt_given1 = 1800.00;
		percent = 0.35950;
		numpymnts = 20;
	END;

	IF Selected = 1 & orig_amtid = 704 THEN DO;
		orig_amtid = 800;
		Risk_Segment = 'AB';
		amt_given1 = 1800.00;
		percent = 0.6498;
		numpymnts = 22;
	END;


	IF Selected = 1 & orig_amtid = 651 THEN DO;
		orig_amtid = 809;
		Risk_Segment = 'ATT';
		amt_given1 = 2000.00;
		percent = 0.43187;
		numpymnts = 18;
	END;
RUN;   */

DATA FINAL_HH;
	SET FINAL_HH;

	IF CST = 'AL' & CAMP_TYPE = 'XS' & RISK_SEGMENT = '650-850' 
		THEN DO;
		amt_given1 = 2200.00;
		percent = 0.36980;
		numpymnts = 24;
		orig_amtid = 691;
		RISK_SEGMENT = '650-750';
	END;

	IF CST = 'GA' & CAMP_TYPE = 'XS' & RISK_SEGMENT = '650-850' 
		THEN DO;
		amt_given1 = 1400.00;
		percent = 0.40780;
		numpymnts = 15;
		orig_amtid = 823;
		RISK_SEGMENT = '650-750';
	END;	

	IF CST = 'NC' & CAMP_TYPE = 'XS' & RISK_SEGMENT = '650-850' 
		THEN DO;
		amt_given1 = 2400.00;
		percent = 0.31120;
		numpymnts = 24;
		orig_amtid = 680;
		RISK_SEGMENT = '650-750';
	END;

	IF CST = 'NM' & CAMP_TYPE = 'XS' & RISK_SEGMENT = '650-850' 
		THEN DO;
		amt_given1 = 2000.00;
		percent = 0.44990;
		numpymnts = 24;
		orig_amtid = 684;
		RISK_SEGMENT = '650-750';
	END;	

	IF CST = 'OK' & CAMP_TYPE = 'XS' & RISK_SEGMENT = '650-850' 
		THEN DO;
		amt_given1 = 1200.00;
		percent = 0.55190;
		numpymnts = 15;
		orig_amtid = 819;
		RISK_SEGMENT = '650-750';
	END;

	IF CST = 'SC' & CAMP_TYPE = 'XS' & RISK_SEGMENT = '650-850' 
		THEN DO;
		amt_given1 = 2000.00;
		percent = 0.44000;
		numpymnts = 24;
		orig_amtid = 707;
		RISK_SEGMENT = '650-750';
	END;

	IF CST = 'TN' & CAMP_TYPE = 'XS' & RISK_SEGMENT = '650-850' 
		THEN DO;
		amt_given1 = 2000.00;
		percent = 0.43192;
		numpymnts = 20;
		orig_amtid = 652;
		RISK_SEGMENT = '650-750';
	END;

	IF CST = 'TX' & CAMP_TYPE = 'XS' & RISK_SEGMENT = '650-850' 
		THEN DO;
		amt_given1 = 2400.00;
		percent = 0.34550;
		numpymnts = 24;
		orig_amtid = 815;
		RISK_SEGMENT = '650-750';
	END;

	IF CST = 'VA' & CAMP_TYPE = 'XS' & RISK_SEGMENT = '650-850' 
		THEN DO;
		amt_given1 = 2400.00;
		percent = 0.35990;
		numpymnts = 24;
		orig_amtid = 861;
		RISK_SEGMENT = '650-750';
	END;

	IF CST = 'MO' & CAMP_TYPE = 'XS' & RISK_SEGMENT = '650-850' 
		THEN DO;
		amt_given1 = 2000.00;
		percent = 0.44990;
		numpymnts = 24;
		orig_amtid = 698;
		RISK_SEGMENT = '650-750';
	END;

	IF CST = 'WI' & CAMP_TYPE = 'XS' & RISK_SEGMENT = '650-850' 
		THEN DO;
		amt_given1 = 2000.00;
		percent = 0.44990;
		numpymnts = 24;
		orig_amtid = 718;
		RISK_SEGMENT = '650-750';
	END;

RUN;
/*
**** This is done on 7/14/21 to change in the test file  ;
data FINAL_HH;
set FINAL_HH;
length campaign_id $ 20.;
if campaign_id='&RETAIL_ID' then campaign_id='RetailXS_08.1_2021';
	if campaign_id='&FB_ID' then campaign_id='FB_08.1_2021CC';
	run;*/

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
		   test_code, POffDate, Phone, CellPhone, suffix/*, RECENTPYOUT, 
		   CAD_OFFER*/,FOOTPRNT, STATE_MISMATCH_FLAG /* ADDED THIS VARIABLE FROM 9.1 CAMPAIGN */
	FROM FINAL_HH;
QUIT;
RUN;

PROC EXPORT DATA=FINAL_HH_TEST 
OUTFILE ="\\mktg-app01\E\Production\2022\06_June_2022\FBXSCC\FBXS_CC_20220520FINAL_JQ_TEST.txt"
DBMS = TAB REPLACE;
RUN;
/*

PROC EXPORT 

	DATA = FINAL_HH_TEST OUTFILE = &FINAL_EXPORT_HH  DBMS = TAB REPLACE;
RUN;

PROC EXPORT 
	DATA = FINAL_HH OUTFILE = &FINAL_EXPORT_HH  DBMS = TAB REPLACE;
RUN;

;