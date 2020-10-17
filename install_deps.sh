#!/bin/bash
#########################################################################
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <https://unlicense.org>
#########################################################################


print_usage() {
    cat << EOF
install_deps.sh, (C) 2020 Falk Werner <https:://github/falk-werner/install_deps>
Install C/C++ dependencies from source

Usage:
    $0 [-f <filename>] [-s] [-c] [-d] [-h]

Options:
    -f <filename> name of dependency file (default: deps.sh)
    -s            install with sudo
    -c            install using checkinstall (recommend for system wide installation)
    -d            debug mode (preserve intermediate files on failure)
    -h            print this message
EOF

}

die() {
    local MESSAGE="$1"
    echo "error: ${MESSAGE}" 1>&2

    if [ "INIT" == "$APP_MODE" ]; then
        print_usage
    fi

    if [ "" != "${WORKING_DIR}" ]; then
        if [ "" == "${DEBUG_MODE}" ]; then
            rm -rf "${WORKING_DIR}"
        else
            echo "debug: intermediate files are located at ${WORKING_DIR}" 1>&2
        fi
    fi

    exit 1
}

check_required_tools() {
    for tool in $REQUIRED_TOOLS ; do
        which "${tool}" &> /dev/null
        if [ "0" != "$?" ]; then
            echo die "missing required tool: ${tool}"
        fi
    done
}

check_deps_file_property() {
    local PACKAGE="$1"
    local PROPERTY="${PACKAGE}_$2"
        if [ "" == "${!PROPERTY}" ]; then
            die "dependency file corrupt: missing ${PROPERTY}" 
        fi
}

check_deps_file() {
    for package in ${PACKAGES}; do
        check_deps_file_property "${package}" VERSION
        check_deps_file_property "${package}" URL
        check_deps_file_property "${package}" MD5
        check_deps_file_property "${package}" TYPE
        check_deps_file_property "${package}" DIR
    done
}

install_cmake_package() {
    local PACKAGE="$1"
    local VERSION="${PACKAGE}_VERSION"
    local SOURCE_DIR=$(realpath "$2")
    local BUILD_DIR="${SOURCE_DIR}_build"
    local CMAKE_OPTS="${PACKAGE}_CMAKE_OPTS"

    local CURRENT_DIR="$(pwd)"
    mkdir -p "${BUILD_DIR}"
    cd "${BUILD_DIR}"

    cmake "${SOURCE_DIR}" ${!CMAKE_OPTS}
    if [ "0" != "$?" ]; then
        die "failed to execute cmake: SOURCE_DIR="${SOURCE_DIR}" CMAKE_OPTS=${!CMAKE_OPTS}"
    fi

    make
    if [ "0" != "$?" ]; then
        die "failed to run make"
    fi

    if [ "" == "${CHECKINSTALL}" ]; then
        ${SUDO} make install
        if [ "0" != "$?" ]; then
            die "failed to run make install"
        fi
    else
        ${SUDO} checkinstall "--pkgname=${PACKAGE}" "--pkgversion=${!VERSION}" -y make install
        if [ "0" != "$?" ]; then
            die "failed to run checkinstall make install"
        fi
    fi

    cd "${CURRENT_DIR}"
}

install_meson_package() {
    local PACKAGE="$1"
    local SOURCE_DIR=$(realpath "$2")
    local BUILD_DIR="${SOURCE_DIR}_build"
    local MESON_OPTS="${PACKAGE}_MESON_OPTS"

    local CURRENT_DIR="$(pwd)"
    cd "${SOURCE_DIR}"

    meson "${BUILD_DIR}" ${!MESON_OPTS}
    if [ "0" != "$?" ]; then
        die "failed to execute meson: SOURCE_DIR="${SOURCE_DIR}" MESON_OPTS=${!MESON_OPTS}"
    fi

    meson compile -C "${BUILD_DIR}"
    if [ "0" != "$?" ]; then
        die "failed to execute meson compile"
    fi

    if [ "" == "${CHECKINSTALL}" ]; then
        ${SUDO} meson install -C "${BUILD_DIR}"
        if [ "0" != "$?" ]; then
            die "failed to execute meson install"
        fi
    else
        ${SUDO} checkinstall "--pkgname=${PACKAGE}" "--pkgversion=${!VERSION}" -y meson install -C "${BUILD_DIR}"
        if [ "0" != "$?" ]; then
            die "failed to run checkinstall meson install"
        fi
    fi

    cd "${CURRENT_DIR}"
}

