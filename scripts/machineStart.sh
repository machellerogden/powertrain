#!/bin/bash
source $POWERTRAIN_DIR/var/ARGS.sh
enforce_args_length 1
source $POWERTRAIN_DIR/var/MACHINE_NAME.sh ${ARGS[0]}

STATUS=$(docker-machine status $MACHINE_NAME)
if [[ "$STATUS" == "Stopped" ]]; then
    docker-machine start $MACHINE_NAME
fi

