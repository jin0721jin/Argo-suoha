#!/bin/bash
# onekey suoha
linux_os=("Debian" "Ubuntu" "CentOS" "Fedora" "Alpine")
linux_update=("apt update" "apt update" "yum -y update" "yum -y update" "apk update")
linux_install=("apt -y install" "apt -y install" "yum -y install" "yum -y install" "apk add -f")
n=0
for i in `echo ${linux_os[@]}`
do
	if [ $i == $(grep -i PRETTY_NAME /etc/os-release | cut -d \" -f2 | awk '{print $1}') ]
	then
		break
	else
		n=$[$n+1]
	fi
done
if [ $n == 5 ]
then
	echo 当前系统$(grep -i PRETTY_NAME /etc/os-release | cut -d \" -f2)没有适配
	echo 默认使用APT包管理器
	n=0
fi
if [ -z $(type -P unzip) ]
then
	${linux_update[$n]}
	${linux_install[$n]} unzip
fi
if [ -z $(type -P curl) ]
then
	${linux_update[$n]}
	${linux_install[$n]} curl
fi
if [ $(grep -i PRETTY_NAME /etc/os-release | cut -d \" -f2 | awk '{print $1}') != "Alpine" ]
then
	if [ -z $(type -P systemctl) ]
	then
		${linux_update[$n]}
		${linux_install[$n]} systemctl
	fi
fi


function quicktunnel(){
case "$(uname -m)" in
	x86_64 | x64 | amd64 )
	curl -L https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip -o xray.zip
	curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared-linux
	;;
	i386 | i686 )
	curl -L https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-32.zip -o xray.zip
	curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386 -o cloudflared-linux
	;;
	armv8 | arm64 | aarch64 )
	echo arm64
	curl -L https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-arm64-v8a.zip -o xray.zip
	curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -o cloudflared-linux
	;;
	armv7l )
	curl -L https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-arm32-v7a.zip -o xray.zip
	curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm -o cloudflared-linux
	;;
	* )
	echo 当前架构$(uname -m)没有适配
	exit
	;;
esac
mkdir xray
unzip -d xray xray.zip
chmod +x cloudflared-linux xray/xray
rm -rf xray.zip
uuid=$(cat /proc/sys/kernel/random/uuid)
urlpath=$(echo $uuid | awk -F- '{print $1}')
port=$[$RANDOM+10000]
if [ $protocol == 1 ]
then
cat>xray/config.json<<EOF
{
	"inbounds": [
		{
			"port": $port,
			"listen": "localhost",
			"protocol": "vmess",
			"settings": {
				"clients": [
					{
						"id": "$uuid",
						"alterId": 0
					}
				]
			},
			"streamSettings": {
				"network": "ws",
				"wsSettings": {
					"path": "$urlpath"
				}
			}
		}
	],
	"outbounds": [
		{
			"protocol": "freedom",
			"settings": {}
		}
	]
}
EOF
fi
if [ $protocol == 2 ]
then
cat>xray/config.json<<EOF
{
	"inbounds": [
		{
			"port": $port,
			"listen": "localhost",
			"protocol": "vless",
			"settings": {
				"decryption": "none",
				"clients": [
					{
						"id": "$uuid"
					}
				]
			},
			"streamSettings": {
				"network": "ws",
				"wsSettings": {
					"path": "$urlpath"
				}
			}
		}
	],
	"outbounds": [
		{
			"protocol": "freedom",
			"settings": {}
		}
	]
}
EOF
fi
./xray/xray run>/dev/null 2>&1 &
./cloudflared-linux tunnel --url http://localhost:$port --no-autoupdate --edge-ip-version auto --protocol http2 >argo.log 2>&1 &
sleep 1
n=0
while true
do
n=$[$n+1]
clear
echo 等待cloudflare argo生成地址 已等待 $n 秒
argo=$(cat argo.log | grep trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
if [ $n == 15 ]
then
	n=0
	if [ $(grep -i PRETTY_NAME /etc/os-release | cut -d \" -f2 | awk '{print $1}') == "Alpine" ]
	then
		kill -9 $(ps -ef | grep cloudflared-linux | grep -v grep | awk '{print $1}') >/dev/null 2>&1
	else
		kill -9 $(ps -ef | grep cloudflared-linux | grep -v grep | awk '{print $2}') >/dev/null 2>&1
	fi
	rm -rf argo.log
	clear
	echo argo获取超时,重试中
	./cloudflared-linux tunnel --url http://localhost:$port --no-autoupdate --edge-ip-version auto --protocol http2 >argo.log 2>&1 &
	sleep 1
elif [ -z "$argo" ]
then
	sleep 1
else
	rm -rf argo.log
	break
fi
done
clear
if [ $protocol == 1 ]
then
	echo -e vmess链接已经生成, cf.877774.xyz 可替换为CF优选IP'\n' > v2ray.txt
	if [ $(grep -i PRETTY_NAME /etc/os-release | cut -d \" -f2 | awk '{print $1}') == "Alpine" ]
	then
		echo 'vmess://'$(echo '{"add":"cf.877774.xyz","aid":"0","host":"'$argo'","id":"'$uuid'","net":"ws","path":"'$urlpath'","port":"443","ps":"'$(echo $isp | sed -e 's/_/ /g')'_tls","tls":"tls","type":"none","v":"2"}' | base64 | awk '{ORS=(NR%76==0?RS:"");}1') >> v2ray.txt
	else
		echo 'vmess://'$(echo '{"add":"cf.877774.xyz","aid":"0","host":"'$argo'","id":"'$uuid'","net":"ws","path":"'$urlpath'","port":"443","ps":"'$(echo $isp | sed -e 's/_/ /g')'_tls","tls":"tls","type":"none","v":"2"}' | base64 -w 0) >> v2ray.txt
	fi
	echo -e '\n'端口 443 可改为 2053 2083 2087 2096 8443'\n' >> v2ray.txt
	if [ $(grep -i PRETTY_NAME /etc/os-release | cut -d \" -f2 | awk '{print $1}') == "Alpine" ]
	then
		echo 'vmess://'$(echo '{"add":"cf.877774.xyz","aid":"0","host":"'$argo'","id":"'$uuid'","net":"ws","path":"'$urlpath'","port":"80","ps":"'$(echo $isp | sed -e 's/_/ /g')'","tls":"","type":"none","v":"2"}' | base64 | awk '{ORS=(NR%76==0?RS:"");}1') >> v2ray.txt
	else
		echo 'vmess://'$(echo '{"add":"cf.877774.xyz","aid":"0","host":"'$argo'","id":"'$uuid'","net":"ws","path":"'$urlpath'","port":"80","ps":"'$(echo $isp | sed -e 's/_/ /g')'","tls":"","type":"none","v":"2"}' | base64 -w 0) >> v2ray.txt
	fi
	echo -e '\n'端口 80 可改为 8080 8880 2052 2082 2086 2095 >> v2ray.txt
fi
if [ $protocol == 2 ]
then
	echo -e vless链接已经生成, cf.877774.xyz 可替换为CF优选IP'\n' > v2ray.txt
	echo 'vless://'$uuid'@cf.877774.xyz:443?encryption=none&security=tls&sni='$domain'&type=ws&host='$argo'&path='$urlpath'#'$(echo $isp | sed -e 's/_/%20/g' -e 's/,/%2C/g')'_tls' >> v2ray.txt
	echo -e '\n'端口 443 可改为 2053 2083 2087 2096 8443'\n' >> v2ray.txt
	echo 'vless://'$uuid'@cf.877774.xyz:80?encryption=none&security=none&type=ws&host='$argo'&path='$urlpath'#'$(echo $isp | sed -e 's/_/%20/g' -e 's/,/%2C/g')'' >> v2ray.txt
	echo -e '\n'端口 80 可改为 8080 8880 2052 2082 2086 2095 >> v2ray.txt
fi
rm -rf argo.log
cat v2ray.txt
echo -e '\n'信息已经保存在 /root/v2ray.txt,再次查看请运行 cat /root/v2ray.txt
echo -e 注意：梭哈模式重启服务器后失效！！！
}

function installtunnel(){
#创建主目录
mkdir -p /opt/suoha/ >/dev/null 2>&1
case "$(uname -m)" in
	x86_64 | x64 | amd64 )
	curl -L https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip -o xray.zip
	curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared-linux
	;;
	i386 | i686 )
	curl -L https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-32.zip -o xray.zip
	curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386 -o cloudflared-linux
	;;
	armv8 | arm64 | aarch64 )
	echo arm64
	curl -L https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-arm64-v8a.zip -o xray.zip
	curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -o cloudflared-linux
	;;
	armv71 )
	curl -L https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-arm32-v7a.zip -o xray.zip
	curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm -o cloudflared-linux
	;;
	* )
	echo 当前架构$(uname -m)没有适配
	exit
	;;
esac
mkdir xray
unzip -d xray xray.zip
chmod +x cloudflared-linux xray/xray
mv cloudflared-linux /opt/suoha/
mv xray/xray /opt/suoha/
rm -rf xray xray.zip
uuid=$(cat /proc/sys/kernel/random/uuid)
urlpath=$(echo $uuid | awk -F- '{print $1}')
port=$[$RANDOM+10000]
if [ $protocol == 1 ]
then
cat>/opt/suoha/config.json<<EOF
{
	"inbounds": [
		{
			"port": $port,
			"listen": "localhost",
			"protocol": "vmess",
			"settings": {
				"clients": [
					{
						"id": "$uuid",
						"alterId": 0
					}
				]
			},
			"streamSettings": {
				"network": "ws",
				"wsSettings": {
					"path": "$urlpath"
				}
			}
		}
	],
	"outbounds": [
		{
			"protocol": "freedom",
			"settings": {}
		}
	]
}
EOF
fi
if [ $protocol == 2 ]
then
cat>/opt/suoha/config.json<<EOF
{
	"inbounds": [
		{
			"port": $port,
			"listen": "localhost",
			"protocol": "vless",
			"settings": {
				"decryption": "none",
				"clients": [
					{
						"id": "$uuid"
					}
				]
			},
			"streamSettings": {
				"network": "ws",
				"wsSettings": {
					"path": "$urlpath"
				}
			}
		}
	],
	"outbounds": [
		{
			"protocol": "freedom",
			"settings": {}
		}
	]
}
EOF
fi
clear
#!/usr/bin/env bash

CLOUDFLARED="/opt/suoha/cloudflared-linux"
CERT="${HOME}/.cloudflared/cert.pem"
ARGO_LOG="argo.log"

if [[ ! -f "$CERT" ]]; then
    echo "复制下面的链接,用浏览器打开并授权需要绑定的域名"
    echo "在网页中授权完毕后会继续进行下一步设置"
    $CLOUDFLARED --edge-ip-version auto --protocol http2 tunnel login
    clear
fi
cert_json=$(sed -n '/-----BEGIN/,/-----END/p' "$CERT" | grep -v '^-----' | tr -d '\n' | base64 -d 2>/dev/null)
zone_id=$(printf '%s' "$cert_json" | grep -o '"zoneID":"[^"]*"' | cut -d'"' -f4)
api_token=$(printf '%s' "$cert_json" | grep -o '"apiToken":"[^"]*"' | cut -d'"' -f4)

if [[ -z "$zone_id" || -z "$api_token" ]]; then
    echo "无法从 cert.pem 解析 zone 信息，请重新 login"
    exit 1
fi
zone_name=$(curl -sS "https://api.cloudflare.com/client/v4/zones/${zone_id}" \
    -H "Authorization: Bearer ${api_token}" \
    | grep -o '"result":{[^}]*}' | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)

if [[ -z "$zone_name" ]]; then
    echo "无法获取 zone 名称"
    exit 1
fi

echo "已授权的域名区域：$zone_name"
$CLOUDFLARED --edge-ip-version auto --protocol http2 tunnel list >"$ARGO_LOG" 2>&1
echo -e "\nARGO TUNNEL 当前已经绑定的服务："
sed 1,2d "$ARGO_LOG" | awk '{print $2}'

echo -e "\n自定义一个二级域名前缀，例如 xxx 或 例子"
echo "完整域名将是 <前缀>.${zone_name}"

read -r -p "输入二级域名前缀: " input

if [[ -z "$input" ]]; then
    echo "没有设置域名"
    exit 1
fi
domain="${input}.${zone_name}"
name="${input}"
if [[ $(sed 1,2d "$ARGO_LOG" | awk '{print $2}' | grep -w "$name" | wc -l) -eq 0 ]]; then
    echo "创建 TUNNEL $name"
    $CLOUDFLARED --edge-ip-version auto --protocol http2 tunnel create "$name" >"$ARGO_LOG" 2>&1
    echo "TUNNEL $name 创建成功"
else
    echo "TUNNEL $name 已经存在"
    tunnel_json="/root/.cloudflared/$(sed 1,2d "$ARGO_LOG" | awk '{print $1" "$2}' | grep -w "$name" | awk '{print $1}').json"
    if [[ ! -f "$tunnel_json" ]]; then
        echo "$tunnel_json 文件不存在"
        echo "清理 TUNNEL $name"
        $CLOUDFLARED --edge-ip-version auto --protocol http2 tunnel cleanup "$name" >"$ARGO_LOG" 2>&1
        echo "删除 TUNNEL $name"
        $CLOUDFLARED --edge-ip-version auto --protocol http2 tunnel delete "$name" >"$ARGO_LOG" 2>&1
        echo "重建 TUNNEL $name"
        $CLOUDFLARED --edge-ip-version auto --protocol http2 tunnel create "$name" >"$ARGO_LOG" 2>&1
    else
        echo "清理 TUNNEL $name"
        $CLOUDFLARED --edge-ip-version auto --protocol http2 tunnel cleanup "$name" >"$ARGO_LOG" 2>&1
    fi
fi
tunneluuid=$($CLOUDFLARED --edge-ip-version auto --protocol http2 tunnel list 2>/dev/null \
    | awk -v n="$name" '$2==n {print $1}')
echo "绑定 TUNNEL $name 到域名 $domain"
$CLOUDFLARED --edge-ip-version auto --protocol http2 tunnel route dns --overwrite-dns "$name" "$domain" >"$ARGO_LOG" 2>&1
if [[ -n "$tunneluuid" ]]; then
    record_info=$(curl -sS "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?type=CNAME&content=${tunneluuid}.cfargotunnel.com" \
        -H "Authorization: Bearer ${api_token}")
    normalized=$(printf '%s' "$record_info" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
    if [[ -n "$normalized" ]]; then
        echo "Cloudflare 返回的标准域名：$normalized"
        domain="$normalized"
    else
        echo "API 未查到记录，保留原值：$domain"
    fi
else
    echo "未取到 tunnel UUID，跳过规范化"
fi
echo "$domain 绑定成功"
if [ $protocol == 1 ]
then
	echo -e vmess链接已经生成, cf.877774.xyz 可替换为CF优选IP'\n' >/opt/suoha/v2ray.txt
	echo 'vmess://'$(echo '{"add":"cf.877774.xyz","aid":"0","host":"'$domain'","id":"'$uuid'","net":"ws","path":"'$urlpath'","port":"443","ps":"'$(echo $isp | sed -e 's/_/ /g')'","tls":"tls","type":"none","v":"2"}' | base64 -w 0) >>/opt/suoha/v2ray.txt
	echo -e '\n'端口 443 可改为 2053 2083 2087 2096 8443'\n' >>/opt/suoha/v2ray.txt
	echo 'vmess://'$(echo '{"add":"cf.877774.xyz","aid":"0","host":"'$domain'","id":"'$uuid'","net":"ws","path":"'$urlpath'","port":"80","ps":"'$(echo $isp | sed -e 's/_/ /g')'","tls":"","type":"none","v":"2"}' | base64 -w 0) >>/opt/suoha/v2ray.txt
	echo -e '\n'端口 80 可改为 8080 8880 2052 2082 2086 2095'\n' >>/opt/suoha/v2ray.txt
	echo 注意:如果 80 8080 8880 2052 2082 2086 2095 端口无法正常使用 >>/opt/suoha/v2ray.txt
	echo 请前往 https://dash.cloudflare.com/ >>/opt/suoha/v2ray.txt
	echo 检查管理面板 SSL/TLS - 边缘证书 - 始终使用HTTPS 是否处于关闭状态 >>/opt/suoha/v2ray.txt
fi
if [ $protocol == 2 ]
then
	echo -e vless链接已经生成, cf.877774.xyz 可替换为CF优选IP'\n' >/opt/suoha/v2ray.txt
	echo 'vless://'$uuid'@cf.877774.xyz:443?encryption=none&security=tls&type=ws&host='$domain'&path='$urlpath'&sni='$domain'#'$(echo $isp | sed -e 's/_/%20/g' -e 's/,/%2C/g')'_tls' >>/opt/suoha/v2ray.txt
	echo -e '\n'端口 443 可改为 2053 2083 2087 2096 8443'\n' >>/opt/suoha/v2ray.txt
	echo 'vless://'$uuid'@cf.877774.xyz:80?encryption=none&security=none&type=ws&host='$domain'&path='$urlpath'#'$(echo $isp | sed -e 's/_/%20/g' -e 's/,/%2C/g')'' >>/opt/suoha/v2ray.txt
	echo -e '\n'端口 80 可改为 8080 8880 2052 2082 2086 2095'\n' >>/opt/suoha/v2ray.txt
	echo 注意:如果 80 8080 8880 2052 2082 2086 2095 端口无法正常使用 >>/opt/suoha/v2ray.txt
	echo 请前往 https://dash.cloudflare.com/ >>/opt/suoha/v2ray.txt
	echo 检查管理面板 SSL/TLS - 边缘证书 - 始终使用HTTPS 是否处于关闭状态 >>/opt/suoha/v2ray.txt
fi
rm -rf argo.log
cat>/opt/suoha/config.yaml<<EOF
tunnel: $tunneluuid
credentials-file: /root/.cloudflared/$tunneluuid.json

ingress:
  - hostname:
    service: http://localhost:$port
EOF
if [ $(grep -i PRETTY_NAME /etc/os-release | cut -d \" -f2 | awk '{print $1}') == "Alpine" ]
then
cat>/etc/local.d/cloudflared.start<<EOF
/opt/suoha/cloudflared-linux --edge-ip-version auto --protocol http2 tunnel --config /opt/suoha/config.yaml run $name &
EOF
cat>/etc/local.d/xray.start<<EOF
/opt/suoha/xray run -config /opt/suoha/config.json &
EOF
chmod +x /etc/local.d/cloudflared.start /etc/local.d/xray.start
rc-update add local
/etc/local.d/cloudflared.start >/dev/null 2>&1
/etc/local.d/xray.start >/dev/null 2>&1
else
#创建服务
cat>/lib/systemd/system/cloudflared.service<<EOF
[Unit]
Description=Cloudflare Tunnel
After=network.target

[Service]
TimeoutStartSec=0
Type=simple
ExecStart=/opt/suoha/cloudflared-linux --edge-ip-version auto --protocol http2 tunnel --config /opt/suoha/config.yaml run $name
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
cat>/lib/systemd/system/xray.service<<EOF
[Unit]
Description=Xray
After=network.target

[Service]
TimeoutStartSec=0
Type=simple
ExecStart=/opt/suoha/xray run -config /opt/suoha/config.json
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
systemctl enable cloudflared.service >/dev/null 2>&1
systemctl enable xray.service >/dev/null 2>&1
systemctl --system daemon-reload
systemctl start cloudflared.service
systemctl start xray.service
fi
if [ $(grep -i PRETTY_NAME /etc/os-release | cut -d \" -f2 | awk '{print $1}') == "Alpine" ]
then
#创建命令链接
cat>/opt/suoha/suoha.sh<<EOF
#!/bin/bash
while true
do
if [ \$(ps -ef | grep cloudflared-linux | grep -v grep | wc -l) == 0 ]
then
	argostatus=stop
else
	argostatus=running
fi
if [ \$(ps -ef | grep xray | grep -v grep | wc -l) == 0 ]
then
	xraystatus=stop
else
	xraystatus=running
fi
echo argo \$argostatus
echo xray \$xraystatus
echo 1.管理TUNNEL
echo 2.启动服务
echo 3.停止服务
echo 4.重启服务
echo 5.卸载服务
echo 6.查看当前v2ray链接
echo 7.更换cf dns
echo 8.添加socks链接
echo 0.退出
read -p "请选择菜单(默认0): " menu
if [ -z "\$menu" ]
then
	menu=0
fi
elif [ \$menu == 0 ]
then
	echo 退出成功
	exit
fi
if [ \$menu == 1 ]
then
	clear
	while true
	do
		echo ARGO TUNNEL当前已经绑定的服务如下
		/opt/suoha/cloudflared-linux tunnel list
		echo 1.删除TUNNEL
		echo 0.退出
		read -p "请选择菜单(默认0): " tunneladmin
		if [ -z "\$tunneladmin" ]
		then
			tunneladmin=0
		fi
		if [ \$tunneladmin == 1 ]
		then
			read -p "请输入要删除的TUNNEL NAME: " tunnelname
			echo 断开TUNNEL \$tunnelname
			/opt/suoha/cloudflared-linux tunnel cleanup \$tunnelname
			echo 删除TUNNEL \$tunnelname
			/opt/suoha/cloudflared-linux tunnel delete \$tunnelname
		else
			break
		fi
	done
elif [ \$menu == 2 ]
then
	kill -9 \$(ps -ef | grep xray | grep -v grep | awk '{print \$1}') >/dev/null 2>&1
	kill -9 \$(ps -ef | grep cloudflared-linux | grep -v grep | awk '{print \$1}') >/dev/null 2>&1
	/etc/local.d/cloudflared.start >/dev/null 2>&1
	/etc/local.d/xray.start >/dev/null 2>&1
	clear
	sleep 1
elif [ \$menu == 3 ]
then
	kill -9 \$(ps -ef | grep xray | grep -v grep | awk '{print \$1}') >/dev/null 2>&1
	kill -9 \$(ps -ef | grep cloudflared-linux | grep -v grep | awk '{print \$1}') >/dev/null 2>&1
	clear
	sleep 2
elif [ \$menu == 4 ]
then
	kill -9 \$(ps -ef | grep xray | grep -v grep | awk '{print \$1}') >/dev/null 2>&1
	kill -9 \$(ps -ef | grep cloudflared-linux | grep -v grep | awk '{print \$1}') >/dev/null 2>&1
	/etc/local.d/cloudflared.start >/dev/null 2>&1
	/etc/local.d/xray.start >/dev/null 2>&1
	clear
	sleep 1
elif [ \$menu == 5 ]
then
	kill -9 \$(ps -ef | grep xray | grep -v grep | awk '{print \$1}') >/dev/null 2>&1
	kill -9 \$(ps -ef | grep cloudflared-linux | grep -v grep | awk '{print \$1}') >/dev/null 2>&1
	rm -rf /opt/suoha /etc/local.d/cloudflared.start /etc/local.d/xray.start /usr/bin/suoha ~/.cloudflared
	echo 所有服务都卸载完成
	echo 彻底删除授权记录
	echo 请访问 https://dash.cloudflare.com/profile/api-tokens
	echo 删除授权的 Argo Tunnel API Token 即可
	exit
elif [ \$menu == 6 ]
then
	clear
	cat /opt/suoha/v2ray.txt
elif [ \$menu == 7 ]
then
	echo "nameserver 1.1.1.1" > /etc/resolv.conf
	echo "nameserver 1.0.0.1" >> /etc/resolv.conf

elif [ \$menu == 8 ]
then
    CONFIG="/opt/suoha/config.json"
    LINKS="/opt/suoha/v2ray.txt"
    Xray="/opt/suoha/xray"

    echo "请输入 SOCKS5 分享链接："
    echo "示例：socks5://user-af:globe-server-af@10.91.0.1:8080#user-af"
    read -r SOCKS_URL

    case "$SOCKS_URL" in
        socks5://*) ;;
        *)
            echo "错误：链接必须以 socks5:// 开头"
            exit 1
            ;;
    esac

    SUFFIX="${SOCKS_URL##*#}"
    if [ "$SUFFIX" = "$SOCKS_URL" ]; then
        echo "错误：链接必须包含 #标签后缀"
        exit 1
    fi

    case "$SUFFIX" in
        ""|*[!a-zA-Z0-9_-]*)
            echo "错误：标签后缀只允许字母、数字、下划线和连字符"
            exit 1
            ;;
    esac

    URL_BODY="${SOCKS_URL#socks5://}"
    URL_BODY="${URL_BODY%%#*}"

    case "$URL_BODY" in
        *@*) ;;
        *)
            echo "错误：链接缺少用户名和密码"
            exit 1
            ;;
    esac

    AUTH="${URL_BODY%@*}"
    HOSTPORT="${URL_BODY##*@}"
    SOCKS_USER="${AUTH%%:*}"
    SOCKS_PASS="${AUTH#*:}"
    SOCKS_HOST="${HOSTPORT%:*}"
    SOCKS_PORT="${HOSTPORT##*:}"

    if [ -z "$SOCKS_USER" ] || [ "$SOCKS_PASS" = "$AUTH" ] ||
       [ -z "$SOCKS_PASS" ] || [ -z "$SOCKS_HOST" ] ||
       [ -z "$SOCKS_PORT" ]; then
        echo "错误：无法解析 SOCKS5 地址、端口或账号密码"
        exit 1
    fi

    case "$SOCKS_PORT" in
        *[!0-9]*)
            echo "错误：端口必须为数字"
            exit 1
            ;;
    esac

    case "$SOCKS_USER$SOCKS_PASS$SOCKS_HOST" in
        *['"\\']*)
            echo "错误：账号、密码或地址包含当前脚本不支持的特殊字符"
            exit 1
            ;;
    esac

    TAG="socks-$SUFFIX"
    UUID="$(cat /proc/sys/kernel/random/uuid)"

    if [ ! -f "$CONFIG" ]; then
        echo "错误：找不到配置文件 $CONFIG"
        exit 1
    fi

    if [ ! -x "$Xray" ]; then
        echo "错误：找不到可执行的 Xray：$Xray"
        exit 1
    fi

    if grep -q "\"email\"[[:space:]]*:[[:space:]]*\"$TAG\"" "$CONFIG" ||
       grep -q "\"tag\"[[:space:]]*:[[:space:]]*\"$TAG\"" "$CONFIG"; then
        echo "错误：标签 $TAG 已存在"
        exit 1
    fi

    # 确认当前配置包含需要修改的数组
    grep -q '"clients"[[:space:]]*:' "$CONFIG" || {
        echo "错误：没有找到 VLESS clients 数组"
        exit 1
    }

    grep -q '"outbounds"[[:space:]]*:' "$CONFIG" || {
        echo "错误：没有找到 outbounds 数组"
        exit 1
    }

    grep -q '"rules"[[:space:]]*:' "$CONFIG" || {
        echo "错误：没有找到 routing.rules 数组"
        exit 1
    }

    BACKUP="${CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
    TMP1="/tmp/suoha-socks-1.$$"
    TMP2="/tmp/suoha-socks-2.$$"
    TMP3="/tmp/suoha-socks-3.$$"

    cp "$CONFIG" "$BACKUP" || exit 1

    # 第一步：向 VLESS clients 数组追加客户端
    # 适配当前配置中 clients 数组结束行的 16 空格缩进
    awk -v uuid="$UUID" -v tag="$TAG" '
        /"clients"[[:space:]]*:/ { inside=1 }
        inside && /^                \]/ {
            print "                ,"
            print "                {\"id\":\"" uuid "\",\"email\":\"" tag "\"}"
            inside=0
            found=1
        }
        { print }
        END { if (!found) exit 2 }
    ' "$CONFIG" > "$TMP1" || {
        echo "错误：无法安全定位 clients 数组"
        rm -f "$TMP1" "$TMP2" "$TMP3"
        exit 1
    }

    # 第二步：追加 SOCKS 出站
    # 适配当前配置中 outbounds 外层数组结束行的 8 空格缩进
    awk -v tag="$TAG" -v host="$SOCKS_HOST" \
        -v port="$SOCKS_PORT" -v user="$SOCKS_USER" \
        -v pass="$SOCKS_PASS" '
        /"outbounds"[[:space:]]*:/ { inside=1 }
        inside && /^        \]/ {
            print "        ,"
            print "        {"
            print "          \"tag\": \"" tag "\","
            print "          \"protocol\": \"socks\","
            print "          \"settings\": {"
            print "            \"servers\": [{"
            print "              \"address\": \"" host "\","
            print "              \"port\": " port ","
            print "              \"users\": [{\"user\": \"" user "\", \"pass\": \"" pass "\"}]"
            print "            }]"
            print "          }"
            print "        }"
            inside=0
            found=1
        }
        { print }
        END { if (!found) exit 2 }
    ' "$TMP1" > "$TMP2" || {
        echo "错误：无法安全定位 outbounds 数组"
        rm -f "$TMP1" "$TMP2" "$TMP3"
        exit 1
    }

    # 第三步：追加按 email 匹配的路由规则
    # 适配当前配置中 routing.rules 数组结束行的 12 空格缩进
    awk -v tag="$TAG" '
        /"rules"[[:space:]]*:/ { inside=1 }
        inside && /^            \]/ {
            print "            ,"
            print "            {"
            print "              \"type\": \"field\","
            print "              \"inboundTag\": [\"vless-ws\"],"
            print "              \"user\": [\"" tag "\"],"
            print "              \"outboundTag\": \"" tag "\""
            print "            }"
            inside=0
            found=1
        }
        { print }
        END { if (!found) exit 2 }
    ' "$TMP2" > "$TMP3" || {
        echo "错误：无法安全定位 routing.rules 数组"
        rm -f "$TMP1" "$TMP2" "$TMP3"
        exit 1
    }

    # 检查生成内容是否包含三个必要部分
    grep -q "\"email\":\"$TAG\"" "$TMP3" || {
        echo "错误：未找到新增客户端"
        rm -f "$TMP1" "$TMP2" "$TMP3"
        exit 1
    }

    grep -q "\"tag\": \"$TAG\"" "$TMP3" || {
        echo "错误：未找到新增出站"
        rm -f "$TMP1" "$TMP2" "$TMP3"
        exit 1
    }

    grep -q "\"outboundTag\": \"$TAG\"" "$TMP3" || {
        echo "错误：未找到新增路由规则"
        rm -f "$TMP1" "$TMP2" "$TMP3"
        exit 1
    }

    # 测试配置通过后才替换原配置
    if ! "$Xray" run -test -config "$TMP3"; then
        echo "错误：Xray 配置测试失败，原配置未修改"
        echo "备份文件：$BACKUP"
        rm -f "$TMP1" "$TMP2" "$TMP3"
        exit 1
    fi

    cat "$TMP3" > "$CONFIG" || {
        echo "错误：写入配置失败，备份文件：$BACKUP"
        rm -f "$TMP1" "$TMP2" "$TMP3"
        exit 1
    }

    rm -f "$TMP1" "$TMP2" "$TMP3"

    # 追加分享链接，不覆盖原有节点
    if [ -n "$domain" ] && [ -n "$urlpath" ]; then
        {
            echo ""
            echo "===== SOCKS5 节点：$TAG ====="
            echo "vless://$UUID@cf.877774.xyz:443?encryption=none&security=tls&type=ws&host=$domain&path=$urlpath&sni=$domain#$TAG"
            echo "vless://$UUID@cf.877774.xyz:80?encryption=none&security=none&type=ws&host=$domain&path=$urlpath#$TAG"
        } >> "$LINKS"

        echo "分享链接已追加到 $LINKS"
    else
        echo "警告：domain 或 urlpath 未定义，未生成分享链接"
    fi

    echo ""
    echo "SOCKS5 节点添加完成"
    echo "UUID：$UUID"
    echo "路由标签：$TAG"
    echo "SOCKS5 地址：$SOCKS_HOST:$SOCKS_PORT"
    echo "配置备份：$BACKUP"
    echo "请按原脚本的服务管理方式重启 Xray，使配置生效。"
