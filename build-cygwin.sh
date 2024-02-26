set -x
set -e

HOST_TRIPLE=x86_64-pc-linux-gnu
HOST_PREFIX=$PWD/install

TARGET_TRIPLE=x86_64-pc-cygwin
TARGET_PREFIX=/usr

SYSROOT=${HOST_PREFIX}/${TARGET_TRIPLE}/sys-root

SRCTOP=${PWD}/src
BUILDTOP=${PWD}/build

BINUTILS_VERSION=2.42
BINUTILS_CYGWIN_VERSION=${BINUTILS_VERSION}-1
GCC_VERSION=13.2.1
GCC_PACKAGE_VERSION=13-20240203
GCC_CYGWIN_VERSION=${GCC_VERSION}+20240203-0.1
CYGWIN_VERSION=3.6.0
CYGWIN_CYGWIN_VERSION=${CYGWIN_VERSION}-0.52.g585855eef863
COCOM_VERSION=0.996
COCOM_CYGWIN_VERSION=${COCOM_VERSION}-2
ZLIB_VERSION=1.3
ZLIB_CYGWIN_VERSION=${ZLIB_VERSION}-1

WIN32API_VERSION=11.0.1
WIN32API_CYGWIN_VERSION=${WIN32API_VERSION}-1

DOWNLOADS=${PWD}/downloads
MIRROR=https://mirrors.kernel.org/sourceware/cygwin/x86_64/release
export PATH=${HOST_PREFIX}/bin:${PATH}

mkdir -p ${BUILDTOP}
mkdir -p ${SRCTOP}
mkdir -p ${SYSROOT}
mkdir -p ${DOWNLOADS}

do_get () {
  pushd ${DOWNLOADS} >/dev/null
  wget -c ${MIRROR}/$1
  popd >/dev/null 
}

do_get binutils/binutils-${BINUTILS_CYGWIN_VERSION}-src.tar.zst
do_get gcc/gcc-${GCC_CYGWIN_VERSION}-src.tar.zst
do_get zlib/zlib-${ZLIB_CYGWIN_VERSION}-src.tar.zst
do_get cocom/cocom-${COCOM_CYGWIN_VERSION}-src.tar.xz
do_get cygwin/cygwin-${CYGWIN_CYGWIN_VERSION}-src.tar.xz

############################################
## Prepare $target libs and headers
############################################
do_get binutils/binutils-${BINUTILS_CYGWIN_VERSION}.tar.zst
do_get w32api-headers/w32api-headers-${WIN32API_CYGWIN_VERSION}.tar.xz
do_get w32api-runtime/w32api-runtime-${WIN32API_CYGWIN_VERSION}.tar.xz
do_get zlib/zlib-devel/zlib-devel-${ZLIB_CYGWIN_VERSION}.tar.zst
do_get cygwin/cygwin-devel/cygwin-devel-${CYGWIN_CYGWIN_VERSION}.tar.xz
do_get libiconv/libiconv-devel/libiconv-devel-1.17-1.tar.xz
do_get gettext/gettext-devel/gettext-devel-0.22.4-1.tar.xz
do_get gettext/libintl-devel/libintl-devel-0.22.4-1.tar.xz

# TODO: Those were in the original script but no longer exist.
#do_get mingw-runtime/mingw-runtime-3.18-1.tar.bz2
#do_get mingw/mingw-zlib/mingw-zlib-devel/mingw-zlib-devel-1.2.3-10.tar.bz2

cd ${SYSROOT}
tar -xf ${DOWNLOADS}/binutils-${BINUTILS_CYGWIN_VERSION}.tar.zst usr/include usr/lib
tar -xf ${DOWNLOADS}/w32api-headers-${WIN32API_CYGWIN_VERSION}.tar.xz usr/include
tar -xf ${DOWNLOADS}/w32api-runtime-${WIN32API_CYGWIN_VERSION}.tar.xz usr/include usr/lib
tar -xf ${DOWNLOADS}/cygwin-devel-${CYGWIN_CYGWIN_VERSION}.tar.xz usr/include usr/lib
tar -xf ${DOWNLOADS}/zlib-devel-${ZLIB_CYGWIN_VERSION}.tar.zst usr/include usr/lib
tar -xf ${DOWNLOADS}/libiconv-devel-1.17-1.tar.xz usr/include usr/lib
tar -xf ${DOWNLOADS}/gettext-devel-0.22.4-1.tar.xz usr/lib
tar -xf ${DOWNLOADS}/libintl-devel-0.22.4-1.tar.xz usr/include usr/lib

# TODO: Those were in the original script but no longer exist.
#tar -xf ${DOWNLOADS}/mingw-runtime-3.18-1.tar.bz2 usr/include usr/lib
#tar -xf ${DOWNLOADS}/mingw-zlib-devel-1.2.3-10.tar.bz2 usr/include usr/lib

