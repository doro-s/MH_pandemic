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

#######################################################################################
# Define variables
# Create n_visits sequential variables for the ONS CIS columns of interest
#######################################################################################


def get_sequential_events(events, num_events, column_name):
    sort_column = getattr(events, column_name)
    previous_date = None
    for _ in range(num_events):
        if previous_date is not None:
            later_events = events.take(sort_column > previous_date)
        else:
            later_events = events
        next_event = later_events.sort_by(sort_column).first_for_patient()
        yield next_event
        previous_date = getattr(next_event, column_name)


visits = get_sequential_events(ons_cis, 26, "visit_date")
for n, visit in enumerate(visits):
    setattr(dataset, f"visit_date_{n}", visit.visit_date)
    setattr(dataset, f"visit_num_{n}", visit.visit_num)
    setattr(dataset, f"last_linkage_dt_{n}", visit.last_linkage_dt)
    setattr(dataset, f"is_opted_out_of_nhs_data_share_{n}", visit.is_opted_out_of_nhs_data_share)
