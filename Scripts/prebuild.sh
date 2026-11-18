#!/bin/bash
# 编译前统一预检 + 预构建。任何一项失败立刻 exit 1，避免白编数小时。
# 由 .github/workflows/quiker-6.18.yml 第 14 步（下载编译环境）调用。
set -uo pipefail

fail() { echo "ERROR: $*"; exit 1; }

echo "===== [1/4] 驱动包是否真的被选中 ====="
missing=0
for p in kmod-usb-net-asix-ax88179 kmod-ath9k-htc kmod-mac80211 kmod-cfg80211 \
         wpad-mbedtls iw iwinfo wireless-regdb usbutils; do
  if grep -q "^CONFIG_PACKAGE_${p}=y" .config; then
    echo "  OK   $p"
  else
    echo "  MISS $p"
    missing=$((missing+1))
  fi
done
[ "$missing" -eq 0 ] || fail "$missing 个驱动包未被选中（会被 defconfig 静默丢弃）"
echo "===== 驱动配置检查通过 ====="

echo "===== [2/4] OpenClash 内核与地理数据 ====="
for f in files/etc/openclash/core/clash_meta \
         files/etc/openclash/GeoIP.dat \
         files/etc/openclash/GeoSite.dat \
         files/etc/openclash/Country.mmdb; do
  if [ -s "$f" ]; then
    echo "  OK   $f  $(stat -c%s "$f") 字节"
  else
    fail "OpenClash 数据缺失或为空: $f"
  fi
done
[ "$(stat -c%s files/etc/openclash/core/clash_meta)" -gt 5000000 ] \
  || fail "clash_meta 过小（大于 5MB 才算真内核），当前 $(stat -c%s files/etc/openclash/core/clash_meta) 字节"
echo "===== OpenClash 检查通过 ====="

echo "===== [3/4] 宿主工具 ====="
for t in dos2unix file bc cpio unzip bzip2 patch python3 git rsync curl wget make g++; do
  command -v "$t" >/dev/null 2>&1 || fail "缺少命令: $t"
  echo "  OK   $t"
done
echo "===== 宿主工具检查通过 ====="

echo "===== [4/4] 预编译 po2lmo ====="
# luci-app-openclash 的 Makefile 直接调用 po2lmo，却没有声明对 luci-base 的构建依赖。
# 并行构建时若 luci-base 还没轮到，就会 command not found -> Error 127。
# 对策：编译前先自己把它建好，并同时放进 staging_dir/hostpkg/bin 和 /usr/local/bin（后者恒在 PATH 里）。
mkdir -p staging_dir/hostpkg/bin
if [ ! -x feeds/luci/modules/luci-base/src/po2lmo ]; then
  make -C feeds/luci/modules/luci-base/src clean po2lmo || fail "po2lmo 源码编译失败"
fi
install -m0755 feeds/luci/modules/luci-base/src/po2lmo staging_dir/hostpkg/bin/po2lmo \
  || fail "po2lmo 安装到 staging_dir/hostpkg/bin 失败"
sudo install -m0755 feeds/luci/modules/luci-base/src/po2lmo /usr/local/bin/po2lmo \
  || fail "po2lmo 安装到 /usr/local/bin 失败"
ls -l staging_dir/hostpkg/bin/po2lmo /usr/local/bin/po2lmo
echo "===== po2lmo 就绪 ====="

echo "===== 全部预检通过，进入正式编译 ====="
