#!/bin/sh

# shellcheck source=/dev/null
. /usr/share/clash/init_env_conf.sh

UPDATE_LOG_FILE="/tmp/clash_update.txt"
download_core_type=$(uci get clash.config.dcore 2>/dev/null)
tmp_core_file="/tmp/clash-core-tmp.tar"

get_log_time() {
	date "+%Y-%m-%d %H:%M:%S"
}

prepare_for_update() {
	if [ -f $tmp_core_file ]; then
		rm -rf $tmp_core_file >/dev/null 2>&1
	fi
	echo '' >$UPDATE_LOG_FILE 2>/dev/null

	if [ -f "$CORE_DOWNLOADED_FLAG" ]; then
		rm -rf "$CORE_DOWNLOADED_FLAG" 2>/dev/null
	fi
}

# shellcheck disable=SC2086
check_latest_version() {
	echo "  $(get_log_time) - Checking latest version.." >$UPDATE_LOG_FILE
	if [ $download_core_type -eq 4 ]; then

		if [ -f /usr/share/clash/download_dtun_version ]; then
			rm -rf /usr/share/clash/download_dtun_version
		fi
		new_clashdtun_core_version=$(wget -qO- "$URL_GITHUB_CORE_DTUN_TAGS" | grep "/frainzy1477/clashdtun/releases/" | head -n 1 | awk -F "/tag/" '{print $2}' | sed 's/\">//')

		if [ $new_clashdtun_core_version ]; then
			echo $new_clashdtun_core_version >/usr/share/clash/download_dtun_version 2>&1
		elif [ $new_clashdtun_core_version = "" ]; then
			echo 0 >/usr/share/clash/download_dtun_version 2>&1
		fi
		sleep 1
		if [ -f /usr/share/clash/download_dtun_version ]; then
			CLASHDTUNC=$(sed -n 1p /usr/share/clash/download_dtun_version 2>/dev/null)
		fi

	elif [ $download_core_type -eq 3 ]; then

		if [ -f /usr/share/clash/download_tun_version ]; then
			rm -rf /usr/share/clash/download_tun_version
		fi
		new_clashtun_core_version=$(wget -qO- "https://github.com/frainzy1477/clashtun/tags" | grep "/frainzy1477/clashtun/releases/" | head -n 1 | awk -F "/tag/" '{print $2}' | sed 's/\">//')

		if [ $new_clashtun_core_version ]; then
			echo $new_clashtun_core_version >/usr/share/clash/download_tun_version 2>&1
		elif [ $new_clashtun_core_version = "" ]; then
			echo 0 >/usr/share/clash/download_tun_version 2>&1
		fi
		sleep 1
		if [ -f /usr/share/clash/download_tun_version ]; then
			CLASHTUN=$(sed -n 1p /usr/share/clash/download_tun_version 2>/dev/null)
		fi

	elif [ $download_core_type -eq 1 ]; then

		if [ -f /usr/share/clash/download_core_version ]; then
			rm -rf /usr/share/clash/download_core_version
		fi
		new_clashr_core_version=$(wget -qO- "https://github.com/frainzy1477/clash_dev/tags" | grep "/frainzy1477/clash_dev/releases/" | head -n 1 | awk -F "/tag/" '{print $2}' | sed 's/\">//')

		if [ $new_clashr_core_version ]; then
			echo $new_clashr_core_version >/usr/share/clash/download_core_version 2>&1
		elif [ $new_clashr_core_version = "" ]; then
			echo 0 >/usr/share/clash/download_core_version 2>&1
		fi
		sleep 1
		if [ -f /usr/share/clash/download_core_version ]; then
			CLASHVER=$(sed -n 1p /usr/share/clash/download_core_version 2>/dev/null)
		fi

	fi
}

