#!
import pandas as pd
from pandas.tseries.offsets import DateOffset

path = 'C:/Users/edavis67/OneDrive - DXC Production/Documents/' \
    'Industrialized AI Badge/Guild_Project/'

with open(path + 'output.csv', 'r') as op:
    lines = op.readlines()
    keys = [i.strip() for i in lines[0].split(", ")][:6]
    keys = [key for key in keys[:6] if key != 'zip_code']
    fmtLines = []
    errLines = []
    for line in lines[1:]:
        ln = line.split(", ")
        date = ln[0] + ", "+ ln[1]
        addr = ln[3]
        price = ln[4]
        lon = float(ln[5])
        lat = float(ln[6])
        values = [date, addr, price, lon, lat]
        fmtLines.append(dict(zip(keys, values)))

df = pd.DataFrame.from_dict(fmtLines)
df['amount'] = df['amount'].str.replace('[\,, \$]', '').astype('float')
df['address'] = df['address'].str.replace('.', '').str.replace(',', '')

date1 = pd.to_datetime(df['date'],
    format = "%B %d, %Y", exact = False, errors = 'coerce')
date2 = pd.to_datetime(df['date'],
    format = "%b. %d, %Y", exact = False, errors = 'coerce')
df['date'] = pd.Series(date1).fillna(value = date2)
df['L1Month'] = df.date - DateOffset(months = 1)
df['L1Month'] = pd.to_datetime(df['L1Month'],
    format = "%Y-%m-%d", unit = 'D',
    exact = False, errors = 'coerce')
df['L1Year'] = df.L1Month - DateOffset(years = 1)
df['L1Year'] = pd.to_datetime(df['L1Year'],
    format = "%Y-%m-%d", unit = 'D',
    exact = False, errors = 'coerce')

df = df[df.L1Month > '2012-02-01']
df = df[df[['address', 'L1Month', 'L1Year', 'longitude', 'latitude']]
    .notna().all(axis = 'columns')]
df = df.drop_duplicates(subset = ['address', 'date']).sort_values(by = 'date')
df.to_parquet(path + 'property.parquet')
