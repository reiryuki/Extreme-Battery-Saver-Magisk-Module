# space
ui_print " "

# var
UID=`id -u`
[ ! "$UID" ] && UID=0

# log
if [ "$BOOTMODE" != true ]; then
  FILE=/data/media/"$UID"/$MODID\_recovery.log
  ui_print "- Log will be saved at $FILE"
  exec 2>$FILE
  ui_print " "
fi

# optionals
OPTIONALS=/data/media/"$UID"/optionals.prop
if [ ! -f $OPTIONALS ]; then
  touch $OPTIONALS
fi

# debug
#if [ "`grep_prop debug.log $OPTIONALS`" == 1 ]; then
  ui_print "- The install log will contain detailed information"
  set -x
  ui_print " "
#fi

# recovery
if [ "$BOOTMODE" != true ]; then
  MODPATH_UPDATE=`echo $MODPATH | sed 's|modules/|modules_update/|g'`
  rm -f $MODPATH/update
  rm -rf $MODPATH_UPDATE
fi

# run
. $MODPATH/function.sh

# info
MODVER=`grep_prop version $MODPATH/module.prop`
MODVERCODE=`grep_prop versionCode $MODPATH/module.prop`
ui_print " ID=$MODID"
ui_print " Version=$MODVER"
ui_print " VersionCode=$MODVERCODE"
if [ "$KSU" == true ]; then
  ui_print " KSUVersion=$KSU_VER"
  ui_print " KSUVersionCode=$KSU_VER_CODE"
  ui_print " KSUKernelVersionCode=$KSU_KERNEL_VER_CODE"
  sed -i 's|#k||g' $MODPATH/post-fs-data.sh
else
  ui_print " MagiskVersion=$MAGISK_VER"
  ui_print " MagiskVersionCode=$MAGISK_VER_CODE"
fi
ui_print " "

# sdk
NUM=30
if [ "$API" -lt $NUM ]; then
  ui_print "! Unsupported SDK $API."
  ui_print "  You have to upgrade your Android version"
  ui_print "  at least SDK $NUM to use this module."
  abort
else
  ui_print "- SDK $API"
  ui_print " "
fi

# recovery
mount_partitions_in_recovery

# sepolicy
FILE=$MODPATH/sepolicy.rule
DES=$MODPATH/sepolicy.pfsd
if [ "`grep_prop sepolicy.sh $OPTIONALS`" == 1 ]\
&& [ -f $FILE ]; then
  mv -f $FILE $DES
fi

# cleaning
ui_print "- Cleaning..."
PKGS=`cat $MODPATH/package.txt`
if [ "$BOOTMODE" == true ]; then
  for PKG in $PKGS; do
    FILE=`find /data/app -name *$PKG*`
    if [ "$FILE" ]; then
      RES=`pm uninstall $PKG 2>/dev/null`
    fi
  done
fi
remove_sepolicy_rule
ui_print " "

# function
cleanup() {
if [ -f $DIR/uninstall.sh ]; then
  sh $DIR/uninstall.sh
fi
DIR=/data/adb/modules_update/$MODID
if [ -f $DIR/uninstall.sh ]; then
  sh $DIR/uninstall.sh
fi
}

# cleanup
DIR=/data/adb/modules/$MODID
FILE=$DIR/module.prop
PREVMODNAME=`grep_prop name $FILE`
if [ "`grep_prop data.cleanup $OPTIONALS`" == 1 ]; then
  sed -i 's|^data.cleanup=1|data.cleanup=0|g' $OPTIONALS
  ui_print "- Cleaning-up $MODID data..."
  cleanup
  ui_print " "
elif [ -d $DIR ]\
&& [ "$PREVMODNAME" != "$MODNAME" ]; then
  ui_print "- Different module name is detected"
  ui_print "  Cleaning-up $MODID data..."
  cleanup
  ui_print " "
fi

# function
permissive_2() {
sed -i 's|#2||g' $MODPATH/post-fs-data.sh
}
permissive() {
FILE=/sys/fs/selinux/enforce
SELINUX=`cat $FILE`
if [ "$SELINUX" == 1 ]; then
  if ! setenforce 0; then
    echo 0 > $FILE
  fi
  SELINUX=`cat $FILE`
  if [ "$SELINUX" == 1 ]; then
    ui_print "  Your device can't be turned to Permissive state."
    ui_print "  Using Magisk Permissive mode instead."
    permissive_2
  else
    if ! setenforce 1; then
      echo 1 > $FILE
    fi
    sed -i 's|#1||g' $MODPATH/post-fs-data.sh
  fi
else
  sed -i 's|#1||g' $MODPATH/post-fs-data.sh
fi
}

