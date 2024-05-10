
exports.handler = async (event, context) => {
  console.log("EVENT: \n" + JSON.stringify(event, null, 2));
  console.log("EVENT: \n" + JSON.stringify(process.env, null, 2));

  event['response']['autoConfirmUser'] = true

  if (event['request']['userAttributes']) {
    event['response']['autoVerifyEmail'] = true

  }
  console.log("EVENT: \n" + JSON.stringify(event, null, 2));

  return event;
}