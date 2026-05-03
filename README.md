# Munshi_Deprescribing_Diabetes_in_LTC_Residents_with_ADRD
Munshi et al. -A Pragmatic Education Approach for Deprescribing Diabetes Treatment Regimens in Long-Term Care (LTC) Residents with Alzheimer’s Disease and Related Dementias (ADRD)

Data Documentation

The data_documentation/ directory contains the following files:
Data_Documentation_STRIDE_GH.xlsx - Data dictionary listing all variables used in the analysis, including definitions for stay construction, medication indicators, person-time, and analytic variables for pre- and post-intervention comparisons.

Code

The code/ directory contains the following programs:
1-Calculate_person_time_in_LTCF_GH.sas - Constructs analytic stay episodes from LTCF stay data, resolves overlapping stays, assigns observations to pre- and post-STRIDE periods, and calculates person-time (in days) for each resident-period.
2-Medication_administrations_GH.sas - Identifies insulin and sulfonylurea administrations from raw eMAR data, and generates medication-level indicators and counts.
3-Prevalence_of_medications_GH.sas - Estimates the prevalence (risk) of insulin, sulfonylurea, and combined medication use in pre- and post-STRIDE periods.
4-Rate_differences_and_confidence_intervals.sas - Calculates rates of medication administrations using person-time denominators and estimates rate differences and rate ratios comparing post- vs pre-STRIDE periods. Confidence intervals for rate differences are obtained using percentile bootstrap resampling.

Programs were run in sequence to produce the study findings.
