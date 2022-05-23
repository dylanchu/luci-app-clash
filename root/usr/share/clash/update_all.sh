#!/bin/bash /etc/rc.common

# shellcheck source=/dev/null
. /lib/functions.sh
# shellcheck source=/dev/null
. /usr/share/clash/init_env_conf.sh

c_type=$(uci get clash.config.config_type 2>/dev/null)

countt=$(grep -c '' /usr/share/clashbackup/confit_list.conf)
count_nums=1
while [[ $count_nums -le $countt ]]; do

	config_name=$(sed -n "$count_nums"p /usr/share/clashbackup/confit_list.conf | awk -F '#' '{print $1}')

	SUBSCRIBED_CONFIG_YAML="/usr/share/clash/config/sub/${config_name}"
	url=$(grep -F "${config_name}" "/usr/share/clashbackup/confit_list.conf" | awk -F '#' '{print $2}')

	type=$(grep -F "${config_name}" "/usr/share/clashbackup/confit_list.conf" | awk -F '#' '{print $3}')

	if [ "$type" = "clash" ] && [ -n "$url" ]; then
		echo "Start updating configuration..." >>"$REAL_LOG"
		wget --no-check-certificate --user-agent="Clash/OpenWRT" "$url" -O "$SUBSCRIBED_CONFIG_YAML" 2>&1
		if [ "$?" -eq "0" ]; then
			echo "Configuration Updated." >>"$REAL_LOG"
		fi
	fi

	if [ "$type" = "ssr2clash" ] && [ -n "$url" ]; then

		echo "Start updating configuration..." >>"$REAL_LOG"
		wget --no-check-certificate --user-agent="Clash/OpenWRT" "https://ssrsub2clashr.herokuapp.com/ssrsub2clash?sub=$url" -O "$SUBSCRIBED_CONFIG_YAML" 2>&1
		if [ "$?" -eq "0" ]; then

			TMP_YAML_FILE_1="/tmp/clash_conf_tmp1"
			TMP_YAML_FILE="/tmp/clash_conf_tmp"
			da_password=$(uci get clash.config.dash_pass 2>/dev/null)
			redir_port=$(uci get clash.config.redir_port 2>/dev/null)
			http_port=$(uci get clash.config.http_port 2>/dev/null)
			socks_port=$(uci get clash.config.socks_port 2>/dev/null)
			dash_port=$(uci get clash.config.dash_port 2>/dev/null)
			bind_addr=$(uci get clash.config.bind_addr 2>/dev/null)
			allow_lan=$(uci get clash.config.allow_lan 2>/dev/null)
			log_level=$(uci get clash.config.level 2>/dev/null)
			p_mode=$(uci get clash.config.p_mode 2>/dev/null)
			cp -f "$SUBSCRIBED_CONFIG_YAML" $TMP_YAML_FILE_1 2>/dev/null
			sed -i "/^Proxy:/i\#clash-openwrt" "$TMP_YAML_FILE_1" 2>/dev/null
			sed -i '1,/#clash-openwrt/d' "$TMP_YAML_FILE_1" 2>/dev/null

			cat /usr/share/clash/dns.yaml "$TMP_YAML_FILE_1" >$TMP_YAML_FILE 2>/dev/null
			rm -f $TMP_YAML_FILE_1

			sed -i "1i\#****CLASH-CONFIG-START****#" "$TMP_YAML_FILE" 2>/dev/null
			sed -i "2i\port: ${http_port}" "$TMP_YAML_FILE" 2>/dev/null
			sed -i "/port: ${http_port}/a\socks-port: ${socks_port}" "$TMP_YAML_FILE" 2>/dev/null
			sed -i "/socks-port: ${socks_port}/a\redir-port: ${redir_port}" "$TMP_YAML_FILE" 2>/dev/null
			sed -i "/redir-port: ${redir_port}/a\allow-lan: ${allow_lan}" "$TMP_YAML_FILE" 2>/dev/null
			if [ "$allow_lan" = "true" ]; then
				sed -i "/allow-lan: ${allow_lan}/a\bind-address: \"${bind_addr}\"" "$TMP_YAML_FILE" 2>/dev/null
				sed -i "/bind-address: \"${bind_addr}\"/a\mode: ${p_mode}" "$TMP_YAML_FILE" 2>/dev/null
				sed -i "/mode: ${p_mode}/a\log-level: ${log_level}" "$TMP_YAML_FILE" 2>/dev/null
				sed -i "/log-level: ${log_level}/a\external-controller: 0.0.0.0:${dash_port}" "$TMP_YAML_FILE" 2>/dev/null
				sed -i "/external-controller: 0.0.0.0:${dash_port}/a\secret: \"${da_password}\"" "$TMP_YAML_FILE" 2>/dev/null
				sed -i "/secret: \"${da_password}\"/a\external-ui: \"/usr/share/clash/dashboard\"" "$TMP_YAML_FILE" 2>/dev/null

			else
				sed -i "/allow-lan: ${allow_lan}/a\mode: Rule" "$TMP_YAML_FILE" 2>/dev/null
				sed -i "/mode: Rule/a\log-level: ${log_level}" "$TMP_YAML_FILE" 2>/dev/null
				sed -i "/log-level: ${log_level}/a\external-controller: 0.0.0.0:${dash_port}" "$TMP_YAML_FILE" 2>/dev/null
				sed -i "/external-controller: 0.0.0.0:${dash_port}/a\secret: \"${da_password}\"" "$TMP_YAML_FILE" 2>/dev/null
				sed -i "/secret: \"${da_password}\"/a\external-ui: \"/usr/share/clash/dashboard\"" "$TMP_YAML_FILE" 2>/dev/null
			fi
			mv $TMP_YAML_FILE "$SUBSCRIBED_CONFIG_YAML" 2>/dev/null

			echo "Configuration Updated." >>"$REAL_LOG"

		fi

	fi

	if [ "$type" = "v2clash" ] && [ -n "$url" ]; then
		echo "Start updating configuration..." >>"$REAL_LOG"
		wget --no-check-certificate --user-agent="Clash/OpenWRT" "https://tgbot.lbyczf.com/v2rayn2clash?url=$url" -O "$SUBSCRIBED_CONFIG_YAML" 2>&1
		if [ "$?" -eq "0" ]; then
			echo "Configuration Updated." >>"$REAL_LOG"
		fi
	fi

	count_nums=$((count_nums + 1))
done

sleep 2

use=$(uci get clash.config.use_config 2>/dev/null)

if [ "$c_type" -eq 1 ] && [ -s "$use" ]; then
	if pidof clash_core >/dev/null; then
		/etc/init.d/clash restart 2>/dev/null
	fi
fi
