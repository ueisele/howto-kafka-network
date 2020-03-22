#!/usr/bin/env bash
set -e
pushd . > /dev/null
cd $(dirname ${BASH_SOURCE[0]})
SCRIPT_DIR=$(pwd)
GIT_REPO_URL=$(git config --get remote.origin.url | sed 's/:/\//' | sed 's/\.git//' | sed 's/git@/https\:\/\//')
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
popd > /dev/null

PUSH=false
BUILD=false
DOCKERREGISTRY_USER="ueisele"
DEBIAN_RELEASE="bullseye"
WIRESHARK_VERSION="3.2.2"
TERMSHARK_VERSION="2.1.1"

function usage () {
    echo "$0: $1" >&2
    echo
    echo "Usage: $0 [--build] [--push] [--user <name, e.g. ueisele>] [--debian-release <debian-release, e.g. bullseye>] <wireshark-version, e.g. 3.2.2>"
    echo
    return 1
}

function build () {
    local commit=$(resolveCommit)
    local readmeUrl=${GIT_REPO_URL}/blob/${commit}/$(realpath --relative-to=${GIT_ROOT_DIR} ${SCRIPT_DIR}/README.adoc)
    
    docker build --target wireshark-build \
        -t "${DOCKERREGISTRY_USER}/wireshark-dev:${WIRESHARK_VERSION}-${DEBIAN_RELEASE}" \
        --build-arg DEBIAN_RELEASE=${DEBIAN_RELEASE} \
        --build-arg WIRESHARK_VERSION=${WIRESHARK_VERSION} \
        ${SCRIPT_DIR}

    docker build --target net-tools \
        -t "${DOCKERREGISTRY_USER}/net-tools:${DEBIAN_RELEASE}" \
        --build-arg DEBIAN_RELEASE=${DEBIAN_RELEASE} \
        --build-arg SOURCE_GIT_REPOSITORY=${GIT_REPO_URL} \
        --build-arg SOURCE_GIT_COMMIT=${commit} \
        --build-arg README_URL=${readmeUrl} \
        ${SCRIPT_DIR}
    docker tag "${DOCKERREGISTRY_USER}/net-tools:${DEBIAN_RELEASE}" "${DOCKERREGISTRY_USER}/net-tools:${DEBIAN_RELEASE}-$(resolveBuildTimestamp ${DOCKERREGISTRY_USER}/net-tools:${DEBIAN_RELEASE})"
    docker tag "${DOCKERREGISTRY_USER}/net-tools:${DEBIAN_RELEASE}" "${DOCKERREGISTRY_USER}/net-tools:latest"

    docker build --target tshark \
        -t "${DOCKERREGISTRY_USER}/tshark:${WIRESHARK_VERSION}-${DEBIAN_RELEASE}" \
        --build-arg DEBIAN_RELEASE=${DEBIAN_RELEASE} \
        --build-arg WIRESHARK_VERSION=${WIRESHARK_VERSION} \
        --build-arg SOURCE_GIT_REPOSITORY=${GIT_REPO_URL} \
        --build-arg SOURCE_GIT_COMMIT=${commit} \
        --build-arg README_URL=${readmeUrl} \
        ${SCRIPT_DIR}
    docker tag "${DOCKERREGISTRY_USER}/tshark:${WIRESHARK_VERSION}-${DEBIAN_RELEASE}" "${DOCKERREGISTRY_USER}/tshark:${WIRESHARK_VERSION}-${DEBIAN_RELEASE}-$(resolveBuildTimestamp ${DOCKERREGISTRY_USER}/tshark:${WIRESHARK_VERSION}-${DEBIAN_RELEASE})"
    docker tag "${DOCKERREGISTRY_USER}/tshark:${WIRESHARK_VERSION}-${DEBIAN_RELEASE}" "${DOCKERREGISTRY_USER}/tshark:${WIRESHARK_VERSION}"
    docker tag "${DOCKERREGISTRY_USER}/tshark:${WIRESHARK_VERSION}-${DEBIAN_RELEASE}" "${DOCKERREGISTRY_USER}/tshark:latest"

    docker build --target termshark \
        -t "${DOCKERREGISTRY_USER}/tshark-termshark:${WIRESHARK_VERSION}-${TERMSHARK_VERSION}-${DEBIAN_RELEASE}" \
        --build-arg DEBIAN_RELEASE=${DEBIAN_RELEASE} \
        --build-arg WIRESHARK_VERSION=${WIRESHARK_VERSION} \
        --build-arg TERMSHARK_VERSION=${TERMSHARK_VERSION} \
        --build-arg SOURCE_GIT_REPOSITORY=${GIT_REPO_URL} \
        --build-arg SOURCE_GIT_COMMIT=${commit} \
        --build-arg README_URL=${readmeUrl} \
        ${SCRIPT_DIR}
    docker tag "${DOCKERREGISTRY_USER}/tshark-termshark:${WIRESHARK_VERSION}-${TERMSHARK_VERSION}-${DEBIAN_RELEASE}" "${DOCKERREGISTRY_USER}/tshark-termshark:${WIRESHARK_VERSION}-${TERMSHARK_VERSION}-${DEBIAN_RELEASE}-$(resolveBuildTimestamp ${DOCKERREGISTRY_USER}/tshark-termshark:${WIRESHARK_VERSION}-${TERMSHARK_VERSION}-${DEBIAN_RELEASE})"
    docker tag "${DOCKERREGISTRY_USER}/tshark-termshark:${WIRESHARK_VERSION}-${TERMSHARK_VERSION}-${DEBIAN_RELEASE}" "${DOCKERREGISTRY_USER}/tshark-termshark:${WIRESHARK_VERSION}-${TERMSHARK_VERSION}"
    docker tag "${DOCKERREGISTRY_USER}/tshark-termshark:${WIRESHARK_VERSION}-${TERMSHARK_VERSION}-${DEBIAN_RELEASE}" "${DOCKERREGISTRY_USER}/tshark-termshark:${WIRESHARK_VERSION}"
    docker tag "${DOCKERREGISTRY_USER}/tshark-termshark:${WIRESHARK_VERSION}-${TERMSHARK_VERSION}-${DEBIAN_RELEASE}" "${DOCKERREGISTRY_USER}/tshark-termshark:latest"

    docker build --target wireshark \
        -t "${DOCKERREGISTRY_USER}/wireshark:${WIRESHARK_VERSION}-${DEBIAN_RELEASE}" \
        --build-arg DEBIAN_RELEASE=${DEBIAN_RELEASE} \
        --build-arg WIRESHARK_VERSION=${WIRESHARK_VERSION} \
        --build-arg SOURCE_GIT_REPOSITORY=${GIT_REPO_URL} \
        --build-arg SOURCE_GIT_COMMIT=${commit} \
        --build-arg README_URL=${readmeUrl} \
        ${SCRIPT_DIR}
    docker tag "${DOCKERREGISTRY_USER}/wireshark:${WIRESHARK_VERSION}-${DEBIAN_RELEASE}" "${DOCKERREGISTRY_USER}/wireshark:${WIRESHARK_VERSION}-${DEBIAN_RELEASE}-$(resolveBuildTimestamp ${DOCKERREGISTRY_USER}/wireshark:${WIRESHARK_VERSION}-${DEBIAN_RELEASE})"
    docker tag "${DOCKERREGISTRY_USER}/wireshark:${WIRESHARK_VERSION}-${DEBIAN_RELEASE}" "${DOCKERREGISTRY_USER}/wireshark:${WIRESHARK_VERSION}"
    docker tag "${DOCKERREGISTRY_USER}/wireshark:${WIRESHARK_VERSION}-${DEBIAN_RELEASE}" "${DOCKERREGISTRY_USER}/wireshark:latest"
}

