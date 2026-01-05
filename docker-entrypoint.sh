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

if [ -z "$INPUT_DOCKER_COMMAND" ]; then
  INPUT_DOCKER_COMMAND="docker compose -f docker-compose.yml up -d"
fi

if [ -z "$INPUT_SSH_PORT" ]; then
  INPUT_SSH_PORT=22
fi

DOCKER_HOST="ssh://$INPUT_REMOTE_DOCKER_HOST:$INPUT_SSH_PORT"
echo $DOCKER_HOST


SSH_HOST=${INPUT_REMOTE_DOCKER_HOST#*@}

echo "Registering SSH keys..."

# register the private key with the agent.
mkdir -p ~/.ssh
ls ~/.ssh
printf '%s\n' "$INPUT_SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
eval $(ssh-agent)
ssh-add ~/.ssh/id_rsa

#echo "Add known hosts"
#ssh-keyscan -p $INPUT_SSH_PORT "$SSH_HOST" >> ~/.ssh/known_hosts
#ssh-keyscan -p $INPUT_SSH_PORT "$SSH_HOST" >> /etc/ssh/ssh_known_hosts
# set context
#echo "Create docker context"
#docker context create staging --docker "host=ssh://$INPUT_REMOTE_DOCKER_HOST:$INPUT_SSH_PORT"
#docker context use staging

# disable host key checking
echo "Disable host key checking via ssh_config"
echo "StrictHostKeyChecking no" >> $(find /etc -iname ssh_config)

if  [ -n "$INPUT_DOCKER_LOGIN_PASSWORD" ] || [ -n "$INPUT_DOCKER_LOGIN_USER" ] || [ -n "$INPUT_DOCKER_LOGIN_REGISTRY" ]; then
  echo "Connecting to $INPUT_REMOTE_DOCKER_HOST... Command: docker login"
  DOCKER_HOST="ssh://$INPUT_REMOTE_DOCKER_HOST:$INPUT_SSH_PORT" docker login -u "$INPUT_DOCKER_LOGIN_USER" -p "$INPUT_DOCKER_LOGIN_PASSWORD" "$INPUT_DOCKER_LOGIN_REGISTRY"
fi

echo "Command: DOCKER_HOST="ssh://$INPUT_REMOTE_DOCKER_HOST:$INPUT_SSH_PORT" ${INPUT_DOCKER_COMMAND}"
DOCKER_HOST="ssh://$INPUT_REMOTE_DOCKER_HOST:$INPUT_SSH_PORT" ${INPUT_DOCKER_COMMAND} 