install_package() {
    local PACKAGE="$1"
    local PACKAGE_VERSION="${PACKAGE}_VERSION"
    local PACKAGE_URL="${PACKAGE}_URL"
    local PACKAGE_MD5="${PACKAGE}_MD5"
    local PACKAGE_TYPE="${PACKAGE}_TYPE"
    local PACKAGE_DIR="${PACKAGE}_DIR"
    local FILENAME="${PACKAGE}_${!PACKAGE_VERSION}.tar.gz"

    echo -n "checking for package ${PACKAGE} (>= ${!PACKAGE_VERSION})... "
    pkg-config --exists "${PACKAGE} >= ${!PACKAGE_VERSION}"
    if [ "0" == "$?" ]; then
        echo "found"
        return
    fi
    echo "not found"

    echo -n "fetch ${PACKAGE} from ${!PACKAGE_URL}... "
    wget "${!PACKAGE_URL}" -O "${FILENAME}" -q
    if [ "0" != "$?" ]; then
        echo "failed"
        die "failed to fetch ${PACKAGE} from ${!PACKAGE_URL}"
    fi
    echo "done"

    echo -n "verify checksum... "
    md5sum -c <(echo "${!PACKAGE_MD5}" "${FILENAME}") &> /dev/null
    if [ "0" != "$?" ]; then
        echo "failed"
        die "failed to verify checksum of ${PACKAGE}: expected ${!PACKAGE_MD5}, but was $(md5sum ${FILENAME})"
    fi
    echo "done"

    echo -n "extract package contents... "
    tar -xf ${FILENAME}
    if [ "0" != "$?" ]; then
        echo "failed"
        die "failed to extract ${PACKAGE}"
    fi
    echo "done"

    case "${!PACKAGE_TYPE}" in
    meson)
        install_meson_package "${PACKAGE}" "${!PACKAGE_DIR}"
        ;;
    cmake)
        install_cmake_package "${PACKAGE}" "${!PACKAGE_DIR}"
        ;;
    *)
        echo "error: unknown package type ${!PACKAGE_TYPE}"
        exit 1
        ;;
    esac
}

# entry piont

APP_MODE="INIT"
REQUIRED_TOOLS="pkg-config wget md5sum realpath"

DEBUG_MODE=""
SUDO=""
CHECKINSTALL=""
DEPS_FILE="deps.sh"
PRINT_USAGE=""

while getopts f:scdh opt ; do
    case $opt in
        f)
            DEPS_FILE="${OPTARG}"
            ;;
        s)
            SUDO="sudo"
            REQUIRED_TOOLS="${REQUIRED_TOOLS} sudo"
            ;;
        c)
            CHECKINSTALL="checkinstall"
            REQUIRED_TOOLS="${REQUIRED_TOOLS} checkinstall"
            ;;
        d)
            DEBUG_MODE="T"
            ;;
        h)
            PRINT_USAGE="T"
            ;;
        ?)
            die "invalid command line option"
            ;;
    esac
done 

if [ "" != "${PRINT_USAGE}" ]; then
    print_usage
    exit 0
fi

check_required_tools

if [ ! -f "${DEPS_FILE}" ]; then
    die "missing dependency file: ${DEPS_FILE}"
fi

. "${DEPS_FILE}"
check_deps_file

if [ "" != "${DESTDIR}" ]; then
    export DESTDIR=$(realpath "${DESTDIR}")
    export PKG_CONFIG_PATH=${PKG_CONFIG_PATH}:${DESTDIR}/usr/local/lib/pkgconfig
fi

APP_MODE="RUNNING"

CURRENT_DIR=$(pwd)
WORKING_DIR=$(mktemp -d /tmp/install_deps_XXXXXX)
cd ${WORKING_DIR}

for package in ${PACKAGES} ; do
    install_package $package
done

cd ${CURRENT_DIR}
rm -rf ${WORKING_DIR}
