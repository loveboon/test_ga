SKIPUNZIP=1

# most of the users are Chinese, so set default language to Chinese
language="zh"

# try to get the system language
locale=$(getprop persist.sys.locale || getprop ro.product.locale || getprop persist.sys.language)

# if the system language is English, set language to English
if echo "$locale" | grep -qi "en"; then
  language="en"
fi

function info() {
  [ "$language" = "en" ] && ui_print "$1" || ui_print "$2"
}

function error() {
  [ "$language" = "en" ] && abort "$1" || abort "$2"
}

info "- 🚀 Installing FuckAD" "- 🚀 开始安装 FuckAD"

MOD_DIR="/data/adb/modules/FuckAD"
IPTABLES_DIR="/data/adb/FuckAD_conf"
IPTABLES_FILE="$IPTABLES_DIR/iptables.conf"

info "- 📦 Extracting module basic files..." "- 📦 解压模块基本文件..."
unzip -o "$ZIPFILE" "action.sh" -d "$MODPATH" >/dev/null 2>&1 
unzip -o "$ZIPFILE" "module.prop" -d "$MODPATH" >/dev/null 2>&1
unzip -o "$ZIPFILE" "service.sh" -d "$MODPATH" >/dev/null 2>&1
unzip -o "$ZIPFILE" "uninstall.sh" -d "$MODPATH" >/dev/null 2>&1

extract_keep_config() {
  info "- 🌈 Keeping old configuration files..." "- 🌈 保留原来的配置文件..."
  info "- 📜 Extracting script files..." "- 📜 正在解压脚本文件..."
  unzip -o "$ZIPFILE" "scripts/*" -d $MODPATH >/dev/null 2>&1 || {
    error "- ❌ Failed to extract scripts!" "- ❌ 解压脚本文件失败！"
  }
  unzip -o "$ZIPFILE" "config/module.conf" -d $MODPATH >/dev/null 2>&1 || {
    error "- ❌ Failed to extract module configuration file!" "- ❌ 解压 module 配置文件失败！"
  }
  info "- 🚫 Skipping iptables configuration file extraction..." "- 🚫 跳过解压 iptables 配置文件..."
}

extract_no_config() {
  info "- 💾 Backing up old configuration files with .bak extension..." "- 💾 使用 .bak 扩展名备份旧配置文件..."
  [ -f "$IPTABLES_FILE" ] && mv "$IPTABLES_FILE" "$IPTABLES_FILE.bak"
  extract_all
}

extract_all() {
  info "- 🌟 Extracting script files..." "- 🌟 正在解压脚本文件..."
  unzip -o "$ZIPFILE" "scripts/*" -d $MODPATH >/dev/null 2>&1 || {
    error "- ❌ Failed to extract scripts" "- ❌ 解压脚本文件失败"
  }
  info "- 📜 Extracting configuration files..." "- 📜 正在解压配置文件..."
  unzip -o "$ZIPFILE" "config/module.conf" -d $MODPATH >/dev/null 2>&1 || {
    error "- ❌ Failed to extract module configuration file!" "- ❌ 解压 module 配置文件失败！"
  }
  mkdir -p "$IPTABLES_DIR"
  unzip -jo "$ZIPFILE" "config/iptables.conf" -d $IPTABLES_DIR >/dev/null 2>&1 || {
    error "- ❌ Failed to extract iptables configuration file!" "- ❌ 解压 iptables 配置文件失败！"
  }
}

if [ -f "$IPTABLES_FILE" ]; then
  info "- 🔄 Do you want to keep the old configuration? (If not, it will be automatically backed up)" "- 🔄 是否保留原来的配置文件？（若不保留则自动备份）"
  info "- 🔊 (Volume Up = Yes, Volume Down = No, 30s no input = Yes)" "- 🔊 （音量上键 = 是, 音量下键 = 否，30秒无操作 = 是）"
  START_TIME=$(date +%s)
  while true; do
    NOW_TIME=$(date +%s)
    timeout 1 getevent -lc 1 2>&1 | grep KEY_VOLUME >"$TMPDIR/events"
    if [ $((NOW_TIME - START_TIME)) -gt 29 ]; then
      info "- ⏰ No input detected after 30 seconds, defaulting to keep old configuration." "- ⏰ 30秒无输入，默认保留原配置。"
      extract_keep_config
      break
    elif $(cat $TMPDIR/events | grep -q KEY_VOLUMEUP); then
      extract_keep_config
      break
    elif $(cat $TMPDIR/events | grep -q KEY_VOLUMEDOWN); then
      extract_no_config
      break
    fi
  done
else
  info "- 📦 First time installation, extracting files..." "- 📦 第一次安装，正在解压文件..."
  extract_all
fi

info "- 🔐 Setting permissions..." "- 🔐 设置权限..."

chmod +x "$MODPATH"/*.sh
chmod +x "$MODPATH"/scripts/*.sh

info "- 🎉 Installation completed, please reboot." "- 🎉 安装完成，请重启设备。"
