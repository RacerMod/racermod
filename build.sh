#!/bin/bash
#
# Copyright (c) 2012-2013 Michael Bestas http://mikeioannina.gitdroid.com
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA


#Configuration
android=~/android/cm7
racermod=~/android/racermod

modver="1.5a2"

usage=\
"RacerMod build script by mikeioannina
\n
\n usage: build.sh \$1 \$2
\n
\n \$2 is optional
\n
\n if \$1 = mooncake , we build for ZTE Racer
\n if \$1 = mooncakec , we build for ZTE Carl/Freddo
\n if \$1 = anything else , this message is displayed
\n if \$2 = clean , we \"make clean\" before building"

if [ "$1" != "mooncake" ] && [ "$1" != "mooncakec" ]; then
    echo -e $usage
    exit
else
    if [ "$2" != "clean" ]; then
        echo "Building without \"make clean\"..."
    fi
    if [ "$1" = "mooncake" ]; then
        device=mooncakec
    else
        device=mooncake
    fi
fi

if [ "${device}" = "mooncakec" ]; then
    product=carl
else
    product=racer
fi


# Build CyanogenMod 7
cd ~/android/cm7

echo "Setting up android build enviroment..."
. build/envsetup.sh

echo "breakfast ${device}"
breakfast ${device}

if [ "$2" = "clean" ]; then
    echo "Cleaning previous build..."
    make clean
    echo "Done!"
fi

echo "brunch ${device}"
brunch ${device}

DATE=$(date -u +%Y%m%d)
echo "Moving update.zip to racermod folder..."
rm ${racermod}/cm7/${product}/*.zip
mv ${android}/out/target/product/${device}/cm-7-$DATE-UNOFFICIAL-${device}.zip ${racermod}/cm7/${product}/cm-7-$DATE-UNOFFICIAL-${device}.zip
echo "Done!"



# Temporary unpack the update.zip file & integrate gen1 & gen2 libs
cd ${racermod}/cm7/${product}

echo "Unzipping update to temp folder..."
rm -r temp
mkdir temp
unzip cm-7-$DATE-UNOFFICIAL-${device}.zip -d temp
echo "Done!"

cp -r boot temp/boot
mv temp/boot.img temp/boot/gen2_boot.img

# Unpack gen2_boot.img to get the ramdisk
echo "Unpacking gen2_boot.img to get the ramdisk..."
rm ramdisk.gz
${racermod}/split_bootimg.pl temp/boot/gen2_boot.img
echo "Done!"

# Delete gen2 zImage & rename ramdisk
rm gen2_boot.img-kernel
mv gen2_boot.img-ramdisk.gz ramdisk.gz



# Build gen1 kernel and create gen1_boot.img
cd ${android}/kernel/zte/msm7x27

# Setup enviroment
export ARCH=arm
export CROSS_COMPILE="ccache ${android}/prebuilt/linux-x86/toolchain/arm-eabi-4.4.3/bin/arm-eabi-"

# Racer gen1
echo "Cleaning up & setting .version..."
make clean
rm .version
echo "Done!"

echo "Loading gen1 defconfig..."
make cyanogen_${device}_gen1_defconfig
echo "Done!"

echo "Compiling kernel..."
make -j4
echo "Done!"

echo "Copying zImage..."
rm ${racermod}/cm7/${product}/gen1zImage
cp ${android}/kernel/zte/msm7x27/arch/arm/boot/zImage ${racermod}/cm7/${product}/gen1zImage
echo "Done!"

echo "Cleaning kernel source..."
make mrproper
echo "Done!"

cd ${racermod}/cm7/${product}

echo "Creating gen1_boot.img..."
${racermod}/mkbootimg --base 0x02A00000 --cmdline 'androidboot.hardware=mooncake console=null' --kernel gen1zImage --ramdisk ramdisk.gz -o temp/boot/gen1_boot.img
echo "Done!"



# Integrate updater-script
echo "Copying updater-script..."
rm temp/META-INF/CERT.RSA
rm temp/META-INF/CERT.SF
rm temp/META-INF/MANIFEST.MF
rm temp/META-INF/com/google/android/updater-script
cp updater-script temp/META-INF/com/google/android/updater-script
echo "Done!"

# Create new update.zip
echo "Packing RacerMod-${modver}-${product}.zip..."
cd temp
zip -r9 ${racermod}/cm7/${product}/RacerMod-${modver}-${product}.zip .
cd ..
rm -r temp
echo "Done!"

# Sign the update.zip
echo "Signing the update zip..."
cd ${racermod}/cm7/${product}
java -Xmx1024m -jar ${racermod}/signapk/signapk.jar -w testkey.x509.pem testkey.pk8 RacerMod-${modver}-${product}.zip RacerMod-${modver}-${product}-signed.zip
rm RacerMod-${modver}-${product}.zip
mv RacerMod-${modver}-${product}-signed.zip RacerMod-${modver}-${product}.zip
echo "Build finished, package is ready in ${racermod}/cm7/${product}/"
