from bs4 import BeautifulSoup as bs
from urllib.request import urlopen as ureq
import pandas as pd
import csv

pages=[]
##parsing the web pages##
pages =["https://nordc.org/parks/"]

##next pages##
for i in range(2,7):      # Number of pages plus one
  url2 = "https://nordc.org/parks/"+ '?page='+str(i)
  pages.append(url2)
#print(pages)
##create a list##
records = []
##for loop to grab Name and address of each parks##
for item in pages:
    page = ureq(item)
    page_html = page.read()
    page.close()
    soup = bs(page_html, 'html.parser')
    containers = soup.find_all("div", {"class": "media-body"})
    container = containers[0]

    for container in containers:
     park_name = container.h4.a.text
     address = container.text
     address = address.replace("   ","")
     address = address.replace("\n", "")
     address = address.replace("\r","")
     records.extend([park_name,address])
    #print(records)
##create a datafreame ##
data = [x.split(', ') for x in records]
#print(data)

def altElement1(a):
  return a[::2]
Name = altElement1(data)
#print(Name)
def altElement2(a):
  return a[1::2]
Address = altElement2(data)
#print(Address)
df1 =pd.DataFrame(Name)
df1.columns=["Name"]
#print(df1)
df2 = pd.DataFrame(Address)
df2.columns=["Address"]
#print(df2)
result = pd.concat([df1, df2], axis=1, sort=False)
#print(result)

##converting dataframe to csv ##
result.to_csv('parks_info.csv')

























#source= requests.get('https://nordc.org/parks/').text
#soup= bs(source,'lxml')
#print(soup.prettify())
#grabing all the park name and address
#containers = soup.find_all("div",{"class": "media-body"})
#print(containers)
#print(len(containers))
#container = containers[0]

#writing the parsed data into a csv file

#csv_file = open('parks_info.csv', "w")
#fieldnames = ['Name','Adress']
#csv_writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
#csv_writer.writeheader()
#csv_writer.writerow(['Name','Adress'])
  #fieldnames = ['Name','Adress']
 # thewriter = csv.DictWriter(f,fieldnames=fieldnames)
  #thewriter.writeheader()
#filename = "Park_info.csv"
#f = open(filename, "w")
#headers = "Park Name, Address \n"
#f.write(headers)
#print(container.text)


#records = []
#with open('parks_info.csv', "w",newline='') as f:
 #csv_writer = csv.writer(f)

# with open('parks_info.csv', 'w') as myfile:
#  wr = csv.writer(myfile, quoting=csv.QUOTE_ALL)
#  wr.writerow(["Name","Address"])
#  for container in containers:
#   park_name = container.h4.a.text
#   address = container.text
#   address = address.replace("   ","")
  #address = address.replace("\n", "")
  #records = [park_name, address]
  #print(records)
  #wr.writerow(records)
#myfile.close()

  #print (park_name)
  #print (address)

  #records.append(( park_name,address))
  #print (records)


#import pandas as pd
#df= pd.DataFrame(records,columns=["Name","Address"])
#df.to_csv("Parks_info.csv",index=False,encoding= 'utf-8')




  #print(park_address.replace(" ",""))
  #thewriter.writerow({'Name': park_name,'Address': address})
  #csv_writer.writerow({'Name': park_name,'Address': park_address})
#csv_file.close()