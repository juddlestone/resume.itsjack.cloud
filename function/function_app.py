import azure.functions as func
import logging
from azure.data.tables import TableServiceClient
from azure.core.exceptions import ResourceNotFoundError
import os

# Initialize the function app
app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

# Connection string should be stored in app settings
connection_string = os.environ["AzureWebJobsStorage"]

@app.route(route="counter")
def counter(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')
    
    try:
        # Create the table service client
        table_service = TableServiceClient.from_connection_string(connection_string)
        
        # Get a reference to the table
        table_client = table_service.get_table_client("visitcounter")
        
        try:
            # Try to get the counter entity
            counter_entity = table_client.get_entity(
                partition_key="statistics",
                row_key="visitors"
            )
            count = counter_entity['count']
        except ResourceNotFoundError:
            # If the entity doesn't exist, create it
            counter_entity = {
                'PartitionKey': 'statistics',
                'RowKey': 'visitors',
                'count': 0
            }
            table_client.create_entity(entity=counter_entity)
            count = 0
        
        # Increment the counter
        count += 1
        
        # Update the entity
        counter_entity['count'] = count
        table_client.update_entity(entity=counter_entity)
        
        # Return the current count
        return func.HttpResponse(
            body=str(count),
            status_code=200,
            mimetype="text/plain"
        )
            
    except Exception as e:
        logging.error(f"Error: {str(e)}")
        return func.HttpResponse(
            body=f"An error occurred: {str(e)}",
            status_code=500
        )