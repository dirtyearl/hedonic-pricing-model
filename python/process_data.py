import pandas as pd
import os
import shutil
from os.path import join
import numpy as np
import geopandas as gpd
###############################################################################
path = 'C:/Users/edavis67/OneDrive - DXC Production/Documents/' \
    'Industrialized AI Badge/Guild_Project'
park_df = pd.read_csv(join(path, 'data', 'Park.csv'))
park_df.rename(columns = {'latitude':'lon',
    'longitude':'lat', 'dataAddress':'addr'},
    inplace = True)
park_df = gpd.GeoDataFrame(park_df, crs = 'EPSG:4326',
    geometry = gpd.points_from_xy(park_df.lon, park_df.lat))
park_df = park_df.drop(['Unnamed: 0', 'lon', 'lat'], axis = 1)
park_df.to_file(join(path, 'data/formatted', 'parks.geojson'),
    driver = 'GeoJSON', encoding = 'UTF8', crs = 'EPSG:4326')
###############################################################################
for x in os.listdir(join(path, 'data/geojson')):
    # x = os.listdir(join(path, 'data/geojson'))[0]
    name = x.split('.')[0].lower().replace(' ','_')
    tmp = gpd.read_file(join(path, 'data/geojson', x))
    tmp = tmp[tmp['geometry'].notna()]
    tmp.columns = [i.lower() for i in tmp.columns]
    drop_col = tmp.columns.isin(["city", "state", "zip", "phonenumber", "suite",
        "locationy", "locationx", "segment"])
    tmp = tmp.drop(tmp.columns[drop_col], axis = 1)
    if name == 'restaurants':
        def switch(val):
            tab = {"1105 - FULL SVC RESTAURANTS (TABLE SERVICE)":"Full Svc Rest",
                "2062 - LIMITED SVC RESTAURANTS(NO TABLE SVC)":"Ltd Svc Rest",
                "1104 - FISH & SEAFOOD MARKETS":"Fish Mkt"}
            if val in tab.keys():
                return tab[val]
            return val
        tmp['businesstype'] = tmp['businesstype'].apply(switch)
    tmp.rename(columns = {'festivalname':'name', 'businessname':'name',
        'gardenfarmname':'name'}, inplace = True)
    tmp.rename(columns = {'festivaltype':'type','businesstype':'type'},
        inplace = True)
    tmp.to_file(join(path, 'data/formatted', name + '.geojson'),
        driver = 'GeoJSON', encoding = 'UTF8', crs = 'EPSG:4326')