fi
done
EOF
else
#创建命令链接
cat>/opt/suoha/suoha.sh<<EOF
#!/bin/bash
clear
while true
do
echo argo \$(systemctl status cloudflared.service | sed -n '3p')
echo xray \$(systemctl status xray.service | sed -n '3p')
echo 1.管理TUNNEL
echo 2.启动服务
echo 3.停止服务
echo 4.重启服务
echo 5.卸载服务
echo 6.查看当前v2ray链接
echo 7.更换cloudflare dns
echo 8.添加socks出口链接
echo 0.退出
read -p "请选择菜单(默认0): " menu
if [ -z "\$menu" ]
then
	menu=0
fi
if [ \$menu == 1 ]
then
	clear
	while true
	do
		echo ARGO TUNNEL当前已经绑定的服务如下
		/opt/suoha/cloudflared-linux tunnel list
		echo 1.删除TUNNEL
		echo 0.退出
		read -p "请选择菜单(默认0): " tunneladmin
		if [ -z "\$tunneladmin" ]
		then
			tunneladmin=0
		fi
		if [ \$tunneladmin == 1 ]
		then
			read -p "请输入要删除的TUNNEL NAME: " tunnelname
			echo 断开TUNNEL \$tunnelname
			/opt/suoha/cloudflared-linux tunnel cleanup \$tunnelname
			echo 删除TUNNEL \$tunnelname
			/opt/suoha/cloudflared-linux tunnel delete \$tunnelname
		else
			break
		fi
	done
