# <a name="about"></a>About

This README explains how to launch MongoDB on Kubernetes and Docker.

For more information, see the
[Official Image Launcher Page](https://console.cloud.google.com/launcher/details/google/mongodb3).

Pull command:
```shell
gcloud docker -- pull launcher.gcr.io/google/mongodb3
```

Dockerfile for this image can be found [here](https://github.com/GoogleCloudPlatform/mongodb-docker/tree/master/3).

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
    - image: launcher.gcr.io/google/mongodb3
      name: mongo
```

Run the following to expose the port:
```shell
kubectl expose pod some-mongo --name some-mongo-27017 \
  --type LoadBalancer --port 27017 --protocol TCP
```

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
    - image: launcher.gcr.io/google/mongodb3
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

Run the following to expose the port:
```shell
kubectl expose pod some-mongo --name some-mongo-27017 \
  --type LoadBalancer --port 27017 --protocol TCP
```

## <a name="configurations-kubernetes"></a>Configurations

See the [official docs](http://docs.mongodb.org/manual/) for infomation on using and configuring MongoDB for things like replica sets and sharding.

### <a name="using-flags-kubernetes"></a>Using flags

Just add the `--storageEngine` argument if you want to use the WiredTiger storage engine in MongoDB 3.0 and above without making a config file. Be sure to check the [docs](http://docs.mongodb.org/manual/release-notes/3.0-upgrade/#change-storage-engine-to-wiredtiger) on how to upgrade from older versions.

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
    - image: launcher.gcr.io/google/mongodb3
      name: mongo
      args:
        - --storageEngine wiredTiger
```

Run the following to expose the port:
```shell
kubectl expose pod some-mongo --name some-mongo-27017 \
  --type LoadBalancer --port 27017 --protocol TCP
```

You can also list all available options (several pages long).

```shell
kubectl run \
  some-mongo-client \
  --image launcher.gcr.io/google/mongodb3 \
  --rm --attach --restart=Never \
  -- --verbose --help
```

### <a name="authentication-and-authorization-kubernetes"></a>Authentication and authorization

MongoDB does not require authentication by default, but it can be configured to do so. For more details about the functionality described here, please see the sections in the official documentation which describe [authentication](https://docs.mongodb.org/manual/core/authentication/) and [authorization](https://docs.mongodb.org/manual/core/authorization/) in more detail.

Start the Database.

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
    - image: launcher.gcr.io/google/mongodb3
      name: mongo
      args:
        - --auth
```

Run the following to expose the port:
```shell
kubectl expose pod some-mongo --name some-mongo-27017 \
  --type LoadBalancer --port 27017 --protocol TCP
```

Add the initial admin user:

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

## <a name="mongo-cli-kubernetes"></a>Mongo CLI

This section describes how to use this image as a MongoDB client.

### <a name="connect-to-a-running-mongodb-container-kubernetes"></a>Connect to a running MongoDB container

You can run a MongoDB client directly within the container.

```shell
kubectl exec -it some-mongo -- mongo
```

### <a name="connect-to-a-remote-mongodb-server-kubernetes"></a>Connect to a remote MongoDB server

Assume that we have a MongoDB server running at `some-host`. We want to log on to `some-db` as `some-user` and password is `some-pass`.

```shell
kubectl run \
  some-mongo-client \
  --image launcher.gcr.io/google/mongodb3 \
  --rm --attach --restart=Never \
  -it \
  -- sh -c 'exec mongo some-host/some-db --username some-user --password some-pass --authenticationDatabase admin'
```

# <a name="using-docker"></a>Using Docker

## <a name="run-a-mongodb-server-docker"></a>Run a MongoDB server

This section describes how to spin up a MongoDB service using this image.

### <a name="start-a-mongodb-instance-docker"></a>Start a MongoDB instance

Use the following content for the `docker-compose.yml` file, then run `docker-compose up`.
```yaml
version: '2'
services:
  mongo:
    image: launcher.gcr.io/google/mongodb3
```

Or you can use `docker run` directly:

```shell
docker run \
  --name some-mongo \
  -d \
  launcher.gcr.io/google/mongodb3
```

The MongoDB server is accessible on port 27017.

See [Configurations](#configurations-docker) for how to customize your MongoDB service instance.

### <a name="use-a-persistent-data-volume-docker"></a>Use a persistent data volume

We can store MongoDB data on a persistent volume. This way the database remains intact across restarts. Assume that `/my/persistent/dir/mongo` is the persistent directory on the host.

Use the following content for the `docker-compose.yml` file, then run `docker-compose up`.
```yaml
version: '2'
services:
  mongo:
    image: launcher.gcr.io/google/mongodb3
    volumes:
      - /my/persistent/dir/mongo:/data/db
```

Or you can use `docker run` directly:

```shell
docker run \
  --name some-mongo \
  -v /my/persistent/dir/mongo:/data/db \
  -d \
  launcher.gcr.io/google/mongodb3
```

## <a name="configurations-docker"></a>Configurations

See the [official docs](http://docs.mongodb.org/manual/) for infomation on using and configuring MongoDB for things like replica sets and sharding.

### <a name="using-flags-docker"></a>Using flags

Just add the `--storageEngine` argument if you want to use the WiredTiger storage engine in MongoDB 3.0 and above without making a config file. Be sure to check the [docs](http://docs.mongodb.org/manual/release-notes/3.0-upgrade/#change-storage-engine-to-wiredtiger) on how to upgrade from older versions.

Use the following content for the `docker-compose.yml` file, then run `docker-compose up`.
```yaml
version: '2'
services:
  mongo:
    image: launcher.gcr.io/google/mongodb3 \
    command:
      - --storageEngine wiredTiger
```

Or you can use `docker run` directly:

```shell
docker run \
  --name some-mongo \
  -d \
  launcher.gcr.io/google/mongodb3 \
  --storageEngine wiredTiger
```

You can also list all available options (several pages long).

```shell
docker run \
  --name some-mongo-client \
  --rm \
  launcher.gcr.io/google/mongodb3 \
  --verbose --help
```

### <a name="authentication-and-authorization-docker"></a>Authentication and authorization

MongoDB does not require authentication by default, but it can be configured to do so. For more details about the functionality described here, please see the sections in the official documentation which describe [authentication](https://docs.mongodb.org/manual/core/authentication/) and [authorization](https://docs.mongodb.org/manual/core/authorization/) in more detail.

Start the Database.

Use the following content for the `docker-compose.yml` file, then run `docker-compose up`.
```yaml
version: '2'
services:
  mongo:
    image: launcher.gcr.io/google/mongodb3 \
    command:
      - --auth
```

Or you can use `docker run` directly:

```shell
docker run \
  --name some-mongo \
  -d \
  launcher.gcr.io/google/mongodb3 \
  --auth
```

Add the initial admin user:

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

## <a name="mongo-cli-docker"></a>Mongo CLI

This section describes how to use this image as a MongoDB client.

### <a name="connect-to-a-running-mongodb-container-docker"></a>Connect to a running MongoDB container

You can run a MongoDB client directly within the container.

```shell
docker exec -it some-mongo mongo
```

### <a name="connect-to-a-remote-mongodb-server-docker"></a>Connect to a remote MongoDB server

Assume that we have a MongoDB server running at `some-host`. We want to log on to `some-db` as `some-user` and password is `some-pass`.

```shell
docker run \
  --name some-mongo-client \
  --rm \
  -it \
  launcher.gcr.io/google/mongodb3 \
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
| /data/db | Stores the database files. |
