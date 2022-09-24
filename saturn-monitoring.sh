#!/usr/bin/env bash
set -eu

: "${TELEGRAM_API_KEY}"
: "${TELEGRAM_CHAT_ID}"
: "${TARGET_NAME:=Service}"
: "${TARGET_URL}"
: "${TARGET_METHOD:=GET}"
: "${TARGET_REQUIRE_2XX:=true}"
: "${CHECK_INTERVAL:=60}"
: "${CHECK_DAILY_PING:=true}"



function today() {
	date +%Y-%m-%d
}

function now() {
	date +%Y-%m-%d_%H-%M-%S
}

CHECK_DETAILS=undefined
PREVIOUS_STATUS=undefined
PREVIOUS_PING_DATE=$(today)


function check() {
	CHECK_DETAILS=$(curl --verbose -X "$TARGET_METHOD" "$TARGET_URL" 2>&1) || return 1
	if [[ "$TARGET_REQUIRE_2XX" != 'false' ]]; then
		echo "$CHECK_DETAILS" | grep -q '< HTTP/1.1 2' || return 1
	fi
}

function send-message() {
	local text="$@"
	curl -X POST "https://api.telegram.org/bot$TELEGRAM_API_KEY/sendMessage" --data "chat_id=$TELEGRAM_CHAT_ID&text=${text:0:4096}" || true
}

function on-exit() {
	send-message "🙈 $TARGET_NAME monitoring goes down"
}
trap on-exit EXIT

send-message "👁 $TARGET_NAME monitoring goes up"
while true; do
	if check; then
		if [[ up != "$PREVIOUS_STATUS" ]]; then
			send-message "🚀 $TARGET_NAME is available"
			PREVIOUS_STATUS=up
		fi
	else
		if [[ down != "$PREVIOUS_STATUS" ]]; then
			send-message "💀 $TARGET_NAME unavailable! Request $TARGET_METHOD $TARGET_URL failed, details below.%0A%0A$CHECK_DETAILS"
			PREVIOUS_STATUS=down
		fi
	fi

	if [[ "$CHECK_DAILY_PING" == 'true' ]] && [[ $PREVIOUS_PING_DATE != $(today) ]] && [[ $(now) > $(today)_12 ]]; then
		send-message "👌 $TARGET_NAME monitoring goes on"
		PREVIOUS_PING_DATE=$(today)
	fi

	CHECK_DETAILS=undefined
	sleep "$CHECK_INTERVAL"
done