elif [ \$menu == 2 ]
then
	systemctl start cloudflared.service
	systemctl start xray.service
	clear
elif [ \$menu == 3 ]
then
	systemctl stop cloudflared.service
	systemctl stop xray.service
	clear
elif [ \$menu == 4 ]
then
	systemctl restart cloudflared.service
	systemctl restart xray.service
	clear
elif [ \$menu == 5 ]
then
	systemctl stop cloudflared.service
	systemctl stop xray.service
	systemctl disable cloudflared.service
	systemctl disable xray.service
	kill -9 \$(ps -ef | grep xray | grep -v grep | awk '{print \$2}') >/dev/null 2>&1
	kill -9 \$(ps -ef | grep cloudflared-linux | grep -v grep | awk '{print \$2}') >/dev/null 2>&1
	rm -rf /opt/suoha /lib/systemd/system/cloudflared.service /lib/systemd/system/xray.service /usr/bin/suoha ~/.cloudflared
	systemctl --system daemon-reload
	echo 所有服务都卸载完成
	echo 彻底删除授权记录
	echo 请访问 https://dash.cloudflare.com/profile/api-tokens
	echo 删除授权的 Argo Tunnel API Token 即可
	exit
elif [ \$menu == 6 ]
then
	clear
	cat /opt/suoha/v2ray.txt
