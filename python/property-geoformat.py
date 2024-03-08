import pandas as pd
from pandas.tseries.offsets import DateOffset
import os
import geopandas as gpd

path = "C:/Users/edavis67/OneDrive - DXC Production/Documents/" \
        "Industrialized AI Badge/Guild_Project"
prop_path = os.path.join(path, "property.parquet")
df = pd.read_parquet(prop_path)
pdf = gpd.GeoDataFrame(pdf, crs = 4326,
    geometry = gpd.points_from_xy(pdf.longitude, pdf.latitude))
pdf = pdf.drop(['longitude', 'latitude'], axis = 1)
pdf.to_file(os.path.join(path, "property.geojson"), driver = 'GeoJSON')
