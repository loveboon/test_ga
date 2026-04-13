. /data/adb/modules/FuckAD/scripts/base.sh

readonly EVENTS=$1
readonly MONITOR_DIR=$2
readonly MONITOR_FILE=$3

run_status=$(read_config "runing")

if [ "${MONITOR_FILE}" = "disable" ]; then
  if [ "${EVENTS}" = "d" ] && [ "$run_status" = "false" ]; then
    $SCRIPT_DIR/tool.sh enable
  elif [ "${EVENTS}" = "n" ]; then
    $SCRIPT_DIR/tool.sh disable
  fi
fi
