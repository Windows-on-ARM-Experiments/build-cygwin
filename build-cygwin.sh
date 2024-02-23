HOST_TRIPLE=i686-pc-linux-gnu
HOST_PREFIX=/opt/devel/cygwin

TARGET_TRIPLE=i686-pc-cygwin
TARGET_PREFIX=/usr

SYSROOT=${HOST_PREFIX}/${TARGET_TRIPLE}/sys-root

SRCTOP=/mnt/junk/gcc45c/src
BUILDTOP=/mnt/junk/gcc45c/build
GCCVER=4.5.0
PKGREL=2


DOWNLOADS=/opt/devel/cygwin/src/DOWNLOADS
MIRROR=http://mirrors.kernel.org/sourceware/cygwin/release
export PATH=${HOST_PREFIX}/bin:/mnt/junk/private/bin:${PATH}

mkdir -p ${BUILDTOP}
mkdir -p ${SRCTOP}
mkdir -p ${SYSROOT}

do_get () {
  pushd ${DOWNLOADS} >/dev/null
  wget ${MIRROR}/$1
  popd >/dev/null 
}


mkdir -p ${DOWNLOADS}
do_get binutils/binutils-2.20.51-2-src.tar.bz2
do_get gcc4/gcc4-4.5.0-1-src.tar.bz2
do_get cygwin/cygwin-1.7.6-1-src.tar.bz2

############################################
## Prepare $target libs and headers
############################################
do_get binutils/binutils-2.20.51-2.tar.bz2
do_get w32api/w32api-3.14-1.tar.bz2
do_get cygwin/cygwin-1.7.6-1.tar.bz2
do_get zlib/zlib-devel/zlib-devel-1.2.3-10.tar.bz2
do_get mingw/mingw-zlib/mingw-zlib-devel/mingw-zlib-devel-1.2.3-10.tar.bz2
do_get mingw-runtime/mingw-runtime-3.18-1.tar.bz2
do_get libiconv/libiconv-1.13.1-1.tar.bz2
do_get gettext/gettext-0.17-11.tar.bz2

cd ${SYSROOT}
tar xjf ${DOWNLOADS}/binutils-2.20.51-2.tar.bz2        usr/include usr/lib
tar xjf ${DOWNLOADS}/gettext-0.17-11.tar.bz2           usr/include usr/lib
tar xjf ${DOWNLOADS}/libiconv-1.13.1-1.tar.bz2         usr/include usr/lib
tar xjf ${DOWNLOADS}/mingw-runtime-3.18-1.tar.bz2      usr/include usr/lib
tar xjf ${DOWNLOADS}/mingw-zlib-devel-1.2.3-10.tar.bz2 usr/include usr/lib
tar xjf ${DOWNLOADS}/zlib-devel-1.2.3-10.tar.bz2       usr/include usr/lib
tar xjf ${DOWNLOADS}/w32api-3.14-1.tar.bz2             usr/include usr/lib
tar xjf ${DOWNLOADS}/cygwin-1.7.6-1.tar.bz2            usr/include usr/lib

find ./usr/lib -name '*.dll.a' -o -name '*.la' | xargs rm

# not sure if sysroot support extends to the w32api stuff, so
# make sure the libs that appear in the specs file exist in the
# main lib dir, and not just in the w32api subdir.  In any case,
# this is *absolutely* necessary during the build of the language
# runtime libraries...
(cd ${SYSROOT}${TARGET_PREFIX}/lib && ln -fs w32api/libkernel32.a .)
(cd ${SYSROOT}${TARGET_PREFIX}/lib && ln -fs w32api/libuser32.a   .)
(cd ${SYSROOT}${TARGET_PREFIX}/lib && ln -fs w32api/libadvapi32.a .)
(cd ${SYSROOT}${TARGET_PREFIX}/lib && ln -fs w32api/libshell32.a  .)
(cd ${SYSROOT}${TARGET_PREFIX}/lib && ln -fs w32api/libgdi32.a    .)
(cd ${SYSROOT}${TARGET_PREFIX}/lib && ln -fs w32api/libcomdlg32.a .)


