# Python + Geo Tools container images

[Find all images and tags on dockerhub](https://hub.docker.com/r/windpioneers/gdal-python)

Can be used to develop and productionise a geodjango project or other scientific / geospatial services.

A range of tools are included - the most important version changes being gdal and python.

But, these tools and configuration can change and be quite fast moving compared to the underlying stack.
So, we use a release name in combination with the key versions of gdal and python to form image tags.

The tag format is:

```
windpioneers/gdal-python:<release-name>-gdal-<gdal-version>-python-<python-version>-<build-mode>
```

Examples:

- `windpioneers/gdal-python:button-gdal-2.4.1-python-3.9-dev`, or
- `windpioneers/gdal-python:monster-gdal-2.4.1-python-3.8-slim`

You'll want to check the release notes for this repository to understand what's in the different named releases.

## For development

Images with the `-dev` tag suffix are based on Microsoft devcontainers, which are useful universally, but especially as a base for `.devcontainer`s and remote code collaboration in VSCode.

These images include additional development features, including:

- A fully set up `zsh` terminal with `oh-my-zsh`, that maps git and SSH to your local machine (seamless git commands and shortcuts from inside your container)
- Poetry pre-installed
- Node.js pre-installed with `prettier`, enabling format-on-save within vscode
- Austin profiler, allowing flame-graph visualisation of python process memory and CPU requirements for optimisation

## For production

Images with the `-slim` tag suffix are based on python's `buster-slim` images, providing a minimal installation of OS dependencies for quick and low-memory container orchestration, and low memory usage in serverless environments.

Of course, these images have none of the developer tools installed but do have `poetry` for installation of your app dependencies.

If you end up needing a development dependency in production (for some reason), that's not a fundamental problem - the `-dev` images shouldn't introduce any insecurities, but will take longer to pass through build process, and cost more to run day-to-day.

## Geo Tools

Included in the geo stack is:

- libkml (Google's version, which is compatible with various features used in Google Maps and Earth that the default `libkml` isn't)
- GDAL (compiled against the Google libkml)
- GEOS
- PROJ

## Using a `.devcontainer`

Follow VSCode's instructions for using `.devcontainer`s (there are endless online tutorials). You'll want to base your devcontainer on one of the `-dev` images.

Your `.devcontainer/Dockerfile` should look like this:

```
FROM windpioneers/gdal-python:button-gdal-2.4.1-python-3.9-dev

# Tell zsh where you want to store history
#     We leave you to decide, but if you put this into a folder that's been mapped
#     into the container, then history will persist over container rebuilds :)
#
#     !!!IMPORTANT!!!
#     Make sure your .zsh_history file is NOT committed into your repository, as it can contain
#     sensitive information. So in this case, you should add
#         .devcontainer/.zsh_history
#     to your .gitignore file.
#
ENV HISTFILE="workspace/.devcontainer/.zsh_history"

# Install poetry, cache poetry dependencies
#
#    Poetry usage in docker: https://stackoverflow.com/a/54763270/3556110
#    Caching package downloads with buildkit: https://pythonspeed.com/articles/docker-cache-pip-downloads/
#    Using pipx for python development utilities: https://github.com/microsoft/vscode-dev-containers/blob/main/containers/python-3/README.md#installing-or-updating-python-utilities
#
#    Why don't we do this for you in the gdal-python image???
#     - we may need to move the poetry version quicker than the base image
#     - because we can't conditionally mount a cache (for dev/slim images)
#     - poetry and dependencies can be agony, so we want per-project control at least for now
#     - if a repo is not using poetry, it doesn't make sense for us to force the presence of the tool
USER vscode
RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python
ENV PATH "/home/vscode/.poetry/bin:$PATH"
RUN poetry config virtualenvs.create false
#
# It is possible to install dependencies with a cache, like this:
# COPY pyproject.toml poetry.lock ./
# RUN --mount=type=cache,id=dev-cache,target=/home/vscode/.cache \
#     poetry install --no-interaction --no-ansi
#
# However, it may be more reliable or convenient to do poetry install as a postcreate command (see devcontainer.json)
```

These are highly opinionated settings which you can change for yourself. But we thing your `.devcontainer/devcontainer.json` should look like this:

```js
// For format details, see https://aka.ms/devcontainer.json. For config options, see the README at:
// https://github.com/microsoft/vscode-dev-containers/tree/v0.187.0/containers/python-3
{
  "name": "GeoPython",
  "build": {
    "dockerfile": "Dockerfile",
    "context": "..",
  },

  // Set *default* container specific settings.json values on container create.
  "settings": {
    "austin.mode": "Wall time",
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true,
    "jupyter.widgetScriptSources": ["jsdelivr.com", "unpkg.com"],
    "prettier.prettierPath": "/usr/local/prettier", // Note: Prettier is installed (with its requisite installation of node to run it) already, and linked here
    "python.formatting.autopep8Path": "/usr/local/py-utils/bin/autopep8",
    "python.formatting.blackPath": "/usr/local/py-utils/bin/black",
    "python.formatting.provider": "black",
    "python.formatting.yapfPath": "/usr/local/py-utils/bin/yapf",
    "python.languageServer": "Pylance",
    "python.linting.banditPath": "/usr/local/py-utils/bin/bandit",
    "python.linting.enabled": true,
    "python.linting.flake8Path": "/usr/local/py-utils/bin/flake8",
    "python.linting.mypyPath": "/usr/local/py-utils/bin/mypy",
    "python.linting.pycodestylePath": "/usr/local/py-utils/bin/pycodestyle",
    "python.linting.pydocstylePath": "/usr/local/py-utils/bin/pydocstyle",
    // Line length to match black settings
    // Disabling specific messages:
    //  - To find the details do: /usr/local/py-utils/bin/pylint --list-msgs
    //  - Disable missing-module-docstring (C0114) because we don't document modules routinely, just their members
    //  - Disable invalid-name (C0103) because pylint thinks that eg 'x', 'df', 'np' are invalid due to their lengths
    "python.linting.pylintArgs": [
      "--max-line-length=120",
      "--disable=missing-module-docstring,invalid-name"
    ],
    "python.linting.pylintEnabled": true,
    "python.linting.pylintPath": "/usr/local/py-utils/bin/pylint",
    "python.pythonPath": "/usr/local/bin/python",
    "terminal.integrated.defaultProfile.linux": "zsh"
  },

  // Add the IDs of extensions you want installed when the container is created.
  "extensions": [
    "erikphansen.vscode-toggle-column-selection",
    "esbenp.prettier-vscode",
    "irongeek.vscode-env",
    "mikestead.dotenv",
    "ms-python.python",
    "ms-python.vscode-pylance",
    "ms-toolsai.jupyter",
    "ms-toolsai.jupyter-renderers",
    "ms-toolsai.jupyter-keymap",
    "ms-vsliveshare.vsliveshare",
    "p403n1x87.austin-vscode", // For profiling
    "ritwickdey.liveserver"  // For serving previews of html documents, e.g. those generated by sphinx
  ],

  // Use 'forwardPorts' to make a list of ports inside the container available locally.
  "forwardPorts": [80, 443, 7045, 7046, 7047, 7048, 7049, 8080],

  // Use 'postCreateCommand' to run commands after the container is created.
  "postCreateCommand": "echo \"Install your requirements here\"",

  // Comment out connect as root instead - but some of the devtools might stop working! More info: https://aka.ms/vscode-remote/containers/non-root.
  "remoteUser": "vscode",

  // Allow ptrace based debuggers (like austin) to work in the container
  // DO NOT add these run arguments to containers that are in any way exposed to external users or the internet
  "runArgs": ["--cap-add=SYS_PTRACE", "--security-opt", "seccomp=unconfined"]

}
```

## Developing this stack

Containers are build and tagged in a matrix, allowing us to add gdal/python versions whilst also evolving the other development tools at the same time.

1. Additional versions can be added to the build matrix in the `.github/workflows/release.yml` file.

2. Additional other edits or installs can be made in the dockerfile.

3. Build the image locally just to check it works. You won't push it from your machine, so don't need to tag it (here we tag as `local-gdal-python` so you can build locally and try it out). We support aarch64 and x86_64 architecture, so always make sure images build for both.

```
docker buildx build --platform linux/arm64 --platform linux/aarch64 --build-arg BASE_IMAGE=mcr.microsoft.com/vscode/devcontainers/python:0-3.9 --build-arg INSTALL_DEV_TOOLS=true --platform linux/x86_64 --platform linux/aarch64 -t local-gdal-python .
```

4. Once satisfied that your dockerfile builds, push or merge your code to main branch.

5. In GitHub Releases, click "create release". Give your new release a name which is:

- lower case
- a noun
- hasn't been used before

> Be creative. Choose `button`? `wildberry`? Up to you. Surprise me. Keep it clean.