function push () {
    docker push "${DOCKERREGISTRY_USER}/net-tools:${DEBIAN_RELEASE}-$(resolveBuildTimestamp ${DOCKERREGISTRY_USER}/net-tools:${DEBIAN_RELEASE})"
    docker push "${DOCKERREGISTRY_USER}/net-tools:${DEBIAN_RELEASE}"
    docker push "${DOCKERREGISTRY_USER}/net-tools:latest"

    docker push "${DOCKERREGISTRY_USER}/tshark:${WIRESHARK_VERSION}-${DEBIAN_RELEASE}-$(resolveBuildTimestamp ${DOCKERREGISTRY_USER}/tshark:${WIRESHARK_VERSION}-${DEBIAN_RELEASE})"
    docker push "${DOCKERREGISTRY_USER}/tshark:${WIRESHARK_VERSION}-${DEBIAN_RELEASE}"
    docker push "${DOCKERREGISTRY_USER}/tshark:${WIRESHARK_VERSION}"
    docker push "${DOCKERREGISTRY_USER}/tshark:latest"

    docker push "${DOCKERREGISTRY_USER}/tshark-termshark:${WIRESHARK_VERSION}-${TERMSHARK_VERSION}-${DEBIAN_RELEASE}-$(resolveBuildTimestamp ${DOCKERREGISTRY_USER}/tshark-termshark:${WIRESHARK_VERSION}-${TERMSHARK_VERSION}-${DEBIAN_RELEASE})"
    docker push "${DOCKERREGISTRY_USER}/tshark-termshark:${WIRESHARK_VERSION}-${TERMSHARK_VERSION}-${DEBIAN_RELEASE}" 
    docker push "${DOCKERREGISTRY_USER}/tshark-termshark:${WIRESHARK_VERSION}-${TERMSHARK_VERSION}"
    docker push "${DOCKERREGISTRY_USER}/tshark-termshark:${WIRESHARK_VERSION}"
    docker push "${DOCKERREGISTRY_USER}/tshark-termshark:latest"

    docker push "${DOCKERREGISTRY_USER}/wireshark:${WIRESHARK_VERSION}-${DEBIAN_RELEASE}-$(resolveBuildTimestamp ${DOCKERREGISTRY_USER}/wireshark:${WIRESHARK_VERSION}-${DEBIAN_RELEASE})"
    docker push "${DOCKERREGISTRY_USER}/wireshark:${WIRESHARK_VERSION}-${DEBIAN_RELEASE}"
    docker push "${DOCKERREGISTRY_USER}/wireshark:${WIRESHARK_VERSION}"
    docker push "${DOCKERREGISTRY_USER}/wireshark:latest"
}

