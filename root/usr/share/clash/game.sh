#!/bin/bash /etc/rc.common

# shellcheck source=/dev/null
. /lib/functions.sh
# shellcheck source=/dev/null
. /usr/share/clash/init_env_conf.sh

game_rules=$(uci get clash.config.g_rules 2>/dev/null)

RULE="/tmp/rules_conf.yaml"
CLASH="/tmp/conf.yaml"
CLASH_CONFIG="/tmp/config.yaml"

if [ "${game_rules}" -eq 1 ]; then

   if [ -f $CLASH_CONFIG ]; then
      rm -rf $CLASH_CONFIG 2>/dev/null
   fi

   cp "$RUNTIME_YAML" $CLASH_CONFIG 2>/dev/null
   if grep -q "^Rule:" "$CLASH_CONFIG"; then
      sed -i "/^Rule:/i\#RULESTART#" $CLASH_CONFIG 2>/dev/null
   elif grep -q "^rules:" "$CLASH_CONFIG"; then
      sed -i "/^rules:/i\#RULESTART#" $CLASH_CONFIG 2>/dev/null
   fi
   sed -i -e "\$a#RULEEND#" $CLASH_CONFIG 2>/dev/null

   awk '/#RULESTART#/,/#RULEEND#/{print}' "$CLASH_CONFIG" 2>/dev/null | sed "s/\'//g" 2>/dev/null | sed 's/\"//g' 2>/dev/null | sed 's/\t/ /g' 2>/dev/null | grep - | awk -F '- ' '{print "- "$2}' | sed 's/^ \{0,\}//' 2>/dev/null | sed 's/ \{0,\}$//' 2>/dev/null >$RULE 2>&1

   sed -i '/#RULESTART#/,/#RULEEND#/d' "$CLASH_CONFIG" 2>/dev/null

   sed -i -e "\$a " $CLASH_CONFIG 2>/dev/null
   sed -i "1i\rules:" $RULE 2>/dev/null
   cat $CLASH_CONFIG $RULE >$CLASH 2>/dev/null
   mv $CLASH $CLASH_CONFIG 2>/dev/null
   rm -rf $RULE 2>/dev/null

   get_rule_file() {
      if [ -z "$1" ]; then
         return
      fi

      GAME_RULE_FILE_NAME=$(grep -F "$1" "$GAME_RULE_INFO_FILE" | awk -F ',' '{print $3}' 2>/dev/null)

      if [ -z "$GAME_RULE_FILE_NAME" ]; then
         GAME_RULE_FILE_NAME=$(grep -F "$1" "$GAME_RULE_INFO_FILE" | awk -F ',' '{print $2}' 2>/dev/null)
      fi

      GAME_RULE_PATH="/usr/share/clash/rules/g_rules/$GAME_RULE_FILE_NAME"
      sed '/^#/d' "$GAME_RULE_PATH" 2>/dev/null | sed '/^ *$/d' | awk '{print "- IP-CIDR,"$0}' | awk -v tag="$2" '{print $0","'tag'""}' >>"$GROUP_FILE_GAME_RULE" 2>/dev/null
   }

   yml_game_rule_get() {
      local section="$1"
      config_get "group" "$section" "group" ""

      if [ -f "$GROUP_FILE_GAME_RULE" ]; then
         rm -rf "$GROUP_FILE_GAME_RULE" 2>/dev/null
      fi

      if [ -z "$group" ]; then
         return
      fi

      config_list_foreach "$section" "rule_name" get_rule_file "$group"
   }

   config_load "clash"
   config_foreach yml_game_rule_get "game"

   if [ -f "$GROUP_FILE_GAME_RULE" ]; then

      sed -i -e "\$a#GAMERULEEND#" "$GROUP_FILE_GAME_RULE" 2>/dev/null
      sed -i '/#GAMERULESTART#/,/#GAMERULEEND#/d' "$CLASH_CONFIG" 2>/dev/null

      if grep -q "^ \{0,\}- GEOIP" "$CLASH_CONFIG"; then
         sed -i '1,/^ \{0,\}- GEOIP,/{/^ \{0,\}- GEOIP,/s/^ \{0,\}- GEOIP,/#GAMERULESTART#\n&/}' "$CLASH_CONFIG" 2>/dev/null
      elif grep -q "^ \{0,\}- MATCH," "$CLASH_CONFIG"; then
         sed -i '1,/^ \{0,\}- MATCH,/{/^ \{0,\}- MATCH,/s/^ \{0,\}- MATCH,/#GAMERULESTART#\n&/}' "$CLASH_CONFIG" 2>/dev/null
      else
         echo "#GAMERULESTART#" >>"$CLASH_CONFIG" 2>/dev/null
      fi

      sed -i '/GAMERULESTART/r/tmp/yaml_game_rule_group.yaml' "$CLASH_CONFIG" 2>/dev/null
      mv $CLASH_CONFIG "$RUNTIME_YAML" 2>/dev/null
   fi
   rm -rf "$GROUP_FILE_GAME_RULE" 2>/dev/null
else
   sed -i '/#GAMERULESTART#/,/#GAMERULEEND#/d' "$RUNTIME_YAML" 2>/dev/null
   rm -rf "$GROUP_FILE_GAME_RULE" 2>/dev/null
fi
