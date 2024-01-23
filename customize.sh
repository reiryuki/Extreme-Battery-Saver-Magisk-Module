# space
ui_print " "

# var
UID=`id -u`

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
if [ "`grep_prop debug.log $OPTIONALS`" == 1 ]; then
  ui_print "- The install log will contain detailed information"
  set -x
  ui_print " "
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
  ui_print "  at least SDK API $NUM to use this module."
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
    RES=`pm uninstall $PKG 2>/dev/null`
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
  ui_print "- Different version detected"
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
APPS="`ls $MODPATH/system/priv-app` `ls $MODPATH/system/app`"
hide_oat

# permission
ui_print "- Granting permissions"
ui_print "  Please wait..."
APP=Flipendo
PKG=com.google.android.flipendo
if ! appops get $PKG > /dev/null 2>&1; then
  if [ "$BOOTMODE" == true ]; then
    FILE=`find $MODPATH/system -type f -name $APP.apk`
    RES=`pm install -g -i com.android.vending $FILE 2>/dev/null`
    if appops get $PKG > /dev/null 2>&1; then
      RES=`pm uninstall -k $PKG 2>/dev/null`
    else
      ui_print "  ! Failed."
      ui_print "    Maybe insufficient storage."
      abort
    fi
  fi
fi
FILE=`find /data ! -path "/data/media/*" -type f -name runtime-permissions.xml`
if grep -q '"com.google.android.flipendo"' $FILE; then
  COUNT=1
  if grep -q '><' $FILE; then
    TIGHT=true
  else
    TIGHT=false
  fi
  LIST=`cat $FILE | sed 's|><|>\n<|g'`
  RES=`echo "$LIST" | grep -A$COUNT '<package name="com.google.android.flipendo">'`
  until echo "$RES" | grep -q '</package>'; do
    COUNT=`expr $COUNT + 1`
    RES=`echo "$LIST" | grep -A$COUNT '<package name="com.google.android.flipendo">'`
  done
  if $TIGHT; then
    RES=`echo $RES | sed 's|> <|><|g'`
  fi
  if echo "$RES" | grep -q false; then
    if grep -q "$RES" $FILE; then
      MODRES=`echo "$RES" | sed 's|false|true|g'`
      sed -i "s|$RES|$MODRES|g" $FILE
      ui_print "  If you are disabling this module,"
      ui_print "  then you need to reinstall this module"
      ui_print "  to re-grant permissions."
    else
      ui_print "  ! There is a format error."
      abort
    fi
  fi
else
  ui_print "  ! Target not found."
  abort
fi
ui_print " "

# overlay
if [ ! -d /product/overlay ]; then
  ui_print "- Using /vendor/overlay/ instead of /product/overlay/"
  mv -f $MODPATH/system/product $MODPATH/system/vendor
  ui_print " "
fi










