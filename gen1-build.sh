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

# Build with colors
CL_RED="\033[31m"
CL_GRN="\033[32m"
CL_YLW="\033[33m"
CL_BLU="\033[34m"
CL_MAG="\033[35m"
CL_CYN="\033[36m"
CL_RST="\033[0m"

# Configuration
android=~/android/cm7
racermod=~/android/racermod

modver="1.6"

usage=\
"RacerMod build script by mikeioannina
\n
\n usage: build.sh \$1 \$2 \$3
\n
\n \$3 is optional
\n
\n if \$1 = mooncake , we build for ZTE Racer
\n if \$1 = mooncakec , we build for ZTE Carl/Freddo
\n if \$1 = blade , we build for ZTE Blade
\n if \$1 = anything else , this message is displayed
\n if \$2 = clean , we \"make clean\" before building"

if [ "$1" != "mooncake" ] && [ "$1" != "mooncakec" ] && [ "$1" != "blade" ]; then
    echo -e $CL_GRN${usage}$CL_RST
    exit
else
    if [ "$2" != "clean" ]; then
        echo -e $CL_GRN"Building without \"make clean\"..."$CL_RST
    fi

    if [ "$1" = "blade" ]; then
        device=blade
        product=blade
    else
        if [ "$1" = "mooncake" ]; then
            device=mooncake
            product=racer
        else
            device=mooncakec
            product=carl
        fi
    fi
fi


# Create temp dir & integrate gen check script / libs
cd ${racermod}/cm7/${product}

echo -e $CL_GRN"Copying gen1 libs & gen2 boot image..."$CL_RST
mkdir temp
cp -r libs temp/libs
cp ${android}/out/target/product/${device}/boot.img temp/gen2_boot.img
echo -e $CL_GRN"Done!"$CL_RST

echo -e $CL_GRN"Copying META-INF folder..."$CL_RST
cp -r META-INF temp/META-INF
echo -e $CL_GRN"Done!"$CL_RST


# Unpack gen2_${image}.img to get the ramdisk
echo -e $CL_GRN"Unpacking gen2_boot.img to get the ramdisk..."$CL_RST
${racermod}/split_bootimg.pl temp/gen2_boot.img
echo -e $CL_GRN"Done!"$CL_RST

# Delete gen2 zImage & rename ramdisk
rm temp/gen2_boot.img
rm gen2_boot.img-kernel
mv gen2_boot.img-ramdisk.gz ramdisk.gz


# Build gen1 kernel and create gen1_boot.img
cd ${android}/kernel/zte/msm7x27

# Setup enviroment
export ARCH=arm
export CROSS_COMPILE="ccache ${android}/prebuilt/linux-x86/toolchain/arm-eabi-4.4.3/bin/arm-eabi-"

# Racer gen1
echo -e $CL_GRN"Loading gen1 defconfig..."$CL_RST
make cyanogen_${device}_gen1_defconfig
echo -e $CL_GRN"Done!"$CL_RST

echo -e $CL_GRN"Compiling kernel..."$CL_RST
make -j4
echo -e $CL_GRN"Done!"$CL_RST

echo -e $CL_GRN"Copying zImage..."$CL_RST
cp ${android}/kernel/zte/msm7x27/arch/arm/boot/zImage ${racermod}/cm7/${product}/gen1zImage
echo -e $CL_GRN"Done!"$CL_RST

echo -e $CL_GRN"Cleaning kernel source..."$CL_RST
make mrproper
echo -e $CL_GRN"Done!"$CL_RST

cd ${racermod}/cm7/${product}

echo -e $CL_GRN"Creating gen1_boot.img..."$CL_RST
if [ "$1" = "blade" ]; then
    ${racermod}/mkbootimg --base 0x02A00000 --cmdline 'androidboot.hardware=blade console=null' --kernel gen1zImage --ramdisk ramdisk.gz -o temp/boot.img
else
    ${racermod}/mkbootimg --base 0x02A00000 --cmdline 'androidboot.hardware=mooncake console=null' --kernel gen1zImage --ramdisk ramdisk.gz -o temp/boot.img
fi

rm ramdisk.gz
rm gen1zImage
echo -e $CL_GRN"Done!"$CL_RST


# Create new update.zip
echo -e $CL_GRN"Packing RacerMod-${modver}-${product}-gen1.zip..."$CL_RST
cd temp
zip -r9 ${racermod}/cm7/zips/RacerMod-${modver}-${product}-gen1.zip .
cd ..
rm -rf temp
echo -e $CL_GRN"Done!"$CL_RST

# Sign the update.zip
echo -e $CL_GRN"Signing the update zip..."$CL_RST
cd ${racermod}/cm7/zips
java -Xmx1024m -jar ${racermod}/signapk/signapk.jar -w ${racermod}/signapk/testkey.x509.pem ${racermod}/signapk/testkey.pk8 RacerMod-${modver}-${product}-gen1.zip RacerMod-${modver}-${product}-gen1-signed.zip
rm RacerMod-${modver}-${product}-gen1.zip
mv RacerMod-${modver}-${product}-gen1-signed.zip RacerMod-${modver}-${product}-gen1.zip
echo -e $CL_GRN"Build finished, package is ready under ${racermod}/cm7/zips/"$CL_RST