# permissive
if [ "`grep_prop permissive.mode $OPTIONALS`" == 1 ]; then
  ui_print "- Using device Permissive mode."
  rm -f $MODPATH/sepolicy.rule
  permissive
  ui_print " "
elif [ "`grep_prop permissive.mode $OPTIONALS`" == 2 ]; then
  ui_print "- Using Magisk Permissive mode."
  rm -f $MODPATH/sepolicy.rule
  permissive_2
  ui_print " "
fi

# function
hide_oat() {
for APP in $APPS; do
  REPLACE="$REPLACE
  `find $MODPATH/system -type d -name $APP | sed "s|$MODPATH||g"`/oat"
done
}

# hide
APPS="`ls $MODPATH/system/priv-app`
      `ls $MODPATH/system/app`"
hide_oat

# function
warning() {
ui_print "  If you are disabling this module,"
ui_print "  then you need to reinstall this module, reboot,"
ui_print "  & reinstall again to re-grant permissions."
}
warning_2() {
ui_print "  Granting permissions at the first installation"
ui_print "  doesn't work. You need to reinstall this module again"
ui_print "  after reboot to grant permissions."
}

# permission
ui_print "- Granting permissions"
ui_print "  Please wait..."
FILE=`find /data/system /data/misc* -type f -name runtime-permissions.xml`
chmod 0600 $FILE
if grep -q '<package name="com.google.android.flipendo" />' $FILE; then
  sed -i 's|<package name="com.google.android.flipendo" />|\
<package name="com.google.android.flipendo">\
<permission name="android.permission.ACCESS_SURFACE_FLINGER" granted="true" flags="0" />\
<permission name="android.permission.ROTATE_SURFACE_FLINGER" granted="true" flags="0" />\
<permission name="android.permission.INTERNAL_SYSTEM_WINDOW" granted="true" flags="0" />\
<permission name="com.google.android.settings.intelligence.BATTERY_DATA" granted="true" flags="0" />\
<permission name="android.permission.REAL_GET_TASKS" granted="true" flags="0" />\
<permission name="android.permission.WRITE_SETTINGS" granted="true" flags="0" />\
<permission name="android.permission.CONTROL_DISPLAY_COLOR_TRANSFORMS" granted="true" flags="0" />\
<permission name="android.permission.POST_NOTIFICATIONS" granted="true" flags="0" />\
<permission name="android.permission.SYSTEM_ALERT_WINDOW" granted="true" flags="0" />\
<permission name="android.permission.FOREGROUND_SERVICE" granted="true" flags="0" />\
<permission name="android.permission.LAUNCH_MULTI_PANE_SETTINGS_DEEP_LINK" granted="true" flags="0" />\
<permission name="android.permission.RECEIVE_BOOT_COMPLETED" granted="true" flags="0" />\
<permission name="android.permission.DEVICE_POWER" granted="true" flags="0" />\
<permission name="com.google.android.flipendo.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION" granted="true" flags="0" />\
<permission name="android.permission.INTERACT_ACROSS_USERS_FULL" granted="true" flags="0" />\
<permission name="android.permission.PACKAGE_USAGE_STATS" granted="true" flags="0" />\
<permission name="android.permission.TETHER_PRIVILEGED" granted="true" flags="0" />\
<permission name="android.permission.WRITE_SECURE_SETTINGS" granted="true" flags="0" />\
<permission name="android.permission.SUBSTITUTE_NOTIFICATION_APP_NAME" granted="true" flags="0" />\
<permission name="android.permission.MANAGE_USERS" granted="true" flags="0" />\
<permission name="android.permission.INTERACT_ACROSS_USERS" granted="true" flags="0" />\
<permission name="android.permission.BROADCAST_CLOSE_SYSTEM_DIALOGS" granted="true" flags="0" />\
<permission name="android.permission.KILL_BACKGROUND_PROCESSES" granted="true" flags="0" />\
<permission name="android.permission.SCHEDULE_EXACT_ALARM" granted="true" flags="0" />\
<permission name="android.permission.SUSPEND_APPS" granted="true" flags="0" />\
<permission name="android.permission.MODIFY_QUIET_MODE" granted="true" flags="0" />\
<permission name="android.permission.QUERY_USERS" granted="true" flags="0" />\
<permission name="android.permission.SET_WALLPAPER_DIM_AMOUNT" granted="true" flags="0" />\
<permission name="android.permission.START_FOREGROUND_SERVICES_FROM_BACKGROUND" granted="true" flags="0" />\
<permission name="android.permission.INTERACT_ACROSS_PROFILES" granted="true" flags="0" />\
<permission name="android.permission.CREATE_USERS" granted="true" flags="0" />\
<permission name="android.permission.QUERY_ALL_PACKAGES" granted="true" flags="0" />\
<permission name="android.permission.READ_DEVICE_CONFIG" granted="true" flags="0" />\
</package>\n|g' $FILE
  warning
