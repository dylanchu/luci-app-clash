#!/bin/sh

# shellcheck source=/dev/null
. /usr/share/clash/init_env_conf.sh

UPDATE_LOG_FILE="/tmp/clash_update.txt"
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

# update_version_file  core_path  fieldname
update_version_file() {
	new_ver=$("$1" -v | awk -F ' ' '{print $2}' 2>/dev/null)
	old_line=$(grep -w "$2" "$CORE_VERSON_META_FILE" 2>/dev/null)
	if [ -z "$old_line" ]; then
		echo "$2=$new_ver" >> "$CORE_VERSON_META_FILE"
	else
		sed -i "s/$old_line/$2=$new_ver/g" "$CORE_VERSON_META_FILE" 2>/dev/null
	fi
}

# shellcheck disable=SC2164
update() {
	download_core_type=$(uci get clash.config.dcore 2>/dev/null)
	url_download_core=$(uci get clash.config.url_dcore 2>/dev/null)

	if [ -z "$url_download_core" ]; then
		echo "  $(get_log_time) - ERROR: Download url is empty." >>$UPDATE_LOG_FILE
		exit 1
	fi

	echo "  $(get_log_time) - Starting clash core download..." >>$UPDATE_LOG_FILE

	if [ "$download_core_type" -eq 1 ]; then
		wget --no-check-certificate "$url_download_core" -O $tmp_core_file 2>&1
	elif [ "$download_core_type" -eq 3 ]; then
		wget --no-check-certificate "$url_download_core" -O $tmp_core_file 2>&1
	elif [ "$download_core_type" -eq 4 ]; then
		wget --no-check-certificate "$url_download_core" -O $tmp_core_file 2>&1
	fi
	if [ "$?" -ne 0 ] || [ ! -s $tmp_core_file ]; then
		echo "  $(get_log_time) - Failed to download core file" >>$UPDATE_LOG_FILE
		rm -f $tmp_core_file >/dev/null 2>&1
		exit 2
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
			exit 3
		fi

		echo "  $(get_log_time) - Updating core now..." >>$UPDATE_LOG_FILE

		if [ "$download_core_type" -eq 1 ]; then
			if [ "$CORE_NAME_IN_TAR" != "$CORE_CLASH" ]; then
				mv "$CORE_NAME_IN_TAR" "$CORE_CLASH"
			fi
			update_version_file  "$CORE_CLASH"  "core"
			echo "  $(get_log_time) - Clash core updated successfully" >>$UPDATE_LOG_FILE
		elif [ "$download_core_type" -eq 3 ]; then
			if [ "$CORE_NAME_IN_TAR" != "$CORE_CLASH_TUN" ]; then
				mv "$CORE_NAME_IN_TAR" "$CORE_CLASH_TUN"
			fi
			update_version_file  "$CORE_CLASH_TUN"  "core_tun"
			echo "  $(get_log_time) - Clash tun core updated successfully" >>$UPDATE_LOG_FILE
		elif [ "$download_core_type" -eq 4 ]; then
			if [ "$CORE_NAME_IN_TAR" != "$CORE_CLASH_DTUN" ]; then
				mv "$CORE_NAME_IN_TAR" "$CORE_CLASH_DTUN"
			fi
			update_version_file  "$CORE_CLASH_DTUN"  "core_dtun"
			echo "  $(get_log_time) - Clash dtun core updated successfully" >>$UPDATE_LOG_FILE
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
	if [ "$1" = "update" ]; then
		prepare_for_update
		update
	elif [ "$1" = "dl_n_update" ]; then
		prepare_for_update
		update
		restart_core
	elif [ "$1" = "update_version" ]; then
		update_version_file  "$2"  "$3"
	fi
}

entry "$@"
