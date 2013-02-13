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
    echo -e $usage
    exit
else
    if [ "$2" != "clean" ]; then
        if [ "$2" = "kernel" ]; then
            if [ "$3" = "clean" ]; then
                echo "Building without \"make clean\"..."
            else
                echo "Kernel build"
            fi
        else
            echo "Building without \"make clean\"..."
        fi
    fi
    if [ "$1" = "recovery" ]; then
        echo "Recovery build"
        device=mooncake
        product=recovery
        image=recovery
    else
        echo "Normal build"
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
    echo "RacerMod repositories need to be synced"
    if [ -d "${android}/.repo/local_manifests" ]; then
        echo "Deleting existing local_manifests folder..."
        rm -rf ${android}/.repo/local_manifests
        echo "Done!"
    fi

    echo "Copying RacerMod manifest..."
    mkdir -p ${android}/.repo/local_manifests
    cp ${racermod}/racermod.xml ${android}/.repo/local_manifests/
    echo "Done!"

    echo "Syncing new repositories..."
    cd ${android}
    repo sync
    echo "Done!"

    touch ${racermod}/.manifest_v1
fi


# Breakfast & clean
cd ${android}

echo "Setting up android build enviroment..."
. build/envsetup.sh

echo "breakfast ${device}..."
breakfast ${device}

if [ "$2" = "clean" ] || [ "$3" = "clean" ]; then
    echo "Cleaning previous build..."
    make clean
    echo "Done!"
fi


# Recovery build
if [ "$1" = "recovery" ] || [ "$2" = "kernel" ]; then
    echo "Making ${image} image ..."
    make -j4 ${image}image

    echo "Moving ${image}.img to racermod folder..."
    rm ${racermod}/cm7/${product}/${image}/gen2_${image}.img
    mv ${android}/out/target/product/${device}/${image}.img ${racermod}/cm7/${product}/${image}/gen2_${image}.img
    echo "Done!"

# Normal build
else
    echo "brunch ${device}..."
    brunch ${device}

    # TODO: fix package date handling
    DATE=$(date -u +%Y%m%d)
    echo "Moving update.zip to racermod folder..."
    rm ${racermod}/cm7/${product}/*.zip
    mv ${android}/out/target/product/${device}/cm-7-$DATE-UNOFFICIAL-${device}.zip ${racermod}/cm7/${product}/cm-7-$DATE-UNOFFICIAL-${device}.zip
    echo "Done!"
fi


# Create temp dir & integrate gen check script / libs
cd ${racermod}/cm7/${product}

echo "Copying ${image} folder..."
mkdir temp
cp -r ${image} temp/${image}
echo "Done!"

if [ "$1" != "recovery" ]; then
    echo "Unzipping update to temp folder & moving gen2_boot.img..."
    unzip cm-7-$DATE-UNOFFICIAL-${device}.zip -d temp
    rm -rf temp/META-INF
    mv temp/boot.img temp/boot/gen2_boot.img
    echo "Done!"
fi

echo "Copying META-INF folder..."
cp -r META-INF temp/META-INF

if [ "$2" = "kernel" ]; then
    rm -f temp/META-INF/com/google/android/updater-script
    cp boot-updater-script temp/META-INF/com/google/android/updater-script
fi
echo "Done!"


# Unpack gen2_${image}.img to get the ramdisk
echo "Unpacking gen2_${image}.img to get the ramdisk..."
rm ramdisk.gz
${racermod}/split_bootimg.pl temp/${image}/gen2_${image}.img
echo "Done!"

# Delete gen2 zImage & rename ramdisk
rm gen2_${image}.img-kernel
mv gen2_${image}.img-ramdisk.gz ramdisk.gz


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
${racermod}/mkbootimg --base 0x02A00000 --cmdline 'androidboot.hardware=mooncake console=null' --kernel gen1zImage --ramdisk ramdisk.gz -o temp/boot/gen1_${image}.img
echo "Done!"

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
echo "Packing ${package_name}-${modver}-${product}.zip..."
cd temp
zip -r9 ${racermod}/cm7/${product}/${package_name}-${modver}-${product}.zip .
cd ..
rm -rf temp
echo "Done!"

# Sign the update.zip
echo "Signing the update zip..."
cd ${racermod}/cm7/${product}
java -Xmx1024m -jar ${racermod}/signapk/signapk.jar -w testkey.x509.pem testkey.pk8 ${package_name}-${modver}-${product}.zip ${package_name}-${modver}-${product}-signed.zip
rm ${package_name}-${modver}-${product}.zip
mv ${package_name}-${modver}-${product}-signed.zip ${package_name}-${modver}-${product}.zip
echo "Build finished, package is ready in ${racermod}/cm7/${product}/"
