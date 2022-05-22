#!/bin/bash /etc/rc.common

# shellcheck source=/dev/null
. /lib/functions.sh
# shellcheck source=/dev/null
. /usr/share/clash/init_env_conf.sh

load="/tmp/config.yaml"
CONFIG_YAML_PATH=$(uci get clash.config.use_config 2>/dev/null)


if [ -s "$CONFIG_YAML_PATH" ]; then
	cp "$CONFIG_YAML_PATH" $load 2>/dev/null
fi

if [ ! -s $load ]; then
	exit 0
fi

rm -rf /tmp/Proxy_Group /tmp/group_*.yaml "$GROUP_FILE" 2>/dev/null

echo "Start updating configuration of policy group..." >>"$REAL_LOG"

sed -i 's/^Proxy Group:/proxy-groups:/g' "$load"
sed -i 's/^proxy-provider:/proxy-providers:/g' "$load"
sed -i 's/^Proxy:/proxies:/g' "$load"
sed -i 's/^Rule:/rules:/g' "$load"
sed -i 's/^rule-provider:/rule-providers:/g' "$load"

group_len=$(sed -n '/^ \{0,\}proxy-groups:/=' "$load" 2>/dev/null)
provider_len=$(sed -n '/^ \{0,\}proxy-providers:/=' "$load" 2>/dev/null)
if [ "$provider_len" -ge "$group_len" ]; then
	awk '/proxies:/,/proxy-providers:/{print}' "$load" 2>/dev/null | sed "s/\'//g" 2>/dev/null | sed 's/\"//g' 2>/dev/null | sed 's/\t/ /g' 2>/dev/null | grep name: | awk -F 'name:' '{print $2}' | sed 's/,.*//' | sed 's/^ \{0,\}//' 2>/dev/null | sed 's/ \{0,\}$//' 2>/dev/null | sed 's/ \{0,\}\}\{0,\}$//g' 2>/dev/null >/tmp/Proxy_Group 2>&1
	sed -i "s/proxy-providers://g" /tmp/Proxy_Group 2>&1
else
	awk '/proxies:/,/rules:/{print}' "$load" 2>/dev/null | sed "s/\'//g" 2>/dev/null | sed 's/\"//g' 2>/dev/null | sed 's/\t/ /g' 2>/dev/null | grep name: | awk -F 'name:' '{print $2}' | sed 's/,.*//' | sed 's/^ \{0,\}//' 2>/dev/null | sed 's/ \{0,\}$//' 2>/dev/null | sed 's/ \{0,\}\}\{0,\}$//g' 2>/dev/null >/tmp/Proxy_Group 2>&1
fi
if [ "$?" -eq "0" ]; then
	echo 'DIRECT' >>/tmp/Proxy_Group
	echo 'REJECT' >>/tmp/Proxy_Group
else
	echo "Read error, invalid configuration file!" >/tmp/Proxy_Group
fi

group_len=$(sed -n '/^ \{0,\}proxy-groups:/=' "$load" 2>/dev/null)
provider_len=$(sed -n '/^ \{0,\}proxy-providers:/=' "$load" 2>/dev/null)
ruleprovider_len=$(sed -n '/^ \{0,\}rule-providers:/=' "$load" 2>/dev/null)
if [ "$provider_len" -ge "$group_len" ]; then
	awk '/proxy-groups:/,/proxy-providers:/{print}' "$load" 2>/dev/null | sed 's/\"//g' 2>/dev/null | sed "s/\'//g" 2>/dev/null | sed 's/\t/ /g' 2>/dev/null >"$GROUP_FILE" 2>&1
	sed -i "s/proxy-providers://g" "$GROUP_FILE" 2>&1
elif [ "$ruleprovider_len" -ge "$group_len" ]; then
	awk '/proxy-groups:/,/rule-providers:/{print}' "$load" 2>/dev/null | sed 's/\"//g' 2>/dev/null | sed "s/\'//g" 2>/dev/null | sed 's/\t/ /g' 2>/dev/null >"$GROUP_FILE" 2>&1
	sed -i "s/rule-providers://g" "$GROUP_FILE" 2>&1
else
	awk '/proxy-groups:/,/Rule:/{print}' "$load" 2>/dev/null | sed 's/\"//g' 2>/dev/null | sed "s/\'//g" 2>/dev/null | sed 's/\t/ /g' 2>/dev/null >"$GROUP_FILE" 2>&1
fi

#######READ GROUPS START

if [ -f "$GROUP_FILE" ]; then
	while [[ "$(grep -c "config conf_groups" "$CFG_FILE")" -ne 0 ]]; do
		uci delete clash.@conf_groups[0] && uci commit clash >/dev/null 2>&1
	done

	count=1
	file_count=1
	match_group_file="/tmp/Proxy_Group"
	line=$(sed -n '/name:/=' "$GROUP_FILE")
	num=$(grep -c "name:" "$GROUP_FILE")

	cfg_get() {
		echo "$(grep "$1" "$2" 2>/dev/null | awk -v tag=$1 'BEGIN{FS=tag} {print $2}' 2>/dev/null | sed 's/,.*//' 2>/dev/null | sed 's/^ \{0,\}//g' 2>/dev/null | sed 's/ \{0,\}$//g' 2>/dev/null | sed 's/ \{0,\}\}\{0,\}$//g' 2>/dev/null)"
	}

	for n in $line; do
		single_group="/tmp/group_$file_count.yaml"

		[ "$count" -eq 1 ] && {
			startLine="$n"
		}

		count=$((count + 1))
		if [ "$count" -gt "$num" ]; then
			endLine=$(sed -n '$=' "$GROUP_FILE")
		else
			endLine=$(($(echo "$line" | sed -n "${count}p") - 1))
		fi

		sed -n "${startLine},${endLine}p" "$GROUP_FILE" >$single_group
		startLine=$((endLine + 1))

		#type
		group_type="$(cfg_get "type:" "$single_group")"
		#name
		group_name="$(cfg_get "name:" "$single_group")"
		#test_url

		echo "Reading [$group_type] - [$group_name] policy group confs..." >>"$REAL_LOG"

		name=clash
		uci_name_tmp=$(uci add $name conf_groups)
		uci_set="uci -q set $name.$uci_name_tmp."
		uci_add="uci -q add_list $name.$uci_name_tmp."
		${uci_set}name="$group_name"
		${uci_set}type="$group_type"

		file_count=$((file_count + 1))

	done

	uci commit clash

	echo "Reading policy group completed." >>"$REAL_LOG"

	rm -rf /tmp/Proxy_Group /tmp/group_*.yaml "$GROUP_FILE" $load 2>/dev/null
fi
#######READ GROUPS END
