mount -o rw,remount /data
MODPATH=${0%/*}

# log
exec 2>$MODPATH/debug-pfsd.log
set -x

# var
ABI=`getprop ro.product.cpu.abi`
API=`getprop ro.build.version.sdk`

# function
permissive() {
if [ "`toybox cat $FILE`" = 1 ]; then
  chmod 640 $FILE
  chmod 440 $FILE2
  echo 0 > $FILE
fi
}
magisk_permissive() {
if [ "`toybox cat $FILE`" = 1 ]; then
  if [ -x "`command -v magiskpolicy`" ]; then
	magiskpolicy --live "permissive *"
  else
	$MODPATH/$ABI/libmagiskpolicy.so --live "permissive *"
  fi
fi
}
sepolicy_sh() {
if [ -f $FILE ]; then
  if [ -x "`command -v magiskpolicy`" ]; then
    magiskpolicy --live --apply $FILE 2>/dev/null
  else
    $MODPATH/$ABI/libmagiskpolicy.so --live --apply $FILE 2>/dev/null
  fi
fi
}

# selinux
FILE=/sys/fs/selinux/enforce
FILE2=/sys/fs/selinux/policy
#1permissive
chmod 0755 $MODPATH/*/libmagiskpolicy.so
#2magisk_permissive
FILE=$MODPATH/sepolicy.rule
#ksepolicy_sh
FILE=$MODPATH/sepolicy.pfsd
sepolicy_sh

# patch plat_seapp_contexts
DIR=/system/etc/selinux
FILE=$DIR/plat_seapp_contexts
rm -f $MODPATH$FILE
if [ "$API" -ge 35 ]; then
  mkdir -p $MODPATH$DIR
  if ! grep 'user=system seinfo=default domain=system_app type=system_app_data_file' $FILE; then
    cp -af $FILE $MODPATH$FILE
    sed -i '1i\
user=system seinfo=default domain=system_app type=system_app_data_file' $MODPATH$FILE
  fi
fi

# permission
DIRS=`find $MODPATH/vendor\
           $MODPATH/system/vendor -type d`
for DIR in $DIRS; do
  chown 0.2000 $DIR
done
if [ -L $MODPATH/system/vendor ]\
&& [ -d $MODPATH/vendor ]; then
  chcon -R u:object_r:vendor_file:s0 $MODPATH/vendor
  chcon -R u:object_r:vendor_overlay_file:s0 $MODPATH/vendor/overlay
else
  chcon -R u:object_r:vendor_file:s0 $MODPATH/system/vendor
  chcon -R u:object_r:vendor_overlay_file:s0 $MODPATH/system/vendor/overlay
fi

# cleaning
FILE=$MODPATH/cleaner.sh
if [ -f $FILE ]; then
  . $FILE
  mv -f $FILE $FILE.txt
fi









