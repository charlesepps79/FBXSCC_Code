
data _null_;
	call symput("outfilex",
		"\\mktg-app01\E\Production\Audits\FBXCC JQ AUDIT - 22.05_02 - Final Mail File.xlsx");
	call symput("importfile",
		"WORK.'31342205.m01.prod.return.final.m'n;");
run;

data auditfbxcc;
	*** BranchNumber as string, checknumber as string ------------ ***;
	set &importfile; 
run;

data snip;
	set auditfbxcc(obs = 4);
run;

data checkinfo1;
	infile datalines delimiter = ",";
	input state $ acctnum_x;
	datalines;
AL, 7482178410,
TN, 7482178428,
GA, 7482178576,
MS, 7482178543,
MO, 7482178550,
NM, 7482178568,
NC, 7482178535,
OK, 7482178600,
SC, 7482178527,
TX, 7482178519,
VA, 7482178618,
WI, 7482178501,
IL, 7482178584,
IN, 7482178592,
UT, 7482178626,
CA, 7482241036,
KY, 7482241044
;
run;

proc sort 
	data = checkinfo1;
	by state;
run;

proc sort 
	data = auditfbxcc;
	by state;
run;

data auditfbxcc;
merge auditfbxcc checkinfo1;
by state;
run;

data auditfbxcc;
	set auditfbxcc;
	if acctnum_x = acctnum 
		then AcctNum_Error = 0;
	else acctnum_error = 1;
run;

data short1;
	set rmcath.mailfile_short_2015(
		keep = CheckNumber);
	where CheckNumber not in("", ".");
run;

data short2;
	set rmcath.mailfile_short_2016(
		keep = CheckNumber);
	where CheckNumber not in("", ".");
run;

data short3;
	set rmcath.mailfile_short_2017(
		keep = CheckNumber);
	where CheckNumber not in("", ".");
run;

data short;
	set short1 short2 short3;
run;

proc sort 
	data = short;
	by checknumber;
run;

proc sort 
	data = auditfbxcc;
	by checknumber;
run;

data dupchecknum;
	merge short(in = x) auditfbxcc(in = y);
	by checknumber;
	if x and y;
	keep checknumber;
run;

proc import 
	datafile = "\\mktg-app01\E\Production\Master Files and Instructions\AMTID Master.xlsx" 
	dbms = xlsx 
	out = amtids 
	replace;
run;

proc print 
	data = amtids;
run;

data amtids2;
	set amtids;
	keep state Amtid offer_amount 'fico range'n MinFICO MaxFICO 
		 'Payment Amount'n Term;
	MinFICO = input(substr('fico range'n, 1, 3), 3.);
	MaxFICO = input(substr('fico range'n, 5, 3), 3.);
run;

data amtids3;
	set amtids2;
	if amtid ne .;
	rename amtid = amt_id;
run;

proc sort 
	data = amtids3;
	by state amt_id;
run;

proc sort 
	data = auditfbxcc;
	by state amt_id;
run;

data auditfbxcc;
	merge auditfbxcc(in = x) amtids3;
	by state amt_id;
	if x;
run;

data auditfbxcc;
	set auditfbxcc;
	if offer_amount ne checkamount 
		then amt_id_error = 1;
	if 'Payment Amount'n ne pmt_amt_1 
		then amt_id_error = 1;
	if term ne num_pmt_1 
		then amt_id_error = 1;
	else amt_id_error = 0;
run;

*** Check Branch Info -------------------------------------------- ***;
data audit2nbcc;
	set auditfbxcc;
	keep BranchNumber BranchStreetAddress BranchCity BranchState
		 BranchZip BranchPhone;
run;

proc sort 
	data = audit2nbcc nodupkey;
	by BranchNumber BranchStreetAddress BranchCity BranchState
	   BranchZip BranchPhone;
run;

data branchinfo;
	set rmcath.branchinfo;
	branchnumber = branchnumber_txt;
run;

proc sort 
	data = branchinfo;
	by branchnumber;
run;

data branchInfo_Check;
	merge branchinfo audit2nbcc(in = x);
	by branchnumber;
	if x;
run;

data branchinfo_check2;
	set branchinfo_check;
	if Branchstreetaddress ne StreetAddress 
		then Br_Info_Mismatch = 1;
	if Branchcity ne city 
		then Br_Info_Mismatch = 1;
	if branchstate ne state 
		then br_info_mismatch = 1;
	if branchzip ne zip_full 
		then br_info_mismatch = 1;
	if branchphone ne phone 
		then br_info_mismatch = 1;
	if br_info_mismatch = 1;
	drop BranchNumber_txt;
	rename BranchNumber_number = Branch;
run;

proc sort 
	data = auditfbxcc;
	by offer_amount;
run;

ods excel file = "&outfilex" options(sheet_name = "Data Snippet" sheet_interval = "none");

proc summary 
	data = auditfbxcc print;
run;

proc print 
	data = snip;
run;

proc print 
	data = dupchecknum;
run;

ods excel options(sheet_interval = 'table');
ods select none; 

data _null_; 
	dcl odsout obj(); 
run; 

ods select all;
ods excel options(sheet_name = "StateAndCompany Checks" sheet_interval = "NONE");

proc tabulate 
	data = auditfbxcc;
	class state branchstate;
	tables state, branchstate;
run;

proc tabulate 
	data = auditfbxcc;
	class state BranchCompany;
	tables state, branchcompany;
run;

proc freq 
	data = auditfbxcc;
	table state / nocum nopercent;
run;

ods excel options(sheet_interval = 'table');
ods select none; 

data _null_; 
	dcl odsout obj(); 
run; 

ods select all;
ods excel options(sheet_name = "Campaign Info" sheet_interval = "none");

proc freq 
	data = auditfbxcc;
	tables Drop_Date Closed_Date / nocum nopercent;
run;

proc tabulate 
	data = auditfbxcc;
	class state amt_id CheckAmount offer_amount;
	var MaxFICO;
	tables state * amt_id * CheckAmount, offer_amount;
	by offer_amount;
run;

proc tabulate 
	data = auditfbxcc;
	class CheckAmount_SpelledOut;
	var CheckAmount;
	tables CheckAmount_SpelledOut, CheckAmount * mean * f = dollar10.2;
run;

proc tabulate 
	data = auditfbxcc;
	class AcctNum_Error amt_id_error;
	tables AcctNum_Error amt_id_error;
run;

ods excel options(sheet_interval = 'table');
ods select none; 

data _null_; 
	dcl odsout obj(); 
run; 

ods select all;
ods excel options(sheet_name = "Branch Info Check" sheet_interval = "none");

proc print 
	data = branchinfo_check2 noobs;
run;

ods excel close;