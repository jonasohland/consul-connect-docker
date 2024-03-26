#! /bin/bash

DATA_DIR="${DATA_DIR:-/var/lib/consul-connect-proxy-builder}"
SOURCE_DIR="${SOURCE_DIR:-/usr/src/consul-connect-proxy}"
MINOR_VERSION="${MINOR_VERSION:-1.15}"


# fetch a list of all available consul versions
if ! readarray -t versions <<<"$(curl --fail -s https://releases.hashicorp.com/consul/ | sed -n 's@.*<a href="/consul/\([0-9\.]*\)/">.*@\1@p' | sort -V)"; then
    exit 1
fi

# make a list of unique minor versions
readarray -t minor_versions <<< "$(printf "%s\n" "${versions[@]}" | cut -d. -f1-2 | uniq)"

# make a list of unique minor versions after MINOR_VERSION
build_minor_versions=()
for minor_version in "${minor_versions[@]}"; do
    if ! printf "%s\n" "${minor_version}" "${MINOR_VERSION}" | sort -CV; then
        build_minor_versions+=("${minor_version}")
    fi
done

echo "building for minor versions:" "${build_minor_versions[@]}"


for minor_version in "${build_minor_versions}"; then
    


fi


exit 0

# build a list of the ones more recent that what was found in $DATA_DIR/last
build=()
for version in "${versions[@]}"; do
    if ! echo -e "${version}\n${last_successful_version}" | sort -CV; then
        build+=("${version}")
    fi
done

# check if enything needs to be built
if [[ "${#build[@]}" = "0" ]]; then
    echo "nothing to build"
    exit 0
fi

echo "building:" "${build[@]}"

for version in "${build[@]}"; do
    echo "starting build for consul v${version}"
    if ! curl --fail -sL "https://api.github.com/repos/hashicorp/consul/tarball/v${version}" -o "/tmp/consul-source-v${version}.tar.gz"; then
        echo "failed download consul source"
    fi

    sourcedir=$(mktemp -d)
    tar -C "$sourcedir" -x -f "/tmp/consul-source-v${version}.tar.gz"

    # read the supported envoy versions from the consul source code
    readarray -t envoy_versions <<< "$(sed -n '/var EnvoyVersions/, /\}/p' "${sourcedir}/"hashicorp-consul-*"/envoyextensions/xdscommon/proxysupport.go" | sed -n 's@.*"\([0-9.]*\)".*@\1@p' | sort -r -V)"

    if [[ "${#envoy_versions[0]}" = "0" ]]; then
        echo "failed to detect compatible envoy versions"
        exit 1
    fi

    echo "building an image envoy=${envoy_versions[0]} consul=${version}"    
    if ! docker build --build-arg consul_version="${version}" --build-arg envoy_version="${envoy_versions[0]}" -t "jonasohland/consul-connect-proxy:${version}" "${SOURCE_DIR}"; then
        echo "failed to build docker image"
        exit 1
    fi

    echo "updating most recently built version to ${version}"
    echo "${version}" > "${DATA_DIR}/last"
done
