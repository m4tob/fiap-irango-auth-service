
const mysql = require('mysql2/promise');
const { cpf: cpfValidator } = require('cpf-cnpj-validator');
const { CognitoUserPool, CognitoUser, AuthenticationDetails } = require('amazon-cognito-identity-js');

function signUp({ cpf, userPool }) {
  return new Promise((resolve, reject) => {
    userPool.signUp(cpf, cpf, [], null, (err, result) => {

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
      console.log("CPF não informado");
      return 402;
    }

    const cpfClear = cpf.replace(/\D/g, '');

    if (!cpfValidator.isValid(cpfClear)) {
      console.log("CPF inválido");
      return 402;
    }

    const connection = await mysql.createConnection({
      host: process.env.DB_HOSTNAME,
      port: process.env.DB_PORT,
      database: process.env.DB_DATABASE,
      user: process.env.DB_USERNAME,
      password: process.env.DB_PASSWORD,
    });

    const [rows, fields] = await connection.execute(
      'SELECT * FROM `Consumidor` WHERE `cpf` = ?',
      [cpf]
    );

    console.log("EVENT: \n" + JSON.stringify(rows, null, 2));

    if (!rows[0]) {
      return 401
    }

    const userPool = new CognitoUserPool({
      UserPoolId: process.env.USER_POOL_ID,
      ClientId: process.env.CLIENT_ID,
    })

    const tt = await signUp({ cpf, userPool })
    console.log(tt)

    const result = await authenticateUser({
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