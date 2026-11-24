import unittest
from unittest.mock import patch, MagicMock

from src.worker.worker import Worker, xray_recorder

class TestWorker(unittest.TestCase):

    @patch("src.worker.worker.boto3.resource")
    @patch("src.worker.worker.boto3.client")
    def setUp(self, mock_client, mock_resource):
        self.worker = Worker()
        xray_recorder.begin_segment("unit-test")

    def tearDown(self):
        xray_recorder.end_segment()

    def test_validate_task_success(self):
        task = {"task_id": "123"}

        result = self.worker.validate_task(task)

        self.assertTrue(result)

    def test_validate_task_missing_id(self):
        task = {"name": "test"}

        with self.assertRaises(ValueError):
            self.worker.validate_task(task)

    def test_validate_task_empty_id(self):
        task = {"task_id": ""}

        with self.assertRaises(ValueError):
            self.worker.validate_task(task)

    def test_get_receive_count(self):
        message = {
            "Attributes": {
                "ApproximateReceiveCount": "2"
            }
        }

        result = self.worker.get_receive_count(message)

        self.assertEqual(result, 2)
        
    def test_invalid_json_message_not_deleted(self):
        message = {
            "Attributes": {
                "ApproximateReceiveCount": "1"
            },
            "Body": '{"task_id": '
        }

        self.worker.delete_message = MagicMock()
        self.worker.fail_task = MagicMock()

        with self.assertRaises(ValueError):
            self.worker.process_message(message)

        self.worker.delete_message.assert_not_called()
        self.worker.fail_task.assert_not_called()

    @patch.dict("os.environ", {"MAX_BATCH_SIZE": "11"})
    def test_invalid_max_batch_size(self):
        with self.assertRaises(ValueError):
            Worker()

    @patch.dict("os.environ", {"POLL_WAIT_SECOND": "21"})
    def test_invalid_poll_wait_seconds(self):
        with self.assertRaises(ValueError):
            Worker()

    @patch.dict("os.environ", {"MAX_BATCH_SIZE": "5", "POLL_WAIT_SECOND": "10"})
    def test_valid_worker_settings(self):
        worker = Worker()

        self.assertEqual(worker.max_batch_size, 5)
        self.assertEqual(worker.poll_wait_seconds, 10)

    def test_message_not_deleted_when_processing_fails(self):
            message = {
                "Attributes": {
                    "ApproximateReceiveCount": "1"
                },
                "Body": '{"task_id": "123"}'
            }
    
            self.worker.parse_message = MagicMock(
                return_value={"task_id": "123"}
            )
    
            self.worker.process_task = MagicMock(
                side_effect=RuntimeError("Processing failed")
            )
    
            self.worker.delete_message = MagicMock()
            self.worker.fail_task = MagicMock()
    
            with self.assertRaises(RuntimeError):
                self.worker.process_message(message)
    
            self.worker.delete_message.assert_not_called()
            self.worker.fail_task.assert_not_called()
    def test_task_not_failed_before_third_attempt(self):
        message = {
            "Attributes": {
                "ApproximateReceiveCount": "2"
            },
            "Body": '{"task_id": "123"}'
        }

        self.worker.parse_message = MagicMock(
            return_value={"task_id": "123"}
        )

        self.worker.process_task = MagicMock(
            side_effect=RuntimeError("Processing failed")
        )

        self.worker.fail_task = MagicMock()

        with self.assertRaises(RuntimeError):
            self.worker.process_message(message)

        self.worker.fail_task.assert_not_called()
    def test_task_failed_on_third_attempt(self):
        message = {
            "Attributes": {
                "ApproximateReceiveCount": "3"
            },
            "Body": '{"task_id": "123"}'
        }

        self.worker.parse_message = MagicMock(
            return_value={"task_id": "123"}
        )

        self.worker.process_task = MagicMock(
            side_effect=RuntimeError("Processing failed")
        )

        self.worker.fail_task = MagicMock()
        self.worker.delete_message = MagicMock()

        with self.assertRaises(RuntimeError):
            self.worker.process_message(message)

        self.worker.fail_task.assert_called_once()
        self.worker.delete_message.assert_not_called()

if __name__ == "__main__":
    unittest.main()
    