. /data/adb/modules/FuckAD/scripts/base.sh

# 读取配置
enable_iptables="$(read_config "enable_iptables")" || { log "Failed to read enable_iptables" "读取 enable_iptables 失败"; return 1; }
block_ipv6_dns="$(read_config "block_ipv6_dns")" || { log "Failed to read block_ipv6_dns" "读取 block_ipv6_dns 失败"; return 1; }
redir_host_4="$(read_config "redir_host_4")" || { log "Failed to read redir_host_4" "读取 redir_host_4 失败"; return 1; }
redir_host_6="$(read_config "redir_host_6")" || { log "Failed to read redir_host_6" "读取 redir_host_6 失败"; return 1; }
redir_port_4="$(read_config "redir_port_4")" || { log "Failed to read redir_port_4" "读取 redir_port_4 失败"; return 1; }
redir_port_6="$(read_config "redir_port_6")" || { log "Failed to read redir_port_6" "读取 redir_port_6 失败"; return 1; }
ignore_dest_list="$(read_config "ignore_dest_list")" || { log "Failed to read ignore_dest_list" "读取 ignore_dest_list 失败"; return 1; }
ignore_src_list="$(read_config "ignore_src_list")" || { log "Failed to read ignore_src_list" "读取 ignore_src_list 失败"; return 1; }

open_network() {
  # 数据流量 和 wifi 开关状态
  mobile_data_key="$1"
  wifi_on_key="$2"

  # 未开启 数据流量 和 wifi 时直接返回
  if [ $mobile_data_key -eq 0 ] && [ $wifi_on_key -eq 0 ]; then
    return 0
  fi

  if [ $mobile_data_key = 1 ]; then
    log "Turning on mobile data..." "正在开启数据流量..."
    cmd phone data enable
  fi

  if [ $wifi_on_key = 1 ]; then
    log "Turning on Wi-Fi..." "正在开启wifi..."
    cmd wifi set-wifi-enabled enabled
  fi

  timeout=10
  while [ $timeout -gt 0 ] && ( [ $(settings get global mobile_data) -ne $mobile_data_key ] || [ $(settings get global wifi_on) -ne $wifi_on_key ] ); do { ((timeout--)); sleep 1; } done
  if [ $mobile_data_key -eq 1 ] && [ $(settings get global mobile_data) -eq 1 ]; then
    log "Mobile data successfully turned on." "开启数据流量成功"
  elif [ $mobile_data_key -eq 1 ] && [ $(settings get global mobile_data) -eq 0 ]; then
    log "Failed to turn on mobile data." "开启数据流量失败"
    return 1
  fi
  if [ $wifi_on_key -eq 1 ] && [ $(settings get global wifi_on) -eq 1 ]; then
    log "Wi-Fi successfully turned on." "开启wifi成功"
  elif [ $wifi_on_key -eq 1 ] && [ $(settings get global wifi_on) -eq 0 ]; then
    log "Failed to turn on Wi-Fi." "开启wifi失败"
    return 1
  fi
}

close_network() {
  # 数据流量 和 wifi 开关状态
  mobile_data_key="$1"
  wifi_on_key="$2"

  # 未开启 数据流量 和 wifi 时直接返回
  if [ $mobile_data_key -eq 0 ] && [ $wifi_on_key -eq 0 ]; then
    return 0
  fi

  if [ $mobile_data_key -eq 1 ]; then
    log "Turning off mobile data..." "正在关闭数据流量..."
    cmd phone data disable
  fi

  if [ $wifi_on_key -eq 1 ]; then
    log "Turning off Wi-Fi..." "正在关闭wifi..."
    cmd wifi set-wifi-enabled disabled
  fi

  timeout=10
  while [ $timeout -gt 0 ] && ( [ $(settings get global mobile_data) -eq 1 ] || [ $(settings get global wifi_on) -eq 1 ] ); do { ((timeout--)); sleep 1; } done
  if [ $mobile_data_key -eq 1 ] && [ $(settings get global mobile_data) -eq 0 ]; then
    log "Mobile data successfully turned off." "关闭数据流量成功"
  elif [ $mobile_data_key -eq 1 ] && [ $(settings get global mobile_data) -eq 1 ]; then
    log "Failed to turn off mobile data." "关闭数据流量失败"
    return 1
  fi
  if [ $wifi_on_key -eq 1 ] && [ $(settings get global wifi_on) -eq 0 ]; then
    log "Wi-Fi successfully turned off." "关闭wifi成功"
  elif [ $wifi_on_key -eq 1 ] && [ $(settings get global wifi_on) -eq 1 ]; then
    log "Failed to turn off Wi-Fi." "关闭wifi失败"
    return 1
  fi
}

enable() {
  if [ "$enable_iptables" = false ]; then
    log "iptables: disabled" "iptables 已禁用"
    update_description "❌ Stopped iptables: disabled" "❌ 已停止 iptables: 已禁用"
    return 1
  fi

  if ! check_redir_host_4; then
      log "dns server ip or port not configured" "未配置dns服务器ip或端口"
      update_description "❌ Stopped, dns server ip or port not configured." "❌ 已停止 未配置dns服务器ip或端口"
      return 1
  fi

  # 获取 数据流量 和 wifi 开关状态
  mobile_data_key=$(settings get global mobile_data)
  wifi_on_key=$(settings get global wifi_on)
  # 关闭网络
  close_network $mobile_data_key $wifi_on_key

  # 开启 iprables
  $SCRIPT_DIR/iptables.sh enable || {
    log "❌ iptables: enable failed" "❌ iptables: 启动失败"
    update_description "❌ iptables: enable failed" "❌ iptables: 启动失败"
    open_network "$mobile_data_key" "wifi_on_key"
    return 1
  }
  # 开启网络
  open_network "$mobile_data_key" "$wifi_on_key"

  updata_config "runing" "true"

  log "🥰 started iptables: enabled" "🥰 启动成功 iptables: 已启用"
  update_description "🥰 Started iptables: enabled" "🥰 启动成功 iptables: 已启用"
}

disable() {
  # 获取 数据流量 和 wifi 开关状态
  mobile_data_key=$(settings get global mobile_data)
  wifi_on_key=$(settings get global wifi_on)
  # 关闭网络
  close_network "$mobile_data_key" "$wifi_on_key"

  $SCRIPT_DIR/iptables.sh disable || {
    log "❌ iptables: disable failed" "❌ iptables: 禁用失败"
    update_description "❌ iptables: disable failed" "❌ iptables: 禁用失败"
    open_network "$network_status_key"
    return 1
  }
  # 开启网络
  open_network "$mobile_data_key" "$wifi_on_key"

  updata_config "runing" "false"

  log "❌ Stopped" "❌ 已停止"
  update_description "❌ Stopped" "❌ 已停止"
}

case "$1" in
enable)
  enable || return 1
  ;;
disable)
  disable || return 1
  ;;
toggle)
  run_status=$(read_config "runing")
  if [ "$run_status" = "true" ]; then
    disable || return 1
  else
    enable || return 1
  fi
  ;;
*)
  echo "Usage: $0 {enable|disable|toggle}"
  exit 1
  ;;
esac
