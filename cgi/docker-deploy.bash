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

if [[ -z "$IMAGE" ]] || [[ -z "$TOKEN" ]] || [[ -z "$NAME" ]] || [[ -z "$PORT" ]]; then
    echo "Missing image, port, token or name query parameter"
    exit 1
fi

if [[ "$TOKEN" != "$AUTHORIZED_TOKEN" ]]; then
    echo "Unauthorized token"
    exit 1
fi

COMMANDS="docker pull \"$IMAGE\"; docker stop \"$NAME\"; docker rm \"$NAME\"; docker run --restart always -d -p \"$PORT\":\"$PORT\" --env PORT=\"$PORT\" --name \"$NAME\" \"$IMAGE\";"

ssh -i "${DOCKER_REMOTE_SSH_KEY}" "${DOCKER_REMOTE_USER}@${DOCKER_REMOTE_HOST}" -t "bash -l -c \"$COMMANDS\""