#!/bin/bash /etc/rc.common

RULE_FILE_NAME="$1"

# shellcheck source=/dev/null
. /lib/functions.sh
# shellcheck source=/dev/null
. /usr/share/clash/init_env_conf.sh


RULE_FILE_ENNAME=$(grep -F "$RULE_FILE_NAME" "$GAME_RULE_INFO_FILE" | awk -F ',' '{print $3}' 2>/dev/null)
if [ -n "$RULE_FILE_ENNAME" ]; then
	DOWNLOAD_PATH=$(grep -F "$RULE_FILE_NAME" "$GAME_RULE_INFO_FILE" | awk -F ',' '{print $2}' 2>/dev/null)
else
	DOWNLOAD_PATH=$RULE_FILE_NAME
fi
RULE_FILE_DIR="/usr/share/clash/rules/g_rules/$RULE_FILE_NAME"
TMP_RULE_DIR="/tmp/$RULE_FILE_NAME"

echo "Updating rule [$RULE_FILE_NAME] ..." >>"$REAL_LOG"

wget --no-check-certificate -c4 https://raw.githubusercontent.com/FQrabbit/SSTap-Rule/master/rules/"$DOWNLOAD_PATH" -O "$TMP_RULE_DIR" 2>&1

if [ "$?" -eq "0" ] && [ -s "$TMP_RULE_DIR" ]; then

	echo "[$RULE_FILE_NAME] Downloaded successfully. Checking if the rules has updates..." >>"$REAL_LOG"

	if ! cmp -s "$TMP_RULE_DIR" "$RULE_FILE_DIR"; then

		echo "Rules has updates. Replacing the old rules..." >>"$REAL_LOG"
		mv "$TMP_RULE_DIR" "$RULE_FILE_DIR" >/dev/null 2>&1
		echo "Deleting download cache..." >>"$REAL_LOG"
		rm -rf "$TMP_RULE_DIR" >/dev/null 2>&1
		echo "Rule [$RULE_FILE_NAME] updated successfully!" >>"$REAL_LOG"
	else
		echo "No updates for rule [$RULE_FILE_NAME]. done." >>"$REAL_LOG"
		rm -rf "$TMP_RULE_DIR" >/dev/null 2>&1
	fi
else
	echo "Failed to download [$RULE_FILE_NAME]" >>"$REAL_LOG"
	rm -rf "$TMP_RULE_DIR" >/dev/null 2>&1
fi
