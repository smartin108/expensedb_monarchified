import csv
from tkinter import Tk
from tkinter.filedialog import askopenfilename
import os.path
import time
from datetime import datetime
import clsSQLServer as SQL

Tk().withdraw()
filename = askopenfilename()
file_c_time = time.ctime(os.path.getctime(filename))
timestamp = datetime.strptime(file_c_time, "%a %b %d %H:%M:%S %Y")
print(timestamp.isoformat())

data = []
with open(filename) as csvfile:
    csv_reader = csv.reader(csvfile)
    for row in csv_reader:
        row.append(timestamp)
        print(row)
        data.append(row)
print(data)

DBS = SQL.Interface(database='Expenses')
insert_statement = """\
            INSERT INTO landing.MonarchLoad (
                TransactionDate
                , Merchant
                , Category
                , Account
                , OriginalStatement
                , Notes
                , Amount
                , Tags
                , FileTimeStamp)
            VALUES (?,?,?,?,?,?,?,?,?);"""
DBS.InsertMany(insert_statement, data[1:])
