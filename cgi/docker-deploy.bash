#!/bin/bash

echo "Content-Type: text/plain"
echo

if [[ -n "$DOCKER_REMOTE_SSH_KEY" ]] || [[ -n "$DOCKER_REMOTE_USER" ]] || [[ -n "$DOCKER_REMOTE_HOST" ]] || [[ -n "$AUTHORIZED_TOKEN" ]]; then
    echo "At least one configuration parameter is missing"
    exit 1
fi

declare -A param   
while IFS='=' read -r -d '&' key value && [[ -n "$key" ]]; do
    param["$key"]=$value
done <<<"${QUERY_STRING}&"

IMAGE="${param[image]}"
TOKEN="${param[token]}"
NAME="${param[name]}"
PORT="${param[port]}"

if [[ -n "$IMAGE" ]] || [[ -n "$TOKEN" ]] || [[ -n "$NAME" ]] || [[ -n "$PORT" ]]; then
    echo "Missing image, port, token or name query parameter"
    exit 1
fi

if [[ "$TOKEN" != "$AUTHORIZED_TOKEN" ]]; then
    echo "Unauthorized token"
    exit 1
fi

ssh -i "${DOCKER_REMOTE_SSH_KEY}" "${DOCKER_REMOTE_USER}@${DOCKER_REMOTE_HOST}" -- docker pull "$IMAGE"
ssh -i "${DOCKER_REMOTE_SSH_KEY}" "${DOCKER_REMOTE_USER}@${DOCKER_REMOTE_HOST}" -- docker stop "$NAME"
ssh -i "${DOCKER_REMOTE_SSH_KEY}" "${DOCKER_REMOTE_USER}@${DOCKER_REMOTE_HOST}" -- docker rm "$NAME"
ssh -i "${DOCKER_REMOTE_SSH_KEY}" "${DOCKER_REMOTE_USER}@${DOCKER_REMOTE_HOST}" -- docker run --restart always -d -p "$PORT":"$PORT" --env PORT="$PORT" --name "$NAME" "$IMAGE"