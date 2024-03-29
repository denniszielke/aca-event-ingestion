param containerImage string
@description('Location resources.')
param location string = resourceGroup().location

@description('Specifies a project name that is used to generate the Event Hub name and the Namespace name.')
param projectName string

module logging 'logging.bicep' = {
  name: 'logging'
  params: {
    location: location
    logAnalyticsWorkspaceName: 'log-${projectName}'
  }
}

module environment 'environment.bicep' = {
  name: 'container-app-environment'
  params: {
    environmentName: '${projectName}'
    logAnalyticsCustomerId: logging.outputs.logAnalyticsCustomerId
    logAnalyticsSharedKey: logging.outputs.logAnalyticsSharedKey
  }
}

module servicebus 'servicebus.bicep' = {
  name: 'servicebus'
  params: {
    serviceBusName: 'sb-${projectName}'
  }
}

module nginx 'app-nginx.bicep' = {
  name: 'nginx-app'
  params: {
    containerImage: containerImage
    environmentName: '${projectName}'
    serviceBusName: projectName
  }
}
