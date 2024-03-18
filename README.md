# Simple Event ingestion into ServiceBus using Nginx in Azure Container Apps and Dapr



High Level Architecture:
![](/architecture.png)


## Deploy Azure resources

```
PROJECT_NAME="dznginx6"
LOCATION="eastus"

bash ./deploy-infra.sh $PROJECT_NAME $LOCATION

```

## Deploy Apps into Container Apps

```
PROJECT_NAME="dznginx6"
NGINX_IMAGE="docker.io/denniszielke/nginx-dapr"

bash ./deploy-apps.sh $PROJECT_NAME $NGINX_IMAGE

```

## Explaination

1.) Publish to the right queue.

Nginx is forwarding to a local Dapr process which is listening on Port 3500.
The path is to be understood like this:
- Dapr expects content type application/json - if not already specied
- Dapr only works for HTTP Post
- /publish  tells Dapr to use a component of type pubsub
- /publisher/ is refering to the name of the publisher component as specified in L32 of app-nginx.bicep
- /queuename/ is refering to the name of the service bus queue as specified in L17 of servicebus.bicep
- ?metadata.rawPayload=true is making sure that Dapr is not encoing the message as a cloud event but passing through raw data

default.conf:
```
    location /return202 {
        proxy_set_header Content-Type 'application/json';
        proxy_method POST;
        proxy_pass http://127.0.0.1:3500/v1.0/publish/publisher/queuename?metadata.rawPayload=true;
        return 202;
    }

```

2.) Authentication to ServiceBus via Dapr in app-nginx.bicep

Dapr is able to use a predefined identity. The deployment script will deply an identity name 'nginx-msi' as specified in L15 of app-nginx.bicep and assign it the role of service bus publisher as defined by the role id in L23 of app-nginx.bicep in the role assignment.

Dapr allows scoping therefore we need to define in the publisher component which Azure Identity (specified in L56 from which tenant L52) is allowed to be used to authenticate to which service bus namespace (specified in L44).

If you want multiple Dapr apps and compnenents with different permissions you can also define scopes L56 for each Dapr App Id L90.

In the Container App we will assign the predefined identity to each container app instance - L73.

3.) Your own image from Azure Container Registry

If you want to use your own imag from your own container registry, you should use the defined Managed Identity acr-msi (L10 in environment.bicep) to grant it pull permissions to your ACR. 
The identity can be configured by uncommenting the registries config in L94 of app-nginx.bicep

4.) Scaling

By default all traffic will be load balanced between all instances. The scaling rules in L137 of app-nxing.bicep will define how much traffic an individual instance of nginx will receive. If there are more requests it will scale out and in accordingly.

The usage of resources might need to be adjusted. By default it will assing 2 CPU and 2GB of memory per Nginx instance. Configurable via L107.


5.) Network reachability of ACA App

By default the app is configured to be published with a public IP. The internal property in L34 of environment.bicep can turn the load balancer of ACA into a private frontend.

```
      internal: true
```

If the load balancer is private Azure will create another resource group with the load balancer in it which can be used to be put in the Application Gateway backend pool.