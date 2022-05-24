#!/bin/bash /etc/rc.common

# shellcheck source=/dev/null
. /usr/share/clash/init_env_conf.sh

clash_url=$(uci get clash.config.clash_url 2>/dev/null)
ssr_url=$(uci get clash.config.ssr_url 2>/dev/null)
v2_url=$(uci get clash.config.v2_url 2>/dev/null)

config_name=$(uci get clash.config.config_name 2>/dev/null)
subtype=$(uci get clash.config.subcri 2>/dev/null)

SUBSCRIBED_CONFIG_YAML="/usr/share/clash/config/sub/${config_name}.yaml"

if [ "$config_name" = "" ] || [ -z "$config_name" ]; then
	echo "ERROR: Please tag your config first" >>"$REAL_LOG"
	exit 0
fi

if [ ! -f "/usr/share/clash/backup/confit_list.conf" ]; then
	touch /usr/share/clash/backup/confit_list.conf
fi

check_name=$(grep -F "${config_name}.yaml" "/usr/share/clash/backup/confit_list.conf")

if [ -n "$check_name" ]; then
	echo "ERROR: Config file with same name exists, please rename the tag and download again" >>"$REAL_LOG"
	exit 0
else
	echo "Downloading Configuration..." >>"$REAL_LOG"
	sleep 1
	if [ "$subtype" = "clash" ]; then
		wget -c4 --no-check-certificate --user-agent="Clash/OpenWRT" "$clash_url" -O "$SUBSCRIBED_CONFIG_YAML" 2>&1
		if [ "$?" -eq "0" ]; then
			echo "${config_name}.yaml#$clash_url#$subtype" >>/usr/share/clash/backup/confit_list.conf
		fi
	fi

	if [ "$subtype" = "ssr2clash" ]; then
		wget -c4 --no-check-certificate --user-agent="Clash/OpenWRT" "https://gfwsb.114514.best/sub?target=clashr&url=$ssr_url" -O "$SUBSCRIBED_CONFIG_YAML" 2>&1
		if [ "$?" -eq "0" ]; then
			echo "${config_name}.yaml#$ssr_url#$subtype" >>/usr/share/clash/backup/confit_list.conf
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

			cat /usr/share/clash/dns.yaml "$TMP_YAML_FILE_1" >$TMP_YAML_FILE
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

		fi
	fi

	if [ "$subtype" = "v2clash" ]; then
		wget -c4 --no-check-certificate --user-agent="Clash/OpenWRT" "https://tgbot.lbyczf.com/v2rayn2clash?url=$v2_url" -O $SUBSCRIBED_CONFIG_YAML 2>&1
		if [ "$?" -eq "0" ]; then
			echo "${config_name}.yaml#$v2_url#$subtype" >>/usr/share/clash/backup/confit_list.conf
		fi
	fi

	echo "Configuration Downloaded." >>"$REAL_LOG"
fi
