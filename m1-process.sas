
/* TODO: After the Dry Run step, change the mode to verify. */
%chckpt(save);

options dlcreatedir msglevel=i;
libname loc 'data';
libname tgt 'data/output';


%let input_ds = loc.cust_data;
%let output_ds = tgt.myoutput;


%let keep_varlist=
acc_id
var9_AVG06M
var15
var12
;

%let SELF1=SELFEMPLOYED;
%let SELF2=SELFEMPLYD;
%let SELF3=SELF;


%macro avg (inv,p);
  %if %length(&p)=1 %then %let pt=0&p;%else %let pt=&p;
  %*array &inv._AVG&pt.{*}  &inv._h1 - &inv._h&p  ;
  &inv._AVG&pt.M=mean( of &inv._h1 - &inv._h&p);
  label &inv._AVG&pt.M="average &inv in last &p.M";
%mend avg;

%macro max (inv,p);
  %if %length(&p)=1 %then %let pt=0&p;%else %let pt=&p;
  &inv._MAX&pt.M=max( of &inv._h1 - &inv._h&p);
  label &inv._MAX&pt.M="max of &inv in &p.M";
%mend max;


%macro msx (inv,p);
  %if %length(&p)=1 %then %let pt=0&p;%else %let pt=&p;
  array &inv._MSX&pt.{*} &inv._h1 - &inv._h&p;
    %do i=1 %to &p;
        &inv._MSX&pt.{&i} = &inv._h&i;
    %end;
    _tmp=min(%eval(&p-1),TTT);
    &inv._MAX&pt.M=max( of &inv._h1 - &inv._h&p);
      if %do i=1 %to &p;(&inv._MSX&pt.[&i] =0 or &inv._MSX&pt.[&i] =.  ) and %end; (&inv._MSX&pt.[_tmp+1]=0 or &inv._MSX&pt.[_tmp+1]=. ) then
    &inv._MSX&pt.M=.;
    %do i=1 %to &p; else if (&inv._MSX&pt.[&i]=&inv._MAX&pt.M) then &inv._MSX&pt.M=%eval(&i-1);%end;
  label &inv._MSX&pt.M="# of mon since &inv=maximum in last &p.mon";
%mend msx;


proc contents data=&input_ds varnum;
run;

data data1;
set &input_ds;

TTT = 12;

%MSX(var4,3);
%AVG(var9, 6);
%MAX(var10,6);


if var2<0 then do;
    var2_miss_rc = .;
    var2=0; end;
else if var2>3 then do;
    var2_miss_rc = 1;
    var2=3; end;
else var2_miss_rc = 1;

if var3<0 then do;
    var3_miss_rc = .;
    var3=0; end;
else if var3>436 then do;
    var3_miss_rc = 1;
    var3=436; end;
else var3_miss_rc = 1;

if var4_MSX03M<0 or var4_MSX03M = . then do;
    var4_MSX03M_miss_rc = .;
    var4_MSX03M=0; end;
else if var4_MSX03M>2 then do;
    var4_MSX03M_miss_rc = 1;
    var4_MSX03M=2; end;
else var4_MSX03M_miss_rc = 1;

if var5=. then do;
    var5_miss_rc = .;
    var5=0; end;
else if  var5~=. and var5<0 then do;
    var5_miss_rc = 1;
    var5=0; end;
else if var5>13378.87 then do;
    var5_miss_rc = 1;
    var5=13378.87; end;
else var5_miss_rc = 1;

if var6<0 then do;
    var6_miss_rc = .;
    var6=0; end;
else if var6>4 then do;
    var6_miss_rc = 1;
    var6=4; end;
else var6_miss_rc = 1;

if var7<0 then do;
    var7_miss_rc = .;
    var7=0; end;
else if var7>10 then do;
    var7_miss_rc = 1;
    var7=10; end;
else var7_miss_rc = 1;

if var7_miss_rc=. or var6_miss_rc=. then
var7_3_miss_rc=.;
else var7_3_miss_rc=1;

if var8=. then do;
    var8_miss_rc = .;
    var8=0; end;
else if var8>1 then do;
    var8_miss_rc = 1;
    var8=1; end;
else var8_miss_rc = 1;

if var9_AVG06M<0 then do;
    var9_AVG06M_miss_rc = .;
    var9_AVG06M=0; end;
else if var9_AVG06M>0.166666667 then do;
    var9_AVG06M_miss_rc = 1;
    var9_AVG06M=0.166666667; end;
else var9_AVG06M_miss_rc = 1;

if var10_MAX06M<0 then do;
    var10_MAX06M_miss_rc = .;
    var10_MAX06M=0; end;
else if var10_MAX06M>1706 then do;
    var10_MAX06M_miss_rc = 1;
    var10_MAX06M=1706; end;
else var10_MAX06M_miss_rc = 1;

var15 = (compress (var11) in ("&SELF1","&SELF2","&SELF3"));

run;

