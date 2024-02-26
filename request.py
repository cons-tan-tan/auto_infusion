import os
import json
import datetime

import requests

# ローカルで実行する場合は以下のコードを有効化する
# from dotenv import load_dotenv
# load_dotenv()

url = os.environ.get("MICROCMS_SERVICE_DOMAIN")
header= {
    "content-type": "application/json",
    "X-MICROCMS-API-KEY": os.environ.get("MICROCMS_API_KEY"),
}
param = {
    "fields": "product,amount,key,sub.key,essentia.name",
    "limit": 100,
}

result = requests.get(url, headers=header, params=param).json()

data = []

for i in range(result["totalCount"]):
    tmp = {}
    recipe = result["contents"][i]
    tmp["product"] = recipe["product"]
    tmp["amount"] = recipe["amount"][0]
    tmp["key"] = recipe["key"]
    if recipe["sub"] != None:
        tmp["sub"] = recipe["sub"]["key"]
    essentia = []
    for j in range(len(recipe["essentia"])):
        tmp1 = {}
        tmp1["aspect"] = recipe["essentia"][j]["aspect"]["name"]
        tmp1["amount"] = recipe["essentia"][j]["amount"]
        essentia.append(tmp1)
    tmp["essentia"] = essentia
    data.append(tmp)
data.append(datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

f = open('recipes.json', 'w')
f.write(json.dumps(data, indent=4))
f.close()
