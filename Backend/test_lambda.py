import os
import sys
import json
import unittest
from unittest.mock import MagicMock

os.environ['AWS_DEFAULT_REGION'] = 'us-east-1'
os.environ['AWS_ACCESS_KEY_ID'] = 'testing'
os.environ['AWS_SECRET_ACCESS_KEY'] = 'testing'

mock_boto3 = MagicMock()
sys.modules['boto3'] = mock_boto3

import lambda_function


class TestLambda(unittest.TestCase):

    def test_lambda_handler_success(self):
        mock_table = mock_boto3.resource.return_value.Table.return_value
        mock_table.update_item.return_value = {
            'Attributes': {'count': 5}
        }

        response = lambda_function.lambda_handler({}, {})

        self.assertEqual(response['statusCode'], 200)

        body = json.loads(response['body'])
        self.assertEqual(body['visitor_count'], 5)

        mock_table.update_item.assert_called_once_with(
            Key={'id': 'count'},
            UpdateExpression='ADD #c :inc',
            ExpressionAttributeNames={'#c': 'count'},
            ExpressionAttributeValues={':inc': 1},
            ReturnValues='UPDATED_NEW'
        )


if __name__ == '__main__':
    unittest.main()