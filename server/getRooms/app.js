// Copyright 2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

const AWS = require('aws-sdk');

const ddb = new AWS.DynamoDB.DocumentClient({ apiVersion: '2012-08-10' });

const { ROOMS_TABLE_NAME } = process.env;

exports.handler = async (event, context) => {
    const connectionId = event.requestContext.connectionId;
    let roomsData;

    try {
        roomsData = await ddb.scan({ TableName: ROOMS_TABLE_NAME }).promise();
    } catch (e) {
        console.log("Error : scan rooms " + JSON.stringify(e));
        return { statusCode: 500, body: e.stack };
    }

    const apigwManagementApi = new AWS.ApiGatewayManagementApi({
        apiVersion: '2018-11-29',
        endpoint: event.requestContext.domainName + '/' + event.requestContext.stage
    });

    const postData = JSON.stringify({ type: 'GET_ROOMS', payload: roomsData.Items });

    try {
        await apigwManagementApi.postToConnection({ ConnectionId: connectionId, Data: postData }).promise();
    } catch (e) {
        if (e.statusCode === 410) {
            console.log(`Found stale connection, deleting ${connectionId}`);
            // await ddb.delete({ TableName: CONNECTIONS_TABLE_NAME, Key: { connectionId } }).promise();
        } else {
            console.log("Error : post rooms " + JSON.stringify(e));
            throw e;
        }
    }
    return { statusCode: 200, body: 'Data sent.' };
};