elif grep -q '<package name="com.google.android.flipendo"/>' $FILE; then
  sed -i 's|<package name="com.google.android.flipendo"/>|\
<package name="com.google.android.flipendo">\
<permission name="android.permission.ACCESS_SURFACE_FLINGER" granted="true" flags="0" />\
<permission name="android.permission.ROTATE_SURFACE_FLINGER" granted="true" flags="0" />\
<permission name="android.permission.INTERNAL_SYSTEM_WINDOW" granted="true" flags="0" />\
<permission name="com.google.android.settings.intelligence.BATTERY_DATA" granted="true" flags="0" />\
<permission name="android.permission.REAL_GET_TASKS" granted="true" flags="0" />\
<permission name="android.permission.WRITE_SETTINGS" granted="true" flags="0" />\
<permission name="android.permission.CONTROL_DISPLAY_COLOR_TRANSFORMS" granted="true" flags="0" />\
<permission name="android.permission.POST_NOTIFICATIONS" granted="true" flags="0" />\
<permission name="android.permission.SYSTEM_ALERT_WINDOW" granted="true" flags="0" />\
<permission name="android.permission.FOREGROUND_SERVICE" granted="true" flags="0" />\
<permission name="android.permission.LAUNCH_MULTI_PANE_SETTINGS_DEEP_LINK" granted="true" flags="0" />\
<permission name="android.permission.RECEIVE_BOOT_COMPLETED" granted="true" flags="0" />\
<permission name="android.permission.DEVICE_POWER" granted="true" flags="0" />\
<permission name="com.google.android.flipendo.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION" granted="true" flags="0" />\
<permission name="android.permission.INTERACT_ACROSS_USERS_FULL" granted="true" flags="0" />\
<permission name="android.permission.PACKAGE_USAGE_STATS" granted="true" flags="0" />\
<permission name="android.permission.TETHER_PRIVILEGED" granted="true" flags="0" />\
<permission name="android.permission.WRITE_SECURE_SETTINGS" granted="true" flags="0" />\
<permission name="android.permission.SUBSTITUTE_NOTIFICATION_APP_NAME" granted="true" flags="0" />\
<permission name="android.permission.MANAGE_USERS" granted="true" flags="0" />\
<permission name="android.permission.INTERACT_ACROSS_USERS" granted="true" flags="0" />\
<permission name="android.permission.BROADCAST_CLOSE_SYSTEM_DIALOGS" granted="true" flags="0" />\
<permission name="android.permission.KILL_BACKGROUND_PROCESSES" granted="true" flags="0" />\
<permission name="android.permission.SCHEDULE_EXACT_ALARM" granted="true" flags="0" />\
<permission name="android.permission.SUSPEND_APPS" granted="true" flags="0" />\
<permission name="android.permission.MODIFY_QUIET_MODE" granted="true" flags="0" />\
<permission name="android.permission.QUERY_USERS" granted="true" flags="0" />\
<permission name="android.permission.SET_WALLPAPER_DIM_AMOUNT" granted="true" flags="0" />\
<permission name="android.permission.START_FOREGROUND_SERVICES_FROM_BACKGROUND" granted="true" flags="0" />\
<permission name="android.permission.INTERACT_ACROSS_PROFILES" granted="true" flags="0" />\
<permission name="android.permission.CREATE_USERS" granted="true" flags="0" />\
<permission name="android.permission.QUERY_ALL_PACKAGES" granted="true" flags="0" />\
<permission name="android.permission.READ_DEVICE_CONFIG" granted="true" flags="0" />\
</package>\n|g' $FILE
  warning