proc freq;
table var11;
run;
/* pysas://inline
print(loc.cust_data.pivot_table(index='var11', aggfunc=[len]))
*/


proc contents varnum;
run;


/*
Check var10_MAX06M_miss_rc count
*/
proc sql ;
   select count(*) from data1
   where var10_MAX06M_miss_rc = .;
quit;

/*
Introduce var14_06M_IND bin indicator based on var9_AVG06M, change scale
*/
data data2_bin; 
    set data1;
    var7_3 = var7 - var6;
    var3_sqrt =round((var3)**0.5,0.001);

    var10_MAX06M_d1k = var10_MAX06M /1000;
    var5_d1k  = var5 / 1000;
    var14_06M_IND = (var9_AVG06M>0);
run;

/* 
Final metadata check before going into the model
*/
proc contents varnum;
run;

data &output_ds (keep=&keep_varlist);
set data2_bin;
if var15=1 then
     do;
     _odds_ = -2.9008379557983 + 
     var2 *0.51321074701043 +
     var6 *0.30869615973879 +
     var3_sqrt *-0.1043988021714 +
     var10_MAX06M_d1k *0.57328563884535 +
     var5_d1k *0.07479182006707 +
     var4_MSX03M *-0.266503841006 +
     var8 *-0.4633683405225 +
     var7_3 *0.09645397289283 +
     var14_06M_IND *0.64209219214701 +
     1*0.47716463611303 ;
     var12 = exp(_odds_) / (1 + exp( _odds_));
     end;

else if var15=0 then
     do;
    _odds_ = -2.8248754875705 +
     var2 *0.3237162514663 +
     var6 *0.1861264978875 +
     var3_sqrt *-0.0770334444827 +
     var10_MAX06M_d1k *0.4585068268165 +
     var5_d1k *0.0744211100811 +
     var4_MSX03M *-0.2234353377510 +
     var8 *-0.2800241718867 +
     var7_3 *0.0948774483357 +
     var14_06M_IND *0.4738297195033 +
     0*0.3760174674156 ;
     var12 = exp(_odds_) / (1 + exp( _odds_));
     end;

beta_var2=(var2-0.44)*0.51321074701043;
beta_var6=(var6-0.34)*0.30869615973879;
beta_var3_sqrt=(var3_sqrt-13.34)*-0.1043988021714;
beta_var10_MAX06M_d1k=(var10_MAX06M_d1k-0.05)*0.57328563884535;
beta_var5_d1k=(var5_d1k-2.76)*0.07479182006707;
beta_var4_MSX03M=(var4_MSX03M-1.01)*-0.266503841006;
beta_var8=(var8- 0.73)*-0.4633683405225;
beta_var7_3=(var7_3- 1.22)*0.09645397289283;
beta_var14_06M_IND=(var14_06M_IND-0.05)*0.64209219214701;

/*
array beta(9)
beta_var2
beta_var6
beta_var3_sqrt
beta_var10_MAX06M_d1k
beta_var5_d1k
beta_var4_MSX03M
beta_var8
beta_var7_3
beta_var14_06M_IND;
*/

array beta_code(9) $ ;
beta_code(1)='3234';
beta_code(2)='2017';
beta_code(3)='3235';
beta_code(4)='3206';
beta_code(5)='3165';
beta_code(6)='3232';
beta_code(7)='3233';
beta_code(8)='2021';
beta_code(9)='3139';


array missing_rc(9)
var2_miss_rc
var6_miss_rc
var3_miss_rc
var10_MAX06M_miss_rc
var5_miss_rc
var4_MSX03M_miss_rc
var8_miss_rc
var7_3_miss_rc
var9_AVG06M_miss_rc;

array inconvenience_sup(9)
var2_in_sup
var6_in_sup
var3_in_sup
var10_MAX06M_in_sup
var5_in_sup
var4_MSX03M_in_sup
var8_in_sup
var7_3_in_sup
var14_06M_IND_in_sup;

if var2 <=0 then var2_in_sup=.;
else var2_in_sup=1;
if var6 <=0 then var6_in_sup=.;
else var6_in_sup=1;
if var3_sqrt >=7 then var3_in_sup=.;
else var3_in_sup=1;
if var10_MAX06M_d1k <=0 then var10_MAX06M_in_sup=.;
else var10_MAX06M_in_sup=1;
if var5_d1k <=0.5 then var5_in_sup=.;
else var5_in_sup=1;
if var4_MSX03M >=2 then var4_MSX03M_in_sup=.;
else var4_MSX03M_in_sup=1;
if var8 >=1 then var8_in_sup=.;
else var8_in_sup=1;
if var7_3 <=0 then var7_3_in_sup=.;
else var7_3_in_sup=1;
if var14_06M_IND =0 then var14_06M_IND_in_sup=.;
else var14_06M_IND_in_sup=1;

run;

proc contents varnum data=&output_ds;
   title 'metadata';
run;


proc print data=&output_ds(obs=10);
   title 'first 10';
run;
