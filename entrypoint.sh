#!/bin/bash

if [[ -z "${VER}" ]]; then
  VER="latest"
fi
echo ${VER}

if [[ -z "${PASSWORD}" ]]; then
  PASSWORD="5c301bb8-6c77-41a0-a606-4ba11bbab084"
fi
echo ${PASSWORD}

if [[ -z "${ENCRYPT}" ]]; then
  ENCRYPT="chacha20-ietf-poly1305"
fi

if [[ -z "${ProxySite}" ]]; then
  ProxySite="www.ietf.org"
fi

if [[ -z "${X_Path}" ]]; then
  X_Path="/s233"
fi
echo ${X_Path}

if [[ -z "${QR_Path}" ]]; then
  QR_Path="/qr_img"
fi
echo ${QR_Path}


if [ "$VER" = "latest" ]; then
  V_VER=`wget -qO- "https://api.github.com/repos/teddysun/xray-plugin/releases/latest" | sed -n -r -e 's/.*"tag_name".+?"([vV0-9\.]+?)".*/\1/p'`
  [[ -z "${V_VER}" ]] && V_VER="v1.8.4"
else
  V_VER="v$VER"
fi

mkdir /xraybin
cd /xraybin
XRAY_URL="https://github.com/teddysun/xray-plugin/releases/download/${V_VER}/xray-plugin-linux-amd64-${V_VER}.tar.gz"
echo ${XRAY_URL}
wget --no-check-certificate ${XRAY_URL}
tar -zxvf xray-plugin-linux-amd64-$V_VER.tar.gz
rm -rf xray-plugin-linux-amd64-$V_VER.tar.gz
mv xray-plugin_linux_amd64 /xx-plugin
rm -rf /xraybin

cd /wwwroot
tar xvf wwwroot.tar.gz
rm -rf wwwroot.tar.gz

plugin=$(echo -n "v2ray;path=${X_Path};host=${AppName}.onrender.com;tls" | sed -e 's/\//%2F/g' -e 's/=/%3D/g' -e 's/;/%3B/g')
ss="ss://$(echo -n ${ENCRYPT}:${PASSWORD} | base64 -w 0)@${AppName}.onrender.com:443?plugin=${plugin}" 
echo ${ss}

echo 'RUN SS SERVER'
/root/go/bin/go-shadowsocks2 -s "ss://AEAD_CHACHA20_POLY1305:${PASSWORD}@:443" -plugin xx-plugin -plugin-opts "server;loglevel=none" -udp=false &
