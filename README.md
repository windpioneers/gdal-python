# Wind Pioneers' GDAL Python base image for windquest stack (backend/django)

## Application

Can be used as the base image for a geodjango project.

## Development

### Authenticate docker cli
`docker login`

Note: Login using an account which has access to the windpioneers organisation

### Clone the repository
`git clone https://github.com/windpioneers/docker-gdal-python`

### Push edited image to docker hub
1. Make necessary edits and build the image locally (automatic build on push is currently not set up)
`docker build -t windpioneers/gdal-python:<tag> .`

Note: If all we need to do is bump the version of either gdal or python you can use build args,

`docker build --build-arg GDAL_VERSION=v2.4.1 --build-arg BASE_IMAGE=python:3.8.6-slim-buster -t windpioneers/gdal-python:<tag> .`

Use the versions you need to build with


2. Push to docker hub
`docker push windpioneers/gdal-python:<tag>`
