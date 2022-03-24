PKG=com.google.android.flipendo*
for PKGS in $PKG; do
  rm -rf /data/user/*/$PKGS/cache/*
done


