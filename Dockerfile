FROM debian:sid

RUN set -ex\
    && apt update -y \
    && apt upgrade -y \
    && apt install golang -y \
    && apt install -y wget unzip qrencode\
    && apt install -y nginx\
    && apt autoremove -y
RUN go install github.com/shadowsocks/go-shadowsocks2@latest

COPY wwwroot.tar.gz /wwwroot/wwwroot.tar.gz
COPY conf/ /conf
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENV PATH="$GOPATH/bin:$PATH"
CMD /entrypoint.sh
