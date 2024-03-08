import pandas as pd
import os
import shutil
from os.path import join
import numpy as np
import geopandas as gpd
###############################################################################
def amenityMapper(addr):
    # addr = pdf.loc[0]
    gpath = join(path, 'data/formatted')
    amenityCount = {x.split('.')[0]:0 for x in os.listdir(join(gpath))}
    for x in os.listdir(gpath):
        df = gpd.read_file(filename = join(gpath, x))
        name = x.split('.')[0]
        df['distance'] = df['geometry'].distance(addr['geometry'])
        cnt = len(df.index[df['distance'] < 0.002])
        amenityCount.update({name:cnt})
    result = dict(addr)
    result.update(amenityCount)
    return pd.Series(result, index = result.keys()).T
###############################################################################
def main():
    pdf = gpd.read_file(join(path, "property.geojson"))
    amen = pdf[:100].apply(amenityMapper, axis = 1)
    amen.to_excel(join(path, 'amenity_sample.xlsx'))
    # amen.crs = 'EPSG:4326'
    # amen.to_file(join(path, 'data/amenity_df.geojson'),
    #     driver = 'GeoJSON', encoding = 'UTF8', crs = 'EPSG:4326')
###############################################################################
if __name__ == '__main__':
    path = "C:/Users/edavis67/OneDrive - DXC Production/Documents/" \
            "Industrialized AI Badge/Guild_Project"
    main()

# import fiona; help(fiona.open)
