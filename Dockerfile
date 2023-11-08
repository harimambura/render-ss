FROM debian:sid

RUN set -ex\
    && apt update -y \
    && apt upgrade -y \
    && apt install golang -y \
    && apt autoremove -y
RUN go install github.com/shadowsocks/go-shadowsocks2@latest
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENV PATH="$GOPATH/bin:/:$PATH"
CMD /entrypoint.sh