elif [ \$menu == 7 ]
then
	echo "nameserver 1.1.1.1" > /etc/resolv.conf
	echo "nameserver 1.0.0.1" >> /etc/resolv.conf
elif [ \$menu == 8 ]
then
    CONFIG="/opt/suoha/config.json"
    LINKS="/opt/suoha/v2ray.txt"
    Xray="/opt/suoha/xray"

    echo "请输入 SOCKS5 分享链接："
    echo "示例：socks5://user-af:globe-server-af@10.91.0.1:8080#user-af"
    read -r SOCKS_URL

    case "$SOCKS_URL" in
        socks5://*) ;;
        *)
            echo "错误：链接必须以 socks5:// 开头"
            exit 1
            ;;
    esac

    SUFFIX="${SOCKS_URL##*#}"
    if [ "$SUFFIX" = "$SOCKS_URL" ]; then
        echo "错误：链接必须包含 #标签后缀"
        exit 1
    fi

    case "$SUFFIX" in
        ""|*[!a-zA-Z0-9_-]*)
            echo "错误：标签后缀只允许字母、数字、下划线和连字符"
            exit 1
            ;;
    esac

    URL_BODY="${SOCKS_URL#socks5://}"
    URL_BODY="${URL_BODY%%#*}"

    case "$URL_BODY" in
        *@*) ;;
        *)
            echo "错误：链接缺少用户名和密码"
            exit 1
            ;;
    esac

    AUTH="${URL_BODY%@*}"
    HOSTPORT="${URL_BODY##*@}"
    SOCKS_USER="${AUTH%%:*}"
    SOCKS_PASS="${AUTH#*:}"
    SOCKS_HOST="${HOSTPORT%:*}"
    SOCKS_PORT="${HOSTPORT##*:}"

    if [ -z "$SOCKS_USER" ] || [ "$SOCKS_PASS" = "$AUTH" ] ||
       [ -z "$SOCKS_PASS" ] || [ -z "$SOCKS_HOST" ] ||
       [ -z "$SOCKS_PORT" ]; then
        echo "错误：无法解析 SOCKS5 地址、端口或账号密码"
        exit 1
    fi

    case "$SOCKS_PORT" in
        *[!0-9]*)
            echo "错误：端口必须为数字"
            exit 1
            ;;
    esac

    case "$SOCKS_USER$SOCKS_PASS$SOCKS_HOST" in
        *['"\\']*)
            echo "错误：账号、密码或地址包含当前脚本不支持的特殊字符"
            exit 1
            ;;
    esac

    TAG="socks-$SUFFIX"
    UUID="$(cat /proc/sys/kernel/random/uuid)"

    if [ ! -f "$CONFIG" ]; then
        echo "错误：找不到配置文件 $CONFIG"
        exit 1
    fi

    if [ ! -x "$Xray" ]; then
        echo "错误：找不到可执行的 Xray：$Xray"
        exit 1
    fi

    if grep -q "\"email\"[[:space:]]*:[[:space:]]*\"$TAG\"" "$CONFIG" ||
       grep -q "\"tag\"[[:space:]]*:[[:space:]]*\"$TAG\"" "$CONFIG"; then
        echo "错误：标签 $TAG 已存在"
        exit 1
    fi

    # 确认当前配置包含需要修改的数组
    grep -q '"clients"[[:space:]]*:' "$CONFIG" || {
        echo "错误：没有找到 VLESS clients 数组"
        exit 1
    }

    grep -q '"outbounds"[[:space:]]*:' "$CONFIG" || {
        echo "错误：没有找到 outbounds 数组"
        exit 1
    }

    grep -q '"rules"[[:space:]]*:' "$CONFIG" || {
        echo "错误：没有找到 routing.rules 数组"
        exit 1
    }

    BACKUP="${CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
    TMP1="/tmp/suoha-socks-1.$$"
    TMP2="/tmp/suoha-socks-2.$$"
    TMP3="/tmp/suoha-socks-3.$$"

    cp "$CONFIG" "$BACKUP" || exit 1

    # 第一步：向 VLESS clients 数组追加客户端
    # 适配当前配置中 clients 数组结束行的 16 空格缩进
    awk -v uuid="$UUID" -v tag="$TAG" '
        /"clients"[[:space:]]*:/ { inside=1 }
        inside && /^                \]/ {
            print "                ,"
            print "                {\"id\":\"" uuid "\",\"email\":\"" tag "\"}"
            inside=0
            found=1
        }
        { print }
        END { if (!found) exit 2 }
    ' "$CONFIG" > "$TMP1" || {
        echo "错误：无法安全定位 clients 数组"
        rm -f "$TMP1" "$TMP2" "$TMP3"
        exit 1
    }

    # 第二步：追加 SOCKS 出站
    # 适配当前配置中 outbounds 外层数组结束行的 8 空格缩进
    awk -v tag="$TAG" -v host="$SOCKS_HOST" \
        -v port="$SOCKS_PORT" -v user="$SOCKS_USER" \
        -v pass="$SOCKS_PASS" '
        /"outbounds"[[:space:]]*:/ { inside=1 }
        inside && /^        \]/ {
            print "        ,"
            print "        {"
            print "          \"tag\": \"" tag "\","
            print "          \"protocol\": \"socks\","
            print "          \"settings\": {"
            print "            \"servers\": [{"
            print "              \"address\": \"" host "\","
            print "              \"port\": " port ","
            print "              \"users\": [{\"user\": \"" user "\", \"pass\": \"" pass "\"}]"
            print "            }]"
            print "          }"
            print "        }"
            inside=0
            found=1
        }
        { print }
        END { if (!found) exit 2 }
    ' "$TMP1" > "$TMP2" || {
        echo "错误：无法安全定位 outbounds 数组"
        rm -f "$TMP1" "$TMP2" "$TMP3"
        exit 1
    }

    # 第三步：追加按 email 匹配的路由规则
    # 适配当前配置中 routing.rules 数组结束行的 12 空格缩进
    awk -v tag="$TAG" '
        /"rules"[[:space:]]*:/ { inside=1 }
        inside && /^            \]/ {
            print "            ,"
            print "            {"
            print "              \"type\": \"field\","
            print "              \"inboundTag\": [\"vless-ws\"],"
            print "              \"user\": [\"" tag "\"],"
            print "              \"outboundTag\": \"" tag "\""
            print "            }"
            inside=0
            found=1
        }
        { print }
        END { if (!found) exit 2 }
    ' "$TMP2" > "$TMP3" || {
        echo "错误：无法安全定位 routing.rules 数组"
        rm -f "$TMP1" "$TMP2" "$TMP3"
        exit 1
    }

    # 检查生成内容是否包含三个必要部分
    grep -q "\"email\":\"$TAG\"" "$TMP3" || {
        echo "错误：未找到新增客户端"
        rm -f "$TMP1" "$TMP2" "$TMP3"
        exit 1
    }

    grep -q "\"tag\": \"$TAG\"" "$TMP3" || {
        echo "错误：未找到新增出站"
        rm -f "$TMP1" "$TMP2" "$TMP3"
        exit 1
    }

    grep -q "\"outboundTag\": \"$TAG\"" "$TMP3" || {
        echo "错误：未找到新增路由规则"
        rm -f "$TMP1" "$TMP2" "$TMP3"
        exit 1
    }

    # 测试配置通过后才替换原配置
    if ! "$Xray" run -test -config "$TMP3"; then
        echo "错误：Xray 配置测试失败，原配置未修改"
        echo "备份文件：$BACKUP"
        rm -f "$TMP1" "$TMP2" "$TMP3"
        exit 1
    fi

    cat "$TMP3" > "$CONFIG" || {
        echo "错误：写入配置失败，备份文件：$BACKUP"
        rm -f "$TMP1" "$TMP2" "$TMP3"
        exit 1
    }

    rm -f "$TMP1" "$TMP2" "$TMP3"

    # 追加分享链接，不覆盖原有节点
    if [ -n "$domain" ] && [ -n "$urlpath" ]; then
        {
            echo ""
            echo "===== SOCKS5 节点：$TAG ====="
            echo "vless://$UUID@cf.877774.xyz:443?encryption=none&security=tls&type=ws&host=$domain&path=$urlpath&sni=$domain#$TAG"
            echo "vless://$UUID@cf.877774.xyz:80?encryption=none&security=none&type=ws&host=$domain&path=$urlpath#$TAG"
        } >> "$LINKS"

        echo "分享链接已追加到 $LINKS"
    else
        echo "警告：domain 或 urlpath 未定义，未生成分享链接"
    fi

    echo ""
    echo "SOCKS5 节点添加完成"
    echo "UUID：$UUID"
    echo "路由标签：$TAG"
    echo "SOCKS5 地址：$SOCKS_HOST:$SOCKS_PORT"
    echo "配置备份：$BACKUP"
    echo "请按原脚本的服务管理方式重启 Xray，使配置生效。"
