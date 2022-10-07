#!/usr/bin/env bash
set -eu


function main() {

	: "${TELEGRAM_API_KEY}"
	: "${TELEGRAM_CHAT_ID}"
	: "${TARGET_NAME:=Service}"
	: "${TARGET_URL}"
	: "${TARGET_METHOD:=GET}"
	: "${TARGET_REQUIRE_2XX:=true}"
	: "${CHECK_INTERVAL:=60}"
	: "${RESEND_TIMEOUT:=$[24*60*60]}"

	trap on-exit EXIT

	local send_timestamp=0
	local previous_status=undefined

	send-message "👁 $TARGET_NAME monitoring goes up"
	while true; do
		local check_details
		if check_details="$(check)"; then
			if [[ up != "$previous_status" ]] || is-resend-timeout; then
				send-message "🚀 $TARGET_NAME is available"
				send_timestamp=$(timestamp)
				previous_status=up
			fi
		else
			if [[ down != "$previous_status" ]] || is-resend-timeout; then
				send-message "💀 $TARGET_NAME unavailable! Request $TARGET_METHOD $TARGET_URL failed, details below.%0A%0A$check_details"
				send_timestamp=$(timestamp)
				previous_status=down
			fi
		fi

		sleep "$CHECK_INTERVAL"
	done
}

function on-exit() {
	send-message "🙈 $TARGET_NAME monitoring goes down"
}

# env: TELEGRAM_API_KEY
#      TELEGRAM_CHAT_ID
#      send_timestamp
function send-message() {
	local text="$@"
	curl -X POST "https://api.telegram.org/bot$TELEGRAM_API_KEY/sendMessage" --data "chat_id=$TELEGRAM_CHAT_ID&text=${text:0:4096}" || true
}

# env: RESEND_TIMEOUT
#      send_timestamp
function is-resend-timeout() {
	[[ $RESEND_TIMEOUT -le 0 ]] && return 1
	#[[ $(now) < $(today)_12 ]] && return 1
	#[[ $(now) > $(today)_20 ]] && return 1
	(( $(timestamp) < $send_timestamp + $RESEND_TIMEOUT )) && return 1
	return 0
}

# env: TARGET_METHOD
#      TARGET_URL
#      TARGET_REQUIRE_2XX
function check() {
	local curl_args=''
	if [[ GET != "$TARGET_METHOD" ]]; then
		curl_args="-X $TARGET_METHOD"
	fi

	local check_details
	local check_result
	check_details=$(curl --verbose $curl_args "$TARGET_URL" 2>&1) && check_result=$? || check_result=$?

	test 0 != $check_result && return $check_result
	
	if [[ "$TARGET_REQUIRE_2XX" != 'false' ]]; then
		echo "$check_details" | grep -Eq '^< HTTP/[^ ]+ 2[0-9]+' || return 1
	fi

	return 0
}

function today() {
	date +%Y-%m-%d
}

function now() {
	date +%Y-%m-%d_%H-%M-%S
}

function timestamp() {
	date +%s
}


# ================================

# env: BASH_SOURCE
#      0
function script-is-sourced() {
	# todo https://unix.stackexchange.com/a/215279
    test "${BASH_SOURCE[0]}" != "${0}" || return 1
}

if ! script-is-sourced; then
	set -eu
	if [[ true == "${DEBUG:-}" ]]; then
		set -x
	fi
	script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )" main "$@"
fi
