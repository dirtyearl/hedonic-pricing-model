import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions
from os.path import join
import pandas as pd

class CrimesRead(beam.DoFn):
    def crime_year(self, element):
        yr_range = {'low':str(pd.Timestamp(element['L1Year']).year),
                    'high':str(pd.Timestamp(element['L1Month']).year)}
        lo = pd.read_parquet(join(
            path, 'CFS', 'CFS-' + yr_range['low'] + '.parquet'))
        hi = pd.read_parquet(join(
            path, 'CFS', 'CFS-' + yr_range['high'] + '.parquet'))
        cdf = pd.concat([lo, hi])
        cdf['call_date'] = pd.to_datetime(cdf['timecreate'],
            format = "%Y-%m-%d", exact = False, errors = 'coerce')
        cdf['call_date'] = cdf['call_date'].dt.tz_localize(None)
        cdf = cdf[cdf['call_date'].lt(element['L1Month']) &
            cdf['call_date'].gt(element['L1Year'])]
        return cdf

def main():
    path = "C:/Users/edavis67/OneDrive - DXC Production/Documents/" \
        "Industrialized AI Badge/Guild_Project"
    pdf = pd.read_parquet(join(path, "property.parquet"))
    # Apply a ParDo to the PCollection "pdf" to compute crimes list.
    df = pdf | beam.ParDo(CrimesRead())
    return df

if __name__ == '__main__':
    main()
