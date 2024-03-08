# -*- coding: utf-8 -*-

import pandas as pd
import numpy as np

def filter_df(path, year):
    df = pd.read_csv(path + "/CFS/Data/csv/Calls.for.Service." \
    + str(year) + ".csv")

    def loc_to_tuple(arg, arg_type):
        if pd.isnull(arg):
            return np.nan
        lat, lon = eval(arg)
        return {0: lat, 1: lon}.get(arg_type, np.nan)

    df['latitude'] = df.location.map(lambda x: loc_to_tuple(x, 0))
    df['longitude'] = df.location.map(lambda x: loc_to_tuple(x, 1))
    df.drop(labels = 'location', axis = 1, inplace = True)
    keep = df.dispositiontext.isin([
        "REPORT TO FOLLOW", "Necessary Action Taken", "GONE ON ARRIVAL"])
    return df[keep]

if __name__ == '__main__':
    write_path = "C:/Users/edavis67/OneDrive - DXC Production" \
        "/Documents/Industrialized AI Badge/Guild_Project"
    read_path = "C:/Users/edavis67/DXC Production/Industrialized " \
        "AI Open Badge Academy Boot Camp 3.13.19-4.17.19 - AI Guild 49 - UTC -6"
    for yr in range(2011, 2020):
        df = filter_df(read_path, yr)
        df.to_parquet(write_path + "/CFS/CFS-" + str(yr) + ".parquet")
