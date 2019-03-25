# About the shell scripts
These shell script is used to deploy services to every environments *EXCEPT production*.
For detail workflow, see [this](https://staroad.atlassian.net/wiki/spaces/ITOPS/pages/360251446/Deploy+krug+services+DRAFT).
# Requirement

- bash version 4 : For macOsx, run `brew upgrade bash` to upgrade bash.
- jq (https://stedolan.github.io/jq/) : For macOsx, run `brew install jq` to install.
- A docker hub account
- A GitHub account
 
# HOW-TO
## Specify environemnt variables for docker login information
- DOCKER_LOGIN_USER : `export DOCKER_LOGIN_USER=${YOUR_LOGIN_USERNAME_OF_DOCKER_HUB}`
- DOCKER_LOGIN_PASSWORD : `export DOCKER_LOGIN_PASSOWRD=${YOUR_LOGIN_PASSWORD_OF_DOCKER_HUB}`

## Edit username and password to login remote servers
File: .passwd-[environment_id]

## Run
Run command: `bash continuous-deploy.sh [environment_id]`

e.g.

- integration: `bash continuous-deploy.sh int`
- staging: `bash continuous-deploy.sh staging`
