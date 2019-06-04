// Copyright 2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

const uuid = require('uuid');
const AWS = require('aws-sdk');

const ddb = new AWS.DynamoDB.DocumentClient({ apiVersion: '2012-08-10' });

const { CONNECTIONS_TABLE_NAME, MESSAGES_TABLE_NAME } = process.env;

exports.handler = async (event, context) => {
  let connectionData;
  const connectionId = event.requestContext.connectionId;

  try {
    connectionData = await ddb.scan({ TableName: CONNECTIONS_TABLE_NAME, ProjectionExpression: 'connectionId' }).promise();
  } catch (e) {
    return { statusCode: 500, body: e.stack };
  }

  const apigwManagementApi = new AWS.ApiGatewayManagementApi({
    apiVersion: '2018-11-29',
    endpoint: event.requestContext.domainName + '/' + event.requestContext.stage
  });

  const { message } = JSON.parse(event.body).data;
  const putParams = {
    TableName: MESSAGES_TABLE_NAME,
    Item: {
      id: uuid.v1(),
      message: message
    }
  };

  ddb.put(putParams, (err, data) => {
    if (!!err) {
      console.log("Error: putItem" + JSON.stringify(err));
      return { statusCode: 500, body: err };
    } else {
    }
  });

  const postData = JSON.stringify({ type: 'POSTED_MESSAGE', message: message });

  const postCalls = connectionData.Items.map(async ({ connectionId }) => {
    try {
      await apigwManagementApi.postToConnection({ ConnectionId: connectionId, Data: postData }).promise();
    } catch (e) {
      if (e.statusCode === 410) {
        console.log(`Found stale connection, deleting ${connectionId}`);
        await ddb.delete({ TableName: CONNECTIONS_TABLE_NAME, Key: { connectionId } }).promise();
      } else {
        throw e;
      }
    }
  });

  try {
    await Promise.all(postCalls);
  } catch (e) {
    console.log(e);
    return { statusCode: 500, body: e.stack };
  }

  return { statusCode: 200, body: 'Data sent.' };
};

