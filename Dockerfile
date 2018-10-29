FROM codacy/ci-base:2018.08.3

LABEL maintainer="team@codacy.com"

WORKDIR /scripts
COPY /src/ ./src/
COPY get_next_version.sh .

RUN mkdir /repo
VOLUME /repo

ENTRYPOINT ["./get_next_version.sh", "/repo"]
