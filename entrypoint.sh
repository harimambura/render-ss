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

if [ ! -d /etc/shadowsocks-libev ]; then  
  mkdir /etc/shadowsocks-libev
fi

# TODO: bug when PASSWORD contain '/'
sed -e "/^#/d"\
    -e "s/\${PASSWORD}/${PASSWORD}/g"\
    -e "s/\${ENCRYPT}/${ENCRYPT}/g"\
    -e "s|\${X_Path}|${X_Path}|g"\
    /conf/shadowsocks-libev_config.json >  /etc/shadowsocks-libev/config.json
echo /etc/shadowsocks-libev/config.json
cat /etc/shadowsocks-libev/config.json

if [[ -z "${ProxySite}" ]]; then
  s="s/proxy_pass/#proxy_pass/g"
  echo "site:use local wwwroot html"
else
  s="s|\${ProxySite}|${ProxySite}|g"
  echo "site: ${ProxySite}"
fi

sed -e "/^#/d"\
    -e "s/\${PORT}/${PORT}/g"\
    -e "s|\${X_Path}|${X_Path}|g"\
    -e "s|\${QR_Path}|${QR_Path}|g"\
    -e "$s"\
    /conf/nginx_ss.conf > /etc/nginx/conf.d/ss.conf
echo /etc/nginx/conf.d/ss.conf
cat /etc/nginx/conf.d/ss.conf


if [ "$AppName" = "no" ]; then
  echo "不生成二维码"
else
  [ ! -d /wwwroot/${QR_Path} ] && mkdir /wwwroot/${QR_Path}
  plugin=$(echo -n "xray;path=${X_Path};host=${AppName}.onrender.com;tls" | sed -e 's/\//%2F/g' -e 's/=/%3D/g' -e 's/;/%3B/g')
  ss="ss://$(echo -n ${ENCRYPT}:${PASSWORD} | base64 -w 0)@${AppName}.onrender.com:443?plugin=${plugin}" 
  echo "${ss}" | tr -d '\n' > /wwwroot/${QR_Path}/index.html
  echo -n "${ss}" | qrencode -s 6 -o /wwwroot/${QR_Path}/vpn.png
  echo ${ss}
fi

echo 'RUN SS SERVER'
/root/go/bin/go-shadowsocks2 -s "ss://AEAD_CHACHA20_POLY1305:${PASSWORD}@:443" -plugin xx-plugin -plugin-opts "server;loglevel=none" -udp=false >> /dev/null
rm -rf /etc/nginx/sites-enabled/default
nginx -g 'daemon off;'
