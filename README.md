mongodb-docker
============

Dockerfile source for mongodb [docker](https://docker.io) image.

## Upstream
This source repo was originally copied from:
https://github.com/docker-library/mongo

## Disclaimer
This is not an official Google product.

## About
This image contains an installation of MongoDB

For more information, see the
[Official Image Marketplace Page](https://console.cloud.google.com/marketplace/product/google/mongodb4).

### Prerequisites

Configure [gcloud](https://cloud.google.com/sdk/gcloud/) as a Docker credential helper:

```shell
gcloud auth configure-docker
```

### Pull command

```shell
docker -- pull marketplace.gcr.io/google/mongodb4
```

# <a name="table-of-contents"></a>Table of Contents
* [Using Kubernetes](#using-kubernetes)
  * [Run a MongoDB server](#run-a-mongodb-server-kubernetes)
    * [Start a MongoDB instance](#start-a-mongodb-instance-kubernetes)
    * [Use a persistent data volume](#use-a-persistent-data-volume-kubernetes)
  * [Configurations](#configurations-kubernetes)
    * [Using flags](#using-flags-kubernetes)
    * [Authentication and authorization](#authentication-and-authorization-kubernetes)
  * [Mongo CLI](#mongo-cli-kubernetes)
    * [Connect to a running MongoDB container](#connect-to-a-running-mongodb-container-kubernetes)
    * [Connect to a remote MongoDB server](#connect-to-a-remote-mongodb-server-kubernetes)
* [Using Docker](#using-docker)
  * [Run a MongoDB server](#run-a-mongodb-server-docker)
    * [Start a MongoDB instance](#start-a-mongodb-instance-docker)
    * [Use a persistent data volume](#use-a-persistent-data-volume-docker)
  * [Configurations](#configurations-docker)
    * [Using flags](#using-flags-docker)
    * [Authentication and authorization](#authentication-and-authorization-docker)
  * [Mongo CLI](#mongo-cli-docker)
    * [Connect to a running MongoDB container](#connect-to-a-running-mongodb-container-docker)
    * [Connect to a remote MongoDB server](#connect-to-a-remote-mongodb-server-docker)
* [References](#references)
  * [Ports](#references-ports)
  * [Volumes](#references-volumes)

# <a name="using-kubernetes"></a>Using Kubernetes

Consult [Launcher container documentation](https://cloud.google.com/launcher/docs/launcher-container)
for additional information about setting up your Kubernetes environment.

## <a name="run-a-mongodb-server-kubernetes"></a>Run a MongoDB server

This section describes how to spin up a MongoDB service using this image.

### <a name="start-a-mongodb-instance-kubernetes"></a>Start a MongoDB instance

Copy the following content to `pod.yaml` file, and run `kubectl create -f pod.yaml`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: some-mongo
  labels:
    name: some-mongo
spec:
  containers:
    - image: marketplace.gcr.io/google/mongodb4
      name: mongo
```

Run the following to expose the port.
Depending on your cluster setup, this might expose your service to the
Internet with an external IP address. For more information, consult
[Kubernetes documentation](https://kubernetes.io/docs/concepts/services-networking/connect-applications-service/).

```shell
kubectl expose pod some-mongo --name some-mongo-27017 \
  --type LoadBalancer --port 27017 --protocol TCP
```

For information about how to retain your database across restarts, see [Use a persistent data volume](#use-a-persistent-data-volume-kubernetes).

See [Configurations](#configurations-kubernetes) for how to customize your MongoDB service instance.

### <a name="use-a-persistent-data-volume-kubernetes"></a>Use a persistent data volume

We can store MongoDB data on a persistent volume. This way the database remains intact across restarts.

Copy the following content to `pod.yaml` file, and run `kubectl create -f pod.yaml`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: some-mongo
  labels:
    name: some-mongo
spec:
  containers:
    - image: marketplace.gcr.io/google/mongodb4
      name: mongo
      volumeMounts:
        - name: data
          mountPath: /data/db
          subPath: data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: data
---
# Request a persistent volume from the cluster using a Persistent Volume Claim.
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: data
  annotations:
    volume.alpha.kubernetes.io/storage-class: default
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 5Gi
```

Run the following to expose the port.
Depending on your cluster setup, this might expose your service to the
Internet with an external IP address. For more information, consult
[Kubernetes documentation](https://kubernetes.io/docs/concepts/services-networking/connect-applications-service/).

```shell
kubectl expose pod some-mongo --name some-mongo-27017 \
  --type LoadBalancer --port 27017 --protocol TCP
```

## <a name="configurations-kubernetes"></a>Configurations

See the [official docs](http://docs.mongodb.org/manual/) for infomation on using and configuring MongoDB for things like replica sets and sharding.

### <a name="using-flags-kubernetes"></a>Using flags

You can specify options directly to `mongod` when starting the instance. For example, you can set `--storageEngine` to `wiredTiger` to enable WiredTiger storage engine.

A common use-case is adding the parameter `--bind_ip_all` to bind the container to all possible IPv4 addresses.

Check other parameters at [mongod Reference](https://docs.mongodb.com/manual/reference/program/mongod/).

Copy the following content to `pod.yaml` file, and run `kubectl create -f pod.yaml`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: some-mongo
  labels:
    name: some-mongo
spec:
  containers:
    - image: marketplace.gcr.io/google/mongodb4
      name: mongo
      args:
        - --storageEngine wiredTiger
```

Run the following to expose the port.
Depending on your cluster setup, this might expose your service to the
Internet with an external IP address. For more information, consult
[Kubernetes documentation](https://kubernetes.io/docs/concepts/services-networking/connect-applications-service/).

```shell
kubectl expose pod some-mongo --name some-mongo-27017 \
  --type LoadBalancer --port 27017 --protocol TCP
```

You can also list all available options (several pages long).

```shell
kubectl run \
  some-mongo-client \
  --image marketplace.gcr.io/google/mongodb4 \
  --rm --attach --restart=Never \
  -- --verbose --help
```

### <a name="authentication-and-authorization-kubernetes"></a>Authentication and authorization

MongoDB does not require authentication by default, but it can be configured to do so by using `--auth` option.

Copy the following content to `pod.yaml` file, and run `kubectl create -f pod.yaml`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: some-mongo
  labels:
    name: some-mongo
spec:
  containers:
    - image: marketplace.gcr.io/google/mongodb4
      name: mongo
      args:
        - --auth
```

Run the following to expose the port.
Depending on your cluster setup, this might expose your service to the
Internet with an external IP address. For more information, consult
[Kubernetes documentation](https://kubernetes.io/docs/concepts/services-networking/connect-applications-service/).

```shell
kubectl expose pod some-mongo --name some-mongo-27017 \
  --type LoadBalancer --port 27017 --protocol TCP
```

Open an admin CLI shell.

```shell
kubectl exec -it some-mongo -- mongo admin
```

Create a user `some-user` and set password as `some-pass`.

```
db.createUser({
  "user" : "some-user",
  "pwd" : "some-pass",
  "roles" : [
    {
      "role" : "userAdminAnyDatabase",
      "db" : "admin"
    }
  ]
});
```

For more information, see [authentication](https://docs.mongodb.org/manual/core/authentication/) and [authorization](https://docs.mongodb.org/manual/core/authorization/) sections on the official MongoDB documentation.

## <a name="mongo-cli-kubernetes"></a>Mongo CLI

This section describes how to use this image as a MongoDB client.

### <a name="connect-to-a-running-mongodb-container-kubernetes"></a>Connect to a running MongoDB container

You can run a MongoDB client directly within the container.

```shell
kubectl exec -it some-mongo -- mongo
```

### <a name="connect-to-a-remote-mongodb-server-kubernetes"></a>Connect to a remote MongoDB server

Assume that we have a MongoDB server running at `some-host`. We want to log on to `some-db` as `some-user` with `some-pass` as the password.

```shell
kubectl run \
  some-mongo-client \
  --image marketplace.gcr.io/google/mongodb4 \
  --rm --attach --restart=Never \
  -it \
  -- sh -c 'exec mongo some-host/some-db --username some-user --password some-pass --authenticationDatabase admin'
```

# <a name="using-docker"></a>Using Docker

Consult [Launcher container documentation](https://cloud.google.com/launcher/docs/launcher-container)
for additional information about setting up your Docker environment.

## <a name="run-a-mongodb-server-docker"></a>Run a MongoDB server

This section describes how to spin up a MongoDB service using this image.

### <a name="start-a-mongodb-instance-docker"></a>Start a MongoDB instance

Use the following content for the `docker-compose.yml` file, then run `docker-compose up`.

```yaml
version: '2'
services:
  mongo:
    container_name: some-mongo
    image: marketplace.gcr.io/google/mongodb4
    ports:
      - '27017:27017'
```

Or you can use `docker run` directly:

```shell
docker run \
  --name some-mongo \
  -p 27017:27017 \
  -d \
  marketplace.gcr.io/google/mongodb4
```

The MongoDB server is accessible on port 27017.

For information about how to retain your database across restarts, see [Use a persistent data volume](#use-a-persistent-data-volume-docker).

See [Configurations](#configurations-docker) for how to customize your MongoDB service instance.

### <a name="use-a-persistent-data-volume-docker"></a>Use a persistent data volume

We can store MongoDB data on a persistent volume. This way the database remains intact across restarts. Assume that `/my/persistent/dir/mongo` is the persistent directory on the host.

Use the following content for the `docker-compose.yml` file, then run `docker-compose up`.

```yaml
version: '2'
services:
  mongo:
    container_name: some-mongo
    image: marketplace.gcr.io/google/mongodb4
    ports:
      - '27017:27017'
    volumes:
      - /my/persistent/dir/mongo:/data/db
```

Or you can use `docker run` directly:

```shell
docker run \
  --name some-mongo \
  -p 27017:27017 \
  -v /my/persistent/dir/mongo:/data/db \
  -d \
  marketplace.gcr.io/google/mongodb4
```

## <a name="configurations-docker"></a>Configurations

See the [official docs](http://docs.mongodb.org/manual/) for infomation on using and configuring MongoDB for things like replica sets and sharding.

### <a name="using-flags-docker"></a>Using flags

You can specify options directly to `mongod` when starting the instance. For example, you can set `--storageEngine` to `wiredTiger` to enable WiredTiger storage engine.

A common use-case is adding the parameter `--bind_ip_all` to bind the container to all possible IPv4 addresses.

Check other parameters at [mongod Reference](https://docs.mongodb.com/manual/reference/program/mongod/).

Use the following content for the `docker-compose.yml` file, then run `docker-compose up`.

```yaml
version: '2'
services:
  mongo:
    container_name: some-mongo
    image: marketplace.gcr.io/google/mongodb4 \
    command:
      - --storageEngine wiredTiger
    ports:
      - '27017:27017'
```

Or you can use `docker run` directly:

```shell
docker run \
  --name some-mongo \
  -p 27017:27017 \
  -d \
  marketplace.gcr.io/google/mongodb4 \
  --storageEngine wiredTiger
```

You can also list all available options (several pages long).

```shell
docker run \
  --name some-mongo-client \
  --rm \
  marketplace.gcr.io/google/mongodb4 \
  --verbose --help
```

### <a name="authentication-and-authorization-docker"></a>Authentication and authorization

MongoDB does not require authentication by default, but it can be configured to do so by using `--auth` option.

Use the following content for the `docker-compose.yml` file, then run `docker-compose up`.

```yaml
version: '2'
services:
  mongo:
    container_name: some-mongo
    image: marketplace.gcr.io/google/mongodb4 \
    command:
      - --auth
    ports:
      - '27017:27017'
```

Or you can use `docker run` directly:

```shell
docker run \
  --name some-mongo \
  -p 27017:27017 \
  -d \
  marketplace.gcr.io/google/mongodb4 \
  --auth
```

Open an admin CLI shell.

```shell
docker exec -it some-mongo mongo admin
```

Create a user `some-user` and set password as `some-pass`.

```
db.createUser({
  "user" : "some-user",
  "pwd" : "some-pass",
  "roles" : [
    {
      "role" : "userAdminAnyDatabase",
      "db" : "admin"
    }
  ]
});
```

For more information, see [authentication](https://docs.mongodb.org/manual/core/authentication/) and [authorization](https://docs.mongodb.org/manual/core/authorization/) sections on the official MongoDB documentation.

## <a name="mongo-cli-docker"></a>Mongo CLI

This section describes how to use this image as a MongoDB client.

### <a name="connect-to-a-running-mongodb-container-docker"></a>Connect to a running MongoDB container

You can run a MongoDB client directly within the container.

```shell
docker exec -it some-mongo mongo
```

### <a name="connect-to-a-remote-mongodb-server-docker"></a>Connect to a remote MongoDB server

Assume that we have a MongoDB server running at `some-host`. We want to log on to `some-db` as `some-user` with `some-pass` as the password.

```shell
docker run \
  --name some-mongo-client \
  --rm \
  -it \
  marketplace.gcr.io/google/mongodb4 \
  sh -c 'exec mongo some-host/some-db --username some-user --password some-pass --authenticationDatabase admin'
```

# <a name="references"></a>References

## <a name="references-ports"></a>Ports

These are the ports exposed by the container image.

| **Port** | **Description** |
|:---------|:----------------|
| TCP 27017 | Standard MongoDB port. |

## <a name="references-volumes"></a>Volumes

These are the filesystem paths used by the container image.

| **Path** | **Description** |
|:---------|:----------------|
| /data/db | Stores the database files.
