. /data/adb/modules/FuckAD/scripts/base.sh

until [ $(getprop init.svc.bootanim) = "stopped" ]; do
  sleep 12
done

$SCRIPT_DIR/tool.sh enable

inotifyd $SCRIPT_DIR/inotify.sh $MOD_PATH:d,n &
