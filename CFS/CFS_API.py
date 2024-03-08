




import pandas as pd
from sodapy import Socrata
import pymongo
import json
# 'https://data.nola.gov/resource/qf6q-pp4b.json'
# 'https://data.nola.gov/resource/qf6q-pp4b.geojson'
client = Socrata('data.nola.gov', None)
results = client.get('qf6q-pp4b', content_type = 'geojson', limit = 50000)
print(results.keys())
results['type']
results['features'][0]
results['crs']
uri = "mongodb://noladata:cwzxKF8a2kRgpG8tHiNZGs34Z5b4jAisQKJJBj8e8MJavd1z7ZtIY98CqiqPa6UOntSwj7rot0t4tBYHWNLrlw==@noladata.documents.azure.com:10255/?ssl=true&replicaSet=globaldb"
client = pymongo.MongoClient(uri)
# client = pymongo.MongoClient('mongodb://localhost:27017/')
# client = pymongo.MongoClient("mongodb+srv://<username>:<password>@<cluster-url>/test?retryWrites=true&w=majority")

db = client.CFS
collection = db['2019']

data = json.dumps(results['features'])
type(data)
data = json.loads(data)
for i in range(len(data)):
    db['2019'].insert_one(data[i])

int(db['201908'].count_documents({}))
