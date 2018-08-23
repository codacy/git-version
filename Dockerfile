FROM codacy/ci-base:2018.08.3

LABEL maintainer="team@codacy.com"

WORKDIR /scripts
COPY get_next_version_date.sh .

RUN mkdir /repo
VOLUME /repo

ENTRYPOINT ["./get_next_version_date.sh", "/repo"]