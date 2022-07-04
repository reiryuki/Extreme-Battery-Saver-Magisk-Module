ui_print " "

# magisk
if [ -d /sbin/.magisk ]; then
  MAGISKTMP=/sbin/.magisk
else
  MAGISKTMP=`find /dev -mindepth 2 -maxdepth 2 -type d -name .magisk`
fi

# optionals
OPTIONALS=/sdcard/optionals.prop

# info
MODVER=`grep_prop version $MODPATH/module.prop`
MODVERCODE=`grep_prop versionCode $MODPATH/module.prop`
ui_print " ID=$MODID"
ui_print " Version=$MODVER"
ui_print " VersionCode=$MODVERCODE"
ui_print " MagiskVersion=$MAGISK_VER"
ui_print " MagiskVersionCode=$MAGISK_VER_CODE"
ui_print " "

# sdk
NUM=30
if [ "$API" -lt $NUM ]; then
  ui_print "! Unsupported SDK $API."
  ui_print "  You have to upgrade your Android version"
  ui_print "  at least SDK API $NUM to use this module."
  abort
else
  ui_print "- SDK $API"
  ui_print " "
fi

# sepolicy.rule
if [ "$BOOTMODE" != true ]; then
  mount -o rw -t auto /dev/block/bootdevice/by-name/persist /persist
  mount -o rw -t auto /dev/block/bootdevice/by-name/metadata /metadata
fi
FILE=$MODPATH/sepolicy.sh
DES=$MODPATH/sepolicy.rule
if [ -f $FILE ] && [ "`grep_prop sepolicy.sh $OPTIONALS`" != 1 ]; then
  mv -f $FILE $DES
  sed -i 's/magiskpolicy --live "//g' $DES
  sed -i 's/"//g' $DES
fi

# cleaning
ui_print "- Cleaning..."
PKG=com.google.android.flipendo
if [ "$BOOTMODE" == true ]; then
  for PKGS in $PKG; do
    RES=`pm uninstall $PKGS`
  done
fi
rm -rf /metadata/magisk/$MODID
rm -rf /mnt/vendor/persist/magisk/$MODID
rm -rf /persist/magisk/$MODID
rm -rf /data/unencrypted/magisk/$MODID
rm -rf /cache/magisk/$MODID
ui_print " "

# function
conflict() {
for NAMES in $NAME; do
  DIR=/data/adb/modules_update/$NAMES
  if [ -f $DIR/uninstall.sh ]; then
    sh $DIR/uninstall.sh
  fi
  rm -rf $DIR
  DIR=/data/adb/modules/$NAMES
  rm -f $DIR/update
  touch $DIR/remove
  FILE=/data/adb/modules/$NAMES/uninstall.sh
  if [ -f $FILE ]; then
    sh $FILE
    rm -f $FILE
  fi
  rm -rf /metadata/magisk/$NAMES
  rm -rf /mnt/vendor/persist/magisk/$NAMES
  rm -rf /persist/magisk/$NAMES
  rm -rf /data/unencrypted/magisk/$NAMES
  rm -rf /cache/magisk/$NAMES
done
}

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
if [ "`grep_prop data.cleanup $OPTIONALS`" == 1 ]; then
  sed -i 's/^data.cleanup=1/data.cleanup=0/' $OPTIONALS
  ui_print "- Cleaning-up $MODID data..."
  cleanup
  ui_print " "
elif [ -d $DIR ] && ! grep -Eq "$MODNAME" $FILE; then
  ui_print "- Different version detected"
  ui_print "  Cleaning-up $MODID data..."
  cleanup
  ui_print " "
fi

# function
permissive() {
  SELINUX=`getenforce`
  if [ "$SELINUX" == Enforcing ]; then
    setenforce 0
    SELINUX=`getenforce`
    if [ "$SELINUX" == Enforcing ]; then
      ui_print "  ! Your device can't be turned to Permissive state."
    fi
    setenforce 1
  fi
  sed -i '1i\
SELINUX=`getenforce`\
if [ "$SELINUX" == Enforcing ]; then\
  setenforce 0\
fi\' $MODPATH/post-fs-data.sh
}

# permissive
if [ "`grep_prop permissive.mode $OPTIONALS`" == 1 ]; then
  ui_print "- Using permissive method"
  rm -f $MODPATH/sepolicy.rule
  permissive
  ui_print " "
fi

# function
hide_oat() {
for APPS in $APP; do
  mkdir -p `find $MODPATH/system -type d -name $APPS`/oat
  touch `find $MODPATH/system -type d -name $APPS`/oat/.replace
done
}

# hide
APP="`ls $MODPATH/system/priv-app` `ls $MODPATH/system/app`"
hide_oat






