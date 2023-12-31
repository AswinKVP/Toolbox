# the below script is generating documents for CosmosDB container
# document looks as following
# {
#    "id": "27a25aab-f3ce-4bd4-b9f8-69fb40b2d234",    #this field is a unique device id
#    "ownerId": 77,     #this field is used as a partitioning key
#    "schemaType": "devices",
#    "deviceType": "laptop",
#    "macAddress": "23007a78-0000-0100-0000-621887c80000",
#    "os": "windows",
# }

import uuid
import random
import numpy as np


columns = ['id', 'ownerId', 'schemaType', 'deviceType', 'macAddress', 'os']
deviceType = ['laptop', 'pc', 'tablet', 'cellphone']
os = ['windows', 'apple', 'android', 'linux']

num_rows = 100

data_df = pd.DataFrame(np.random.randint(0,100,size=(10, 1)), columns=['id_int'])
data_df["id"] = data_df.apply(lambda _: f'{uuid.uuid4()}', axis=1)
data_df["deviceType"] = np.random.choice(deviceType, size=len(data_df))
data_df['ownerId'] = 77
data_df['schemaType'] = 'devices'
data_df['os']= np.random.choice(os, size=len(data_df))
data_df['macAddress'] = data_df.apply(lambda _: f'{uuid.uuid4()}', axis=1)


display(data_df)

sparkDF=spark.createDataFrame(data_df[columns])

sparkDF.write.format("cosmos.oltp")\
    .option("spark.synapse.linkedService", "<enter linked service name>")\
    .option("spark.cosmos.container", "<enter container name>")\
    .mode('append')\
    .save()