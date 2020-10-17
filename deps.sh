PACKAGES="gtest jansson fuse"

gtest_VERSION=1.10.0
gtest_URL=https://github.com/google/googletest/archive/release-${gtest_VERSION}.tar.gz
gtest_MD5=ecd1fa65e7de707cd5c00bdac56022cd
gtest_DIR=googletest-release-${gtest_VERSION}
gtest_TYPE=cmake

jansson_VERSION=2.13.1
jansson_URL=https://github.com/akheron/jansson/archive/v${jansson_VERSION}.tar.gz
jansson_MD5=3d589a62053874893715453a46a32a0e
jansson_DIR=jansson-${jansson_VERSION}
jansson_TYPE=cmake
jansson_CMAKE_OPTS=-DCMAKE_BUILD_TYPE=debug

fuse3_VERSION=3.10.0
fuse3_URL=https://github.com/libfuse/libfuse/archive/fuse-${fuse3_VERSION}.tar.gz
fuse3_MD5=22aec9bc9008eea6b17e203653d1b938
fuse3_DIR=libfuse-fuse-${fuse3_VERSION}
fuse3_TYPE=meson
fuse3_MESON_OPTS=-Dexamples=false
