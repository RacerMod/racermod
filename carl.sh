#!/bin/sh
#
# Copyright 2012 - mikeioannina
#

cd ~/android/cm7/device/zte/mooncake

echo "Changing sensor from AK8973 to AK8962..."
cp BoardConfig.mk BoardConfig.bak
cat BoardConfig.bak | sed -e 's/SENSORS_COMPASS_AK8973 := true/SENSORS_COMPASS_AK8973 := false/' -e 's/SENSORS_COMPASS_AK8962 := false/SENSORS_COMPASS_AK8962 := true/' > BoardConfig.mk
echo "Done!"

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
mv ./out/target/product/mooncake/cm-7-$DATE-NIGHTLY-mooncake.zip ~/android/nightlies/cm7/cm-7-$DATE-NIGHTLY-mooncake-Racer.zip
echo "Done!"

cd ~/android/cm7/device/zte/mooncake

echo "Changing sensor from AK8962 to AK8973..."
rm BoardConfig.mk
mv BoardConfig.bak BoardConfig.mk
echo "Done!"
