// Copyright 2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

var AWS = require("aws-sdk");
AWS.config.update({ region: process.env.AWS_REGION });
const ddb = new AWS.DynamoDB.DocumentClient({ apiVersion: '2012-08-10' });

const { CONNECTIONS_TABLE_NAME } = process.env;

exports.handler = async (event, context) => {
  console.log(event);

  var putParams = {
    TableName: CONNECTIONS_TABLE_NAME,
    Item: {
      connectionId: event.requestContext.connectionId,
      roomId: null
    }
  };

  try {
    await ddb.put(putParams).promise();
    return { statusCode: 200, body: "Connected!" }
  } catch(e) {
    console.log(e);
    return { statusCode: 500, body: e.stack }
  }
};
