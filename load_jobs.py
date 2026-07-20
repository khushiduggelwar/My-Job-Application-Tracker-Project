import pandas as pd
import numpy as np
import psycopg2 

#  Load data
df = pd.read_excel("Job Search Sheet.xlsx", engine='openpyxl')

#  CLEANING STEP (PUT YOUR CODE HERE)

# Remove empty rows
df = df.dropna(how='all')

# Remove duplicate rows
df = df.drop_duplicates()

df.columns = df.columns.str.strip()

df['Status'] = df['Status'].replace(r'^\s*$', np.nan, regex=True)
df['Status'] = df['Status'].fillna("No Reply")

# Fix datetime columns
date_cols = ['Date Applied']

for col in date_cols:
    if col in df.columns:
        df[col] = pd.to_datetime(df[col], errors='coerce')
        df[col] = df[col].astype(object).where(pd.notnull(df[col]), None)

# Replace remaining NaN
df = df.where(pd.notnull(df), None)

# Connect to PostgreSQL
conn = psycopg2.connect(
    host="localhost",
    database="Job_tracker",
    user="postgres",
    password="Khushi@2002",
    port="5432"
)

cursor = conn.cursor()

# DEFINE QUERY (you missed this ❗)
insert_query = """
INSERT INTO job_application (
    job_id,
    company_name,
    job_title,
    application_link,
    date_applied,
    place_of_job,
    experience_required,
    referred_person,
    contact_person,
    contact_person_details,
    status
)
VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
"""
# Clear old data
cursor.execute("TRUNCATE TABLE job_application RESTART IDENTITY;")

# Insert loop
for _, row in df.iterrows():
    cursor.execute(
        insert_query,
        (
            None if pd.isna(row['Job ID']) else str(row['Job ID']),
            None if pd.isna(row['Company Name']) else row['Company Name'],
            None if pd.isna(row['Job Title']) else row['Job Title'],
            None if pd.isna(row['Application Link']) else row['Application Link'],
            None if pd.isna(row['Date Applied']) else row['Date Applied'],
            None if pd.isna(row['Place of job']) else row['Place of job'],
            None if pd.isna(row['Experience Required']) else row['Experience Required'],
            None if pd.isna(row['Referred person']) else row['Referred person'],
            None if pd.isna(row['Contact Person']) else row['Contact Person'],
            None if pd.isna(row['Contact Person Details']) else row['Contact Person Details'],
            None if pd.isna(row['Status']) else row['Status']
        )
    )

# Commit + Close
conn.commit()

print("Data loaded successfully into PostgreSQL!")

cursor.close()
conn.close()