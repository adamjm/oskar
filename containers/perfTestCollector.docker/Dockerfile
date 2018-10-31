FROM golang:alpine
MAINTAINER Michael Hackstein <michael@arangodb.com>

RUN apk update && apk add gnuplot fish openssh-client

COPY entrypoint.sh /entrypoint.sh
COPY ./tools /tools
ENTRYPOINT [ "/entrypoint.sh" ]

CMD [ "collect" ]
