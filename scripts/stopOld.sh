#!/bin/bash
source $POWERTRAIN_DIR/var/ARGS.sh
VERSION_SCRIPT=${ARGS[3]}
source $POWERTRAIN_DIR/var/NAME.sh ${ARGS[0]}
source $POWERTRAIN_DIR/var/IMAGE.sh ${ARGS[0]} ${ARGS[1]}
source $POWERTRAIN_DIR/var/REGISTRY.sh ${ARGS[2]}
source $POWERTRAIN_DIR/var/INSTANCES.sh ${ARGS[4]}
CONTAINERS="$(docker ps | grep "$REGISTRY""$NAME" | awk '{print $1}' | xargs docker inspect -f "{{.Created}} {{.Id}}" | sort -r | tail -n +$((INSTANCES + 1)) | awk '{print $2}')"
if [ -n "$CONTAINERS" ]; then
    echo "Stopping the following containers:"
    printf "$CONTAINERS"
    printf "$CONTAINERS" | xargs docker stop
else
    echo "No containers to stop."
fi
