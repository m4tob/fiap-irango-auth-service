
const pg = require('pg');
const { cpf: cpfValidator } = require('cpf-cnpj-validator');
const { CognitoUserPool, CognitoUser, AuthenticationDetails } = require('amazon-cognito-identity-js');
const { Client } = pg;

function signUp({ cpf, userPool }) {
 return new Promise((resolve, reject) => {  userPool.signUp(cpf, cpf, [], null, (err, result) => {

    if (!result) {
      return reject(err);
    }
    return resolve(result.user)
  });
 })
}

function authenticateUser({ cpf, userPool }) {

  const userData = {
    Username: cpf,
    Pool: userPool,
    }
  const authenticationDetails = new AuthenticationDetails({
    Username: cpf,
    Password: cpf
  })
  const userCognito = new CognitoUser(userData)

  return new Promise((resolve, reject) => {  
    userCognito.authenticateUser(authenticationDetails, {
      onSuccess: (result) => {
        resolve(result)
      },
      onFailure: (err) => {
        reject(err)
      }
    })
  })
}


exports.handler = async (event, context) => {
    console.log("EVENT: \n" + JSON.stringify(event, null, 2));
    console.log("EVENT: \n" + JSON.stringify(process.env, null, 2));

  try {

    const queryParams = event.queryStringParameters;
    const cpf = queryParams && queryParams.cpf ? queryParams.cpf : undefined;

    if (!cpf) {
        return 402;
    }

    const cpfClear = cpf.replace(/\D/g, '');

    if (!cpfValidator.isValid(cpfClear)) {
        return 402;
    }

    const client = new Client({
      host: process.env.PGHOST.split(':')[0],
      port: process.env.PGPORT,
      user: process.env.PGUSER,
      password: process.env.PGPASSWORD,
    })
    
    await client.connect()

    console.log("EVENT: \n" + JSON.stringify(client, null, 2));

    const query = {
        name: 'fetch-consumidor',
        text: 'SELECT * FROM Consumidor where cpf = $1',
        values: [cpf],
    }

    const res = await client.query(query);
    
    if (!res.rows[0]) {
        return 401
    }

    console.log("EVENT: \n" + JSON.stringify(res, null, 2));

    const userPool = new CognitoUserPool({
      UserPoolId: process.env.USER_POOL_ID,
      ClientId: process.env.CLIENT_ID,
    })

    const tt = await signUp({cpf, userPool})
    console.log(tt)

    const result =  await authenticateUser({
        cpf, userPool
    })

    console.log(result)
    return {
      status: 200,
      body: 'hello world!'
    }
      
  } catch (error) {
    console.log(error)

    return {
      status: 500,
      body: process.env
    }
  }
}