# shellcheck disable=SC2164
update() {
	tmp_model_type=$(uci get clash.config.download_core 2>/dev/null)
	if [ -f /tmp/clash.gz ]; then
		rm -rf /tmp/clash.gz >/dev/null 2>&1
	fi

	echo "  $(get_log_time) - Starting clash core download..." >>$UPDATE_LOG_FILE

	if [ "$download_core_type" -eq 1 ]; then
		wget --no-check-certificate https://files.cnblogs.com/files/dylanchu/clash-core-softfloat.tar?t=1653323230 -O $tmp_core_file 2>&1
	elif [ "$download_core_type" -eq 3 ]; then
		wget --no-check-certificate https://github.com/frainzy1477/clashtun/releases/download/"$CLASHTUN"/clash-"$tmp_model_type".gz -O $tmp_core_file 2>&1
	elif [ "$download_core_type" -eq 4 ]; then
		wget --no-check-certificate https://github.com/frainzy1477/clashdtun/releases/download/"$CLASHDTUNC"/clash-"$tmp_model_type".gz -O $tmp_core_file 2>&1
	fi
	if [ "$?" -ne 0 ] || [ ! -s $tmp_core_file ]; then
		echo "  $(get_log_time) - Failed to download core file" >>$UPDATE_LOG_FILE
		rm -f $tmp_core_file >/dev/null 2>&1
		exit 1
	else
		echo "  $(get_log_time) - Trying to extract core file..." >>$UPDATE_LOG_FILE
		cd /tmp
		if tar -xf $tmp_core_file; then
			rm -f $tmp_core_file >/dev/null 2>&1
			chmod 755 "$CORE_NAME_IN_TAR" && chown root:root "$CORE_NAME_IN_TAR"
			echo "  $(get_log_time) - Core file extracted." >>$UPDATE_LOG_FILE
		else
			rm -f $tmp_core_file >/dev/null 2>&1
			echo "  $(get_log_time) - Failed to extract file." >>$UPDATE_LOG_FILE
			exit 1
		fi

		echo "  $(get_log_time) - Updating core now..." >>$UPDATE_LOG_FILE

		if [ "$download_core_type" -eq 1 ]; then
			if [ "$CORE_NAME_IN_TAR" != "$CORE_CLASH" ]; then
				mv "$CORE_NAME_IN_TAR" "$CORE_CLASH"
			fi
			rm -rf /usr/share/clash/core_version >/dev/null 2>&1
			# mv /usr/share/clash/download_core_version /usr/share/clash/core_version >/dev/null 2>&1
			echo "  $(get_log_time) - Clash core updated successfully" >>$UPDATE_LOG_FILE
		elif [ "$download_core_type" -eq 3 ]; then
			if [ "$CORE_NAME_IN_TAR" != "$CORE_CLASH_TUN" ]; then
				mv "$CORE_NAME_IN_TAR" "$CORE_CLASH_TUN"
			fi
			rm -rf /usr/share/clash/tun_version >/dev/null 2>&1
			# mv /usr/share/clash/download_tun_version /usr/share/clash/tun_version >/dev/null 2>&1
			# tun=$(sed -n 1p /usr/share/clash/tun_version 2>/dev/null)
			# sed -i "s/${tun}/v${tun}/g" /usr/share/clash/tun_version 2>&1
			echo "  $(get_log_time) - Clash core updated successfully" >>$UPDATE_LOG_FILE
		fi

		touch "$CORE_DOWNLOADED_FLAG" >/dev/null 2>&1
		rm -rf /var/run/core_update >/dev/null 2>&1
	fi
}

restart_core() {
	echo "  $(get_log_time) - Now restart clash core" >>$UPDATE_LOG_FILE
	if pidof clash_core >/dev/null; then
		if [ "$download_core_type" = "$(uci get clash.config.core 2>/dev/null)" ]; then
			/etc/init.d/clash restart >/dev/null
		fi
	fi
}

#=============================================================================================================================

entry() {
	download_core_type=$(uci get clash.config.dcore 2>/dev/null)
	if [ "$1" = "check" ]; then
		check_latest_version
	elif [ "$1" = "update" ]; then
		prepare_for_update
		update
	elif [ -z "$1" ]; then
		prepare_for_update
		check_latest_version
		sleep 1
		if [ "$download_core_type" -eq 1 ] || [ "$download_core_type" -eq 3 ] || [ "$download_core_type" -eq 4 ]; then
			update
		fi
		restart_core
	fi
}

entry "$@"
