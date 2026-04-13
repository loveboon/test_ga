# most of the users are Chinese, so set default language to Chinese
language="zh"

# try to get the system language
locale=$(echo $LANG)

# if the system language is English, set language to English
if echo "$locale" | grep -qi "en"; then
  language="en"
fi

function log() {
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  local str
  [ "$language" = "en" ] && str="$timestamp $1" || str="$timestamp $2"
  echo "$str" | tee -a "$AGH_DIR/history.log"
}