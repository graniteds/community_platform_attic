#!/bin/bash

#set -x

JBOSS_ROOT_DIR=$1
JBOSS_ARCHIVE=$2

GDS_VERSION=$3
GDS_ROOT_DIR="graniteds-cp-$GDS_VERSION"

echo "Building platform $GDS_ROOT_DIR from $JBOSS_ARCHIVE..."

BASE_DIR=`pwd`
BUILD_DIR="build"
COMMON_DIR="common"
SAMPLES_DIR="samples"
/bin/rm -rf "$BUILD_DIR" "$COMMON_DIR" "$SAMPLES_DIR"
/bin/mkdir "$BUILD_DIR"

UNZIP_JBOSS_EXCLUDE="\
$JBOSS_ROOT_DIR/server/all/* \
$JBOSS_ROOT_DIR/server/minimal/* \
$JBOSS_ROOT_DIR/server/standard/* \
$JBOSS_ROOT_DIR/server/web/* \
$JBOSS_ROOT_DIR/server/default/deployers/webbeans.deployer/* \
$JBOSS_ROOT_DIR/server/default/deploy/management/*"

echo "Unziping $JBOSS_ARCHIVE to $BUILD_DIR..."
unzip -q "$JBOSS_ARCHIVE" -d "$BUILD_DIR" -x $UNZIP_JBOSS_EXCLUDE
/bin/mv "$BUILD_DIR/$JBOSS_ROOT_DIR" "$BUILD_DIR/$GDS_ROOT_DIR"

SAMPLES_PROJECTS_DIR="$COMMON_DIR/graniteds/$SAMPLES_DIR"
SAMPLES_PROJECTS_ZIP="$BASE_DIR/$SAMPLES_PROJECTS_DIR/sample-projects.zip"
echo "Creating sample projects $SAMPLES_PROJECTS_ZIP..."
/bin/mkdir -p "$SAMPLES_PROJECTS_DIR"
cd "$SAMPLES_DIR"
zip -qr "$SAMPLES_PROJECTS_ZIP" *
cd "$BASE_DIR"

echo "Copying common platform files..."
/bin/cp -rf common/* "$BUILD_DIR/$GDS_ROOT_DIR"

echo "Copying samples..."
PLATFORM_HOME="$BASE_DIR/$BUILD_DIR/$GDS_ROOT_DIR"
/bin/cp -rf samples/* "$PLATFORM_HOME/server/default/samples"

COMMON_TAR="$GDS_ROOT_DIR.tar"
COMMON_ZIP="$GDS_ROOT_DIR.zip"

echo "Creating common platform archive: $BUILD_DIR/$COMMON_TAR..."
tar --directory="$BUILD_DIR" -cf "$BUILD_DIR/$COMMON_TAR" "$GDS_ROOT_DIR"

echo "Creating common platform archive: $BUILD_DIR/$COMMON_ZIP..."
cd "$BUILD_DIR"
zip -n ".zip" -qr "$COMMON_ZIP" "$GDS_ROOT_DIR"
cd ..

JBOSS_NATIVE_VERSION="2.0.9"
TMP="$BUILD_DIR/tmp"

function distrib_tar() {
  echo ""
  /bin/rm -rf "$TMP"
  /bin/mkdir "$TMP"

  DISTRIB_TAR="$BUILD_DIR/$GDS_ROOT_DIR-$1.tar"
  echo "Copying $BUILD_DIR/$COMMON_TAR to $DISTRIB_TAR..."
  /bin/cp "$BUILD_DIR/$COMMON_TAR" "$DISTRIB_TAR" 

  NATIVE_TAR_GZ="jboss-native-$JBOSS_NATIVE_VERSION-$1.tar.gz"
  echo "Unarchiving $NATIVE_TAR_GZ into $TMP/$GDS_ROOT_DIR..."
  /bin/mkdir "$TMP/$GDS_ROOT_DIR"
  tar --directory "$TMP/$GDS_ROOT_DIR" -zxf "$NATIVE_TAR_GZ"

  echo "Updating $DISTRIB_TAR with $TMP/$GDS_ROOT_DIR..."
  cd "$TMP"
  tar rf "$BASE_DIR/$DISTRIB_TAR" "$GDS_ROOT_DIR"
  cd "$BASE_DIR"

  echo "Gziping $DISTRIB_TAR to $DISTRIB_TAR.gz..."
  gzip "$DISTRIB_TAR"

  /bin/rm -rf "$TMP"
}

function distrib_zip() {
  echo ""
  /bin/rm -rf "$TMP"
  /bin/mkdir "$TMP"

  DISTRIB_ZIP="$BUILD_DIR/$GDS_ROOT_DIR-$1.zip"
  echo "Copying $BUILD_DIR/$COMMON_ZIP to $DISTRIB_ZIP..."
  /bin/cp "$BUILD_DIR/$COMMON_ZIP" "$DISTRIB_ZIP"

  NATIVE_ZIP="jboss-native-$JBOSS_NATIVE_VERSION-$1.zip"
  echo "Unziping $NATIVE_ZIP into $TMP/$GDS_ROOT_DIR"
  /bin/mkdir "$TMP/$GDS_ROOT_DIR"
  unzip -q "$NATIVE_ZIP" -d "$TMP/$GDS_ROOT_DIR"

  echo "Updating $DISTRIB_ZIP with $TMP/$GDS_ROOT_DIR..."
  cd "$TMP"
  zip -qr "$BASE_DIR/$DISTRIB_ZIP" "$GDS_ROOT_DIR"
  cd "$BASE_DIR"

  /bin/rm -rf "$TMP"
}

distrib_tar "linux2-x64-ssl"
distrib_tar "linux2-x86-ssl"

distrib_tar "macosx-x64-ssl"
distrib_tar "macosx-x86-ssl"

distrib_zip "windows-x64-ssl"
distrib_zip "windows-x86-ssl"

/bin/rm -f "$BUILD_DIR/$COMMON_TAR" "$BUILD_DIR/$COMMON_ZIP"
