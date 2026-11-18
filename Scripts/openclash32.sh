#设置armv7 32位的openclash

#删除以前设置的所有openclash
rm -rf ./package/OpenClash
rm -rf ./package/luci-app-openclash
rm -rf feeds/kenzo/luci-app-openclash
rm -rf feeds/luci/applications/luci-app-openclash

#如果 core 文件夹不存在，创建文件夹
if [ ! -d "./files/etc/openclash/core" ]; then
  mkdir -p files/etc/openclash/core
fi

#Open Clash
git clone --depth=1 --single-branch --branch "dev" https://github.com/vernesong/OpenClash.git package/OpenClash

CORE_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-armv7.tar.gz"
GEOIP_URL="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
GEOSITE_URL="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"
GEO_MMDB_URL="https://github.com/alecthw/mmdb_china_ip_list/raw/release/lite/Country.mmdb"

echo ">>> 下载 clash_meta 内核 (armv7 meta, 带重试与空文件校验)"
ok=0
for i in 1 2 3; do
  echo "    第 $i 次尝试"
  if wget -O /tmp/clash-armv7.tar.gz --timeout=60 --tries=3 "${CORE_URL}" \
     && tar xOvzf /tmp/clash-armv7.tar.gz > files/etc/openclash/core/clash_meta \
     && [ -s files/etc/openclash/core/clash_meta ]; then
    ok=1; break
  fi
  echo "    失败, 5 秒后重试"; sleep 5
done
if [ "$ok" != "1" ]; then
  echo "ERROR: clash_meta 内核获取失败(空文件或下载失败), 中止构建"
  exit 1
fi
chmod +x files/etc/openclash/core/clash_meta
echo ">>> clash_meta 就绪:"
ls -l files/etc/openclash/core/clash_meta

echo ">>> 下载地理数据（失败不中断，刷好后可在界面里再下载）"
wget -O files/etc/openclash/GeoIP.dat    --timeout=60 --tries=2 "${GEOIP_URL}"    || { echo "  GeoIP 失败, 跳过";        rm -f files/etc/openclash/GeoIP.dat; }
wget -O files/etc/openclash/GeoSite.dat  --timeout=60 --tries=2 "${GEOSITE_URL}"  || { echo "  GeoSite 失败, 跳过";      rm -f files/etc/openclash/GeoSite.dat; }
wget -O files/etc/openclash/Country.mmdb --timeout=60 --tries=2 "${GEOS_MMDB_URL:-$GEO_MMDB_URL}" || { echo "  Country.mmdb 失败, 跳过"; rm -f files/etc/openclash/Country.mmdb; }

ls -lh files/etc/openclash/core files/etc/openclash
