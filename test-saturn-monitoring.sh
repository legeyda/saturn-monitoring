#!/usr/bin/env bash
set -eu


function main() {
	export TELEGRAM_API_KEY=xyz
	export TELEGRAM_CHAT_ID=xyz

	. ./saturn-monitoring.sh

	test-check
	test-is-resend-timeout

	echo all tests ok
}

function test-check() {


	export TARGET_METHOD=GET
	export TARGET_URL=https://www.google.com/
	export TARGET_REQUIRE_2XX=true
	check > /dev/null || fail 1 google should be available

	export TARGET_METHOD=GET
	export TARGET_URL=https://www.google.coms/
	export TARGET_REQUIRE_2XX=false
	check > /dev/null && fail 1 google should be available || {
		local result_code=$?
		test $result_code == 6 || fail "errcode should be 6 (got $result_code)"
	}

}

function test-is-resend-timeout() {
	RESEND_TIMEOUT=-1 is-resend-timeout && fail is-resend-timeout succeed when RESEND_TIMEOUT is negative
	RESEND_TIMEOUT=0  is-resend-timeout && fail is-resend-timeout succeed when RESEND_TIMEOUT is zero

	RESEND_TIMEOUT=1 send_timestamp=$[ $(timestamp)     ] is-resend-timeout && fail
	RESEND_TIMEOUT=1 send_timestamp=$[ $(timestamp) - 1 ] is-resend-timeout || fail

	RESEND_TIMEOUT=10 send_timestamp=$[ $(timestamp) - 9  ] is-resend-timeout && fail
	RESEND_TIMEOUT=10 send_timestamp=$[ $(timestamp) - 10 ] is-resend-timeout || fail
	RESEND_TIMEOUT=10 send_timestamp=$[ $(timestamp) - 11 ] is-resend-timeout || fail
}


# fun: fail 1 error message
# txt: print error message and exits with given errcode
fail() {
	local msg="$@"
	test -n "$msg" && msg="test failure: $msg" || msg='test failure'
	(>&2 echo "$msg")
	exit 1
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
