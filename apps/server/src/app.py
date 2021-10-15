import os.path
import flask
from time import sleep

app = flask.Flask(__name__)


def get_delay_value(fpath: str) -> int:
    delay = 0

    if os.path.exists(fpath):
        with open(fpath, "r") as f:
            delay = int(f.readline())
    return delay


@app.route("/")
def hello_world():
    ua = flask.request.headers.get("User-Agent", "")
    if ua == "ELB-HealthChecker/2.0":
        delay = get_delay_value("elb_healthcheck_delay.txt")
    else:
        delay = get_delay_value("default_delay.txt")

    sleep(delay)
    return f"Delay: {delay}\n"


if __name__ == "__main__":
    app.run(threaded=False, processes=1, host="0.0.0.0")
