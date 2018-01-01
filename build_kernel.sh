#!/bin/bash
# Kernel Build Script

BUILD_WHERE=$(pwd)
BUILD_KERNEL_DIR=$BUILD_WHERE
BUILD_ROOT_DIR=$BUILD_KERNEL_DIR/..
BUILD_KERNEL_OUT_DIR=$BUILD_ROOT_DIR/kernel_out/KERNEL_OBJ
PRODUCT_OUT=$BUILD_ROOT_DIR/kernel_out

export PATH=$PATH:/home/vaughn/android2/TOOLCHAIN/aarch64-android-linux-gnu/bin/
export PATH=$PATH:/home/vaughn/android2/TOOLCHAIN/aarch64-linux-android/bin/
#export PATH=$PATH:/home/vaughn/android2/TOOLCHAIN/clang-4053586/bin/
export KERNEL_TOOLCHAIN=aarch64-linux-android-
export BUILD_CROSS_COMPILE=aarch64-linux-android-

CLANG_TOOLCHAIN_FOLDER=clang-4053586
CLANG_TOOLCHAIN=/home/vaughn/android2/TOOLCHAIN/${CLANG_TOOLCHAIN_FOLDER}/bin/clang

CLANG=clang
CLANG_VERSION=$(${CLANG_TOOLCHAIN} --version | head -n 1) 
GCC_TOOLCHAIN_CC=${GCC_TOOLCHAIN%gcc}
GCC_TOOLCHAIN=$(find ${GCC_TOOLCHAIN_FOLDER}/bin -type f -name '*-gcc' | head -n1)
export GCC_TOOLCHAIN_FOLDER=$PATH:/home/vaughn/android2/TOOLCHAIN/aarch64-linux-android

BUILD_CROSS_COMPILE=$KERNEL_TOOLCHAIN
BUILD_JOB_NUMBER=`grep processor /proc/cpuinfo|wc -l`

KERNEL_DEFCONFIG=exynos8895-dreamlte_eur_open_defconfig

KERNEL_IMG=$PRODUCT_OUT/Image
DTIMG=$PRODUCT_OUT/dt.img

DTBTOOL=$KERNEL_DTBTOOL

FUNC_GENERATE_DEFCONFIG()
{
	echo ""
        echo "=============================================="
        echo "START : FUNC_GENERATE_DEFCONFIG"
        echo "=============================================="
        echo "build config="$KERNEL_DEFCONFIG ""
        echo ""

	make -C $BUILD_KERNEL_DIR O=$BUILD_KERNEL_OUT_DIR -j$BUILD_JOB_NUMBER ARCH=arm64 \
			CROSS_COMPILE=$BUILD_CROSS_COMPILE \
			$KERNEL_DEFCONFIG || exit -1

	cp $BUILD_KERNEL_OUT_DIR/.config $BUILD_KERNEL_DIR/arch/arm64/configs/$KERNEL_DEFCONFIG

	echo ""
	echo "================================="
	echo "END   : FUNC_GENERATE_DEFCONFIG"
	echo "================================="
	echo ""
}

FUNC_GENERATE_DTB()
{
	echo ""
        echo "=============================================="
        echo "START : FUNC_GENERATE_DTB"
        echo "=============================================="
        echo ""
	rm -rf $BUILD_KERNEL_OUT_DIR/arch/arm64/boot/dts

	make dtbs -C $BUILD_KERNEL_DIR O=$BUILD_KERNEL_OUT_DIR -j$BUILD_JOB_NUMBER ARCH=arm64 \
			CROSS_COMPILE=$BUILD_CROSS_COMPILE || exit -1
	echo ""
	echo "================================="
	echo "END   : FUNC_GENERATE_DTB"
	echo "================================="
	echo ""
}

FUNC_BUILD_KERNEL()
{
	echo ""
	echo "================================="
	echo "START   : FUNC_BUILD_KERNEL"
	echo "================================="
	echo ""
	rm $KERNEL_IMG $BUILD_KERNEL_OUT_DIR/arch/arm64/boot/Image
	rm -rf $BUILD_KERNEL_OUT_DIR/arch/arm64/boot/dts

	make -C $BUILD_KERNEL_DIR O=$BUILD_KERNEL_OUT_DIR -j$BUILD_JOB_NUMBER ARCH=arm64 \
			CC=$CLANG \
			CLANG_TRIPLE=aarch64-linux-gnu- \
			COMPILER_NAME="${CLANG_VERSION}" \
			CROSS_COMPILE=$GCC_TOOLCHAIN_CC \
			HOSTCC=$CLANG || exit -1

	cp $BUILD_KERNEL_OUT_DIR/arch/arm64/boot/Image $KERNEL_IMG
	echo "Made Kernel image: $KERNEL_IMG"
	echo "================================="
	echo "END   : FUNC_BUILD_KERNEL"
	echo "================================="
	echo ""
}

FUNC_GENERATE_DTIMG()
{
	echo ""
	echo "================================="
	echo "START   : FUNC_GENERATE_DTIMG"
	echo "================================="
	rm $DTIMG
	$DTBTOOL -o $DTIMG -s 2048 -p $BUILD_KERNEL_OUT_DIR/scripts/dtc/ $BUILD_KERNEL_OUT_DIR/arch/arm64/boot/dts/exynos
	if [ -f "$DTIMG" ]; then
		echo "Made DT image: $DTIMG"
	fi
	echo "================================="
	echo "END   : FUNC_GENERATE_DTIMG"
	echo "================================="
	echo ""
}

# MAIN FUNCTION
(
    START_TIME=`date +%s`

    FUNC_GENERATE_DEFCONFIG
    if [ "$2" = "--dt-only" ]
    then
        FUNC_GENERATE_DTB
    else
        FUNC_BUILD_KERNEL
    fi
    FUNC_GENERATE_DTIMG

    END_TIME=`date +%s`

    let "ELAPSED_TIME=$END_TIME-$START_TIME"
    echo "Total compile time is $ELAPSED_TIME seconds"
) 2>&1

if [ ! -f "$KERNEL_IMG" ]; then
  exit -1
fi
