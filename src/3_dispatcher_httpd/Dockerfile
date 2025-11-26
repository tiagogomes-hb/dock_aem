#
# Copyright (c) 2024 Adobe Systems Incorporated. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
FROM --platform=$TARGETPLATFORM redhat/ubi8:8.8

# Install HTTPD
RUN yum -y update && yum -y install httpd mod_ssl procps haproxy iputils less openssl && yum clean all

# Remove default httpd config
RUN rm -rf /etc/httpd/conf/* && rm -rf /etc/httpd/conf.d/* && rm -rf /etc/httpd/conf.modules.d/*

# Copy the AMS base files into the image.
COPY ams/2.6/etc/httpd /etc/httpd
# Setup sample configs
COPY sample/weretail_filters.any /etc/httpd/conf.dispatcher.d/filters/weretail_filters.any
COPY sample/weretail_publish_farm.any /etc/httpd/conf.dispatcher.d/available_farms/100_weretail_publish_farm.any
COPY sample/weretail.vhost /etc/httpd/conf.d/available_vhosts/

# Copy haproxy config
COPY haproxy/haproxy.cfg /etc/haproxy

COPY scripts/local-dev-setup.sh /
# Ensuring correct file ending on windows systems
RUN sed -i -e 's/\r\n/\n/' /local-dev-setup.sh
RUN chmod +x /local-dev-setup.sh

# Install dispatcher
ARG TARGETARCH
COPY scripts/setup.sh /
RUN chmod +x /setup.sh
# Ensuring correct file ending on windows systems
RUN sed -i -e 's/\r\n/\n/' /setup.sh
RUN ./setup.sh
RUN rm /setup.sh

COPY scripts/launch.sh /
# Ensuring correct file ending on windows systems
RUN sed -i -e 's/\r\n/\n/' /launch.sh
RUN chmod +x /launch.sh
RUN mkdir -p /mnt/var/www/lc

COPY scripts/reload.sh /
# Ensuring correct file ending on windows systems
RUN sed -i -e 's/\r\n/\n/' /reload.sh
RUN chmod +x /reload.sh

COPY LICENSE /
COPY NOTICE /

EXPOSE  80 443

# Start container
ENTRYPOINT ["/bin/bash","/launch.sh"]
#ENTRYPOINT ["tail", "-f", "/dev/null"]