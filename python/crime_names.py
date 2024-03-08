import pandas as pd
import os
from os.path import join, exists
import numpy as np
###############################################################################
namen = pd.read_csv(join('./', 'CFS', 'CFS_names_big.csv'),
    usecols = ['old_names', 'consolidated_name', 'new_name'])
namen.rename(columns = {'old_names':'old_name',
    'consolidated_name':'cons_name'}, inplace = True)
namen['new_name'] = namen['new_name'].apply(lambda i: i.replace(' ', '_'))
namen['new_name'] = namen['new_name'].apply(lambda i: i.replace('-', ''))
cons_name = namen['cons_name'][namen['cons_name'].notna()].unique()
###############################################################################
path = 'C:/Users/edavis67/OneDrive - DXC Production/Documents/' \
    'Industrialized AI Badge/Guild_Project'
for yr in range(2011, 2020):
    fpath = join(path, 'CFS', 'CFS-' + str(yr) + '.parquet')
    if os.path.exists(fpath):
        next
    df = pd.read_parquet(fpath)
    for n in cons_name:
        nm = namen['old_name'][namen['new_name'] == n]
        df.loc[df['typetext'].isin(nm), 'typetext'] = n
    df.to_parquet(fpath)
