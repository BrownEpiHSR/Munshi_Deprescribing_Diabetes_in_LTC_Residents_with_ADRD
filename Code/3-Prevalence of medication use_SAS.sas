*Program name: 3-Prevalence of medication use
*Last updated date: June 20, 2025
*Purpose: Calculate prevalence of high-risk medication use, along with risk ratio and differences;

libname ltcdc "YOUR PATH";
libname output "YOUR PATH";

*Stack the 2022, 2023, 2024 insulin or sulfonylurea administratoin data;
data stacked_medic;
	set output.medication_2022 output.medication_2023 output.medication_2024;
run;

*Keep master_patient_id in my cohort;
proc sql;
	create table output.medication_cohort as
	select *
	from stacked_medic
	where master_patient_id in (select master_patient_id from output.condition_analytic_sample);
quit;

*Subset medication records to STRIDE intervention periods;
data medic_stride;
	set output.medication_cohort;
	if "18jan2022"d<=date_medic<="17jan2024"d;
run;

*Divide the pre- and post-STRIDE samples;
data pre_stride post_stride;
	set output.condition_analytic_sample;
	if period_master="Pre-STRIDE" then output pre_stride;
	else if period_master="Post-STRIDE" then output post_stride;
run;

*Pre-STRIDE calculations;

*Merge all medication records to the pre-STRIDE cohort;
proc sql;
	create table pre_all as
	select *
	from pre_stride as a
	left join medic_stride (where= ("18jan2022"d<=date_medic<="17jan2023"d)) as b
	on a.master_patient_id=b.master_patient_id
	order by master_patient_id;
quit;

*Create indicators for ever administered insulin or sulfonylureas during the pre-STRIDE period;
proc sql;
	create table pre_prev as 
	select distinct master_patient_id, max(flag_insulin) as max_flag_insulin, max(flag_sulfonylurea) as max_flag_sulfonylurea,
	sum(flag_insulin) as count_insulin, sum(flag_sulfonylurea) as count_sulfonylurea, days_stay_total
	from pre_all
	group by master_patient_id;
quit;

proc freq data=pre_prev;
	tables max_flag_insulin max_flag_sulfonylurea/missing;
	title "Prevalence of glucose-loweing medication use Pre-STRIDE intervention";
run;

*Post-STRIDE calculations;

*Merge all medication records to the post-STRIDE cohort;
proc sql;
	create table post_all as
	select *
	from post_stride as a
	left join medic_stride (where= ("18jan2023"d<=date_medic<="17jan2024"d)) as b
	on a.master_patient_id=b.master_patient_id
	order by master_patient_id;
quit;

*Create indicators for ever administered insulin or sulfonylureas during the post-STRIDE period;
proc sql;
	create table post_prev as 
	select distinct master_patient_id, max(flag_insulin) as max_flag_insulin, max(flag_sulfonylurea) as max_flag_sulfonylurea,
	sum(flag_insulin) as count_insulin, sum(flag_sulfonylurea) as count_sulfonylurea, days_stay_total
	from post_all
	group by master_patient_id;
quit;

proc freq data=post_prev;
	tables max_flag_insulin max_flag_sulfonylurea/missing;
	title "Prevalence of glucose-loweing medication use post-STRIDE intervention";
run;

*Stack pre and post prev datasets and recode missing for max_flag_insulin, max_flag_sulfonylurea, count_insulin,
count_sulfonylurea to 0;
data output.pre_post_prev;
	length period_master $15;
	set pre_prev (in=a) post_prev (in=b);
	if max_flag_insulin=. then max_flag_insulin=0;
	if max_flag_sulfonylurea=. then max_flag_sulfonylurea=0;
	if count_insulin=. then count_insulin=0;
	if count_sulfonylurea=. then count_sulfonylurea=0;

	if a=1 then period_master="Pre-STRIDE";
	else period_master="Post-STRIDE";

	if max_flag_insulin=1 or max_flag_sulfonylurea=1 then combined_meds=1; else combined_meds=0;
	count_combined_meds=sum(count_insulin,count_sulfonylurea); 
	log_pt=log(days_stay_total);
run;


proc freq data=output.pre_post_prev;
	tables combined_meds max_flag_insulin max_flag_sulfonylurea/list ;
run;

ods html;

*Insulin risk ratio;
proc genmod data=output.pre_post_prev desc;
	class master_patient_id period_master (ref="Pre-STRIDE")/param=ref ;
	model max_flag_insulin =period_master /link=log dist=bin;
	repeated subject=master_patient_id/type=ind;
	estimate "Comparing  Post- to Pre-STRIDE" period_master  1/exp;
	lsmeans period_master/ilink cl;
run;

*Insulin risk difference;
proc genmod data=output.pre_post_prev desc;
	class master_patient_id period_master (ref="Pre-STRIDE")/param=ref ;
	model max_flag_insulin =period_master /link=identity dist=bin;
	repeated subject=master_patient_id/type=ind;
/*	estimate "Comparing  Post- to Pre-STRIDE" period_master  1/exp;*/
run;

*Sulfonylurea risk ratio;
proc genmod data=pre_post_prev desc;
	class master_patient_id period_master (ref="Pre-STRIDE")/param=ref ;
	model max_flag_Sulfonylurea =period_master /link=log dist=bin;
	repeated subject=master_patient_id/type=ind;
	estimate "Comparing  Post- to Pre-STRIDE" period_master  1/exp;
/*	lsmeans period_master/ilink cl;*/
run;

*Sulfonylurea risk difference;
proc genmod data=pre_post_prev desc;
	class master_patient_id period_master (ref="Pre-STRIDE")/param=ref ;
	model max_flag_Sulfonylurea =period_master /link=identity dist=bin;
	repeated subject=master_patient_id/type=ind;
/*	estimate "Comparing  Post- to Pre-STRIDE" period_master  1/exp;*/
run;

*Combined_meds risk ratio;
proc genmod data=pre_post_prev desc;
	class master_patient_id period_master (ref="Pre-STRIDE")/param=ref ;
	model Combined_meds =period_master /link=log dist=bin;
	repeated subject=master_patient_id/type=ind;
	estimate "Comparing  Post- to Pre-STRIDE" period_master  1/exp;
/*	lsmeans period_master/ilink cl;*/
run;

*Combined_meds risk difference;
proc genmod data=pre_post_prev desc;
	class master_patient_id period_master (ref="Pre-STRIDE")/param=ref ;
	model Combined_meds =period_master /link=identity dist=bin;
	repeated subject=master_patient_id/type=ind;
/*	estimate "Comparing  Post- to Pre-STRIDE" period_master  1/exp;*/
run;

proc sort data=pre_post_prev;
	by period_master;
run;