find ./usr/lib -name '*.dll.a' -o -name '*.la' | xargs rm

# not sure if sysroot support extends to the w32api stuff, so
# make sure the libs that appear in the specs file exist in the
# main lib dir, and not just in the w32api subdir.  In any case,
# this is *absolutely* necessary during the build of the language
# runtime libraries...
(cd ${SYSROOT}/usr/lib && ln -fs w32api/libkernel32.a .)
(cd ${SYSROOT}/usr/lib && ln -fs w32api/libuser32.a .)
(cd ${SYSROOT}/usr/lib && ln -fs w32api/libadvapi32.a .)
(cd ${SYSROOT}/usr/lib && ln -fs w32api/libshell32.a .)
(cd ${SYSROOT}/usr/lib && ln -fs w32api/libgdi32.a .)
(cd ${SYSROOT}/usr/lib && ln -fs w32api/libcomdlg32.a .)
(cd ${SYSROOT}/usr/lib && ln -fs w32api/libntdll.a .)
(cd ${SYSROOT}/usr/lib && ln -fs w32api/libnetapi32.a .)
(cd ${SYSROOT}/usr/lib && ln -fs w32api/libpsapi.a .)
(cd ${SYSROOT}/usr/lib && ln -fs w32api/libuserenv.a .)
(cd ${SYSROOT}/usr/lib && ln -fs w32api/libnetapi32.a .)
(cd ${SYSROOT}/usr/lib && ln -fs w32api/libdbghelp.a .)

############################################
## unpack binutils, apply patches
############################################

cd ${SRCTOP}
tar -xf ${DOWNLOADS}/binutils-${BINUTILS_CYGWIN_VERSION}-src.tar.zst

pushd binutils-${BINUTILS_CYGWIN_VERSION}.src
tar -xf binutils-${BINUTILS_VERSION}.tar.xz
cd binutils-${BINUTILS_VERSION}
cat ../binutils-${BINUTILS_VERSION}-cygwin-config-rpath.patch | patch -p2
cat ../binutils-${BINUTILS_VERSION}-cygwin-pep-dll-double-definition.patch | patch -p2
cat ../binutils-${BINUTILS_VERSION}-cygwin-shared-libs.patch | patch -p2
popd

############################################
## unpack gcc, apply patches
############################################

cd ${SRCTOP}
rm -rf gcc-${GCC_CYGWIN_VERSION}.src
tar -xf ${DOWNLOADS}/gcc-${GCC_CYGWIN_VERSION}-src.tar.zst

pushd gcc-${GCC_CYGWIN_VERSION}.src
tar -xf gcc-${GCC_PACKAGE_VERSION}.tar.xz
cd gcc-${GCC_PACKAGE_VERSION}
cat ../0001-Cygwin-use-SysV-ABI-on-x86_64.patch | patch -p1
cat ../0002-Cygwin-add-dummy-pthread-tsaware-and-large-address-a.patch | patch -p1
cat ../0003-Cygwin-handle-dllimport-properly-in-medium-model-V2.patch | patch -p1
cat ../0004-Cygwin-MinGW-skip-test.patch | patch -p1
cat ../0005-Cygwin-define-RTS_CONTROL_ENABLE-and-DTR_CONTROL_ENA.patch | patch -p1
cat ../0007-Cygwin-__cxa-atexit.patch | patch -p1
cat ../0008-Cygwin-libgomp-soname.patch | patch -p1
cat ../0009-Cygwin-g-time.patch | patch -p1
cat ../0010-Cygwin-newlib-ftm.patch | patch -p1
cat ../0011-Cygwin-define-STD_UNIX.patch | patch -p1
cat ../v4-0001-libstdc-Implement-most-of-locale-features-for-newlib.patch | patch -p1
cat ../0101-Cygwin-enable-libgccjit-not-just-for-MingW.patch | patch -p1
cat ../0102-Cygwin-testsuite-fixes-for-libgccjit.patch | patch -p1
cat ../0201-Cygwin-ada-shared-prefix.patch | patch -p2
popd

############################################
## unpack zlib, apply patches
############################################

cd ${SRCTOP}
rm -rf zlib-${ZLIB_CYGWIN_VERSION}.src
tar -xf ${DOWNLOADS}/zlib-${ZLIB_CYGWIN_VERSION}-src.tar.zst

pushd zlib-${ZLIB_CYGWIN_VERSION}.src
tar -xf zlib-${ZLIB_VERSION}.tar.xz
cd zlib-${ZLIB_VERSION}
cat ../zlib-1.3-configure.patch | patch -p2
cat ../zlib-1.3-gzopen_w.patch | patch -p2
popd

