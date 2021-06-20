import sqlite3
db_path = r"C:\Users\minhh\Documents\MMF\Code\scraped_data_tmp.db" # Specify db path, this can be changed
webdriver_path = r'C:\Users\minhh\Downloads\Compressed\chromedriver_win32\chromedriver.exe' # change this 
# # if run on serer use this
# db_path = r"/home/scraped_data.db"
# webdriver_path = r'/usr/bin/chromedriver'
conn = sqlite3.connect(db_path)
cur = conn.cursor()
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, NoSuchElementException
import pandas as pd
import time
import random
import os
import requests
from datetime import date, timedelta

class SemRushProcessor():
    def __init__(self, username, password):
        self.username = username
        self.password = password
        self.result = []
        self.day_upper_bound = date.today() + timedelta(days=-1)
        self.day_lower_bound = date.today() + timedelta(days=-7)
        self.day_upper_bound = self.day_upper_bound.strftime('%b %d, %Y')
        self.day_lower_bound = self.day_lower_bound.strftime('%b %d, %Y')
        self.today = date.today().strftime('%#m/%#d/%Y')

    def wait_for_element(self, xpath, time=30):
        WebDriverWait(self.driver, time).until(EC.presence_of_element_located((By.XPATH, xpath)))

    def connect_to_semrush(self):
        # Add some options to our webdriver
        self.options = webdriver.ChromeOptions()
        self.options.headless = True
        self.options.add_argument("--disable-blink-features=AutomationControlled") # bypass cloudfare
        self.options.add_argument("--start-maximized")
        self.options.add_argument("no-sandbox")
        self.options.add_argument('disable-infobars')
        self.options.add_argument('--disable-extensions')
        self.options.add_argument("--window-size=1920,1080")
        self.options.add_argument('--no-proxy-server') 
        self.options.add_argument("--proxy-server='direct://'")
        self.options.add_argument("--proxy-bypass-list=*")
        self.options.add_argument('--ignore-certificate-errors')
        self.options.add_argument('--allow-running-insecure-content')
        self.options.add_argument("user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.163 Safari/537.36")
        # Initiate the session
        self.driver = webdriver.Chrome(executable_path=webdriver_path, chrome_options=self.options)
        self.driver.get(r'https://www.semrush.com/login/?src=header&redirect_to=%2Ftracking%2Foverview%2F4434160.html')
        time.sleep(10)
        # If we are logged in
        if self.driver.current_url.startswith('https://www.semrush.com/tracking/overview/4434160.html'):
            pass
        else: # Find the form to fill
            email_waiter = self.wait_for_element('//*[@id="loginForm"]/div[2]/div[2]/div/div/input')
            password_waiter = self.wait_for_element('//*[@id="loginForm"]/div[3]/div[2]/div/div/input')
            email = self.driver.find_element_by_css_selector('div._flex_llbyh_gg_:nth-child(3) > div:nth-child(2) > div:nth-child(1) > div:nth-child(1) > input:nth-child(1)')
            password = self.driver.find_element_by_css_selector('div._flex_llbyh_gg_:nth-child(4) > div:nth-child(2) > div:nth-child(1) > div:nth-child(1) > input:nth-child(1)')
            # Fill in the form
            email.send_keys(self.username)
            password.send_keys(self.password)
            # Submit credential
            password.send_keys(Keys.ENTER)
        try:
            self.wait_for_element('/html/body/div/div[3]/button',30)
            self.driver.find_element_by_xpath('/html/body/div/div[3]/button').click()
            self.div_element=3
        except TimeoutException:
            self.div_element=2
        time.sleep(3)
        # try:
        #     self.driver.execute_script("window.scrollBy(0, arguments[0]);", 5000)
        #     self.driver.find_element_by_xpath("/html/body/div[12]/div//*[local-name() = 'svg']").click()
        # except NoSuchElementException:
        #     pass
        # change the days range
        self.wait_for_element('//*[@id="react-page-container"]/div/div[2]/div[1]/div[2]/div/button'.format(self.div_element))
        self.driver.find_element_by_xpath('//*[@id="react-page-container"]/div/div[2]/div[1]/div[2]/div/button'.format(self.div_element)).click()
        self.driver.find_element_by_xpath('//*[@id="react-page-container"]/div/div[2]/div[1]/div[2]/div/div/div[2]/div[1]/input[1]'.format(self.div_element)).send_keys(Keys.BACK_SPACE*100)
        self.driver.find_element_by_xpath('//*[@id="react-page-container"]/div/div[2]/div[1]/div[2]/div/div/div[2]/div[1]/input[1]'.format(self.div_element)).send_keys(self.day_lower_bound)
        self.driver.find_element_by_xpath('//*[@id="react-page-container"]/div/div[2]/div[1]/div[2]/div/div/div[2]/div[1]/input[2]'.format(self.div_element)).send_keys(Keys.BACK_SPACE*100)
        self.driver.find_element_by_xpath('//*[@id="react-page-container"]/div/div[2]/div[1]/div[2]/div/div/div[2]/div[1]/input[2]'.format(self.div_element)).send_keys(self.day_upper_bound)
        self.driver.find_element_by_xpath('//*[@id="react-page-container"]/div/div[2]/div[1]/div[2]/div/div/div[2]/div[3]/button/div'.format(self.div_element)).click()
    
    def process_overview(self):
        self.wait_for_element('/html/body/div[{}]/main/div/div/div[3]/div[3]/div/div/div[2]/div[4]/div[3]/div[3]/div/div/div/div/div[1]/table/tbody/tr'.format(self.div_element))
        try:
            self.wait_for_element('//*[@id="react-page-container"]/div/div[2]/div[4]/div[3]/div[4]/nav/button[4]', 30)
            num_pages = int(self.driver.find_element_by_xpath('//*[@id="react-page-container"]/div/div[2]/div[4]/div[3]/div[4]/nav/button[4]').text)
            next_button = '//*[@id="react-page-container"]/div/div[2]/div[4]/div[3]/div[4]/nav/button[3]'
        except:
            num_pages = 1

        def process_overview_position(result):
            def process(result):
                time.sleep(3)
                self.wait_for_element('/html/body/div[{}]/main/div/div/div[3]/div[3]/div/div/div[2]/div[4]/div[3]/div[3]/div/div/div/div/div[1]/table/tbody/tr'.format(self.div_element))
                rows = self.driver.find_elements_by_xpath('/html/body/div[{}]/main/div/div/div[3]/div[3]/div/div/div[2]/div[4]/div[3]/div[3]/div/div/div/div/div[1]/table/tbody/tr'.format(self.div_element))
                for row in rows:
                    kw = row.find_element_by_xpath('td[3]').text
                    serp = len(row.find_elements_by_xpath('td[5]/div/div'))
                    mmf_pos = row.find_element_by_xpath('td[7]').text
                    cult3d_pos = row.find_element_by_xpath('td[10]').text
                    yeggi_pos = row.find_element_by_xpath('td[13]').text
                    thingiverse_pos = row.find_element_by_xpath('td[16]').text
                    all3dp_pos = row.find_element_by_xpath('td[19]').text
                    volumn = row.find_element_by_xpath('td[21]').text
                    cpc = row.find_element_by_xpath('td[22]').text
                    result.append([kw, serp, mmf_pos, cult3d_pos, yeggi_pos, thingiverse_pos, all3dp_pos, volumn, cpc])
                return result

            return process(result)

        def process_overview_other(result):
            def process(result):
                time.sleep(3)
                self.wait_for_element('/html/body/div[{}]/main/div/div/div[3]/div[3]/div/div/div[2]/div[4]/div[3]/div[3]/div/div/div/div/div[1]/table/tbody/tr'.format(self.div_element))
                rows = self.driver.find_elements_by_xpath('/html/body/div[{}]/main/div/div/div[3]/div[3]/div/div/div[2]/div[4]/div[3]/div[3]/div/div/div/div/div[1]/table/tbody/tr'.format(self.div_element))
                for row in rows:
                    kw = row.find_element_by_xpath('td[3]').text
                    serp = len(row.find_elements_by_xpath('td[5]/div/div'))
                    mmf_pos = row.find_element_by_xpath('td[6]').text
                    cult3d_pos = row.find_element_by_xpath('td[8]').text
                    yeggi_pos = row.find_element_by_xpath('td[10]').text
                    thingiverse_pos = row.find_element_by_xpath('td[12]').text
                    all3dp_pos = row.find_element_by_xpath('td[14]').text
                    volumn = row.find_element_by_xpath('td[16]').text
                    cpc = row.find_element_by_xpath('td[17]').text
                    result.append([kw, serp, mmf_pos, cult3d_pos, yeggi_pos, thingiverse_pos, all3dp_pos, volumn, cpc])
                return result

            return process(result)
        
        columns=['keyword','serp','mmf','cult3d','yeggi','thingiverse','all3dp','volumn','cpc']

        # first page #
        # process position
        self.position = process_overview_position([])
        # process traffic
        self.driver.find_elements_by_xpath('//*[@id="react-page-container"]/div/div[2]/div[4]/div[3]/div[2]/div[3]/div/div/button')[1].click()
        self.traffic = process_overview_other([])
        # process visibility
        self.driver.find_elements_by_xpath('//*[@id="react-page-container"]/div/div[2]/div[4]/div[3]/div[2]/div[3]/div/div/button')[2].click()
        self.visibility = process_overview_other([])
        
        # other pages #
        while num_pages > 1:
            self.driver.find_element_by_xpath(next_button).click()
            time.sleep(3)
            # process position
            self.driver.find_elements_by_xpath('//*[@id="react-page-container"]/div/div[2]/div[4]/div[3]/div[2]/div[3]/div/div/button')[0].click()
            self.position = process_overview_position(self.position)
            # process traffic
            self.driver.find_elements_by_xpath('//*[@id="react-page-container"]/div/div[2]/div[4]/div[3]/div[2]/div[3]/div/div/button')[1].click()
            self.traffic = process_overview_other(self.traffic)
            # process visibility
            self.driver.find_elements_by_xpath('//*[@id="react-page-container"]/div/div[2]/div[4]/div[3]/div[2]/div[3]/div/div/button')[2].click()
            self.visibility = process_overview_other(self.visibility)
            num_pages -= 1
        
        self.position = pd.DataFrame(self.position,columns=columns)
        self.traffic = pd.DataFrame(self.traffic,columns=columns)
        self.visibility = pd.DataFrame(self.visibility,columns=columns)

    def process_ranking(self):
        self.driver.find_element_by_xpath('//*[@id="ptr-header"]/div[2]/a[3]/span'.format(self.div_element)).click()
        # process ranking_dist
        self.wait_for_element('//*[@id="react-page-container"]/div/div[2]/div[4]/div[2]/div/div/div/div/div/div[1]/table/tbody/tr'.format(self.div_element))
        rows = self.driver.find_elements_by_xpath('//*[@id="react-page-container"]/div/div[2]/div[4]/div[2]/div/div/div/div/div/div[1]/table/tbody/tr'.format(self.div_element))
        num_rows = len(rows)
        while num_rows < 7:
            rows = self.driver.find_elements_by_xpath('//*[@id="react-page-container"]/div/div[2]/div[4]/div[2]/div/div/div/div/div/div[1]/table/tbody/tr'.format(self.div_element))
            num_rows = len(rows)
        result = []
        for row in rows:
            domain=row.find_element_by_xpath('td[1]').text
            visibility=row.find_element_by_xpath('td[2]').text[:-1]
            est_traffic=row.find_element_by_xpath('td[4]').text
            result.append([domain,visibility,est_traffic])
        self.ranking_dist = pd.DataFrame(result, columns=['domain','visibility','est_traffic'])
        # process top3
        self.wait_for_element('//*[@id="react-page-container"]/div/div[2]/div[4]/div[4]/div/div/div/div/div/div[1]/table/tbody/tr'.format(self.div_element))
        rows = self.driver.find_elements_by_xpath('//*[@id="react-page-container"]/div/div[2]/div[4]/div[4]/div/div/div/div/div/div[1]/table/tbody/tr'.format(self.div_element))
        num_rows = len(rows)
        while num_rows < 7:
            rows = self.driver.find_elements_by_xpath('//*[@id="react-page-container"]/div/div[2]/div[4]/div[4]/div/div/div/div/div/div[1]/table/tbody/tr'.format(self.div_element))
            num_rows = len(rows)
        result=[]
        for row in rows:
            domain=row.find_element_by_xpath('td[1]').text
            keywords=row.find_element_by_xpath('td[2]').text
            new=row.find_element_by_xpath('td[4]').text
            improved=row.find_element_by_xpath('td[5]').text
            lost=row.find_element_by_xpath('td[6]').text
            declined=row.find_element_by_xpath('td[7]').text
            result.append([domain,keywords,new,improved,lost,declined])
        self.top_ranking=pd.DataFrame(result, columns=['domain','keywords','new','improved','lost','declined'])
        self.top_ranking['top']=3
        # process top10
        self.wait_for_element('//*[@id="react-page-container"]/div/div[2]/div[4]/div[6]/div/div/div/div/div/div[1]/table/tbody/tr'.format(self.div_element))
        rows = self.driver.find_elements_by_xpath('//*[@id="react-page-container"]/div/div[2]/div[4]/div[6]/div/div/div/div/div/div[1]/table/tbody/tr'.format(self.div_element))
        num_rows = len(rows)
        while num_rows < 7:
            rows = self.driver.find_elements_by_xpath('//*[@id="react-page-container"]/div/div[2]/div[4]/div[6]/div/div/div/div/div/div[1]/table/tbody/tr'.format(self.div_element))
            num_rows = len(rows)
        result=[]
        for row in rows:
            domain=row.find_element_by_xpath('td[1]').text
            keywords=row.find_element_by_xpath('td[2]').text
            new=row.find_element_by_xpath('td[4]').text
            improved=row.find_element_by_xpath('td[5]').text
            lost=row.find_element_by_xpath('td[6]').text
            declined=row.find_element_by_xpath('td[7]').text
            result.append([domain,keywords,new,improved,lost,declined])
        tmp=pd.DataFrame(result, columns=['domain','keywords','new','improved','lost','declined'])
        tmp['top']=10
        self.top_ranking=self.top_ranking.append(tmp)
        # process top20
        self.wait_for_element('//*[@id="react-page-container"]/div/div[2]/div[4]/div[8]/div/div/div/div/div/div[1]/table/tbody/tr'.format(self.div_element))
        rows = self.driver.find_elements_by_xpath('//*[@id="react-page-container"]/div/div[2]/div[4]/div[8]/div/div/div/div/div/div[1]/table/tbody/tr'.format(self.div_element))
        num_rows = len(rows)
        while num_rows < 7:
            rows = self.driver.find_elements_by_xpath('//*[@id="react-page-container"]/div/div[2]/div[4]/div[8]/div/div/div/div/div/div[1]/table/tbody/tr'.format(self.div_element))
            num_rows = len(rows)
        result=[]
        for row in rows:
            domain=row.find_element_by_xpath('td[1]').text
            keywords=row.find_element_by_xpath('td[2]').text
            new=row.find_element_by_xpath('td[4]').text
            improved=row.find_element_by_xpath('td[5]').text
            lost=row.find_element_by_xpath('td[6]').text
            declined=row.find_element_by_xpath('td[7]').text
            result.append([domain,keywords,new,improved,lost,declined])
        tmp=pd.DataFrame(result, columns=['domain','keywords','new','improved','lost','declined'])
        tmp['top']=20
        self.top_ranking=self.top_ranking.append(tmp)
        # process top100
        self.wait_for_element('//*[@id="react-page-container"]/div/div[2]/div[4]/div[10]/div/div/div/div/div/div[1]/table/tbody/tr'.format(self.div_element))
        rows = self.driver.find_elements_by_xpath('//*[@id="react-page-container"]/div/div[2]/div[4]/div[10]/div/div/div/div/div/div[1]/table/tbody/tr'.format(self.div_element))
        num_rows = len(rows)
        while num_rows < 7:
            rows = self.driver.find_elements_by_xpath('//*[@id="react-page-container"]/div/div[2]/div[4]/div[10]/div/div/div/div/div/div[1]/table/tbody/tr'.format(self.div_element))
            num_rows = len(rows)
        result=[]
        for row in rows:
            domain=row.find_element_by_xpath('td[1]').text
            keywords=row.find_element_by_xpath('td[2]').text
            new=row.find_element_by_xpath('td[4]').text
            improved=row.find_element_by_xpath('td[5]').text
            lost=row.find_element_by_xpath('td[6]').text
            declined=row.find_element_by_xpath('td[7]').text
            result.append([domain,keywords,new,improved,lost,declined])
        tmp=pd.DataFrame(result, columns=['domain','keywords','new','improved','lost','declined'])
        tmp['top']=100
        self.top_ranking=self.top_ranking.append(tmp)
        
    def post_process(self):
        dfs = [self.position, self.traffic, self.visibility, self.ranking_dist, self.top_ranking]

        def clean(list_input):
            result = []
            for text in list_input:
                if text == '–' or text == 'n/a':
                    result.append(None)
                elif isinstance(text,str):
                    tmp = text
                    if ',' in text: 
                        tmp = text.replace(',','')
                    if '%' in text:
                        tmp = text.replace('%','')
                    if '\nYou' in text:
                        tmp = text.replace('\nYou','')
                    result.append(tmp)
                else: 
                    result.append(text)
            return result
        
        for df in dfs:
            df['updated']=self.today
            cols=list(set(df.columns).difference(['keyword','updated','serp']))
            df[cols] = df[cols].apply(clean, axis=0).convert_dtypes()
        
        self.visibility

    def terminate_session(self):
        self.driver.quit()
    
    def write_to_db(self,df,table_name):
        df.to_sql(table_name,conn,if_exists='append',index=False)

    def start_scraping(self):
        self.connect_to_semrush()
        self.process_overview()
        self.process_ranking()
        self.post_process()
        self.terminate_session()
        self.write_to_db(self.position, 'postrack_position')
        self.write_to_db(self.traffic, 'postrack_traffic')
        self.write_to_db(self.visibility, 'postrack_visibility')
        self.write_to_db(self.ranking_dist, 'postrack_ranking_distribution')
        self.write_to_db(self.top_ranking, 'postrack_ranking_top')

# Define our scraper        
my_scraper = SemRushProcessor('harry@myminifactory.com', 'MyM1n1seo738')
my_scraper.start_scraping()
