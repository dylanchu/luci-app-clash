#!/bin/sh

# shellcheck source=/dev/null
. /usr/share/clash/init_env_conf.sh

LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
LOG_FILE="/tmp/clash_update.txt"
MODELTYPE=$(uci get clash.config.download_core 2>/dev/null)
CORETYPE=$(uci get clash.config.dcore 2>/dev/null)
CORE=$(uci get clash.config.core 2>/dev/null)
# lang=$(uci get luci.main.lang 2>/dev/null)

if [ -f /tmp/clash.tar.gz ]; then
	rm -rf /tmp/clash.tar.gz >/dev/null 2>&1
fi
echo '' >/tmp/clash_update.txt 2>/dev/null

if [ -f /usr/share/clash/core_down_complete ]; then
	rm -rf /usr/share/clash/core_down_complete 2>/dev/null
fi

echo "  ${LOGTIME} - Checking latest version.." >$LOG_FILE
# shellcheck disable=SC2086
if [ $CORETYPE -eq 4 ]; then
	if [ -f /usr/share/clash/download_dtun_version ]; then
		rm -rf /usr/share/clash/download_dtun_version
	fi
	new_clashdtun_core_version=$(wget -qO- "$URL_GITHUB_CORE_DTUN_TAGS" | grep "/frainzy1477/clashdtun/releases/" | head -n 1 | awk -F "/tag/" '{print $2}' | sed 's/\">//')

	if [ $new_clashdtun_core_version ]; then
		echo $new_clashdtun_core_version >/usr/share/clash/download_dtun_version 2>&1
	elif [ $new_clashdtun_core_version = "" ]; then
		echo 0 >/usr/share/clash/download_dtun_version 2>&1
	fi
	sleep 5
	if [ -f /usr/share/clash/download_dtun_version ]; then
		CLASHDTUNC=$(sed -n 1p /usr/share/clash/download_dtun_version 2>/dev/null)
	fi
fi

# shellcheck disable=SC2086
if [ $CORETYPE -eq 3 ]; then
	if [ -f /usr/share/clash/download_tun_version ]; then
		rm -rf /usr/share/clash/download_tun_version
	fi
	new_clashtun_core_version=$(wget -qO- "https://github.com/frainzy1477/clashtun/tags" | grep "/frainzy1477/clashtun/releases/" | head -n 1 | awk -F "/tag/" '{print $2}' | sed 's/\">//')

	if [ $new_clashtun_core_version ]; then
		echo $new_clashtun_core_version >/usr/share/clash/download_tun_version 2>&1
	elif [ $new_clashtun_core_version = "" ]; then
		echo 0 >/usr/share/clash/download_tun_version 2>&1
	fi
	sleep 5
	if [ -f /usr/share/clash/download_tun_version ]; then
		CLASHTUN=$(sed -n 1p /usr/share/clash/download_tun_version 2>/dev/null)
	fi
fi

# shellcheck disable=SC2086
if [ $CORETYPE -eq 1 ]; then
	if [ -f /usr/share/clash/download_core_version ]; then
		rm -rf /usr/share/clash/download_core_version
	fi
	new_clashr_core_version=$(wget -qO- "https://github.com/frainzy1477/clash_dev/tags" | grep "/frainzy1477/clash_dev/releases/" | head -n 1 | awk -F "/tag/" '{print $2}' | sed 's/\">//')

	if [ $new_clashr_core_version ]; then
		echo $new_clashr_core_version >/usr/share/clash/download_core_version 2>&1
	elif [ $new_clashr_core_version = "" ]; then
		echo 0 >/usr/share/clash/download_core_version 2>&1
	fi
	sleep 5
	if [ -f /usr/share/clash/download_core_version ]; then
		CLASHVER=$(sed -n 1p /usr/share/clash/download_core_version 2>/dev/null)
	fi
fi

sleep 2

# shellcheck disable=SC2086
update() {
	if [ -f /tmp/clash.gz ]; then
		rm -rf /tmp/clash.gz >/dev/null 2>&1
	fi
	echo "  ${LOGTIME} - Starting clash core download..." >>$LOG_FILE
	if [ $CORETYPE -eq 1 ]; then
		wget --no-check-certificate https://github.com/frainzy1477/clash_dev/releases/download/"$CLASHVER"/clash-"$MODELTYPE".gz -O /tmp/clash.gz 2>&1
	elif [ $CORETYPE -eq 3 ]; then
		wget --no-check-certificate https://github.com/frainzy1477/clashtun/releases/download/"$CLASHTUN"/clash-"$MODELTYPE".gz -O /tmp/clash.gz 2>&1
	elif [ $CORETYPE -eq 4 ]; then
		wget --no-check-certificate https://github.com/frainzy1477/clashdtun/releases/download/"$CLASHDTUNC"/clash-"$MODELTYPE".gz -O /tmp/clash.gz 2>&1
	fi

	if [ "$?" -eq "0" ] && [ "$(ls -l /tmp/clash.gz | awk '{print int($5)}')" -ne 0 ]; then
		echo "  ${LOGTIME} - Unzipping core file..." >>$LOG_FILE
		gunzip /tmp/clash.gz >/dev/null 2>&1 &&
			rm -rf /tmp/clash.gz >/dev/null 2>&1 &&
			chmod 755 /tmp/clash &&
			chown root:root /tmp/clash

		echo "  ${LOGTIME} - Updating core now..." >>$LOG_FILE

		if [ $CORETYPE -eq 1 ]; then
			rm -rf ${CORE_CLASH} >/dev/null 2>&1
			mv /tmp/clash ${CORE_CLASH} >/dev/null 2>&1
			rm -rf /usr/share/clash/core_version >/dev/null 2>&1
			mv /usr/share/clash/download_core_version /usr/share/clash/core_version >/dev/null 2>&1
			echo "  ${LOGTIME} - Clash core updated successfully" >>$LOG_FILE

		elif [ $CORETYPE -eq 3 ]; then
			rm -rf ${CORE_CLASH_TUN} >/dev/null 2>&1
			mv /tmp/clash ${CORE_CLASH_TUN} >/dev/null 2>&1
			rm -rf /usr/share/clash/tun_version >/dev/null 2>&1
			mv /usr/share/clash/download_tun_version /usr/share/clash/tun_version >/dev/null 2>&1
			tun=$(sed -n 1p /usr/share/clash/tun_version 2>/dev/null)
			sed -i "s/${tun}/v${tun}/g" /usr/share/clash/tun_version 2>&1
			echo "  ${LOGTIME} - Clash core updated successfully" >>$LOG_FILE

		fi

		sleep 2
		touch /usr/share/clash/core_down_complete >/dev/null 2>&1
		sleep 2
		rm -rf /var/run/core_update >/dev/null 2>&1
		echo "" >/tmp/clash_update.txt >/dev/null 2>&1

	else
		echo "  ${LOGTIME} - Failed to download core file" >>$LOG_FILE
		rm -rf /tmp/clash.tar.gz >/dev/null 2>&1
		echo "" >/tmp/clash_update.txt >/dev/null 2>&1
	fi
	if pidof clash_core >/dev/null; then
		if [ $CORETYPE = $CORE ]; then
			/etc/init.d/clash restart >/dev/null
		fi
	fi
}

# shellcheck disable=SC2086
if [ $CORETYPE -eq 1 ] || [ $CORETYPE -eq 3 ] || [ $CORETYPE -eq 4 ]; then
	update
fi
