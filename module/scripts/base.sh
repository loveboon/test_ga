. /data/adb/modules/FuckAD/config/module.conf

# most of the users are Chinese, so set default language to Chinese
language="zh"

# try to get the system language
locale=$(getprop persist.sys.locale || getprop ro.product.locale || getprop persist.sys.language)

# if the system language is English, set language to English
if echo "$locale" | grep -qi "en"; then
  language="en"
fi

function log() {
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  local str
  [ "$language" = "en" ] && str="$timestamp $1" || str="$timestamp $2"
  echo "$str" | tee -a "$MOD_PATH/history.log"
}

function read_config() {
  [ -f "$IPTABLES_FILE" ] && grep "^$1=" "$IPTABLES_FILE" | cut -f2 -d "=" || return 1
  return 0
}

function updata_config() {
  grep -q "^$1=" "$IPTABLES_FILE" && sed -i "/^$1=/c\\$1=$2" "$IPTABLES_FILE" || return 1
  return 0
}

function update_description() {
  local description
  [ "$language" = "en" ] && description="$1" || description="$2"
  sed -i "/^description=/c\description=$description" "$MOD_PATH/module.prop"
}

function check_redir_host_4() {
  [ -n "$(read_config "redir_host_4")" ] || return 1
  [ -n "$(read_config "redir_port_4")" ] || return 1
  return 0
}

function check_redir_host_6() {
  [ -n "$(read_config "redir_host_6")" ] || return 1
  [ -n "$(read_config "redir_port_6")" ] || return 1
  return 0
}