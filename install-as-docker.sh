#/usr/bin/env bash
set -eu

# todo install docker

docker build -t saturn-monitoring .
docker stop partner-api-monitoring && docker rm partner-api-monitoring || true
docker run --name partner-api-monitoring --detach --restart always \
	--env TELEGRAM_API_KEY="${TELEGRAM_API_KEY}" --env TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID}" \
	--env TARGET_NAME="${TARGET_NAME:-Service}" --env TARGET_METHOD="${TARGET_METHOD:-GET}" --env TARGET_URL="$TARGET_URL" --env TARGET_REQUIRE_2XX="${TARGET_REQUIRE_2XX:-true}" \
	--env CHECK_INTERVAL="${CHECK_INTERVAL:-60}" --env CHECK_DAILY_PING="${CHECK_DAILY_PING:-true}" \
	saturn-monitoring
