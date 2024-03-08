import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions

import pandas as pd
import os
from os.path import join
import numpy as np
import geopandas as gpd

# The DoFn to perform on each element in the input PCollection.
class CrimesFind(beam.DoFn):
    def crime_func(self, element):
        cdf = gpd.GeoDataFrame(cdf, crs = 'EPSG:4326',
            geometry = gpd.points_from_xy(cdf.longitude, cdf.latitude))
        cdf['distance'] = cdf['geometry'].distance(element['geometry'])

        xdf = cdf[cdf['distance'] < 0.002]
        xdf = xdf.pivot_table(index = 'typetext', aggfunc = 'count', fill_value = 0)
        xdf = xdf.T.apply('max')
        xdf.index = xdf.index.rename(None)
        if len(xdf) < 1 :
            return element
        return element.append(xdf)


def main():
    path = "C:/Users/edavis67/OneDrive - DXC Production/Documents/" \
        "Industrialized AI Badge/Guild_Project"
    pdf = gpd.read_file(join(path, "property.geojson"))
    # Apply a ParDo to the PCollection "pdf" to compute crimes list.
    df = pdf | beam.ParDo(CrimesFind())
    return df

if __name__ == '__main__':
    main()