fi
elif [ \$menu == 0 ]
then
	echo 退出成功
	exit
fi
done
EOF
fi
chmod +x /opt/suoha/suoha.sh
ln -sf /opt/suoha/suoha.sh /usr/bin/suoha
}

clear
#!/bin/sh

# 打印 ASCII 艺术
echo "       _       _                              _                "
echo "      | |     | |       ___   _   _    ___   | |__     ____       "
echo "    __| |_____| |_     / __| | | | |  / _ \  | |_ \   / _  |   "
echo "   |__   ______  _|    \__ \ | |_| | | (_) | | | | | | (_| | "
echo "      | |_    | |_     |___/  \___/   \___/  |_| |_|  \____|"
echo "       \__|    \__|"
echo "                                 "
echo -e '\n'欢迎使用 TT Agro-suoha 一键梭哈脚本...'\n'
# 其他脚本内容
echo 梭哈模式不需要自己提供域名,使用CF ARGO QUICK TUNNEL创建快速链接
echo 梭哈模式在重启或者脚本再次运行后失效,如果需要使用需要再次运行创建
echo 安装服务模式,需要有CF托管域名,并且需要按照提示手动绑定ARGO服务
echo 首次绑定ARGO服务后如果不想再次跳转网页绑定
echo 将已经绑定的系统目录下的 /root/.cloudflared 文件夹以及内容
echo 拷贝至新系统下同样的目录,会自动跳过登录验证

