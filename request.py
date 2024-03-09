import os
import sys
import json
import datetime
import traceback

import requests


def main():
    prepare_env()
    try:
        data = serialize(get_recipe())
        result, key = is_valid(data)
        if result:
            write_to_file(data)
        else:
            raise Exception(key + "はサブキーとして登録されています")
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
        "content": ":x:GitHub Actions実行時にエラーが発生しました",
        "embeds": [
            {
                "title": "GitHub Actions",
                "description": "```" + traceback.format_exc() + "```",
                "url": "https://github.com/cons-tan-tan/auto_infusion/actions",
                "color": int("ff3434", 16),
            }
        ]
    }
    requests.post(url, data=json.dumps(data).encode(), headers={"Content-Type": "application/json"})


def get_recipe() -> dict:
    url = os.environ.get("MICROCMS_SERVICE_DOMAIN")
    header= {
        "content-type": "application/json",
        "X-MICROCMS-API-KEY": os.environ.get("MICROCMS_API_KEY"),
    }
    param = {
        "fields": "product,amount,key,sub.key,essentia.name",
        "limit": 100,
    }
    return requests.get(url, headers=header, params=param).json()


def serialize(raw_data) -> dict:
    raw_data = get_recipe()
    data = {}
    data["recipe"] = {}
    data["sub"] = {}

    if raw_data["totalCount"] > 100:
        raise Exception("レシピ総数がデフォルトの上限の100を超えました")
    for i in range(raw_data["totalCount"]):
        tmp = {}
        recipe = raw_data["contents"][i]
        tmp["product"] = recipe["product"]
        tmp["amount"] = int(recipe["amount"][0])
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
    data["updated_at"] = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    return data


def is_valid(data) -> tuple[bool, str]:
    sub = data["sub"]
    for key in data["recipe"]:
        if key in sub: return False, key
    return True, None


def write_to_file(data):
    f = open('recipes.json', 'w')
    f.write(json.dumps(data, indent=4))
    f.close()


if __name__ == "__main__":
    main()
