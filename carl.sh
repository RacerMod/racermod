#!/bin/bash
#
# Copyright 2012 - mikeioannina
#

# Build CyanogenMod 7 for ZTE Carl
cd ~/android/cm7

echo "Setting up android build enviroment..."
source build/envsetup.sh

echo "breakfast mooncakec - Carl"
breakfast mooncakec

if [ "$1" = "clean" ]; then
	echo "Cleaning previous build..."
	make clean
	echo "Done!"
fi

echo "brunch mooncakec - Carl"
brunch mooncakec

export DATE=$(date -u +%Y%m%d)
echo "Moving update.zip to racermod folder..."
rm ~/android/racermod/cm7/carl/*.zip
mv ./out/target/product/mooncakec/cm-7-$DATE-UNOFFICIAL-mooncakec.zip ~/android/racermod/cm7/carl/cm-7-$DATE-UNOFFICIAL-mooncakec.zip
echo "Done!"



# Temporary unpack the update.zip file & integrate gen1 & gen2 libs
cd ~/android/racermod/cm7/carl

echo "Unzipping update to temp folder..."
rm -r temp
mkdir temp
unzip cm-7-$DATE-UNOFFICIAL-mooncakec.zip -d temp
echo "Done!"

cp -r boot temp/boot
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
rm ~/android/racermod/cm7/carl/gen1zImage
cp ./arch/arm/boot/zImage ~/android/racermod/cm7/carl/gen1zImage
echo "Done!"

echo "Cleaning kernel source..."
make mrproper
echo "Done!"

cd ~/android/racermod/cm7/carl

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
export MODVER="1.5"

# Create new update.zip
echo "Packing RacerMod-$MODVER-Carl.zip..."
cd temp
zip -r9 ../RacerMod-$MODVER-Carl.zip .
cd ..
rm -r temp
echo "Done!"

# Sign the update.zip
echo "Signing the update zip..."
cd ~/android/racermod/signapk
java -Xmx1024m -jar signapk.jar -w testkey.x509.pem testkey.pk8 ../cm7/carl/RacerMod-$MODVER-Carl.zip ../cm7/carl/RacerMod-$MODVER-Carl-signed.zip
cd ~/android/racermod/cm7/carl
rm RacerMod-$MODVER-Carl.zip
mv RacerMod-$MODVER-Carl-signed.zip RacerMod-$MODVER-Carl.zip
echo "Done!"
