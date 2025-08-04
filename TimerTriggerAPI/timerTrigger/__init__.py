import azure.functions as func
from ..shared import run_pipeline

def main(mytimer: func.TimerRequest) -> None:
    # Du kan fjerne return-verdien for timer-trigger
    run_pipeline()
