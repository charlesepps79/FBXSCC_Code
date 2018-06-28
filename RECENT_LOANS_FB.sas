data x;
set dw.vw_loan(keep=entdate ssno1 pocd plcd bnkrptdate pldate poffdate);
where entdate>"2018-06-06" & pocd="" & plcd="" & poffdate="" & pldate="" & BnkrptDate="";
recent_open="X";
run;

proc sort data=x out=x2 nodupkey;
by ssno1;
run;

data y; 
set WORK.FBXS_CC_20180606FINAL;
run;

proc sort data=y;
by ssno1;
run;

data z;
merge x2 y (in=x);
by ssno1;
if x;
run;

data m;
set z;
if recent_open="X";
keep bracctno;
run;

proc export data=m outfile="\\mktg-app01\E\Production\2018\06-June_2018\FBXSCC\recentopens0615.txt" dbms=tab;
run;