/**
 * A Lambda function that logs the payload received from a CloudWatch scheduled event.
 */

import AWS from 'aws-sdk';
const sns = new AWS.SNS();
const dynamodb = new AWS.DynamoDB.DocumentClient();

const getTodayDate = () => {
  const today = new Date();
  return today.toISOString().split('T')[0]; // "2025-07-30"
};

export const scheduledEventLoggerHandler = async (event, context) => {
    // All log statements are written to CloudWatch by default. For more information, see
    // https://docs.aws.amazon.com/lambda/latest/dg/nodejs-prog-model-logging.html
    // console.info(JSON.stringify(event));

    // const message = process.env.REMINDER_MESSAGE || 'Stay awesome! 💪';
    const topicArn = process.env.SNS_TOPIC_ARN;
    const tableName = process.env.REMINDER_TABLE;

    if (!topicArn || topicArn.startsWith('!GetAtt') || !topicArn.includes('arn:aws:sns:')) {
        console.log('Running in local mode - SNS publishing skipped');
        console.log('Message that would be sent:', message);
        return {
            statusCode: 200,
            body: 'Local execution - reminder logged successfully!',
        };
    }

    const today = getTodayDate();
    try {
        const reminders = await dynamodb.query({
            TableName: tableName,
            IndexName: 'DueDateIndex',
            KeyConditionExpression: 'dueDate = :dueDate',
            ExpressionAttributeValues: {
                ':dueDate': today,
            },
        }).promise();

        if (!reminders.Items || reminders.Items.length === 0) {
            console.log('No reminders due today');
            return { statusCode: 200, body: 'No reminders due today' };
        }

        const message = reminders.Items.map(r => `- ${r.message}`).join('\n');

        await sns.publish({
            Message: `Today's Reminders:\n${message}`,
            TopicArn: topicArn
        }).promise();


        console.log('Sent reminders:', message);
        return {
            statusCode: 200,
            body: 'Reminders sent successfully!',
        };
    } catch (error) {
        console.error('Error fetching or sending reminders:', error);
        return {
            statusCode: 500,
            body: 'Failed to process reminders',
        };
    }
};
