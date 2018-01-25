# Verdaccio npm registry

Dockerfile for setting up and running a [Verdaccio](http://www.verdaccio.org/) npm registry instance. 

[Verdaccio](https://github.com/verdaccio/verdaccio) is the successor to [Sinopia](https://github.com/rlidwka/sinopia).

## Usage

To create a local copy of the image from the Dockerfile
```
./make.sh build
```
To run the built image
```
./make.sh run
```
This will run something like the following, based on the variables in make.sh
```
  docker run \
    --detach \
    --volume verdaccio-storage:/verdaccio/storage:rw \
    --publish 4873:4873 \
    --name verdaccio \
    --restart always  \
    deployable/verdaccio:2.7.3
```
