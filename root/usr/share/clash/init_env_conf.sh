#!/bin/sh

# init like this:
# # shellcheck source=/dev/null
# . /usr/share/clash/init_env_conf.sh

# shellcheck disable=SC2034
# core
CORE_CLASH="/tmp/clash_core"
CORE_CLASH_TUN="/etc/clash/clashtun/clash_core"
CORE_CLASH_DTUN="/etc/clash/dtun/clash_core"
CORE_NAME_IN_TAR="clash_core"

CORE_DOWNLOADED_FLAG="/tmp/clash_flag_core_down_complete"

# geoip
GEOIP_FILE="/etc/clash/Country.mmdb"

# log
LOG_FILE="/tmp/clash_log.txt"
REAL_LOG="/tmp/clash_real_log.txt"
CORE_LOG_FILE=$LOG_FILE

# config
CFG_FILE="/etc/config/clash"
CLASH_CONF_DIR="/etc/clash"
GEOIP_FILE="$CLASH_CONF_DIR/Country.mmdb"
RUNTIME_YAML="$CLASH_CONF_DIR/config.yaml"

# custom rule
CUSTOM_IP_RULE_FILE="/tmp/ipadd.conf"
# game rule
GAME_RULE_INFO_FILE="/usr/share/clash/rules/rules.list"

# group
GROUP_FILE="/tmp/yaml_group.yaml"
GROUP_FILE_GAME_RULE="/tmp/yaml_game_rule_group.yaml"

# version
CORE_VERSON_META_FILE="/etc/clash/core_versions"
NEW_VERSON_META_FILE="/tmp/clash_new_version_meta"
NEW_VERSON_META_URL="https://github.com/dylanchu/luci-app-clash/releases/download/new_version_meta/new_version_meta"
