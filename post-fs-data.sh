mount -o rw,remount /data
MODPATH=${0%/*}
API=`getprop ro.build.version.sdk`

# debug
exec 2>$MODPATH/debug-pfsd.log
set -x

# run
FILE=$MODPATH/sepolicy.sh
if [ -f $FILE ]; then
  sh $FILE
fi

# context
if [ "$API" -ge 26 ]; then
  chcon -R u:object_r:vendor_overlay_file:s0 $MODPATH/system/product/overlay
fi

# cleaning
FILE=$MODPATH/cleaner.sh
if [ -f $FILE ]; then
  sh $FILE
  rm -f $FILE
fi


