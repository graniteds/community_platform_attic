#!/bin/bash

#set -x

####################################################################################################
# Configuration

# Platform version / name
JBOSS_DIST=$1
JBOSS_ROOT_DIR=$2
JBOSS_ARCHIVE="$JBOSS_DIST/$3"

GDS_RELEASE=$4
GDS_ROOT_DIR="${GDS_RELEASE}"
# JBoss native version
JBOSS_NATIVE_VERSION="2.0.10"


# Temporary directories
BASE_DIR=`pwd`
BUILD_DIR="build"
COMMON_DIR="common"
SAMPLES_DIR="samples"
/bin/rm -rf "${BUILD_DIR}" "${COMMON_DIR}/graniteds"
/bin/mkdir "${BUILD_DIR}"

####################################################################################################
# Extract JBoss

echo "Building community platform ${GDS_ROOT_DIR} from ${JBOSS_ARCHIVE}..."

# Extract JBoss distribution, excluing unused configurations/features
echo "Unziping ${JBOSS_ARCHIVE} to ${BUILD_DIR}..."
UNZIP_JBOSS_EXCLUDE="\
$JBOSS_ROOT_DIR/server/all/* \
$JBOSS_ROOT_DIR/server/minimal/* \
$JBOSS_ROOT_DIR/server/standard/* \
$JBOSS_ROOT_DIR/server/web/* \
$JBOSS_ROOT_DIR/server/default/deployers/webbeans.deployer/* \
$JBOSS_ROOT_DIR/server/default/deploy/management/*"
unzip -q "${JBOSS_ARCHIVE}" -d "${BUILD_DIR}" -x ${UNZIP_JBOSS_EXCLUDE}


# Rename jboss root directory.
/bin/mv "${BUILD_DIR}/${JBOSS_ROOT_DIR}" "${BUILD_DIR}/${GDS_ROOT_DIR}"

####################################################################################################
# Extract distribution artifacts
echo "Unzipping GraniteDS distribution to ${COMMON_DIR}..."
unzip -q "dist/${GDS_RELEASE}.zip" -d "${COMMON_DIR}"


####################################################################################################
# Overwrite / add JBoss files 

# Copy samples from previous job
echo "Copying ${SAMPLES_DIR}..."
/bin/cp -rf "${SAMPLES_DIR}" "${BUILD_DIR}/${GDS_ROOT_DIR}/server/default/."

# Update/add platform files
echo "Copying common platform files..."
/bin/cp -rf "${COMMON_DIR}/*" "${BUILD_DIR}/${GDS_ROOT_DIR}"
####################################################################################################
# Zip/tar common platform files (without APR libraries)

COMMON_TAR="${GDS_ROOT_DIR}.tar"
COMMON_ZIP="${GDS_ROOT_DIR}.zip"

echo ""
echo "Creating common platform archive: ${BUILD_DIR}/${COMMON_TAR}..."
tar --directory="${BUILD_DIR}" -cf "${BUILD_DIR}/${COMMON_TAR}" "${GDS_ROOT_DIR}"

echo "Creating common platform archive: ${BUILD_DIR}/${COMMON_ZIP}..."
cd "${BUILD_DIR}"
zip -n ".zip" -qr "${COMMON_ZIP}" "${GDS_ROOT_DIR}"
cd ..


####################################################################################################
# Add APR libraries to archives.

TMP="${BUILD_DIR}/tmp"
function distrib_tar() {
	echo ""
	/bin/rm -rf "${TMP}"
	/bin/mkdir "${TMP}"

	DISTRIB_TAR="${BUILD_DIR}/${GDS_ROOT_DIR}-${1}.tar"
	echo "Copying ${BUILD_DIR}/${COMMON_TAR} to ${DISTRIB_TAR}..."
	/bin/cp "${BUILD_DIR}/${COMMON_TAR}" "${DISTRIB_TAR}" 

	NATIVE_TAR_GZ="${JBOSS_DIST}/jboss-native-${JBOSS_NATIVE_VERSION}-${1}.tar.gz"
	echo "Unarchiving ${NATIVE_TAR_GZ} into ${TMP}/${GDS_ROOT_DIR}..."
	/bin/mkdir "${TMP}/${GDS_ROOT_DIR}"
	tar --directory "${TMP}/${GDS_ROOT_DIR}" -zxf "${NATIVE_TAR_GZ}"
	cd "${BASE_DIR}"
	echo "Updating ${DISTRIB_TAR} with ${TMP}/${GDS_ROOT_DIR}..."
	cd "${TMP}"
	tar rf "${BASE_DIR}/${DISTRIB_TAR}" "${GDS_ROOT_DIR}"
	cd "${BASE_DIR}"

	echo "Gziping ${DISTRIB_TAR} to ${DISTRIB_TAR}.gz..."
	gzip "${DISTRIB_TAR}"

	/bin/rm -rf "${TMP}"
}

function distrib_zip() {
	echo ""
	/bin/rm -rf "${TMP}"
	/bin/mkdir "${TMP}"

	DISTRIB_ZIP="${BUILD_DIR}/${GDS_ROOT_DIR}-${1}.zip"
	echo "Copying ${BUILD_DIR}/${COMMON_ZIP} to ${DISTRIB_ZIP}..."
	/bin/cp "${BUILD_DIR}/${COMMON_ZIP}" "${DISTRIB_ZIP}"

	NATIVE_ZIP="${JBOSS_DIST}/jboss-native-${JBOSS_NATIVE_VERSION}-${1}.zip"
	echo "Unziping ${NATIVE_ZIP} into ${TMP}/${GDS_ROOT_DIR}..."
	/bin/mkdir "${TMP}/${GDS_ROOT_DIR}"
	unzip -q "${NATIVE_ZIP}" -d "${TMP}/${GDS_ROOT_DIR}"

	
	echo "Updating ${DISTRIB_ZIP} with ${TMP}/${GDS_ROOT_DIR}..."
	cd "${TMP}"
	zip -qr "${BASE_DIR}/${DISTRIB_ZIP}" "${GDS_ROOT_DIR}"
	cd "${BASE_DIR}"

	/bin/rm -rf "${TMP}"
}

distrib_tar "linux2-x64"
distrib_tar "linux2-x86"

distrib_tar "macosx-x86"

distrib_zip "windows-x64"
distrib_zip "windows-x86"

/bin/rm -f "${BUILD_DIR}/${COMMON_TAR}" "${BUILD_DIR}/${COMMON_ZIP}"
