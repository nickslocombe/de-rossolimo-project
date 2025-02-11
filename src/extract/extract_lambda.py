from utils.extract_data import extract_func
from utils.load_data import load
from utils.log_time import get_timestamp_from_logs
import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    """
    Handler function - runs extract and load functions, passing in time
    to query from to load function

    Parameters:
    event - unused, comes from AWS
    context - unused, comes from AWS

    Returns:
    None
    """
    try:
        data = extract_func(get_timestamp_from_logs())
        load(data)
        logger.info({"Result": "Success",
                     "Message": "Extract Lambda ran successfully"})
    except Exception as e:
        logger.error(
            {
                "Result": "Failure",
                "Error": f"Unexpected Exception occured in " +
                f"lambda_handler: {str(e)}"
                })
        raise e
