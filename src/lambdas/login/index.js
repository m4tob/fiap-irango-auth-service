
const mysql = require('mysql2/promise');
const { cpf: cpfValidator } = require('cpf-cnpj-validator');
const { CognitoUserPool, CognitoUser, AuthenticationDetails, CognitoUserAttribute } = require('amazon-cognito-identity-js');

function signUp({ email, cpf, userPool }) {
  return new Promise((resolve, reject) => {
    userPool.signUp(email, cpf, [
      new CognitoUserAttribute({
        Name: 'custom:cpf', Value: cpf
      })
    ], null, (err, result) => {

      if (!result) {
        return reject(err);
      }
      return resolve(result.user)
    });
  })
}

function authenticateUser({ email, cpf, userPool }) {
  const userData = {
    Username: email,
    Pool: userPool,
  }

  const authenticationDetails = new AuthenticationDetails({
    Username: email,
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

    const userPool = new CognitoUserPool({
      UserPoolId: process.env.USER_POOL_ID,
      ClientId: process.env.CLIENT_ID,
    })


    if (!cpf) {
      console.log("CPF não informado");
      const result = await authenticateUser({
        email: process.env.NOT_IDENTIFIED_USERNAME,
        cpf: process.env.NOT_IDENTIFIED_PASS,
        userPool
      })

      return {
        statusCode: 200,
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify(result)
      }
    }

    const cpfClear = cpf.replace(/\D/g, '');

    if (!cpfValidator.isValid(cpfClear)) {
      console.log("CPF inválido");
      return {
        statusCode: 402,
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          message: "CPF inválido!"
          // Add more data as needed
        })
      }
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
      return {
          statusCode: 401,
          headers: {
            "Content-Type": "application/json"
          },
          body: JSON.stringify({
          message: " inválido!"
        })
      }
    }

    const email = $row[0]['email'] 

    try {
      const tt = await signUp({ email, cpf, userPool })
      console.log(tt)

    } catch (error) {
      console.log(error)

      if (error?.code !== 'UsernameExistsException') {
        return {
          statusCode: 401,
          headers: {
            "Content-Type": "application/json"
          },
          body: JSON.stringify({
            message: " inválido!"
          })
        }
      }
    }

    const result = await authenticateUser({
      email,
      cpf,
      userPool
    })

    console.log(result)
    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify(result)
    }
  } catch (error) {
    console.log(error)

    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        message: error
      })
    }
  }
}