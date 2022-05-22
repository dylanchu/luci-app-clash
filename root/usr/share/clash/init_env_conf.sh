#!/bin/sh

# shellcheck disable=SC2034
# core
CORE_CLASH="/tmp/clash_core"
CORE_CLASH_TUN="/etc/clash/clashtun/clash_core"
CORE_CLASH_DTUN="/etc/clash/dtun/clash_core"
GEOIP_FILE="/etc/clash/Country.mmdb"

# log
LOG_FILE="/usr/share/clash/clash.txt"
REAL_LOG="/usr/share/clash/clash_real.txt"

#config
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

# url
URL_GITHUB_CORE_DTUN_TAGS="https://github.com/frainzy1477/clashdtun/tags"