function resolveCommit () {
    pushd . > /dev/null
    cd $SCRIPT_DIR
    git rev-list --abbrev-commit --abbrev=7 -1 master
    popd > /dev/null
}

function resolveBuildTimestamp() {
    local imageName=${1:?"Missing image name as first parameter!"}
    local created=$(docker inspect --format "{{ index .Created }}" "${imageName}")
    date --utc -d "${created}" +'%Y%m%dT%H%M%Z'
}

function parseCmd () {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --build)
                BUILD=true
                shift
                ;;
            --push)
                PUSH=true
                shift
                ;;
            --user)
                shift
                case "$1" in
                    ""|--*)
                        usage "Requires Docker registry user name"
                        return 1
                        ;;
                    *)
                        DOCKERREGISTRY_USER=$1
                        shift
                        ;;
                esac
                ;;
            --debian-release)
                shift
                case "$1" in
                    ""|--*)
                        usage "Requires debian release"
                        return 1
                        ;;
                    *)
                        DEBIAN_RELEASE=$1
                        shift
                        ;;
                esac
                ;;
            -*)
                usage "Unknown option: $1"
                return $?
                ;;
            *)
                WIRESHARK_VERSION="$1"
                shift
                ;;
        esac
    done
    if [ -z "${WIRESHARK_VERSION}" ]; then
        usage "Requires Wireshark version"
        return $?
    fi
    return 0
}

function main () {
    parseCmd "$@"
    local retval=$?
    if [ $retval != 0 ]; then
        exit $retval
    fi

    if [ "$BUILD" = true ]; then
        build
    fi
    if [ "$PUSH" = true ]; then
        push
    fi
}

main "$@"