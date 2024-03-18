@description('Specifies the Azure location for all resources.')
param location string = resourceGroup().location

param serviceBusName string 

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  name: serviceBusName
  location: location
  sku: {
    name: 'Premium'
    tier: 'Premium'
    capacity: 4
  }
}

resource queuename 'Microsoft.ServiceBus/namespaces/queues@2021-11-01' = {
  name: 'queuename'
  parent: serviceBus
}
