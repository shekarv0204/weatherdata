import requests
import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq
from datetime import datetime, timedelta

def pull_api_data(api_url):
    try:
        response = requests.get(api_url)
        response.raise_for_status()  # Raise an HTTPError for bad responses
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error pulling API data: {e}")
        return None

def aggregate_and_save(data):
    if data is None:
        return

    # Extract relevant fields and create a DataFrame
    df = pd.DataFrame(data['hourly'])
    
    # Convert timestamp to datetime
    df['timestamp'] = pd.to_datetime(df['timestamp'], unit='s')
    
    # Aggregate fields to daily total
    df_daily = df.resample('D', on='timestamp').sum()

    # Save as Parquet file
    table = pa.Table.from_pandas(df_daily)
    pq.write_table(table, 'daily_aggregated_data.parquet')

def main():
    api_url = "https://api.open-meteo.com/v1/forecast?latitude=51.5085&longitude=-0.1257&hourly=temperature_2m,rain,showers,visibility&past_days=31"
    api_data = pull_api_data(api_url)
    aggregate_and_save(api_data)

if __name__ == "__main__":
    main()
