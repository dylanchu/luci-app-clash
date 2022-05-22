#!/bin/sh

# shellcheck source=/dev/null
. /usr/share/clash/init_env_conf.sh

new_clashdtun_core_version=$(curl -sL "$URL_GITHUB_CORE_DTUN_TAGS" | grep "/frainzy1477/clashdtun/releases/" | head -n 1 | awk -F "/tag/" '{print $2}' | sed 's/\">//')
if [ "$?" -eq "0" ]; then
    rm -rf /usr/share/clash/new_clashdtun_core_version
    if [ $new_clashdtun_core_version ]; then
        echo $new_clashdtun_core_version >/usr/share/clash/new_clashdtun_core_version 2>&1 &
        >/dev/null
    elif [ $new_clashdtun_core_version =="" ]; then
        echo 0 >/usr/share/clash/new_clashdtun_core_version 2>&1 &
        >/dev/null
    fi
fi