############################################
## unpack cocom
############################################

cd ${SRCTOP}
rm -rf cocom-${COCOM_CYGWIN_VERSION}.src
tar -xf ${DOWNLOADS}/cocom-${COCOM_CYGWIN_VERSION}-src.tar.xz

pushd cocom-${COCOM_CYGWIN_VERSION}.src
tar -xf cocom-${COCOM_VERSION}.tar.gz
popd

############################################
## unpack cygwin
############################################

cd ${SRCTOP}
rm -rf cygwin-${CYGWIN_CYGWIN_VERSION}.src
tar -xf ${DOWNLOADS}/cygwin-${CYGWIN_CYGWIN_VERSION}-src.tar.xz

pushd cygwin-${CYGWIN_CYGWIN_VERSION}.src
tar -xf newlib-cygwin-${CYGWIN_VERSION}.tar.bz2
popd

############################################
## build binutils
############################################

cd ${BUILDTOP}
rm -rf binutils
mkdir -p binutils
cd binutils

${SRCTOP}/binutils-${BINUTILS_CYGWIN_VERSION}.src/binutils-${BINUTILS_VERSION}/configure \
  --prefix=${HOST_PREFIX} \
  --target=${TARGET_TRIPLE} \
  --disable-bootstrap \
  --enable-static \
  --enable-shared \
  --enable-host-shared \
  --enable-64-bit-bfd \
  --enable-install-libiberty \
  --enable-targets=x86_64-pep \
  --with-sysroot=${SYSROOT} \
  --with-build-sysroot=${SYSROOT} \
  --with-system-zlib \
  --with-gcc-major-version-only \
   lt_cv_deplibs_check_method=pass_all

make V=1 -j$(nproc)

rm -rf ${BUILDTOP}/binutils-inst
mkdir -p ${BUILDTOP}/binutils-inst
make install DESTDIR=${BUILDTOP}/binutils-inst

cd ${BUILDTOP}/binutils-inst/${HOST_PREFIX:1}
tar -cJf ${BUILDTOP}/binutils-${BINUTILS_CYGWIN_VERSION}-cygwin.tar.xz *

cd ${HOST_PREFIX}
tar -xf ${BUILDTOP}/binutils-${BINUTILS_CYGWIN_VERSION}-cygwin.tar.xz

############################################
## build gcc
############################################

cd ${BUILDTOP}
rm -rf gcc
mkdir -p gcc
cd gcc

export glibcxx_cv_realpath=yes

# --enable-languages=ada,d,jit
# --enable-libada
${SRCTOP}/gcc-${GCC_CYGWIN_VERSION}.src/gcc-${GCC_PACKAGE_VERSION}/configure \
  --prefix=${HOST_PREFIX} \
  --target=${TARGET_TRIPLE} \
  --libexecdir=${HOST_PREFIX}/usr/lib \
  --enable-static \
  --enable-shared \
  --enable-shared-libgcc \
  --enable-languages=c,c++,fortran,lto,objc,obj-c++ \
  --enable-version-specific-runtime-libs \
  --enable-__cxa_atexit \
  --enable-graphite \
  --enable-threads=posix \
  --enable-libatomic \
  --enable-libgomp \
  --enable-libquadmath \
  --enable-libquadmath-support \
  --enable-linker-build-id \
  --enable-libstdcxx-filesystem-ts \
  --disable-bootstrap \
  --disable-libssp \
  --disable-symvers \
  --disable-multilib \
  --with-sysroot=${SYSROOT} \
  --with-build-sysroot=${SYSROOT} \
  --with-gcc-major-version-only \
  --with-dwarf2 \
  --with-arch=nocona \
  --with-tune=generic \
  --with-gnu-ld \
  --with-gnu-as \
  --with-cloog-include=${SYSROOT}/usr/include/cloog-isl \
  --without-libiconv-prefix \
  --without-libintl-prefix \
  --with-system-zlib \
  --with-default-libstdcxx-abi=gcc4-compatible

make V=1 -j$(nproc)

rm -rf ${BUILDTOP}/gcc-inst
mkdir -p ${BUILDTOP}/gcc-inst
make install DESTDIR=${BUILDTOP}/gcc-inst

cd ${BUILDTOP}/gcc-inst/${HOST_PREFIX:1}
tar -cJf ${BUILDTOP}/gcc-${GCC_CYGWIN_VERSION}-cygwin.tar.xz *

cd ${HOST_PREFIX}
tar -xf ${BUILDTOP}/gcc-${GCC_CYGWIN_VERSION}-cygwin.tar.xz

############################################
## build zlib
############################################

cd ${SRCTOP}/zlib-${ZLIB_CYGWIN_VERSION}.src/zlib-${ZLIB_VERSION}

