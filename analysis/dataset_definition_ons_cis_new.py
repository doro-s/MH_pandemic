from databuilder.ehrql import Dataset
from databuilder.tables.beta import tpp as schema


#######################################################################################
# Define study dates 
#######################################################################################

start_date = '2020-01-24'
end_date = '2022-03-31'
n_visits = 26

dataset = Dataset()

#######################################################################################
# Set population
# Filter ONS CIS table to visit dates between the study start and end dates (inclusive) 
# and set the population to only patients who have at least one visit date in study date
# range
#######################################################################################

ons_cis = schema.ons_cis.take(schema.ons_cis.visit_date.is_on_or_between(start_date, end_date))
dataset.set_population(ons_cis.exists_for_patient())

def create_sequential_variables(
    dataset, variable_name_template, events, column, num_variables, sort_column=None, start=0
):
    """
    This function generates a series of sequential variables (a number specified by num_variables)
    `variable_name_template` is a string that includes the template {n}, used for naming
    the variables.  Variables will contain the same template name plus a number, starting at
    0 by default.    
    e.g. 
    create_sequential_variables(
        dataset,
        variable_name_template="var_{n}",
        num_variables=2,
        ...
    )
    will add 2 variables to the dataset,
    `dataset.var_0`
    `dataset.var_1`

    To label the variables starting at 1 instead of 0, call the function with start=1, i.e.
    create_sequential_variables(
        dataset,
        variable_name_template="var_{n}",
        num_variables=2,
        ...
        start=1
    )
    will add 2 variables to the dataset,
    `dataset.var_1`
    `dataset.var_2`
    """
    sort_column = sort_column or column
    # Define later_events initially as the full set of events
    later_events = events
    for index in range(num_variables + start):
        # Each iteration through this loop creates the next variable by sorting `later_events`
        # and taking the first row for each patient
        next_event = later_events.sort_by(getattr(events, sort_column)).first_for_patient()
        variable_name = variable_name_template.format(n=index)
        # set the variable on the dataset by getting the desired column from the event row
        setattr(dataset, variable_name, getattr(next_event, column))

        # Now later_events is redefined for the next iteration by filtering to those that
        # are AFTER the event we just found
        later_events = events.take(
            getattr(events, sort_column) > getattr(next_event, sort_column)
        )


#######################################################################################
# Define variables
# Create n_visits sequential variables for the ONS CIS columns of interest
#######################################################################################
ons_cis_columns = [
    "visit_date", 
    "visit_num", 
    "last_linkage_dt", 
    "is_opted_out_of_nhs_data_share"
]
for column_name in ons_cis_columns:
    create_sequential_variables(
        dataset,
        column_name + "_{n}",
        num_variables=n_visits,
        events=ons_cis,
        column=column_name,
        sort_column="visit_date",
    )