echo -e 基于 Cloudflare Tunnel 的新一代超轻量级穿透工具
echo -e 无需公网 IP  无需端口转发  极致隐藏  专为 NAT VPS 打造

echo -e 注意：梭哈模式重启服务器后失效！！！

echo -e '\n'TT Cloudflare Tunnel 一键suoha脚本  无需公网 IP  无需端口转发 Agro隧道'\n'
echo 1.梭哈模式 无需cloudflare域名重启会失效！
echo 2.安装服务 需要cloudflare域名重启不会失效！
echo 3.卸载服务
echo 4.清空缓存
echo 5.管理服务
echo -e 0.退出脚本'\n'
read -p "请选择模式(默认1):" mode
if [ -z "$mode" ]
then
	mode=1
fi
# 在选择安装服务时再次检查
if [ $mode == 2 ]; then
    if [ -f "/usr/bin/suoha" ]; then
        echo "服务已经安装，正在跳转到管理菜单..."
        suoha
        exit 0
    fi
    # 继续安装流程...
fi
if [ $mode == 1 ]
then
	read -p "请选择xray协议(1.vmess,默认2.vless):" protocol
	if [ -z "$protocol" ]
	then
		protocol=2
	fi
	if [ $protocol != 1 ] && [ $protocol != 2 ]
	then
		echo 请输入正确的xray协议
		exit
	fi
	isp=$(curl -sm 3 -H "User-Agent: Mozilla/5.0" "https://api.ip.sb/geoip" | tr -d '\n' | awk -F\" '{c="";i="";for(x=1;x<=NF;x++){if($x=="country_code")c=$(x+2);if($x=="isp")i=$(x+2)};if(c&&i)print c"-"i}' | sed 's/ /_/g' || curl -sm 3 -H "User-Agent: Mozilla/5.0" "https://ipapi.co/json" | tr -d '\n' | awk -F\" '{c="";o="";for(x=1;x<=NF;x++){if($x=="country_code")c=$(x+2);if($x=="org")o=$(x+2)};if(c&&o)print c"-"o}' | sed 's/ /_/g' || echo "vps")
	if [ $(grep -i PRETTY_NAME /etc/os-release | cut -d \" -f2 | awk '{print $1}') == "Alpine" ]
	then
		kill -9 $(ps -ef | grep xray | grep -v grep | awk '{print $1}') >/dev/null 2>&1
		kill -9 $(ps -ef | grep cloudflared-linux | grep -v grep | awk '{print $1}') >/dev/null 2>&1
	else
		kill -9 $(ps -ef | grep xray | grep -v grep | awk '{print $2}') >/dev/null 2>&1
		kill -9 $(ps -ef | grep cloudflared-linux | grep -v grep | awk '{print $2}') >/dev/null 2>&1
	fi
	rm -rf xray cloudflared-linux v2ray.txt
	quicktunnel
elif [ $mode == 2 ]
then
	read -p "请选择xray协议(1.vmess,默认2.vless):" protocol
	if [ -z "$protocol" ]
	then
		protocol=2
	fi
	if [ $protocol != 1 ] && [ $protocol != 2 ]
	then
		echo 请输入正确的xray协议
		exit
	fi
	isp=$(curl -sm 3 -H "User-Agent: Mozilla/5.0" "https://api.ip.sb/geoip" | tr -d '\n' | awk -F\" '{c="";i="";for(x=1;x<=NF;x++){if($x=="country_code")c=$(x+2);if($x=="isp")i=$(x+2)};if(c&&i)print c"-"i}' | sed 's/ /_/g' || curl -sm 3 -H "User-Agent: Mozilla/5.0" "https://ipapi.co/json" | tr -d '\n' | awk -F\" '{c="";o="";for(x=1;x<=NF;x++){if($x=="country_code")c=$(x+2);if($x=="org")o=$(x+2)};if(c&&o)print c"-"o}' | sed 's/ /_/g' || echo "vps")
	if [ $(grep -i PRETTY_NAME /etc/os-release | cut -d \" -f2 | awk '{print $1}') == "Alpine" ]
	then
		kill -9 $(ps -ef | grep xray | grep -v grep | awk '{print $1}') >/dev/null 2>&1
		kill -9 $(ps -ef | grep cloudflared-linux | grep -v grep | awk '{print $1}') >/dev/null 2>&1
		rm -rf /opt/suoha /lib/systemd/system/cloudflared.service /lib/systemd/system/xray.service /usr/bin/suoha
	else
		systemctl stop cloudflared.service
		systemctl stop xray.service
		systemctl disable cloudflared.service
		systemctl disable xray.service
		kill -9 $(ps -ef | grep xray | grep -v grep | awk '{print $2}') >/dev/null 2>&1
		kill -9 $(ps -ef | grep cloudflared-linux | grep -v grep | awk '{print $2}') >/dev/null 2>&1
		rm -rf /opt/suoha /lib/systemd/system/cloudflared.service /lib/systemd/system/xray.service /usr/bin/suoha
		systemctl --system daemon-reload
	fi
	installtunnel
	cat /opt/suoha/v2ray.txt
	echo 服务安装完成,管理服务请运行命令 suoha
elif [ $mode == 3 ]
then
	if [ $(grep -i PRETTY_NAME /etc/os-release | cut -d \" -f2 | awk '{print $1}') == "Alpine" ]
	then
		kill -9 $(ps -ef | grep xray | grep -v grep | awk '{print $1}') >/dev/null 2>&1
		kill -9 $(ps -ef | grep cloudflared-linux | grep -v grep | awk '{print $1}') >/dev/null 2>&1
		rm -rf /opt/suoha /lib/systemd/system/cloudflared.service /lib/systemd/system/xray.service /usr/bin/suoha
	else
		systemctl stop cloudflared.service
		systemctl stop xray.service
		systemctl disable cloudflared.service
		systemctl disable xray.service
		kill -9 $(ps -ef | grep xray | grep -v grep | awk '{print $2}') >/dev/null 2>&1
		kill -9 $(ps -ef | grep cloudflared-linux | grep -v grep | awk '{print $2}') >/dev/null 2>&1
		rm -rf /opt/suoha /lib/systemd/system/cloudflared.service /lib/systemd/system/xray.service /usr/bin/suoha ~/.cloudflared
		systemctl --system daemon-reload
	fi
	clear
	echo 所有服务都卸载完成
	echo 彻底删除授权记录
	echo 请访问 https://dash.cloudflare.com/profile/api-tokens
	echo 删除授权的 Argo Tunnel API Token 即可
elif [ $mode == 5 ]
then
    if [ -f "/usr/bin/suoha" ]; then
        suoha
    else
        echo "管理服务未安装，请先安装服务（选择模式2）"
    
    fi

elif [ $mode == 4 ]
then
	if [ $(grep -i PRETTY_NAME /etc/os-release | cut -d \" -f2 | awk '{print $1}') == "Alpine" ]
	then
		kill -9 $(ps -ef | grep xray | grep -v grep | awk '{print $1}') >/dev/null 2>&1
		kill -9 $(ps -ef | grep cloudflared-linux | grep -v grep | awk '{print $1}') >/dev/null 2>&1
	else
		kill -9 $(ps -ef | grep xray | grep -v grep | awk '{print $2}') >/dev/null 2>&1
		kill -9 $(ps -ef | grep cloudflared-linux | grep -v grep | awk '{print $2}') >/dev/null 2>&1
	fi
	rm -rf xray cloudflared-linux v2ray.txt
else
	echo 退出成功
	exit
fi

    

