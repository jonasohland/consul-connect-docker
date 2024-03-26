ARG envoy_version

FROM envoyproxy/envoy:v${envoy_version}

ARG consul_version

RUN apt-get update \
    && apt-get install -y curl unzip \
    && curl -sSLO https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_amd64.deb \
    && dpkg -i dumb-init_1.2.5_amd64.deb \
    && rm dumb-init_1.2.5_amd64.deb \
    && curl -sSLO https://releases.hashicorp.com/consul/${consul_version}/consul_${consul_version}_linux_amd64.zip \
    && unzip consul_${consul_version}_linux_amd64.zip \
    && mv consul /usr/bin/consul \
    && rm consul_${consul_version}_linux_amd64.zip \
    && apt-get purge -y unzip curl \
    && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

ENTRYPOINT ["dumb-init", "consul", "connect", "envoy"]