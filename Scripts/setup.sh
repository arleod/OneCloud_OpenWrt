#公用函数
source $GITHUB_WORKSPACE/Scripts/functions.sh

./scripts/feeds update -a
./scripts/feeds install -a

rm -rf feeds/luci/applications/luci-app-homeproxy
merge_package main https://github.com/VIKINGYFY/packages package luci-app-homeproxy

rm -rf feeds/luci/applications/luci-app-amlogic
git clone https://github.com/ophub/luci-app-amlogic package/luci-app-amlogic

rm -rf feeds/luci/applications/luci-app-ssr-plus
git clone https://github.com/stupidloud/helloworld package/helloworld

rm -rf feeds/packages/net/hysteria/*
rm -rf feeds/packages/net/xray-core/*
rm -rf feeds/packages/net/v2ray-core/*
cp -rf package/helloworld/hysteria/* feeds/packages/net/hysteria
cp -rf package/helloworld/xray-core/* feeds/packages/net/xray-core
cp -rf package/helloworld/v2ray-core/* feeds/packages/net/v2ray-core

rm -rf feeds/packages/net/v2ray-geodata
rm -rf package/helloworld/v2ray-geodata
git clone https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

rm -rf feeds/packages/net/sing-box
merge_package main https://github.com/VIKINGYFY/packages  feeds/packages/net sing-box

cd package
$GITHUB_WORKSPACE/Scripts/Packages.sh
$GITHUB_WORKSPACE/Scripts/Handles.sh

# === 修复：ath9k-htc 依赖的 ath9k-htc-firmware 包在本源码树中不存在，会导致该驱动被 defconfig 静默丢弃 ===
cd $GITHUB_WORKSPACE/openwrt
sed -i 's/+ath9k-htc-firmware//g' package/kernel/mac80211/ath.mk
echo ">>> ath9k-htc 依赖修复结果:"
grep -n "KernelPackage/ath9k-htc" -A4 package/kernel/mac80211/ath.mk | head -8
# === 兜底：erofs-utils 源码包从 kernel.org snapshot 下载会 404，改用仓库内自带包 ===
cd $GITHUB_WORKSPACE/openwrt
mkdir -p dl
cp -f $GITHUB_WORKSPACE/Scripts/dl/erofs-utils-1.8.10.tar.gz dl/erofs-utils-1.8.10.tar.gz
sha256sum dl/erofs-utils-1.8.10.tar.gz
echo ">>> dl 目录:"; ls -l dl/ | head -5
