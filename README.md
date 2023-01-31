# Microservice communication using service invoke (sync)

In this quickstart, you'll create two microservices that communicate using Dapr's Service Invocation API. The Service Invocation API enables your applications to communicate reliably and securely by leveraging auto-mTLS and built-in retries.

![](images/service-invocation-quickstart.png)

Visit [this](https://docs.dapr.io/developing-applications/building-blocks/service-invocation/) link for more information about Dapr and Service Invocation.

# Run and develop locally

### Run the order-processor service (callee) with Dapr

2. Open a new terminal window, change directories to `./order-processor` and run: 

```bash
cd order-processor
dotnet restore
dotnet build
```

3. Run the order-processor service (callee) service with Dapr: 

```bash
dapr run --app-port 7001 --app-id order-processor --app-protocol http --dapr-http-port 3501 -- dotnet run
```

### Run the checkout service (caller) with Dapr

2. Open a new terminal window, change directories to `./checkout` and run: 

```bash
cd checkout
dotnet restore
dotnet build
```

3. Run the checkout service (callee) service with Dapr: 

```bash
dapr run  --app-id checkout --app-protocol http --dapr-http-port 3500 -- dotnet run
```

4. Expected output:
In both terminals, you'll see orders passed and orders received. Service invocation requests are made from the checkout service to the order-processor service: 

Output from the checkout service:
```bash
== APP == Order passed: {"orderId":1}
== APP == Order passed: {"orderId":2}
== APP == Order passed: {"orderId":3}
== APP == Order passed: {"orderId":4}
```

Output from the order-processor service:
```bash
== APP == Order received: { orderId: 1 }
== APP == Order received: { orderId: 2 }
== APP == Order received: { orderId: 3 }
== APP == Order received: { orderId: 4 }
```

# Deploy to Azure (Azure Container Apps)
Deploy to Azure for dev-test

> NOTE: make sure you have Azure Dev CLI pre-reqs [here](https://github.com/Azure-Samples/todo-python-mongo-aca)

1. Provision infra and deploy application:
```bash
azd up
```

2. Confirm the deployment is susccessful:

Navigate to the Container App resources for both the Checkout and Order-Processor services. Locate the `Log stream` and confirm the app container is logging each request successfully. 

![](images/log_stream_checkout.png)
![](images/log_stream_orders.png)

