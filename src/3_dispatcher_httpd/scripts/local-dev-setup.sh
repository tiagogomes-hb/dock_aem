#!/bin/sh

echo "AUTHOR_FORCE_SSL should be updated accordingly ..."

if [ -z "${AUTHOR_FORCE_SSL}" ]; then
    AUTHOR_FORCE_SSL=0
fi

if [ -z "${PUBLISH_FORCE_SSL}" ]; then
    PUBLISH_FORCE_SSL=0
fi

sed -i -e 's/Define AUTHOR_FORCE_SSL [0-9]/Define AUTHOR_FORCE_SSL ${AUTHOR_FORCE_SSL}/g' /etc/httpd/conf.d/variables/*
sed -i -e 's/Define PUBLISH_FORCE_SSL [0-9]/Define PUBLISH_FORCE_SSL ${PUBLISH_FORCE_SSL}/g' /etc/httpd/conf.d/variables/*

echo "DISPATCHER_FLUSH_FROM_ANYWHERE should be updated accordingly ..."

if [ -z "${DISPATCHER_FLUSH_FROM_ANYWHERE}" ]; then
    DISPATCHER_FLUSH_FROM_ANYWHERE=deny
fi

echo -e "/999 {\n    /glob \"*.*.*.*\"\n    /type \"${DISPATCHER_FLUSH_FROM_ANYWHERE}\"\n}$(cat /etc/httpd/conf.dispatcher.d/cache/ams_publish_invalidate_allowed.any)" > /etc/httpd/conf.dispatcher.d/cache/ams_publish_invalidate_allowed.any
#sed -i '1i/999 {\n/    glob "*.*.*.*"\n    /type "${DISPATCHER_FLUSH_FROM_ANYWHERE}"\n}' /etc/httpd/conf.dispatcher.d/cache/ams_publish_invalidate_allowed.any
#echo '/999 {\n/    glob "*.*.*.*"\n    /type "${DISPATCHER_FLUSH_FROM_ANYWHERE}"\n}' | cat - /etc/httpd/conf.dispatcher.d/cache/ams_publish_invalidate_allowed.any > temp && mv temp /etc/httpd/conf.dispatcher.d/cache/ams_publish_invalidate_allowed.any

# /etc/httpd/conf.dispatcher.d/cache/ams_publish_invalidate_allowed.any
# /999 {
#        /glob "*.*.*.*"
#        /type "${DISPATCHER_FLUSH_FROM_ANYWHERE}"
#}

#echo "apache user must have permissions to write on the PUBLISH_DOCROOT ..."
# docker exec dispatcher-ams chown -R apache:apache /mnt/var/www/html
# docker exec dispatcher-ams chmod -R 755 /mnt/var/www/html
# docker exec dispatcher-ams ls -ld /mnt/var/www/html
# docker exec dispatcher-ams ls -l /mnt/var/www/html
# docker exec dispatcher-ams ls -ld /mnt/var/www/html/*
# docker exec dispatcher-ams ls -l /mnt/var/www/html/*
# docker exec dispatcher-ams ls -ld /mnt/var/www/html/*/*
# docker exec dispatcher-ams ls -l /mnt/var/www/html/*/*