*Program name: 4-Rate difference and confidence interval
*Last updated date: May 3, 2026
*Purpose: Calculate rate differences and confidence intervals;


libname ltcdc "YOUR PATH";
libname output "YOUR PATH";

*The macro below calculates the point estimate rate difference;
%macro main_est (outcome);
ods output genmod.lsmeans=&outcome._main_est;

proc genmod data=output.pre_post_prev ;
	class master_patient_id period_master (ref="Pre-STRIDE");
	model  &outcome =period_master / dist=poisson offset=log_pt link=log;
	estimate "Comparing  Post- to Pre-STRIDE" period_master  1 /exp;
	lsmeans period_master/  exp cl;
run;

proc transpose data=&outcome._main_est out=&outcome._t ;
	var expestimate;
	id  period_master ;
run;

data output.&outcome._main_est ;
	length outcome $20;
	set &outcome._t ;
	rate_diff=post_stride-pre_stride;
	outcome="&outcome";
run;


%mend;

%main_est (count_insulin);
%main_est (count_sulfonylurea);
%main_est (count_combined_meds);

*Generate 1000 bootstrap samples;
proc surveyselect data=output.pre_post_prev out=output.bootsample
	seed=549285 method=urs samprate=1 outhits rep=1000;
run;

proc sort data=output.bootsample;
	by replicate;
run;
	
*Calculate rate difference in each bootstrap;
%macro boot_est (outcome);
%do bsample=1 %to 1000;
ods output  Genmod.LSMeans=&outcome._boot_&bsample;
proc genmod data=output.bootsample;
	where replicate=&bsample;
	class master_patient_id period_master (ref="Pre-STRIDE");
	model  &outcome =period_master / dist=poisson offset=log_pt link=log;
	estimate "Comparing  Post- to Pre-STRIDE" period_master  1 /exp;
	lsmeans period_master/  exp cl;
run;

proc transpose data=&outcome._boot_&bsample out=&outcome._t_&bsample ;
	var expestimate;
	id  period_master ;
run;

data output.&outcome._final_&bsample ;
	length outcome $20;
	set &outcome._t_&bsample ;
	rate_diff=post_stride-pre_stride;
	outcome="&outcome";
run;

proc datasets library=work kill nolist;
quit;

%end;

%mend;
%boot_est (count_insulin);
%boot_est (count_sulfonylurea);
%boot_est (count_combined_meds);

*Insulin-Calculte the percentile based 95% Confidence Interval;
proc sql noprint;
	select cats ("output.", memname)
	into :insulin
	separated by " "
	from dictionary.tables

	where libname="OUTPUT" and memname contains "COUNT_INSULIN_FINAL_"
;
QUIT;

%put &insulin;

data insulin_Stacked;
	set &insulin;
run;

proc univariate data=insulin_stacked noprint;
	var rate_diff;
output out=output.insulin_bstrap pctlpts=2.5 97.5 pctlpre=CI;
run;

*Sulfonylurea-Calculte the percentile based 95% Confidence Interval;
proc sql noprint;
	select cats ("output.", memname)
	into :sulfonylurea
	separated by " "
	from dictionary.tables

	where libname="OUTPUT" and memname contains "COUNT_SULFONYLUREA_FINAL_"
;
QUIT;

%put &sulfonylurea;

data sulfonylurea_Stacked;
	set &sulfonylurea;
run;

proc univariate data=sulfonylurea_stacked noprint;
	var rate_diff;
output out=sulfonylurea_bstrap pctlpts=2.5 97.5 pctlpre=CI;
run;

*Combined meds-Calculte the percentile based 95% Confidence Interval;
proc sql noprint;
	select cats ("output.", memname)
	into :COMBINED
	separated by " "
	from dictionary.tables

	where libname="OUTPUT" and memname contains "COUNT_COMBINED_MEDS_FINAL_"
;
QUIT;

%put &COMBINED;

data combined_Stacked;
	set &combined;
run;

proc univariate data=combined_stacked noprint;
	var rate_diff;
output out=output.combined_bstrap pctlpts=2.5 97.5 pctlpre=CI;
run;

