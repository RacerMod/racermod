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

#Configuration
android=~/android/cm7
racermod=~/android/racermod

modver="1.5-alpha-2"

usage=\
"RacerMod build script by mikeioannina
\n
\n usage: build.sh \$1 \$2 \$3
\n
\n \$2 & \$3 are optional
\n
\n if \$1 = mooncake , we build for ZTE Racer
\n if \$1 = mooncakec , we build for ZTE Carl/Freddo
\n if \$1 = recovery , we build CWM recovery
\n if \$1 = anything else , this message is displayed
\n if \$2 = clean , we \"make clean\" before building
\n if \$2 = kernel , we build only kernel
\n if \$2 = kernel & \$3 clean , we \"make clean\" before building"

if [ "$1" != "mooncake" ] && [ "$1" != "mooncakec" ] && [ "$1" != "recovery" ]; then
    echo -e $CL_GRN $usage $CL_RST
    exit
else
    if [ "$2" != "clean" ]; then
        if [ "$2" = "kernel" ]; then
            echo -e $CL_GRN "Kernel build" $CL_RST
            if [ "$3" != "clean" ]; then
                echo -e $CL_GRN "Building without \"make clean\"..." $CL_RST
            fi
        else
            echo -e $CL_GRN "Building without \"make clean\"..." $CL_RST
        fi
    fi
    if [ "$1" = "recovery" ]; then
        echo -e $CL_GRN "Recovery build" $CL_RST
        device=mooncake
        product=recovery
        image=recovery
    else
        if [ "$2" != "kernel" ]; then
            echo -e $CL_GRN "Normal build" $CL_RST
        fi
        if [ "$1" = "mooncake" ]; then
            device=mooncake
            product=racer
        else
            device=mooncakec
            product=carl
        fi
        image=boot
    fi
fi


# Check for update needed in local_manifest
if [ ! -f "${racermod}/.manifest_v1" ]; then
    echo -e $CL_GRN "RacerMod repositories need to be synced" $CL_RST
    if [ -d "${android}/.repo/local_manifests" ]; then
        echo -e $CL_GRN "Deleting existing local_manifests folder..." $CL_RST
        rm -rf ${android}/.repo/local_manifests
        echo -e $CL_GRN "Done!" $CL_RST
    fi

    echo -e $CL_GRN "Copying RacerMod manifest..." $CL_RST
    mkdir -p ${android}/.repo/local_manifests
    cp ${racermod}/racermod.xml ${android}/.repo/local_manifests/
    echo -e $CL_GRN "Done!" $CL_RST

    echo -e $CL_GRN "Syncing new repositories..." $CL_RST
    cd ${android}
    repo sync
    echo -e $CL_GRN "Done!" $CL_RST

    touch ${racermod}/.manifest_v1
fi


# Breakfast & clean
cd ${android}

echo -e $CL_GRN "Setting up android build enviroment..." $CL_RST
. build/envsetup.sh

echo -e $CL_GRN "breakfast ${device}..." $CL_RST
breakfast ${device}

if [ "$2" = "clean" ] || [ "$3" = "clean" ]; then
    echo -e $CL_GRN "Cleaning previous build..." $CL_RST
    make clean
    echo -e $CL_GRN "Done!" $CL_RST
fi


# Recovery build
if [ "$1" = "recovery" ] || [ "$2" = "kernel" ]; then
    echo -e $CL_GRN "Making ${image} image ..." $CL_RST
    make -j4 ${image}image

    echo -e $CL_GRN "Moving ${image}.img to racermod folder..." $CL_RST
    rm ${racermod}/cm7/${product}/${image}/gen2_${image}.img
    mv ${android}/out/target/product/${device}/${image}.img ${racermod}/cm7/${product}/${image}/gen2_${image}.img
    echo -e $CL_GRN "Done!" $CL_RST

