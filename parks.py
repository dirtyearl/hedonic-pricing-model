#!/usr/bin/env python
# coding: utf-8

from bs4 import BeautifulSoup
from urllib.request import urlopen, HTTPError
import lxml
import pandas as pd
import re
import random
from time import sleep

# df.to_csv('parks.csv', header = False)
# df_dict = {k:v for (v,k) in kv}
# names = [re.sub('["<>"]','',i[1]) for i in df_str]
# values = [i[0] for i in df_str]

def address_finder(addr):
    try: vbs = BeautifulSoup(urlopen('https://nordc.org/parks/' + addr), 'lxml')
    except HTTPError:
        print("Missing {0}".format(addr))
        return None
    except:
        return None
    vdf = [str(i) for i in vbs.find_all('strong')][0]
    vdf = re.sub(' +',' ', vdf)
    vdf = re.sub('<strong>||</strong>||<br/>\r\n||amp;','', vdf)
    print(addr + "|" + vdf)
    sleep(random.uniform(0.5, 2))
    return vdf

if __name__ == '__main__':
    bs = BeautifulSoup(urlopen('https://nordc.org/parks/'), 'lxml')
    df = [str(i) for i in bs.find_all(['li', 'a'])]
    df_str = [i.split(sep='/')[2:4] for i in df][17:231]
    nm = set((i[0],re.sub('["<>"]','',i[1])) for i in df_str)

    addr_list = {str(key):address_finder(value) for (value,key) in nm}
    df = pd.DataFrame.from_dict(addr_list, orient='index')
    df.to_csv('./park_addr.csv')
