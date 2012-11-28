#!/bin/bash
#
# Copyright 2012 - mikeioannina
#

# Change sensor to AK8962
cd ~/android/cm7/device/zte/mooncake

echo "Changing sensor from AK8973 to AK8962..."
cp BoardConfig.mk BoardConfig.bak
cat BoardConfig.bak | sed -e 's/SENSORS_COMPASS_AK8973 := true/SENSORS_COMPASS_AK8973 := false/' -e 's/SENSORS_COMPASS_AK8962 := false/SENSORS_COMPASS_AK8962 := true/' > BoardConfig.mk
echo "Done!"

# Build CyanogenMod 7 for ZTE Carl
cd ~/android/cm7

echo "Setting up android build enviroment..."
source build/envsetup.sh

echo "breakfast mooncake - Carl"
breakfast mooncake

echo "Cleaning previous build..."
make clean
echo "Done!"

echo "brunch mooncake - Carl"
brunch mooncake

export DATE=$(date -u +%Y%m%d)
echo "Moving update.zip to nightlies folder..."
rm ~/android/nightlies/cm7/carl/*.zip
mv ./out/target/product/mooncake/cm-7-$DATE-NIGHTLY-mooncake.zip ~/android/nightlies/cm7/carl/cm-7-$DATE-NIGHTLY-mooncake-Carl.zip
echo "Done!"

# Change back to AK8973 sensor
cd ~/android/cm7/device/zte/mooncake

echo "Changing sensor from AK8962 to AK8973..."
rm BoardConfig.mk
mv BoardConfig.bak BoardConfig.mk
echo "Done!"



# Temporary unpack the update.zip file & integrate gen1 & gen2 libs
cd ~/android/nightlies/cm7/carl

echo "Unzipping update to temp folder..."
mkdir temp
unzip cm-7-$DATE-NIGHTLY-mooncake-Carl.zip -d temp
echo "Done!"

cp boot temp/boot
mv temp/boot.img temp/boot/gen2_boot.img

# Unpack gen2_boot.img to get the ramdisk
echo "Unpacking gen2_boot.img to get the ramdisk..."
rm ramdisk.gz
../../split_bootimg.pl temp/boot/gen2_boot.img
echo "Done!"

# Delete gen2 zImage & rename ramdisk
rm gen2_boot.img-kernel
mv gen2_boot.img-ramdisk.gz ramdisk.gz



# Build gen1 kernel and create gen1_boot.img
cd ~/android/cm7/kernel/zte/msm7x27

# Setup enviroment
export ARCH=arm
export CROSS_COMPILE="ccache $CCOMPILER7"

# Racer gen1
echo "Cleaning up & setting .version..."
make clean
rm .version
echo "Done!"

echo "Loading Carl gen1 defconfig..."
make cyanogen_mooncakec_gen1_defconfig
echo "Done!"

echo "Compiling kernel..."
make -j4
echo "Done!"

echo "Copying zImage..."
rm ~/android/nightlies/cm7/carl/gen1zImage
cp ./arch/arm/boot/zImage ~/android/nightlies/cm7/carl/gen1zImage
echo "Done!"

cd ~/android/nightlies/cm7/carl

echo "Creating gen1_boot.img..."
../../mkbootimg --base 0x02A00000 --cmdline 'androidboot.hardware=mooncake console=null' --kernel gen1zImage --ramdisk ramdisk.gz -o temp/boot/gen1_boot.img
echo "Done!"



# Integrate updater-script
echo "Copying updater-script..."
rm temp/META-INF/CERT.RSA
rm temp/META-INF/CERT.SF
rm temp/META-INF/MANIFEST.MF
rm temp/META-INF/com/google/android/updater-script
cp updater-script temp/META-INF/com/google/android/updater-script
echo "Done!"

# Mod Version
export MODVER="1.3"

# Create new update.zip
echo "Packing RacerMod-$MODVER-Carl.zip..."
cd temp
zip -r9 ../RacerMod-$MODVER-Carl.zip .
cd ..
rm -r temp
echo "Done!"

# Sign the update.zip
echo "Signing the update zip..."
cd ~/android/nightlies/signapk
java -Xmx1024m -jar signapk.jar -w testkey.x509.pem testkey.pk8 ../cm7/carl/RacerMod-$MODVER-Carl.zip RacerMod-$MODVER-Carl-signed.zip
cd ~/android/nightlies/cm7/carl
rm RacerMod-$MODVER-Carl.zip
mv RacerMod-$MODVER-Carl-signed.zip RacerMod-$MODVER-Carl.zip
echo "Done!"
