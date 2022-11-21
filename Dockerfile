FROM crystallang/crystal:1.6-alpine AS builder

RUN apk add --update --no-cache --force-overwrite git

RUN git config --global user.email "team@codacy.com" && git config --global user.name "Codacy"

RUN mkdir -p /workspace

WORKDIR /workspace
COPY ./ /workspace

RUN make test buildStatic

FROM alpine:3.15

LABEL maintainer="team@codacy.com"

RUN apk add --update --no-cache git jq

COPY --from=builder /workspace/bin/git-version /bin

RUN mkdir -p /repo
VOLUME /repo

CMD ["/bin/git-version", "--folder=/repo"]