rm -f Makefile zconf.h

CROSS_PREFIX=x86_64-pc-cygwin- \
./configure \
  --prefix=${HOST_PREFIX} \
  --includedir=${HOST_PREFIX}/include \
  --libdir=${HOST_PREFIX}/lib

make V=1 -j$(nproc) \
  -f win32/Makefile.gcc \
  CC=x86_64-pc-cygwin-gcc \
  AR=x86_64-pc-cygwin-ar \
  RC=x86_64-pc-cygwin-windres \
  STRIP=: \
  SHAREDLIB=cygz.dll \
  IMPLIB=libz.dll.a

rm -rf ${BUILDTOP}/zlib-inst
mkdir -p ${BUILDTOP}/zlib-inst

make install DESTDIR=${BUILDTOP}/zlib-inst \
  -f win32/Makefile.gcc \
  SHAREDLIB=cygz.dll \
  IMPLIB=libz.dll.a \
  SHARED_MODE=1 \
  prefix=${HOST_PREFIX} \
  BINARY_PATH=${HOST_PREFIX}/bin \
  INCLUDE_PATH=${HOST_PREFIX}/include \
  LIBRARY_PATH=${HOST_PREFIX}/lib

cd ${BUILDTOP}/zlib-inst/${HOST_PREFIX:1}
tar -cJf ${BUILDTOP}/zlib-${ZLIB_CYGWIN_VERSION}-cygwin.tar.xz *

cd ${HOST_PREFIX}
tar -xf ${BUILDTOP}/zlib-${ZLIB_CYGWIN_VERSION}-cygwin.tar.xz

############################################
## build cocom
############################################

cd ${BUILDTOP}
rm -rf cocom
mkdir -p cocom
cd cocom

${SRCTOP}/cocom-${COCOM_CYGWIN_VERSION}.src/cocom-${COCOM_VERSION}/configure \
  --prefix=${HOST_PREFIX} \
  --target=${TARGET_TRIPLE} \

make V=1 -j$(nproc)

rm -rf ${BUILDTOP}/cocom-inst
mkdir -p ${BUILDTOP}/cocom-inst
make install DESTDIR=${BUILDTOP}/cocom-inst

cd ${BUILDTOP}/cocom-inst/${HOST_PREFIX:1}
tar -cJf ${BUILDTOP}/cocom-${COCOM_CYGWIN_VERSION}-cygwin.tar.xz *

cd ${HOST_PREFIX}
tar -xf ${BUILDTOP}/cocom-${COCOM_CYGWIN_VERSION}-cygwin.tar.xz

############################################
## build cygwin
############################################

cd ${BUILDTOP}
rm -rf cygwin
mkdir -p cygwin
cd cygwin

### note: because by default cygwin is build using -Werror,
### the following will result in the build halting several
### times due to warnings (cut-n-paste the failing command,
### add -Wno-error, and then re-make). Or configure with
### CFLAGS="-Wno-error" [untested].

pushd ${SRCTOP}/cygwin-${CYGWIN_CYGWIN_VERSION}.src/newlib-cygwin/winsup
./autogen.sh
popd

CFLAGS="-Wno-error -Wno-narrowing" \
CFLAGS_FOR_TARGET="-Wno-error -Wno-narrowing" \
CXXFLAGS="-Wno-error -Wno-narrowing" \
CXXFLAGS_FOR_TARGET="-Wno-error -Wno-narrowing -I${HOST_PREFIX}/include -I${HOST_PREFIX}/${TARGET_TRIPLE}/include" \
LDFLAGS_FOR_TARGET="-L${HOST_PREFIX}/lib -L${HOST_PREFIX}/${TARGET_TRIPLE}/lib" \
${SRCTOP}/cygwin-${CYGWIN_CYGWIN_VERSION}.src/newlib-cygwin/configure \
  --prefix=${HOST_PREFIX} \
  --sysconfdir=/etc \
  --host=${TARGET_TRIPLE} \
  --target=${TARGET_TRIPLE} \
  --disable-doc \
  --disable-dumper \
  --with-cross-bootstrap

make V=1 -j$(nproc)

rm -rf ${BUILDTOP}/cygwin-inst
mkdir -p ${BUILDTOP}/cygwin-inst
make install DESTDIR=${BUILDTOP}/cygwin-inst

cd ${BUILDTOP}/cygwin-inst/${HOST_PREFIX:1}
tar -cJf ${BUILDTOP}/cygwin-${CYGWIN_CYGWIN_VERSION}.tar.xz *

cd ${HOST_PREFIX}
tar -xf ${BUILDTOP}/cygwin-${CYGWIN_CYGWIN_VERSION}.tar.xz
