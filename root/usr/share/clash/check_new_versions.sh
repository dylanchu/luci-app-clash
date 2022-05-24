#!/bin/sh

# shellcheck source=/dev/null
. /usr/share/clash/init_env_conf.sh

tmp_file="$NEW_VERSON_META_FILE"_tmp

if wget --no-check-certificate "$NEW_VERSON_META_URL" -O "$tmp_file" 2>&1 && [ -s "$tmp_file" ]; then
    rm -rf "$NEW_VERSON_META_FILE" 2>&1
    mv "$tmp_file" "$NEW_VERSON_META_FILE"
else
    touch "$NEW_VERSON_META_FILE"
fi
