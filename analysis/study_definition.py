from cohortextractor import (
    StudyDefinition,
    codelist,
    codelist_from_csv,
    combine_codelists,
    filter_codes_by_category,
    patients
)

from codelists import *

start_date = '2020-01-24'
end_date = '2021-09-30'
n_years = str(5)

study = StudyDefinition(

    default_expectations={
        "date": {"earliest": "1900-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 0.5
    },

    population=patients.all(),

    # Date of death, any reason
    dod=patients.died_from_any_cause(
        on_or_before=end_date,
        returning='date_of_death',
        date_format='YYYY-MM-DD',
        return_expectations={
            "date" : {"earliest" : start_date, "latest" : end_date}
        }
    ),

    # Date of earliest hospitalisation from Covid
    hes_admission=patients.admitted_to_hospital(
        on_or_before=end_date,
        returning='date_admitted',
        find_first_match_in_period=True,
        date_format='YYYY-MM-DD',
        with_these_primary_diagnoses=codelist_from_csv(
            'codelists/opensafely-covid-identification.csv',
            system='icd10',
            column='icd10_code'
        ),
        return_expectations={
            "date" : {"earliest": start_date, "latest": end_date}
        }
    ),

    # Date of earliest +ve test and trace result
    tt_positive=patients.with_test_result_in_sgss(
        pathogen='SARS-CoV-2',
        test_result='positive',
        on_or_before=end_date,
        returning="date",
        date_format="YYYY-MM-DD",
        restrict_to_earliest_specimen_date=True,
        return_expectations={
            "date" : {"earliest": start_date, "latest": end_date}
        }
    ),

    # Date of 1st Covid vaccine
    covid_vaccine=patients.with_tpp_vaccination_record(
        target_disease_matches="SARS-2 CORONAVIRUS",
        on_or_before=end_date,
        returning="date",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date" : {"earliest": start_date, "latest": end_date}
        }
    ),

    # # Date of earliest +ve cis result
    
    # TODO, this is incorrect for now, but leaving in
    # to enable dynamic dates elsewhere. Returns 1st visit date
    # per person for now
    cis_positive=patients.with_an_ons_cis_record(
        returning='visit_date',
        on_or_before=end_date,
        find_first_match_in_period=True,
        date_format='YYYY-MM-DD',
        date_filter_column='visit_date',
        return_expectations={
            "date" : {"earliest": start_date, "latest": end_date}
        }
    ),
    
    ### Derive comorbidities ###
    
    alcohol=patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/opensafely-hazardous-alcohol-drinking.csv',
            system='ctv3',
            column='code'
        ),
        between=['cis_positive - ' + n_years + ' years', 'cis_positive'],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            'rate' : 'uniform'
        }
    ),
    
    # TODO - obesity
    
    cancer=patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/user-jkua-cancer.csv',
            system='ctv3',
            column='code'
        ),
        between=['cis_positive - ' + n_years + ' years', 'cis_positive'],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            'rate' : 'uniform'
        }
    ),
    
    CVD_ctv3=patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/ons-cardiovascular-disorders.csv',
            system='ctv3',
            column='code'
        ),
        between=[f'cis_positive - {n_years} years', 'cis_positive'],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.1
            }
    ),
    
    CVD_snomed=patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/nhsd-primary-care-domain-refsets-angina_cod.csv',
            system='snomed',
            column='code'
        ),
        between=[f'cis_positive - {n_years} years', 'cis_positive'],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.1
            }
    ),
    
    hiv_aids=patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/opensafely-hiv-snomed.csv',
            system='snomed',
            column='id'
        ),
        between=[f'cis_positive - {n_years} years', 'cis_positive'],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.1
            }
    ),
    
    metabolic=patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/ons-metabolic-disorders.csv',
            system='ctv3',
            column='code'
        ),
        between=[f'cis_positive - {n_years} years', 'cis_positive'],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.1
            }
    ),
    
    musculoskeletal_ctv3=patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/ons-musculoskeletal-disorders.csv',
            system='ctv3',
            column='code'
        ),
        between=[f'cis_positive - {n_years} years', 'cis_positive'],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.1
            }
    ),
    
    musculoskeletal_snomed=patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/nhsd-primary-care-domain-refsets-osteo_cod.csv',
            system='snomed',
            column='code'
        ),
        between=[f'cis_positive - {n_years} years', 'cis_positive'],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.1
            }
    )
    
    # TODO - neurological disorders

    # Outcomes, 12 months forward from index date

)
