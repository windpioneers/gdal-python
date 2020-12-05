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
1. Build the image locally (automatic build on push is currently not set up)
`docker build -t <hub-user>/<repo-name>[:<tag>] .`

2. Push to docker hub
`docker push <hub-user>/<repo-name>:<tag>`