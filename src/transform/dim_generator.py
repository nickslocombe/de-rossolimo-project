import pandas as pd
from src.transform.currency_code_to_name import currency_code_to_name
from src.transform.pandas_testing import dataframe_creator
import json


def create_date_table(
        start='2000-01-01',
          end='2050-12-31'
    ):
    """
    Creates a date dimension table that should not need to be modified
    after creation

    Should only be ran once to generate original table
    """
   
    df = pd.DataFrame(
        {"Date": pd.date_range(start, end)}
        )
    df["year"] = df.Date.dt.year
    df["month"] = df.Date.dt.month
    df["day"] = df.Date.dt.day
    df["day_of_week"] = df.Date.dt.day_of_week
    df["day_name"] = df.Date.dt.day_name()
    df["month_name"] = df.Date.dt.month_name()
    df["quarter"] = df.Date.dt.quarter
    df.set_index("Date", inplace=True)
    df.index.name="date_id"
    return df


def currency_dim(file_dict=None):
    currency_df = dataframe_creator("currency", file_dict)
    currency_df = currency_df.drop(['created_at', 'last_updated'], axis=1)
    currency_df["currency_name"] = currency_df["currency_code"].apply(currency_code_to_name)
    return currency_df

def payment_type_dim(file_dict=None):
    payment_df = dataframe_creator("payment_type", file_dict)
    payment_df = payment_df.drop(['created_at', 'last_updated'], axis=1)
    return payment_df

def staff_dim(file_dict=None):
    part_staff_df = dataframe_creator("staff", file_dict)
    department_df = dataframe_creator("department", file_dict)

    full_staff_df = part_staff_df.join(
        department_df, on="department_id", how="left", rsuffix="a"
        )
    desired_columns_and_order = [
        "first_name", "last_name", "department_name", "location", "email_address"
        ]
    full_staff_df = full_staff_df[desired_columns_and_order]
    return full_staff_df

def counterparty_dim(file_dict=None):
    part_counterparty_df = dataframe_creator("counterparty", file_dict)
    address_df = dataframe_creator("address", file_dict)
    address_df["legal_address_id"] = address_df.index
    

    full_counterparty_df = part_counterparty_df.join(
        address_df, on="legal_address_id", how="left", rsuffix="a")
    desired_columns_and_order = [
        "counterparty_legal_name", "address_line_1", "address_line_2", "district", "city", "postal_code", "country", "phone"
    ]
    
    
    full_counterparty_df = full_counterparty_df[desired_columns_and_order]
    full_counterparty_df.rename(columns={
        "address_line_1" : "counterparty_legal_address_line_1",
        "address_line_2" : "counterparty_legal_address_line_2",
        "district" : "counterparty_legal_district",
        "city" : "counterparty_legal_city",
        "postal_code" : "counterparty_legal_postal_code",
        "country": "counterparty_legal_country",
        "phone" : "counterparty_legal_phone_number"
    }, inplace=True)
    return full_counterparty_df

