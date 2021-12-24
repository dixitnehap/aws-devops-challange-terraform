// const axios = require('axios')
// const url = 'http://checkip.amazonaws.com/';
let response;

/**
 *
 * Event doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-input-format
 * @param {Object} event - API Gateway Lambda Proxy Input Format
 *
 * Context doc: https://docs.aws.amazon.com/lambda/latest/dg/nodejs-prog-model-context.html 
 * @param {Object} context
 *
 * Return doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html
 * @returns {Object} object - API Gateway Lambda Proxy Output Format
 * 
 */
 exports.lambdaHandler = async (event, context) => {
    let body;
    let statusCode = 200;
    let htmlTemplate = "";
    const headers = {
        "Content-Type": "text/html"
    };
    
    try {
        switch (event.httpMethod) {
            case "GET":
            case "POST":
                let welcomeMessage = `<h1>Welcome to our demo API, here are the details of your request:</h1>`;
                let eventContentType = `<b>Headers:</b> Content-Type: ${event.headers["content-type"]}`;
                let eventHttpMethod = `<b>Method:</b> ${event.httpMethod}`;
                let eventJsonBody = `<b>Body:</b> ${event.body}<br/>`;
                htmlTemplate = `<html><head>AWS Lamda Function Response</head><body>${welcomeMessage}<br/>${eventContentType}<br />${eventHttpMethod}<br />${eventJsonBody}</body></html>`;
            break;
            default:
                throw new Error(`Unsupported route: "${event.httpMethod}"`);
        }
    } catch (err) {
        statusCode = 400;
        htmlTemplate = err.message;
    } finally {
        body = htmlTemplate;
    }
    
    return {
        statusCode,
        body,
        headers
    };
};
