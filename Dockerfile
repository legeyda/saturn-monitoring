FROM alpine

ENV TELEGRAM_API_KEY=
ENV TELEGRAM_CHAT_ID=
ENV TARGET_NAME=Service
ENV TARGET_URL=
ENV TARGET_METHOD=GET
ENV TARGET_REQUIRE_2XX true
ENV CHECK_INTERVAL 60
ENV CHECK_DAILY_PING true

RUN apk update && apk add bash curl
COPY ./saturn-monitoring.sh /
COPY ./entry-point.sh /

CMD ["bash", "/entry-point.sh"]