from cohortextractor import (
    StudyDefinition,
    codelist,
    codelist_from_csv,
    combine_codelists,
    filter_codes_by_category,
    patients
)


start_date = '2016-01-01'
end_date = '2021-09-30'

study = StudyDefinition(
    
    population=patients.all(),
    
    default_expectations={
        "date": {"earliest": start_date, "latest": end_date},
        "rate": "uniform"
    },

    sex=patients.sex(
        return_expectations={
            "category": {"ratios": {"M": 0.49, "F": 0.51}},
            "incidence": 1
            }),
    
    cmd=patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/ons-cmd-codes.csv',
            system='snomed',
            column='code'
            ),
        between=[start_date, end_date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.05
        })   
)
