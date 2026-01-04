#!/bin/sh
set -eu

if [ -z "$INPUT_REMOTE_DOCKER_HOST" ]; then
    echo "Input remote_docker_host is required!"
    exit 1
fi

if [ -z "$INPUT_SSH_PRIVATE_KEY" ]; then
    echo "Input ssh_private_key is required!"
    exit 1
fi

if [ -z "$INPUT_ARGS" ]; then
  echo "Input input_args is required!"
  exit 1
fi

if [ -z "$INPUT_STACK_FILE_NAME" ]; then
  INPUT_STACK_FILE_NAME=docker-compose.yml
fi

if [ -z "$INPUT_SSH_PORT" ]; then
  INPUT_SSH_PORT=22
fi

STACK_FILE=${INPUT_STACK_FILE_NAME}
DOCKER_HOST="ssh://$INPUT_REMOTE_DOCKER_HOST:$INPUT_SSH_PORT"
echo $DOCKER_HOST

DEPLOYMENT_COMMAND="docker compose -f $STACK_FILE"


SSH_HOST=${INPUT_REMOTE_DOCKER_HOST#*@}

echo "Registering SSH keys..."

# register the private key with the agent.
mkdir -p ~/.ssh
ls ~/.ssh
printf '%s\n' "$INPUT_SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
eval $(ssh-agent)
ssh-add ~/.ssh/id_rsa


# disable host key checking
echo "StrictHostKeyChecking no" >> $(find /etc -iname ssh_config)

if  [ -n "$INPUT_DOCKER_LOGIN_PASSWORD" ] || [ -n "$INPUT_DOCKER_LOGIN_USER" ] || [ -n "$INPUT_DOCKER_LOGIN_REGISTRY" ]; then
  echo "Connecting to $INPUT_REMOTE_DOCKER_HOST... Command: docker login"
  DOCKER_HOST="ssh://$INPUT_REMOTE_DOCKER_HOST:$INPUT_SSH_PORT" docker login -u "$INPUT_DOCKER_LOGIN_USER" -p "$INPUT_DOCKER_LOGIN_PASSWORD" "$INPUT_DOCKER_LOGIN_REGISTRY"
fi

echo "Command: DOCKER_HOST="ssh://$INPUT_REMOTE_DOCKER_HOST:$INPUT_SSH_PORT" ${DEPLOYMENT_COMMAND} ${INPUT_ARGS}"
DOCKER_HOST="ssh://$INPUT_REMOTE_DOCKER_HOST:$INPUT_SSH_PORT" ${DEPLOYMENT_COMMAND} ${INPUT_ARGS}


