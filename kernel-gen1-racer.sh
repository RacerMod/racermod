#!/bin/sh
#
# Copyright 2012 - mikeioannina
#

cd ~/android/cm7/kernel/zte/mooncake

# Setup enviroment
export ARCH=arm
export CROSS_COMPILE="ccache $CCOMPILER7"

# Racer gen1
echo "Cleaning up & setting .version..."
make clean
rm .version
echo "Done!"

echo "Loading Racer gen1 defconfig..."
make cyanogen_mooncake_gen1_defconfig
echo "Done!"

echo "Compiling kernel..."
make -j4
echo "Done!"

echo "Copying zImage..."
rm ~/android/nightlies/cm7/racer/gen1zImage
cp ./arch/arm/boot/zImage ~/android/nightlies/cm7/racer/gen1zImage
echo "Done!"
