from bs4 import BeautifulSoup
import requests
import pandas as pd
import time

results=[]
page_num=1

while len(results) <= 1000:
    print(page_num)
    page=requests.get('https://grabcad.com/engineers/category/3d-printing?page={}&sort=score&time=all'.format(page_num))
    soup = BeautifulSoup(page.text, 'html.parser')
    els=soup.find_all(class_='member-details')
    for el in els:
        name=el.find_all('h3')[0].get_text().strip()
        url='https://grabcad.com'+el.find_all('h3')[0].find_all('a')[0]['href']
        location=el.find_all(class_='member-details__location content-block')[0].get_text().strip()
        location=location.split(', ')
        try:
            city,country=location[0],location[1]
        except:
            city,country='',''

        details=requests.get(url)
        soup_detail=BeautifulSoup(details.text, 'html.parser')
        models=int(soup_detail.find(class_='responsive-tabs__tab--badge').get_text().strip())
        _,downloads,views,followers,_,comments,created=[i.find('td').get_text().strip() for i in soup_detail.find(class_='sidebar__table sidebar__table--alt').find_all('tr')]

        if models > 0:
            m=requests.get(url+'/models')
            soup_m=BeautifulSoup(m.text, 'html.parser')
            recent_m=requests.get('https://grabcad.com/community/api/v1/models/'+soup_m.find(class_='profile-tile__link')['href'].split('/')[-1])
            last_object=recent_m.json()['created_at']
        else:
            last_object=''

        results.append([name,city,country,location,followers,models,int(downloads),int(views),int(followers),int(comments),created,last_object])

    page_num+=1

results=pd.DataFrame(results,columns=['Designer','City','Country','Location','# Followers','# Models','# Downloads','# Views','# Followers','# Comments','Date created','Date of last object'])

result.to_csv('grabcad_designer.csv')