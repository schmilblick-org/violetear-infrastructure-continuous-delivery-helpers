#!/bin/bash

echo "Content-Type: text/plain"
echo

if [[ -z "$DOCKER_REMOTE_SSH_KEY" ]] || [[ -z "$DOCKER_REMOTE_USER" ]] || [[ -z "$DOCKER_REMOTE_HOST" ]] || [[ -z "$AUTHORIZED_TOKEN" ]]; then
    echo "At least one configuration parameter is missing"
    exit 1
fi

declare -A param   
while IFS='=' read -r -d '&' key value && [[ -n "$key" ]]; do
    param["$key"]=$value
done

IMAGE="${param[image]}"
TOKEN="${param[token]}"
NAME="${param[name]}"
PORT="${param[port]}"
IMAGE_PORT="${param[image_port]}"

if [[ -z "$IMAGE_PORT" ]]; then
    IMAGE_PORT="$PORT"
fi

if [[ -z "$IMAGE" ]] || [[ -z "$TOKEN" ]] || [[ -z "$NAME" ]] || [[ -z "$PORT" ]]; then
    echo "Missing image, port, token or name query parameter"
    exit 1
fi

if [[ "$TOKEN" != "$AUTHORIZED_TOKEN" ]]; then
    echo "Unauthorized token"
    exit 1
fi

DOCKER_ENV=""
for key in "${!param[@]}"; do
    if [[ "$key" != "image" ]] && [[ "$key" != "token" ]] && [[ "$key" != "name" ]] && [[ "$key" != "port" ]] && [[ "$key" != "image_port" ]]; then
        DOCKER_ENV += "-e \"${key@Q}=${param[$key]@Q}\" "
    fi
done

COMMANDS="docker pull \"${IMAGE@Q}\"; docker stop \"${NAME@Q}\"; docker rm \"${NAME@Q}\"; docker run --restart always -d -p \"${PORT@Q}\":\"${IMAGE_PORT@Q}\" --env PORT=\"${PORT@Q}\" ${DOCKER_ENV} --name \"${NAME@Q}\" \"${IMAGE@Q}\";"

ssh -i "${DOCKER_REMOTE_SSH_KEY}" "${DOCKER_REMOTE_USER}@${DOCKER_REMOTE_HOST}" -t "bash -l -c \"$COMMANDS\""