elif grep -q '<package name="com.google.android.flipendo">' $FILE; then
  COUNT=1
  LIST=`cat $FILE | sed 's|><|>\n<|g'`
  RES=`echo "$LIST" | grep -A$COUNT '<package name="com.google.android.flipendo">'`
  until echo "$RES" | grep -q '</package>'; do
    COUNT=`expr $COUNT + 1`
    RES=`echo "$LIST" | grep -A$COUNT '<package name="com.google.android.flipendo">'`
  done
  if ! echo "$RES" | grep -q 'name="android.permission.LAUNCH_MULTI_PANE_SETTINGS_DEEP_LINK" granted="true"'\
  || ! echo "$RES" | grep -q 'name="android.permission.DEVICE_POWER" granted="true"'\
  || ! echo "$RES" | grep -q 'name="android.permission.INTERACT_ACROSS_USERS_FULL" granted="true"'\
  || ! echo "$RES" | grep -q 'name="android.permission.SUSPEND_APPS" granted="true"'\
  || ! echo "$RES" | grep -q 'name="android.permission.READ_DEVICE_CONFIG" granted="true"'; then
    PATCH=true
  elif [ "$API" -le 33 ]\
  && ! echo "$RES" | grep -q 'name="android.permission.QUERY_USERS" granted="true"'; then
    PATCH=true
  else
    PATCH=false
  fi
  if [ "$PATCH" == true ]; then
    sed -i 's|<package name="com.google.android.flipendo">|\
<package name="com.google.android.flipendo">\
<permission name="android.permission.ACCESS_SURFACE_FLINGER" granted="true" flags="0" />\
<permission name="android.permission.ROTATE_SURFACE_FLINGER" granted="true" flags="0" />\
<permission name="android.permission.INTERNAL_SYSTEM_WINDOW" granted="true" flags="0" />\
<permission name="com.google.android.settings.intelligence.BATTERY_DATA" granted="true" flags="0" />\
<permission name="android.permission.REAL_GET_TASKS" granted="true" flags="0" />\
<permission name="android.permission.WRITE_SETTINGS" granted="true" flags="0" />\
<permission name="android.permission.CONTROL_DISPLAY_COLOR_TRANSFORMS" granted="true" flags="0" />\
<permission name="android.permission.POST_NOTIFICATIONS" granted="true" flags="0" />\
<permission name="android.permission.SYSTEM_ALERT_WINDOW" granted="true" flags="0" />\
<permission name="android.permission.FOREGROUND_SERVICE" granted="true" flags="0" />\
<permission name="android.permission.LAUNCH_MULTI_PANE_SETTINGS_DEEP_LINK" granted="true" flags="0" />\
<permission name="android.permission.RECEIVE_BOOT_COMPLETED" granted="true" flags="0" />\
<permission name="android.permission.DEVICE_POWER" granted="true" flags="0" />\
<permission name="com.google.android.flipendo.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION" granted="true" flags="0" />\
<permission name="android.permission.INTERACT_ACROSS_USERS_FULL" granted="true" flags="0" />\
<permission name="android.permission.PACKAGE_USAGE_STATS" granted="true" flags="0" />\
<permission name="android.permission.TETHER_PRIVILEGED" granted="true" flags="0" />\
<permission name="android.permission.WRITE_SECURE_SETTINGS" granted="true" flags="0" />\
<permission name="android.permission.SUBSTITUTE_NOTIFICATION_APP_NAME" granted="true" flags="0" />\
<permission name="android.permission.MANAGE_USERS" granted="true" flags="0" />\
<permission name="android.permission.INTERACT_ACROSS_USERS" granted="true" flags="0" />\
<permission name="android.permission.BROADCAST_CLOSE_SYSTEM_DIALOGS" granted="true" flags="0" />\
<permission name="android.permission.KILL_BACKGROUND_PROCESSES" granted="true" flags="0" />\
<permission name="android.permission.SCHEDULE_EXACT_ALARM" granted="true" flags="0" />\
<permission name="android.permission.SUSPEND_APPS" granted="true" flags="0" />\
<permission name="android.permission.MODIFY_QUIET_MODE" granted="true" flags="0" />\
<permission name="android.permission.QUERY_USERS" granted="true" flags="0" />\
<permission name="android.permission.SET_WALLPAPER_DIM_AMOUNT" granted="true" flags="0" />\
<permission name="android.permission.START_FOREGROUND_SERVICES_FROM_BACKGROUND" granted="true" flags="0" />\
<permission name="android.permission.INTERACT_ACROSS_PROFILES" granted="true" flags="0" />\
<permission name="android.permission.CREATE_USERS" granted="true" flags="0" />\
<permission name="android.permission.QUERY_ALL_PACKAGES" granted="true" flags="0" />\
<permission name="android.permission.READ_DEVICE_CONFIG" granted="true" flags="0" />\
</package>\n<package name="removed">|g' $FILE
    warning
  fi
else
  warning_2
fi
ui_print " "

# overlay
if [ ! -d /product/overlay ]; then
  ui_print "- Using /vendor/overlay/ instead of /product/overlay/"
  mv -f $MODPATH/system/product $MODPATH/system/vendor
  ui_print " "
fi










