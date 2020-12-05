# Wind Pioneers' GDAL Python base image for windquest stack (backend/django)

Versions
GDAL - 2.4.1
Python - 3.6.9

## Application

Can be used as the base image for a geodjango project (as it is being used right now).

**Tagging is done based on versions of gdal and python - this one will have a G241_P369 tag**

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

`docker build --build-arg GDAL_VERSION=v2.4.1 --build-arg PYTHON_RUNTIME_VERSION=3.6.9 -t windpioneers/gdal-python:<tag> .`

Use the versions you need to build with


2. Push to docker hub
`docker push windpioneers/gdal-python:<tag>`