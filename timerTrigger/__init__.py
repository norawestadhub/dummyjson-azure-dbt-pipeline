import logging
import azure.functions as func
from shared import run_pipeline
from datetime import datetime, timezone

logger = logging.getLogger(__name__)

def main(mytimer: func.TimerRequest) -> None:
    now = datetime.now(timezone.utc).isoformat()
    logger.info("Timer-trigger fired at %s", now)

    result = run_pipeline()
    logger.info("Resultat: %s", result)
