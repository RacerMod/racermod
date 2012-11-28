#!/bin/bash
#
# Copyright 2012 - mikeioannina
#

# Build CyanogenMod 7 for ZTE Racer
cd ~/android/cm7

echo "Setting up android build enviroment..."
source build/envsetup.sh

echo "breakfast mooncake - Racer"
breakfast mooncake

echo "Cleaning previous build..."
make clean
echo "Done!"

echo "brunch mooncake - Racer"
brunch mooncake

export DATE=$(date -u +%Y%m%d)
echo "Moving update.zip to nightlies folder..."
rm ~/android/nightlies/cm7/racer/*.zip
mv ./out/target/product/mooncake/cm-7-$DATE-NIGHTLY-mooncake.zip ~/android/nightlies/cm7/racer/cm-7-$DATE-NIGHTLY-mooncake-Racer.zip
echo "Done!"



# Temporary unpack the update.zip file & integrate gen1 & gen2 libs
cd ~/android/nightlies/cm7/racer

echo "Unzipping update to temp folder..."
mkdir temp
unzip cm-7-$DATE-NIGHTLY-mooncake-Racer.zip -d temp
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

cd ~/android/nightlies/cm7/racer

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
echo "Packing RacerMod-$MODVER-Racer.zip..."
cd temp
zip -r9 ../RacerMod-$MODVER-Racer.zip .
cd ..
rm -r temp
echo "Done!"

# Sign the update.zip
echo "Signing the update zip..."
cd ~/android/nightlies/signapk
java -Xmx1024m -jar signapk.jar -w testkey.x509.pem testkey.pk8 ../cm7/racer/RacerMod-$MODVER-Racer.zip RacerMod-$MODVER-Racer-signed.zip
cd ~/android/nightlies/cm7/racer
rm RacerMod-$MODVER-Racer.zip
mv RacerMod-$MODVER-Racer-signed.zip RacerMod-$MODVER-Racer.zip
echo "Done!"
