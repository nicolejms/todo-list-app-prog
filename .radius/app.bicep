extension radius

param environment string

@secure()
param password string

@secure()
param registryUsername string

@secure()
param registryPassword string

resource todoApp 'Radius.Core/applications@2025-08-01-preview' = {
  name: 'todo-list-app-prog'
  properties: {
    environment: environment
  }
}

resource mysqlDb 'Radius.Data/mySqlDatabases@2025-08-01-preview' = {
  name: 'mysql'
  properties: {
    environment: environment
    application: todoApp.id
    codeReference: 'src/persistence/mysql.js#L31'
    database: 'todos'
    version: '8.0'
    username: 'myadmin'
    password: password
  }
}

resource registryCreds 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'radius-ghcr-registry-creds'
  properties: {
    environment: environment
    application: todoApp.id
    data: {
      username: {
        value: registryUsername
      }
      password: {
        value: registryPassword
      }
    }
  }
}

resource todoImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'todo-list-app-prog-image'
  properties: {
    environment: environment
    application: todoApp.id
    codeReference: 'Dockerfile'
    build: {
      source: 'git::https://github.com/nicolejms/todo-list-app-prog.git?ref=0c1d96f2bc6e404d47024ec295ea45946d3a614d'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource todoContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'todo-list-app-prog'
  properties: {
    environment: environment
    application: todoApp.id
    codeReference: 'src/index.js#L18'
    containers: {
      todo: {
        image: todoImage.properties.imageReference
        ports: {
          web: {
            containerPort: 3000
          }
        }
        env: {
          MYSQL_HOST: {
            value: mysqlDb.properties.host
          }
          MYSQL_USER: {
            value: 'myadmin'
          }
          MYSQL_PASSWORD: {
            value: password
          }
          MYSQL_DB: {
            value: 'todos'
          }
        }
      }
    }
  }
}
