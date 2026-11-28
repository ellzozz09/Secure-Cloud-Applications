import os
import json
import boto3
import logging

from aws_xray_sdk.core import xray_recorder, patch_all
# Enable AWS X-Ray instrumentation
patch_all()
# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class Worker:
    def __init__(self):
        self.region = os.getenv("AWS_REGION", "us-east-1")
        self.queue_name = os.getenv("QUEUE_NAME", "depi-dev-tasks-queue")
        self.table_name = os.getenv("DYNAMODB_TABLE", "depi-dev-tasks-table")

        self.max_batch_size = int(os.getenv("MAX_BATCH_SIZE", "10"))
        self.poll_wait_seconds = int(os.getenv("POLL_WAIT_SECOND", "20"))

        if not 1 <= self.max_batch_size <= 10:
            raise ValueError("MAX_BATCH_SIZE must be between 1 and 10")

        if not 0 <= self.poll_wait_seconds <= 20:
            raise ValueError("POLL_WAIT_SECOND must be between 0 and 20")

        self.sqs = boto3.client("sqs", region_name=self.region)
        self.dynamodb = boto3.resource("dynamodb", region_name=self.region)
        self.table = self.dynamodb.Table(self.table_name)

    def validate_task(self, task):
        if not isinstance(task, dict):
            raise ValueError("Task must be a JSON object")

        required_fields = ["task_id"]

        for field in required_fields:
            if field not in task:
                raise ValueError(f"Missing required field: {field}")

        if not isinstance(task["task_id"], str) or not task["task_id"].strip():
            raise ValueError("task_id must be a non-empty string")

        return True
    
    def get_queue_url(self):
        response = self.sqs.get_queue_url(
            QueueName=self.queue_name
        )

        return response["QueueUrl"]
    
    def receive_messages(self):
        queue_url = self.get_queue_url()

        response = self.sqs.receive_message(
            QueueUrl=queue_url,
            MaxNumberOfMessages=self.max_batch_size,
            WaitTimeSeconds=self.poll_wait_seconds,
            AttributeNames=["ApproximateReceiveCount"]
        )

        return response.get("Messages", [])

    def get_receive_count(self, message):
        attributes = message.get("Attributes", {})
        receive_count = attributes.get("ApproximateReceiveCount", "1")

        return int(receive_count)

    def delete_message(self, message):
        queue_url = self.get_queue_url()

        self.sqs.delete_message(
            QueueUrl=queue_url,
            ReceiptHandle=message["ReceiptHandle"]
        )

        logger.info("Message deleted from SQS")

    def parse_message(self, message):
        try:
            task = json.loads(message["Body"])
            self.validate_task(task)
            return task

        except (json.JSONDecodeError, KeyError, ValueError) as error:
            logger.error(f"Invalid message: {error}")
            raise

    def update_task_status(self, task_id, status):
        self.table.update_item(
            Key={
                "task_id": task_id
            },
            UpdateExpression="SET #status = :status",
            ExpressionAttributeNames={
                "#status": "status"
            },
            ExpressionAttributeValues={
                ":status": status
            },
            ConditionExpression="attribute_exists(task_id)"
        )

    
    def start_task(self, task_id):
        self.update_task_status(task_id, "PROCESSING")
        logger.info(f"Task {task_id} is now PROCESSING")

    def complete_task(self, task_id):
        self.update_task_status(task_id, "COMPLETED")
        logger.info(f"Task {task_id} completed successfully")

    def fail_task(self, task_id, error):
        self.update_task_status(task_id, "FAILED")
        logger.error(f"Task {task_id} failed: {error}")

    def process_task(self, task):
        raise NotImplementedError(
            "Task execution is not implemented yet"
    )

    def process_message(self, message):
        receive_count = self.get_receive_count(message)
        task = None

        with xray_recorder.in_segment("process_sqs_message"):
            with xray_recorder.in_subsegment("message_processing") as subsegment:
                try:
                    task = self.parse_message(message)

                    subsegment.put_annotation("task_id", task["task_id"])
                    subsegment.put_annotation("receive_count", receive_count)

                    self.start_task(task["task_id"])
                    self.process_task(task)
                    self.complete_task(task["task_id"])

                    self.delete_message(message)

                except Exception as error:
                    subsegment.put_annotation("error", True)

                    if task is not None and receive_count >= 3:
                        try:
                            self.fail_task(task["task_id"], error)
                        except Exception as status_error:
                            logger.error(
                                f"Could not update task status: {status_error}"
                            )

                    logger.error(
                        f"Message processing failed. Attempt {receive_count}/3: {error}"
                    )
                    raise

    def run(self):
        logger.info("Worker started")

        while True:
            messages = self.receive_messages()

            if not messages:
                logger.info("No messages received")
                continue

            for message in messages:
                try:
                    self.process_message(message)
                except Exception as error:
                    logger.error(f"Failed to process message: {error}")