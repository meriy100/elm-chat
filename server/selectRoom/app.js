// Copyright 2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

const AWS = require('aws-sdk');

const ddb = new AWS.DynamoDB.DocumentClient({ apiVersion: '2012-08-10' });

const { CONNECTIONS_TABLE_NAME, ROOMS_TABLE_NAME } = process.env;

exports.handler = async (event, context) => {
    const connectionId = event.requestContext.connectionId;
    const request = JSON.parse(event.body);
    const roomData = await ddb.get({ TableName: ROOMS_TABLE_NAME, Key: { id: request.keys.id } }).promise();
    const params = {
        TableName: CONNECTIONS_TABLE_NAME,
        Key: {
            connectionId: connectionId
        },
        ExpressionAttributeNames: {
            '#rid': 'roomId',
        },
        ExpressionAttributeValues: {
            ':roomId': roomData.Item.id,
        },
        UpdateExpression: 'SET #rid = :roomId'
    };

    try {
        await ddb.update(params).promise();
    } catch(e) {
        console.log(e);
        return { statusCode: 500, body: JSON.stringify(e) }
    }

    const apigwManagementApi = new AWS.ApiGatewayManagementApi({
        apiVersion: '2018-11-29',
        endpoint: event.requestContext.domainName + '/' + event.requestContext.stage
    });

    const postData = JSON.stringify({ type: 'SET_ROOM_ID', payload: true });

    try {
        await apigwManagementApi.postToConnection({ ConnectionId: connectionId, Data: postData }).promise();
    } catch (e) {
        if (e.statusCode === 410) {
            console.log(`Found stale connection, deleting ${connectionId}`);
            await ddb.delete({ TableName: CONNECTIONS_TABLE_NAME, Key: { connectionId } }).promise();
        } else {
            console.log("Error : post rooms " + JSON.stringify(e));
            throw e;
        }
    }
    return { statusCode: 200, body: 'Data sent.' };
};

