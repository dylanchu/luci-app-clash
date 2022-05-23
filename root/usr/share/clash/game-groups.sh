#!/bin/sh /etc/rc.common

# shellcheck source=/dev/null
. /lib/functions.sh
# shellcheck source=/dev/null
. /usr/share/clash/init_env_conf.sh


cfg_groups_set() {

   tmp_section="$1"
   config_get "name" "$tmp_section" "name" ""
   config_get "old_name_cfg" "$tmp_section" "old_name_cfg" ""
   config_get "old_name" "$tmp_section" "old_name" ""

   if [ -z "$name" ]; then
      return
   fi

   if [ "$name" != "$old_name_cfg" ]; then
      sed -i "s/\'${old_name_cfg}\'/\'${name}\'/g" "$CFG_FILE" 2>/dev/null
      sed -i "s/old_name \'${name}\'/old_name \'${old_name}\'/g" "$CFG_FILE" 2>/dev/null
      config_load "clash"
   fi

}

start() {
   status=$(pgrep /usr/share/clash/game-groups.sh | wc -l)
   [ "$status" -gt "3" ] && exit 0

   config_load "clash"
   config_foreach cfg_groups_set "conf_groups"
}
