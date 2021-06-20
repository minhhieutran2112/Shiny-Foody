# GET POPULAR OBJECT THE PAST YEAR

webdriver_path = r'C:\Users\minhh\Downloads\Compressed\chromedriver_win32\chromedriver.exe' # change this 
username_text='shaiya2112'
password_text='metmoivcl123'

from seleniumwire import webdriver 
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
import time
import json
import requests
import pandas as pd

def get_token(username_text,password_text):
    options = webdriver.ChromeOptions()
    options.headless = True
    options.add_argument("user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.163 Safari/537.36")

    # Go to the login page
    print('Initiating webdriver')
    driver = webdriver.Chrome(executable_path=webdriver_path,chrome_options=options)
    driver.get('https://accounts.thingiverse.com/')

    # login
    email = WebDriverWait(driver, 3600).until(EC.presence_of_element_located((By.CSS_SELECTOR, '#username')))
    password = WebDriverWait(driver, 3600).until(EC.presence_of_element_located((By.CSS_SELECTOR, '#password')))
    ## Fill in the form
    email.send_keys(username_text)
    password.send_keys(password_text)
    ## Submit credential
    password.send_keys(Keys.ENTER)
    print('Logged in')

    print('Sleeping')
    time.sleep(10)
    print('Wake up')

    # Get token
    token=''
    for request in driver.requests:
        if request.response and request.url == 'https://www.thingiverse.com/ajax/user/exchange_session_for_token':
            token=request.response.body
            token=json.loads(token.decode('utf8').replace("'", '"'))['token']
            print(f'Found token {token}')
            break

    driver.quit()

    return token

token=get_token('shaiya2112','metmoivcl123')

types=['things','users','makes']
params={
    'thing':{
        'sort':['popular','newest','makes'],
        'posted_after':['now-7d','now-30d','now-365d'],
        'category_id':[]
    },
    'users':{
        'sort':['followers','designs','make']
    },
    'makes':{
        'sort':['popular','newest']
    }
<<<<<<< HEAD
=======
}

things=requests.get(
    'https://api.thingiverse.com/search/?page=1&per_page=20&sort=popular&posted_after=now-1y&type=things',
    headers={
        'authorization':'Bearer ' + token
    }
>>>>>>> 3c468fd0412208b590152052f7616334fe0bcb94
)

result={}
for obj in things.json()['hits']:
    for key,value in obj.items():
        if type(value)!=dict:
            result[key]=result.get(key,[])+[value]
        else:
            for k,v in value.items():
                result[key+'_'+k]=result.get(key+'_'+k,[])+[v]

result=pd.DataFrame(result)