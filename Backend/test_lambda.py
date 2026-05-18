import os
import sys
import unittest
from unittest.mock import MagicMock
#import lambda_function #This imports my actual file

#Feed Boto3 dummy credentials so it doesnt crash on laptop
os.environ['AWS_DEFAULT_REGION']='us-east-1'
os.environ['AWS_ACCESS_KEY_ID']='testing'
os.environ['AWS_SECRET_ACCESS_KEY']='testing'

#Intercept Boto3 before importing my code
#This stops your global variables from hitting the real internet
mock_boto3=MagicMock()
sys.modules['boto3']=mock_boto3

import lambda_function #Now its safe to imports my actual file

class TestLambda(unittest.TestCase):

    # @patch intercepts Boto3 so it don't hit real db
    #@patch('lambda_function.boto3.resource')
    def test_lambda_handler_success(self):
        #Fake the db returning a visitor count of '5'
        mock_table = mock_boto3.resource.return_value.Table.return_value
        mock_table.update_item.return_value = {
            'Attributes': {
                'count': 5
            }
        }
        mock_table.get_item.return_value = {
            'item':{
                'count': 5
            }
        }
        #Run actual lambda function
        response= lambda_function.lambda_handler({},{})

        #Test did it return a 200 OK status?
        self.assertEqual(response['statusCode'],200)

        #Test did the body contain the word visitor_count
        #self.assertIn('visitor_count',response['body'])
        
        #Print the reponse to the terminal so you can see it working!
        print("\nSUCCESS!Your function returned:",response)

if __name__ == '__main__':
    unittest.main()
