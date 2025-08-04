import azure.functions as func
from ..shared import run_pipeline

def main(req: func.HttpRequest) -> func.HttpResponse:
    result_json = run_pipeline()
    return func.HttpResponse(
        result_json,
        status_code=200,
        mimetype="application/json"
    )
