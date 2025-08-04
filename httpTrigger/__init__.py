import logging
import azure.functions as func
from shared import run_pipeline   # ← absolutt import

logger = logging.getLogger(__name__)

def main(req: func.HttpRequest) -> func.HttpResponse:
    logger.info("HTTP-trigger aktivert")
    result = run_pipeline()
    return func.HttpResponse(body=result, status_code=200, mimetype="application/json")
