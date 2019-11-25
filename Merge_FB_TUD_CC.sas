%LET FINAL_FB_HH_IMPORT = 
"\\mktg-app01\E\Production\2019\12_DECEMBER_2019\FBXSCC\FBXS_CC_20191125FINAL_HH.txt";
%LET FINAL_MO_HH_IMPORT = 
"\\mktg-app01\E\Production\2019\12_DECEMBER_2019\FBXSCC\MOCC_20191125FINAL_HH.txt";
%LET FINAL_EXPORT_HH = 
"\\mktg-app01\E\Production\2019\12_DECEMBER_2019\FBXSCC\FBMO_CC_20191125FINAL_HH_TEST.txt";

%LET VARLIST = branch $4 cfname1 $16 cmname1 $14 clname1 $22 caddr1 $40
			   caddr2 $40 ccity $25 cst $3 czip $10 ssn $7 camp_type $2
			   fico 8 Risk_Segment $7 ConProfile $12 BrAcctNo $25
			   cifno $25 POffDate $10 Phone $40 CellPhone $13;
%LET FORMATLIST = amt_given1 DOLLAR10.2;

data _null_;
	call symput("importFB",
		"WORK.FBXS_CC_20191125FINAL_HH_TEST");
run;

data _null_;
	call symput("importMO",
		"WORK.MOCC_20191125FINAL_HH");
run;

data FINAL_FB_HH;
	*** BranchNumber as string, checknumber as string ------------ ***;
	set &importFB; 
	if length(SSN) lt 7 then SSN = cats(repeat('0',7-1-length(SSN)),SSN);
run;

data FINAL_MO_HH;
	*** BranchNumber as string, checknumber as string ------------ ***;
	set &importMO; 
	if length(SSN) lt 7 then SSN = cats(repeat('0',7-1-length(SSN)),SSN);
run;

DATA FINAL_HH;
	SET FINAL_FB_HH FINAL_MO_HH;
RUN;

PROC SQL;
	CREATE TABLE FINAL_HH_TEST AS
	SELECT custid, branch, cfname1, cmname1, clname1, caddr1, caddr2,
		   ccity, cst, czip, ssn, amt_given1, percent, numpymnts,
		   camp_type, orig_amtid, fico, DOB, mla_status, Risk_Segment,
		   n_60_dpd, ConProfile, BrAcctNo, cifno, campaign_id, mgc,
		   month_split, Made_Unmade, fico_range_25pt, state1, 
		   test_code, POffDate, Phone, CellPhone, suffix
	FROM FINAL_HH;
QUIT;
RUN;

PROC EXPORT 
	DATA = FINAL_HH_TEST OUTFILE = &FINAL_EXPORT_HH  DBMS = TAB;
RUN;

PROC EXPORT 
	DATA = FINAL_HH OUTFILE = &FINAL_EXPORT_HH  DBMS = TAB;
RUN;