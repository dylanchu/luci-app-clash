#!/bin/sh /etc/rc.common

# shellcheck source=/dev/null
. /lib/functions.sh
# shellcheck source=/dev/null
. /usr/share/clash/init_env_conf.sh


rules_set() {
   tmp_section="$1"
   config_get "type" "$tmp_section" "type" ""
   config_get "rulename" "$tmp_section" "rulename" ""
   config_get "rulenamee" "$tmp_section" "rulenamee" ""

   if [ -z "$type" ]; then
      return
   fi

   if [ -z "$rulename" ]; then
      uci set clash."$tmp_section".rulename="$rulenamee"
      uci commit clash
   fi
}

start() {
   config_load "clash"
   config_foreach rules_set "rules"
}

start
