#!/bin/sh
#
# Copyright 2012 - mikeioannina
#

cd ~/android/cm7

echo "Setting up android build enviroment..."
. build/envsetup.sh

echo "breakfast mooncake - Racer"
breakfast mooncake

echo "Cleaning previous build..."
make clean
echo "Done!"

echo "brunch mooncake - Racer"
brunch mooncake

export DATE=$(date -u +%Y%m%d)
echo "Moving update.zip to nightlies folder..."
mv ./out/target/product/mooncake/cm-7-$DATE-NIGHTLY-mooncake.zip ~/android/nightlies/cm7/cm-7-$DATE-NIGHTLY-mooncake-Carl.zip
echo "Done!