# ensure linux package installed: libgmp-devel, libgmp10
# ensure linux package installed: mpfr-devel, libmpfr1
# ensure linux package installed: libmpc-devel, libmpc2
# ensure linux package installed: libcloog-devel, libcloog0
# ensure linux package installed: libppl-devel, libppl7

############################################
## custom autoconf, automake
## gcc-4.5.0 requires ac-2.64, am-1.11.1
############################################
cd ${DOWNLOADS}
wget http://ftp.gnu.org/gnu/autoconf/autoconf-2.64.tar.bz2
wget http://ftp.gnu.org/gnu/automake/automake-1.11.1.tar.bz2

cd ${SRCTOP}
tar xvjf ${DOWNLOADS}/autoconf-2.64.tar.bz2
tar xvjf ${DOWNLOADS}/automake-1.11.1.tar.bz2
cd ${BUILDTOP}
mkdir autoconf
cd autoconf
${SRCTOP}/autoconf-2.64/configure --prefix=/mnt/junk/private
make
make install

cd ${BUILDTOP}
mkdir automake
cd automake
${SRCTOP}/automake-1.11.1/configure --prefix=/mnt/junk/private
make
make install
mkdir -p /mnt/junk/private/share/aclocal
echo '/usr/share/aclocal' > /mnt/junk/private/share/aclocal/dirlist

############################################
## unpack gcc, binutils source
############################################
cd $SRCTOP
tar xvjf ${DOWNLOADS}/binutils-2.20.51-2-src.tar.bz2
tar xvjf ${DOWNLOADS}/gcc4-4.5.0-1-src.tar.bz2
tar xvjf gcc-4.5.0.tar.bz2

############################################
## apply patches
############################################
cd gcc-4.5.0
patch -p2 < ../classpath-0.98-FIONREAD.patch
patch -p2 < ../classpath-0.98-build.patch
patch -p2 < ../classpath-0.98-awt.patch
patch -p2 < ../gcc45-ada.diff
patch -p0 < ../gcc45-cygwin-lto.diff
patch -p2 < ../gcc45-ehdebug.diff
patch -p2 < ../gcc45-libffi.diff
patch -p2 < ../gcc45-libstdc.diff
patch -p2 < ../gcc45-misc-core.diff
patch -p2 < ../gcc45-mnocygwin.diff
patch -p0 < ../gcc45-sig-unwind.diff
patch -p2 < ../gcc45-skiptest.diff
patch -p0 < ../gcc45-pruneopts-term.diff
patch -p2 < ../gcc45-weak-binding.diff
patch -p2 < ../gcc4-4.5.0-1.cygwin.patch
cd ..


############################################
## binutils
############################################
cd ${BUILDTOP}
mkdir binutils
cd binutils
${SRCTOP}/binutils-2.20.51-2/configure \
  --prefix=${HOST_PREFIX} \
  --target=${TARGET_TRIPLE} \
  --disable-bootstrap --enable-version-specific-runtime-libs \
  --enable-static --enable-shared --enable-shared-libgcc \
  --disable-__cxa_atexit --with-gnu-ld --with-gnu-as --with-dwarf2 \
  --disable-sjlj-exceptions --enable-languages=c,c++,fortran --disable-symvers \
  --enable-threads=posix --with-arch=i686 --with-tune=generic \
  --with-newlib \
  --with-build-sysroot=${SYSROOT} \
  --with-sysroot=${SYSROOT} \
  --datadir=${HOST_PREFIX}/share \
  --mandir=${HOST_PREFIX}/share/man \
  --infodir=${HOST_PREFIX}/share/info \
  --libexecdir=${HOST_PREFIX}/lib \
  --enable-libgomp --enable-libssp

# --enable-graphite --disable-lto

make
mkdir ${BUILDTOP}/binutils-inst
make install DESTDIR=${BUILDTOP}/binutils-inst
cd ${BUILDTOP}/binutils-inst
tar cvJf ../binutils-2.20.51-2-cygwin.tar.xz opt
cd /
tar xvJf ${BUILDTOP}/binutils-2.20.51-2-cygwin.tar.xz

