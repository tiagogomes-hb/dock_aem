#!/bin/bash

echo "1. Installing apt packages..."
artifactsToRemove="aem-base aem-author-65 aem-author-cloud aem-publish-65 aem-publish-cloud dispatcher-amd dispatcher-arm dispatcher-ams fake-smtp-server"

echo $artifactsToRemove | xargs -n2 docker container stop --time 30

echo $artifactsToRemove | xargs -n2 docker container remove --force

echo $artifactsToRemove | xargs -n2 docker image rm --force

docker volume remove --force aem-author-65-data aem-author-cloud-data aem-publish-65-data aem-publish-cloud-data

docker network rm aem-network
