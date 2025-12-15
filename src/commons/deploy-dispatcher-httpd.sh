#!/bin/bash

echo "Check if PROJECT_SRC_DIR environment variable is defined ..."

if [ -z "${PROJECT_SRC_DIR}" ]; then
    echo "PROJECT_SRC_DIR environment variable is not defined, please set it to the root folder of your project where dispatcher folder is placed."
else
    echo "Copying project configs from ${PROJECT_SRC_DIR} to /etc/httpd ..."

    docker cp ${PROJECT_SRC_DIR}/dispatcher/httpd/conf dispatcher:/etc/httpd
    docker cp ${PROJECT_SRC_DIR}/dispatcher/httpd/conf.d dispatcher:/etc/httpd
    docker cp ${PROJECT_SRC_DIR}/dispatcher/httpd/conf.dispatcher.d dispatcher:/etc/httpd
    docker cp ${PROJECT_SRC_DIR}/dispatcher/httpd/conf.modules.d dispatcher:/etc/httpd

    echo "Running local-dev-setup.sh ..."

    docker exec dispatcher ./local-dev-setup.sh

    echo "Reloading dispatcher ..."

    docker exec dispatcher /reload.sh
    #docker restart -t0 dispatcher

    echo "Dispatcher reloaded."
fi