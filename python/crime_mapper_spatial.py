import pandas as pd
import os
from os.path import join
import numpy as np
import geopandas as gpd

def crime_func(prop):
    yr_range = {'low':str(pd.Timestamp(prop['L1Year']).year),
                'high':str(pd.Timestamp(prop['L1Month']).year)}
    path = "C:/Users/edavis67/OneDrive - DXC Production/Documents/" \
        "Industrialized AI Badge/Guild_Project"
    lo = pd.read_parquet(join(
        path, 'CFS', 'CFS-' + yr_range['low'] + '.parquet'))
    hi = pd.read_parquet(join(
        path, 'CFS', 'CFS-' + yr_range['high'] + '.parquet'))
    cdf = pd.concat([lo, hi])

    cdf['call_date'] = pd.to_datetime(cdf['timecreate'],
        format = "%Y-%m-%d", exact = False, errors = 'coerce')
    cdf['call_date'] = cdf['call_date'].dt.tz_localize(None)
    cdf = cdf[cdf['call_date'].lt(prop['L1Month']) &
        cdf['call_date'].gt(prop['L1Year'])]
    cdf = gpd.GeoDataFrame(cdf, crs = 'EPSG:4326',
        geometry = gpd.points_from_xy(cdf.longitude, cdf.latitude))
    cdf['distance'] = cdf['geometry'].distance(prop['geometry'])

    xdf = cdf[cdf['distance'] < 0.002]
    xdf = xdf.pivot_table(index = 'typetext', aggfunc = 'count', fill_value = 0)
    xdf = xdf.T.apply('max')
    xdf.index = xdf.index.rename(None)
    if len(xdf) < 1 :
        return prop
    return prop.append(xdf)

def main():
    path = "C:/Users/edavis67/OneDrive - DXC Production/Documents/" \
        "Industrialized AI Badge/Guild_Project"
    pdf = gpd.read_file(join(path, "property.geojson"))
    df = pdf[:100].apply(crime_func, axis = 1)
    return df.to_excel(join(path, 'sample.xlsx'))

if __name__ == '__main__':
    main()
