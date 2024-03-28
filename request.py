import zlib
import os
import sys
import json
import datetime
import traceback

import requests


LIMIT = 100

def main():
    prepare_env()
    try:
        data = get_serialized_data()
        write_to_file(data)
    except Exception as e:
        post_to_discord()
        raise e


def is_github_actions() -> bool:
    args = sys.argv
    return len(args) == 2 and args[1] == "auto"


def prepare_env():
    if not is_github_actions():
        from dotenv import load_dotenv
        load_dotenv()


def post_to_discord():
    url = os.environ.get("DISCORD_WEBHOOK_URL")
    data = {
        "content": "**" + traceback.format_exception_only(sys.exc_info()[0], sys.exc_info()[1])[-1] + "**",
        "embeds": [
            {
                "title": "GitHub Actions",
                "description": ":x:シリアライズ実行時にエラーが発生しました",
                "url": "https://github.com/cons-tan-tan/auto_infusion/actions",
                "color": int("ff3434", 16),
            }
        ]
    }
    requests.post(url, data=json.dumps(data).encode(), headers={"Content-Type": "application/json"})


def get_recipe(offset) -> dict:
    url = os.environ.get("MICROCMS_SERVICE_DOMAIN")
    header= {
        "content-type": "application/json",
        "X-MICROCMS-API-KEY": os.environ.get("MICROCMS_API_KEY"),
    }
    param = {
        "fields": "product,amount,key,sub.key,essentia.name",
        "limit": LIMIT,
        "offset": offset,
    }
    return requests.get(url, headers=header, params=param).json()


def get_serialized_data() -> dict:
    now = datetime.datetime.utcnow() + datetime.timedelta(hours=9)
    data = {"recipe": {}, "sub": {}, "updated_at": now.strftime("%Y-%m-%d %H:%M:%S")}

    raw_data = get_recipe(0)
    total_count = raw_data["totalCount"]
    i = 0
    while True:
        contents = raw_data["contents"]
        for j in range(len(contents)):
            tmp = {}
            recipe = contents[j]
            tmp["product"] = recipe["product"]
            amount = int(recipe["amount"][0])
            if amount != 1:
                tmp["amount"] = amount
            if recipe["sub"] != None:
                tmp["sub"] = recipe["sub"]["key"]
                data["sub"][recipe["sub"]["key"]] = True
            essentia = {}
            for j in range(len(recipe["essentia"])):
                aspect = recipe["essentia"][j]["aspect"]["name"].lower()
                amount = recipe["essentia"][j]["amount"]
                essentia[aspect] = amount
            tmp["essentia"] = essentia
            data["recipe"][recipe["key"]] = tmp
            i += 1
        if i >= total_count:
            break
        raw_data = get_recipe(i)

    return data


def write_to_file(data):
    f = open('recipes.json', 'w')
    f.write(json.dumps(data, indent=4))
    f.close()
    f = open('recipes.json.zlib', 'wb')
    f.write(zlib.compress(json.dumps(data).encode()))
    f.close()


if __name__ == "__main__":
    main()