# Normal build
else
    echo -e $CL_GRN "brunch ${device}..." $CL_RST
    brunch ${device}

    # TODO: fix package date handling
    DATE=$(date -u +%Y%m%d)
    echo -e $CL_GRN "Moving update.zip to racermod folder..." $CL_RST
    rm ${racermod}/cm7/${product}/*.zip
    mv ${android}/out/target/product/${device}/cm-7-$DATE-UNOFFICIAL-${device}.zip ${racermod}/cm7/${product}/cm-7-$DATE-UNOFFICIAL-${device}.zip
    echo -e $CL_GRN "Done!" $CL_RST
fi


# Create temp dir & integrate gen check script / libs
cd ${racermod}/cm7/${product}

echo -e $CL_GRN "Copying ${image} folder..." $CL_RST
mkdir temp
cp -r ${image} temp/${image}
echo -e $CL_GRN "Done!" $CL_RST

if [ "$1" != "recovery" ] && [ "$2" != "kernel" ]; then
    echo -e $CL_GRN "Unzipping update to temp folder & moving gen2_boot.img..." $CL_RST
    unzip cm-7-$DATE-UNOFFICIAL-${device}.zip -d temp
    rm -rf temp/META-INF
    mv temp/boot.img temp/boot/gen2_boot.img
    echo -e $CL_GRN "Done!" $CL_RST
fi

echo -e $CL_GRN "Copying META-INF folder..." $CL_RST
cp -r META-INF temp/META-INF

if [ "$2" = "kernel" ]; then
    rm -f temp/META-INF/com/google/android/updater-script
    cp boot-updater-script temp/META-INF/com/google/android/updater-script
fi
echo -e $CL_GRN "Done!" $CL_RST


# Unpack gen2_${image}.img to get the ramdisk
echo -e $CL_GRN "Unpacking gen2_${image}.img to get the ramdisk..." $CL_RST
rm ramdisk.gz
${racermod}/split_bootimg.pl temp/${image}/gen2_${image}.img
echo -e $CL_GRN "Done!" $CL_RST

# Delete gen2 zImage & rename ramdisk
rm gen2_${image}.img-kernel
mv gen2_${image}.img-ramdisk.gz ramdisk.gz


# Build gen1 kernel and create gen1_boot.img
cd ${android}/kernel/zte/msm7x27

# Setup enviroment
export ARCH=arm
export CROSS_COMPILE="ccache ${android}/prebuilt/linux-x86/toolchain/arm-eabi-4.4.3/bin/arm-eabi-"

# Racer gen1
echo -e $CL_GRN "Cleaning up & setting .version..." $CL_RST
make clean
rm .version
echo -e $CL_GRN "Done!" $CL_RST

echo -e $CL_GRN "Loading gen1 defconfig..." $CL_RST
make cyanogen_${device}_gen1_defconfig
echo -e $CL_GRN "Done!" $CL_RST

echo -e $CL_GRN "Compiling kernel..." $CL_RST
make -j4
echo -e $CL_GRN "Done!" $CL_RST

echo -e $CL_GRN "Copying zImage..." $CL_RST
rm ${racermod}/cm7/${product}/gen1zImage
cp ${android}/kernel/zte/msm7x27/arch/arm/boot/zImage ${racermod}/cm7/${product}/gen1zImage
echo -e $CL_GRN "Done!" $CL_RST

echo -e $CL_GRN "Cleaning kernel source..." $CL_RST
make mrproper
echo -e $CL_GRN "Done!" $CL_RST

cd ${racermod}/cm7/${product}

echo -e $CL_GRN "Creating gen1_boot.img..." $CL_RST
${racermod}/mkbootimg --base 0x02A00000 --cmdline 'androidboot.hardware=mooncake console=null' --kernel gen1zImage --ramdisk ramdisk.gz -o temp/boot/gen1_${image}.img
echo -e $CL_GRN "Done!" $CL_RST

# Define package name
if [ "$1" = "recovery" ]; then
    package_name="CWM-5.0.2.8"
else
    if [ "$2" = "kernel" ]; then
        package_name="RacerMod-kernel"
    else
        package_name="RacerMod"
    fi
fi

# Create new update.zip
echo -e $CL_GRN "Packing ${package_name}-${modver}-${product}.zip..." $CL_RST
cd temp
zip -r9 ${racermod}/cm7/${product}/${package_name}-${modver}-${product}.zip .
cd ..
rm -rf temp
echo -e $CL_GRN "Done!" $CL_RST

# Sign the update.zip
echo -e $CL_GRN "Signing the update zip..." $CL_RST
cd ${racermod}/cm7/${product}
java -Xmx1024m -jar ${racermod}/signapk/signapk.jar -w ${racermod}/signapk/testkey.x509.pem ${racermod}/signapk/testkey.pk8 ${package_name}-${modver}-${product}.zip ${package_name}-${modver}-${product}-signed.zip
rm ${package_name}-${modver}-${product}.zip
mv ${package_name}-${modver}-${product}-signed.zip ${package_name}-${modver}-${product}.zip
echo -e $CL_GRN "Build finished, package is ready in ${racermod}/cm7/${product}/" $CL_RST
