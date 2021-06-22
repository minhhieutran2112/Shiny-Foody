# %%
import logging
import pandas as pd
import gspread
import os
import re
from oauth2client.service_account import ServiceAccountCredentials
from linkedin_jobs_scraper import LinkedinScraper
from linkedin_jobs_scraper.events import Events, EventData
from linkedin_jobs_scraper.query import Query, QueryOptions, QueryFilters
from linkedin_jobs_scraper.filters import RelevanceFilters, TimeFilters, TypeFilters, ExperienceLevelFilters, RemoteFilters

# Change root logger level (default is WARN)
logging.basicConfig(level = logging.INFO)


def on_data(data: EventData):
    if len(re.findall(r'(\bHuman Resources\b)|(\bHR\b)', data.job_function)) > 0:
        result.append([data.title,data.company,data.company_size,data.place,data.description,data.date,data.employment_type,data.industries,data.link])
    print('[ON_DATA] Done')


def on_error(error):
    print('[ON_ERROR]', error)


def on_end():
    print('[ON_END]')


scraper = LinkedinScraper(
    chrome_executable_path=None, # Custom Chrome executable path (e.g. /foo/bar/bin/chromedriver) 
    chrome_options=None,  # Custom Chrome options here
    headless=True,  # Overrides headless mode only if chrome_options is None
    max_workers=1,  # How many threads will be spawned to run queries concurrently (one Chrome driver for each thread)
    slow_mo=2,  # Slow down the scraper to avoid 'Too many requests (429)' errors
)

# Add event listeners
scraper.on(Events.DATA, on_data)
scraper.on(Events.ERROR, on_error)
scraper.on(Events.END, on_end)

queries = [
    Query(
        query='human resources',
        options=QueryOptions(
            locations=['Sharnbrook, England, United Kingdom'],
            optimize=False,
            limit=1000,
            filters=QueryFilters(
                relevance=RelevanceFilters.RECENT,
                time=TimeFilters.DAY,
                type=[TypeFilters.FULL_TIME, TypeFilters.CONTRACT, TypeFilters.TEMPORARY],
                experience=ExperienceLevelFilters.ENTRY_LEVEL,                
            )
        )
    ),
    Query(
        query='human resources',
        options=QueryOptions(
            locations=['United Kingdom'],
            optimize=False,
            limit=1000,
            filters=QueryFilters(
                relevance=RelevanceFilters.RECENT,
                time=TimeFilters.DAY,
                type=[TypeFilters.FULL_TIME, TypeFilters.CONTRACT, TypeFilters.TEMPORARY],
                experience=ExperienceLevelFilters.ENTRY_LEVEL,            
                remote=RemoteFilters.REMOTE,    
            )
        )
    ),
]

result=[]
scraper.run(queries)
# %%
# upload data
# define the scope
scope = ['https://spreadsheets.google.com/feeds','https://www.googleapis.com/auth/drive']
# add credentials to the account
creds_path = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')
creds = ServiceAccountCredentials.from_json_keyfile_name(creds_path, scope)

# authorize the clientsheet 
client = gspread.authorize(creds)

# get the instance of the Spreadsheet
workbook = client.open('HR Jobs')

# get sheet
sheet = workbook.worksheets()[0]

# if have result then update
if len(result) > 0:
    sheet.append_rows(result)
# %%