############################################
## gcc
############################################
cd ${SRCTOP}/gcc-4.5.0
pushd libstdc++-v3 >/dev/null
cat <<"EOF" > crossconfig.m4.patch
--- crossconfig.m4.orig 2009-06-02 15:15:03.000000000 -0400
+++ crossconfig.m4      2010-08-22 22:35:55.345320303 -0400
@@ -141,7 +141,7 @@
        ;;
     esac
     ;;
-  *-linux* | *-uclinux* | *-gnu* | *-kfreebsd*-gnu | *-knetbsd*-gnu)
+  *-linux* | *-uclinux* | *-gnu* | *-kfreebsd*-gnu | *-knetbsd*-gnu | *-cygwin* )
     GLIBCXX_CHECK_COMPILER_FEATURES
     GLIBCXX_CHECK_LINKER_FEATURES
     GLIBCXX_CHECK_MATH_SUPPORT
EOF
patch -p0 < ./crossconfig.m4.patch
popd >/dev/null
gcc_reconf() {
	local S=${SRCTOP}/gcc-4.5.0
        pushd ${S} >/dev/null
        cd ${S}
        autoconf || exit -1
        cd ${S}/gcc
        autoconf || exit -1
        autoheader || exit -1
        cd ${S}/libiberty
        autoconf || exit -1
        cd ${S}/libstdc++-v3
        autoconf || exit -1
        cd ${S}/libjava
        autoconf || exit -1
        cd ${S}/libffi
        aclocal -I . -I .. -I ../config || exit -1
        autoconf || exit -1
        cd ${S}
        for x in boehm-gc libffi libgfortran libgomp libjava libmudflap libssp libstdc++-v3 zlib;
        do
                pushd $x >/dev/null
                automake || exit -1
                popd >/dev/null
        done
        cd ${S}/gcc/testsuite/ada/acats
        chmod a+x run_test.exp
	popd >/dev/null
}
gcc_reconf

cd ${BUILDTOP}
mkdir gcc
cd gcc
${SRCTOP}/gcc-4.5.0/configure \
  --prefix=${HOST_PREFIX} \
  --target=${TARGET_TRIPLE} \
  --disable-bootstrap --enable-version-specific-runtime-libs \
  --enable-static --enable-shared --enable-shared-libgcc \
  --disable-__cxa_atexit --with-gnu-ld --with-gnu-as --with-dwarf2 \
  --disable-sjlj-exceptions --enable-languages=c,c++,fortran --disable-symvers \
  --enable-threads=posix --with-arch=i686 --with-tune=generic \
  --with-newlib \
  --with-build-sysroot=${SYSROOT} \
  --with-sysroot=${SYSROOT} \
  --datadir=${HOST_PREFIX}/share \
  --mandir=${HOST_PREFIX}/share/man \
  --infodir=${HOST_PREFIX}/share/info \
  --libexecdir=${HOST_PREFIX}/lib \
  --enable-libgomp --enable-libssp
make
mkdir ${BUILDTOP}/gcc-inst
make install DESTDIR=${BUILDTOP}/gcc-inst
D=${BUILDTOP}/gcc-inst
cd ${D}

# don't install target libiberty
rm -f ${HOST_PREFIX:1}/lib/libiberty.a
rm -f ${HOST_PREFIX:1}/${TARGET_TRIPLE}/lib/libiberty.a

