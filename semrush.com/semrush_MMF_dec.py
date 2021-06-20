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
import pandas as pd
import time
import random
import os
import requests
from datetime import date

class SemRushProcessor():
    def __init__(self, username, password):
        self.username = username
        self.password = password
        self.rows_xpath = '/html/body/div[1]/main/div/div/div[3]/div/div[2]/div/div[1]/div/div/table/tbody/tr'
        self.keyword_xpath = 'td[2]'
        self.volumn_xpath = 'td[4]'
        self.kd_xpath = 'td[8]'
        self.cpc_xpath = 'td[6]'
        self.com_xpath = 'td[7]'
        self.click_potential = 'td[10]'
        self.s_class = 'sm-cell-serp-features__item'
        self.s_class_2 = 'sm-cell-serp-features__trigger'
        self.next_button_xpath = '/html/body/div[1]/main/div/div/div[3]/div/div[2]/div/div[2]/div/button[3]/span'
        self.result = []
        self.update_date_xpath = 'td[12]'
        self.update_button = 'td[13]/span/div/div[1]'
        self.today = date.today().strftime('%#m/%#d/%Y')

    def wait_for_element(self, xpath):
        WebDriverWait(self.driver, 3600).until(EC.presence_of_element_located((By.XPATH, xpath)))

    def connect_to_semrush(self):
        self.options = webdriver.ChromeOptions()
        # Add some options to our webdriver
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
        self.driver.get(r'https://www.semrush.com/login/?src=header&redirect_to=%2Fanalytics%2Fkeywordmanager%2Flists')
        if self.driver.current_url.startswith('https://www.semrush.com/analytics/keywordmanager/lists'):
            pass
        else:
            # Find the form to fill
            email = WebDriverWait(self.driver, 3600).until(EC.presence_of_element_located((By.CSS_SELECTOR, 'div._flex_llbyh_gg_:nth-child(3) > div:nth-child(2) > div:nth-child(1) > div:nth-child(1) > input:nth-child(1)')))
            password = WebDriverWait(self.driver, 3600).until(EC.presence_of_element_located((By.CSS_SELECTOR, 'div._flex_llbyh_gg_:nth-child(4) > div:nth-child(2) > div:nth-child(1) > div:nth-child(1) > input:nth-child(1)')))
            # Fill in the form
            email.send_keys(self.username)
            password.send_keys(self.password)
            # Submit credential
            password.send_keys(Keys.ENTER)
    
    def access_kw_list(self):
        # wait for html element to show up
        waiter = self.wait_for_element('/html/body/div[1]/main/div/div/div[3]/div/div[3]/div/div/div/div/div/div[1]/div[1]/div[1]/div/a/span/span/span/span')
        # Access the MMF Keywords keywords page
        mmf_keywords = self.driver.find_elements_by_xpath('/html/body/div[1]/main/div/div/div[3]/div/div[3]/div/div/div/div/div/div[1]/div[1]/div[1]/div/a/span/span/span/span')
        for keyword in mmf_keywords:
            if keyword.text == 'MMF Keywords':
                keyword_toclick = keyword
                break
        time.sleep(2)
        keyword_toclick.click()
        # Retrieve number of pages to process
        waiter = self.wait_for_element(self.rows_xpath)
        try:
            self.num_pages = int(WebDriverWait(self.driver, 30).until(EC.presence_of_element_located((By.XPATH, '/html/body/div[1]/main/div/div/div[3]/div/div[2]/div/div[2]/div/a/span/span'))).text)
        except:
            self.num_pages = 1

    def process_page(self):
        # Wait for information on rows to show up
        time.sleep(3)
        waiter = self.wait_for_element(self.rows_xpath)
        rows = self.driver.find_elements_by_xpath(self.rows_xpath)
        # If the updated date is not today, then update these rows
        for row in rows:
            time.sleep(0.5)
            if row.find_element_by_xpath(self.update_date_xpath).text != self.today:
                row.find_element_by_xpath(self.update_button).click()
        # Check if every element is loaded
        # print(self.driver.current_url)
        loaded = self.driver.find_elements_by_xpath('/html/body/div[1]/main/div/div/div[3]/div/div[2]/div/div[1]/div/div/table/tbody/tr/td[8]')
        loaded_element = [element.text for element in loaded if element.text != '']
        while len(loaded_element) != len(rows):
            loaded_element = [element.text for element in loaded if element.text != '']
            time.sleep(1)
        # Retrieve data for each rows, and store it in a list
        self.wait_for_element(self.rows_xpath)
        rows = self.driver.find_elements_by_xpath(self.rows_xpath)
        for row in rows:
            row_result = []
            row_result.append(row.find_element_by_xpath(self.keyword_xpath).text)
            row_result.append(row.find_element_by_xpath(self.volumn_xpath).text)
            row_result.append(row.find_element_by_xpath(self.kd_xpath).text)
            row_result.append(row.find_element_by_xpath(self.cpc_xpath).text)
            row_result.append(row.find_element_by_xpath(self.com_xpath).text)
            non_visible_s_class = row.find_elements_by_class_name(self.s_class_2)
            if len(non_visible_s_class) == 0:
                row_result.append(len(row.find_elements_by_class_name(self.s_class)))
            else:
                row_result.append(len(row.find_elements_by_class_name(self.s_class))+int(row.find_elements_by_class_name(self.s_class_2)[0].text[1:]))
            row_result.append(row.find_element_by_xpath(self.click_potential).text)
            self.result.append(row_result)

    def process_all_pages(self):
        self.process_page()
        if self.num_pages == 1:
            return
        else:
            self.num_pages -= 1
            self.driver.find_element_by_xpath(self.next_button_xpath).click()
            self.process_all_pages()
    
    def replace_scientific(self, list_input):
        result = []
        for number in list_input:
            if number == None or number == 'Needs updating':
                result.append(number)
                continue
            number = number.replace(',','')
            if number[-1] == 'K':  # Check if the last digit is K
                result.append(float(number[:-1]) * 1000)  # Remove the last digit with [:-1], and convert to int and multiply by 1000
            elif number[-1:] == 'M':  # Check if the last digit is M
                result.append(float(number[:-1]) * 1000000)  # Remove the last digit with [:-1], and convert to int and multiply by 1000000
            else:  # just in case data doesnt have an M or K
                result.append(float(number))
        return result 

    def terminate_session(self):
        self.driver.quit()
    
    def write_to_db(self):
        self.result_df.to_sql('SemRush_MMF',conn,if_exists='append',index=False)

    def start_scraping(self):
        self.connect_to_semrush()
        self.access_kw_list()
        self.process_all_pages()
        self.terminate_session()
        self.result_df = pd.DataFrame(self.result, columns=['keyword','volumn','kw_difficulty','cost_per_click','competitive_density','serp_features','click_potential'])
        self.result_df['updated'] = self.today
        numeric_columns = list(set(self.result_df.columns).difference(['keyword','updated','serp_features']))
        self.result_df.replace({'n/a': None}, inplace=True)
        self.result_df[numeric_columns] = self.result_df[numeric_columns].apply(self.replace_scientific, axis=0)
        self.write_to_db()

    

# Define our scraper        
my_scraper = SemRushProcessor('harry@myminifactory.com', 'MyM1n1seo738')
my_scraper.start_scraping()