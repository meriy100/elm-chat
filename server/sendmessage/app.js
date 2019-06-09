// Copyright 2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

const uuid = require('uuid');
const AWS = require('aws-sdk');

const ddb = new AWS.DynamoDB.DocumentClient({ apiVersion: '2012-08-10' });

const { CONNECTIONS_TABLE_NAME, ROOMS_TABLE_NAME } = process.env;

exports.handler = async (event, context) => {
  let connectionData;
  const connectionId = event.requestContext.connectionId;

  try {
    connectionData = await ddb.scan({ TableName: CONNECTIONS_TABLE_NAME }).promise();
  } catch (e) {
    return { statusCode: 500, body: e.stack };
  }

  const apigwManagementApi = new AWS.ApiGatewayManagementApi({
    apiVersion: '2018-11-29',
    endpoint: event.requestContext.domainName + '/' + event.requestContext.stage
  });

  const { roomId } = JSON.parse(event.body);
  const { message } = JSON.parse(event.body).data;
  const roomData = await ddb.get({ TableName: ROOMS_TABLE_NAME, Key: { id: roomId } }).promise();
  const newMessage = { id: uuid.v1(), content: message.content, timestamp: Number(Math.floor(Date.now() / 1000)) };

  const params = {
    TableName: ROOMS_TABLE_NAME,
    Key: {
      id: roomData.Item.id
    },
    ExpressionAttributeNames: {
      '#ms': 'messages',
    },
    ExpressionAttributeValues: {
      ':messages': [...roomData.Item.messages, newMessage],
    },
    UpdateExpression: 'SET #ms = :messages'
  };

  try {
    await ddb.update(params).promise();
  } catch(e) {
    console.log(e);
    return { statusCode: 500, body: JSON.stringify(e) }
  }

  const postData = JSON.stringify({ type: 'POSTED_MESSAGE', payload: newMessage });

  const postCalls = connectionData.Items.filter(c => c.roomId === roomId).map(async ({ connectionId }) => {
    try {
      await apigwManagementApi.postToConnection({ ConnectionId: connectionId, Data: postData }).promise();
    } catch (e) {
      if (e.statusCode === 410) {
        console.log(`Found stale connection, deleting ${connectionId}`);
        await ddb.delete({ TableName: CONNECTIONS_TABLE_NAME, Key: { connectionId } }).promise();
      } else {
        console.log(e);
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

