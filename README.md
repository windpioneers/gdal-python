# GDAL + Python base image for windquest geo stack

## Application

Can be used as the base image for a geodjango project.


## Development

### Clone the repository
`git clone https://github.com/windpioneers/docker-gdal-python`


### Edit the dockerfile
1. Make necessary edits to update python and gdal versions, add extra dependencies, etc

2. Build the image locally just to check it works. You won't push it from your machine, so don't need to tag it. We support arm64 and x86 architecture, so build for both.

`docker buildx build --platform linux/arm64,linux/arm64 .`


### Release 

1. Once satisfied that your dockerfile builds, push your code to main branch.

2. In GitHub Releases, click "create release". Give your new release a tag with the pattern `gdal-x.y.z-python-x.y.z`, with any kebab-case suffixes you need.


## Note
The dockerfile is set up to use build args; it's possible to bump the version of either gdal or python for your own purposes like...

`docker build --build-arg GDAL_VERSION=v2.4.1 --build-arg BASE_IMAGE=python:3.8.6-slim-buster .`

For now however, the automated build-deploy of releases to docker hub don't use build args, so you have to ensure the release tag matches the versions in the dockerfile. 
