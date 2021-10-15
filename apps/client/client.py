#!/usr/bin/env python

import click
import requests
from time import sleep

@click.command()
@click.option("-u", "--url", help="url")
def run_check(url: str) -> None:
    # r = requests.get(url)
    # for c in r.text:
    #     print(c)
    with requests.get(url, stream=True) as r:
        # for c in r.content:
        #     print(c.real)
        for chunk in r.iter_content(1):
            print(chunk.decode("utf"))
            sleep(1)


if __name__ == "__main__":
    run_check()