# move runtime DLLs...
mkdir -p ${SYSROOT:1}${TARGET_PREFIX}/bin
mv ${HOST_PREFIX:1}/bin/*.dll ${SYSROOT:1}${TARGET_PREFIX}/bin

# libgcc1
cd ${D}
tar cvJf ${BUILDTOP}/libgcc1-${GCCVER}-${PKGREL}-cygwin.tar.xz \
	${SYSROOT:1}${TARGET_PREFIX}/bin/cyggcc_s-1.dll

# libstdc++6
cd ${D}
tar cvJf ${BUILDTOP}/libstdc++6-${GCCVER}-${PKGREL}-cygwin.tar.xz \
	${SYSROOT:1}${TARGET_PREFIX}/bin/cygstdc++-6.dll

# libssp0
cd ${D}
tar cvJf ${BUILDTOP}/libssp0-${GCCVER}-${PKGREL}-cygwin.tar.xz \
	${SYSROOT:1}${TARGET_PREFIX}/bin/cygssp-0.dll

# libgfortran3
cd ${D}
tar cvJf ${BUILDTOP}/libgfortran3-${GCCVER}-${PKGREL}-cygwin.tar.xz \
	${SYSROOT:1}${TARGET_PREFIX}/bin/cyggfortran-3.dll

# libgomp1
cd ${D}
tar cvJf ${BUILDTOP}/libgomp1-${GCCVER}-${PKGREL}-cygwin.tar.xz \
	${SYSROOT:1}${TARGET_PREFIX}/bin/cyggomp-1.dll


# g++
cd ${D}
tar cvJf ${BUILDTOP}/gcc-g++-${GCCVER}-${PKGREL}-cygwin.tar.xz \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/include/c++ \
	${HOST_PREFIX:1}/bin/${TARGET_TRIPLE}-c++ \
	${HOST_PREFIX:1}/bin/${TARGET_TRIPLE}-g++ \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/cc1plus \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/libstdc++.a \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/libstdc++.dll.a \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/libstdc++.la \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/libsupc++.a \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/libsupc++.la \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/libstdc++.dll.a-gdb.py \
	${HOST_PREFIX:1}/share/gcc-${GCCVER}/python/libstdcxx/__init__.py \
	${HOST_PREFIX:1}/share/gcc-${GCCVER}/python/libstdcxx/v6/__init__.py \
	${HOST_PREFIX:1}/share/gcc-${GCCVER}/python/libstdcxx/v6/printers.py \
	${HOST_PREFIX:1}/share/man/man1/${TARGET_TRIPLE}-g++.1


# gfortran
tar cvJf ${BUILDTOP}/gcc-gfortran-${GCCVER}-${PKGREL}-cygwin.tar.xz \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/finclude \
	${HOST_PREFIX:1}/bin/${TARGET_TRIPLE}-gfortran \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/f951 \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/libgfortran.a \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/libgfortran.dll.a \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/libgfortran.la \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/libgfortranbegin.a \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/libgfortranbegin.la \
	${HOST_PREFIX:1}/share/info/gfortran.info \
	${HOST_PREFIX:1}/share/man/man1/${TARGET_TRIPLE}-gfortran.1

# gcc
tar cvJf ${BUILDTOP}/gcc-core-${GCCVER}-${PKGREL}-cygwin.tar.xz \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/include/*.h \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/include/ssp \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/include-fixed \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/install-tools \
	${HOST_PREFIX:1}/bin/${TARGET_TRIPLE}-cpp \
	${HOST_PREFIX:1}/bin/${TARGET_TRIPLE}-gcc \
	${HOST_PREFIX:1}/bin/${TARGET_TRIPLE}-gcc-${GCCVER} \
	${HOST_PREFIX:1}/bin/${TARGET_TRIPLE}-gccbug \
	${HOST_PREFIX:1}/bin/${TARGET_TRIPLE}-gcov \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/cc1 \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/collect2 \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/crtbegin.o \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/crtend.o \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/crtfastmath.o \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/libgcc.a \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/libgcc_eh.a \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/libgcc_s.dll.a \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/libgcov.a \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/libgomp.spec \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/libgomp.la \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/libgomp.dll.a \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/libgomp.a \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/libssp.a \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/libssp.dll.a \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/libssp.la \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/libssp_nonshared.a \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/libssp_nonshared.la \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/lto-wrapper \
	${HOST_PREFIX:1}/lib/gcc/${TARGET_TRIPLE}/${GCCVER}/plugin/ \
	${HOST_PREFIX:1}/share/locale/* \
	${HOST_PREFIX:1}/share/info/cpp.info \
	${HOST_PREFIX:1}/share/info/cppinternals.info \
	${HOST_PREFIX:1}/share/info/gcc.info \
	${HOST_PREFIX:1}/share/info/gccinstall.info \
	${HOST_PREFIX:1}/share/info/gccint.info \
	${HOST_PREFIX:1}/share/info/libgomp.info \
	${HOST_PREFIX:1}/share/man/man1/${TARGET_TRIPLE}-cpp.1 \
	${HOST_PREFIX:1}/share/man/man1/${TARGET_TRIPLE}-gcc.1 \
	${HOST_PREFIX:1}/share/man/man1/${TARGET_TRIPLE}-gcov.1 \
	${HOST_PREFIX:1}/share/man/man7/gpl.7 \
	${HOST_PREFIX:1}/share/man/man7/gfdl.7 \
	${HOST_PREFIX:1}/share/man/man7/fsf-funding.7

cd /
tar xvJf ${BUILDTOP}/gcc-core-${GCCVER}-${PKGREL}-cygwin.tar.xz
tar xvJf ${BUILDTOP}/gcc-g++-${GCCVER}-${PKGREL}-cygwin.tar.xz
tar xvJf ${BUILDTOP}/gcc-gfortran-${GCCVER}-${PKGREL}-cygwin.tar.xz
tar xvJf ${BUILDTOP}/libgcc1-${GCCVER}-${PKGREL}-cygwin.tar.xz 
tar xvJf ${BUILDTOP}/libgfortran3-${GCCVER}-${PKGREL}-cygwin.tar.xz
tar xvJf ${BUILDTOP}/libssp0-${GCCVER}-${PKGREL}-cygwin.tar.xz
tar xvJf ${BUILDTOP}/libstdc++6-${GCCVER}-${PKGREL}-cygwin.tar.xz
tar xvJf ${BUILDTOP}/libgomp1-${GCCVER}-${PKGREL}-cygwin.tar.xz

############################################
## cygwin
############################################
cd ${SRCTOP}
tar xvjf ${DOWNLOADS}/cygwin-1.7.6-1-src.tar.bz2
cd ${BUILDTOP}
mkdir cygwin
cd cygwin

### note: because by default cygwin is build using -Werror,
### the following will result in the build halting several
### times due to warnings (cut-n-paste the failing command,
### add -Wno-error, and then re-make). Or configure with
### CFLAGS="-Wno-error" [untested].

${SRCTOP}/cygwin-1.7.6-1/configure \
	--prefix=/usr \
	--sysconfdir=/etc \
	--host=i686-pc-cygwin \
	--target=i686-pc-cygwin
make


mkdir ${BUILDTOP}/cygwin-inst
DATE=$(date +%Y%m%d)
make install DESTDIR=${BUILDTOP}/cygwin-inst
D=${BUILDTOP}/cygwin-inst

### some manipulations to make the inst tree look "correct"
cd ${D}/usr
mv i686-pc-cygwin/{include,lib} .
mv i686-pc-cygwin/share/doc/mingw-runtime share/doc/
mv i686-pc-cygwin/bin/mingwm10.dll bin/
rmdir i686-pc-cygwin/bin
rmdir i686-pc-cygwin/share/doc
rmdir i686-pc-cygwin/share
rmdir i686-pc-cygwin
rm -f include/iconv.h
rm -f share/info/{configure.info,standards.info}
cd bin/
cp -p ${BUILDTOP}/cygwin/i686-pc-cygwin/winsup/cygwin/cygwin1.dbg .
rename cygwin1 cygwin1-${DATE} cygwin1*
mv cyglsa.dll cyglsa-${DATE}.dll
# oddly, cp -p DTRT, but mv does not
cp -p cyglsa64.dll "cyglsa64-${DATE}.dll"
rm -f cyglsa64.dll

# and...package
tar -C ${D} -cvJf ${BUILDTOP}/cygwin1-${DATE}.tar.xz \
	--exclude usr/lib/mingw     --exclude usr/lib/w32api \
	--exclude usr/include/mingw --exclude usr/include/w32api \
	--exclude usr/bin/mingwm10.dll \
	--exclude usr/share/doc/mingw-runtime \
	--exclude usr/share/man/manmingw \
	etc/ usr/
tar -C ${D} -cvJf ${BUILDTOP}/w32api-${DATE}.tar.xz \
	usr/include/w32api usr/lib/w32api
tar -C ${D} -cvJf ${BUILDTOP}/mingw-runtime-${DATE}.tar.xz \
	usr/bin/mingwm10.dll \
	usr/include/mingw usr/lib/mingw \
	usr/share/doc/mingw-runtime \
	usr/share/man/manmingw


