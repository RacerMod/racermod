[RacerMod](http://mikeioannina.droid.tk) build script by mikeioannina
=====================================

Getting Started
---------------

Initialize your local repository using the CyanogenMod trees, use a command like this:

    repo init -u git://github.com/CyanogenMod/android.git -b gingerbread

Then sync up:

    repo sync

Building
---------------

First of all you need to clone this repository to ~/android/racermod/

I have created a script for easy building of RacerMod that generates update zips supporting both gen1 & gen2 versions.
You just need to execute:

    build.sh $1 $2 $3

$2 & $3 are optional

if $1 = mooncake , build for ZTE Racer

if $1 = mooncakec , build for ZTE Carl/Freddo

if $1 = recovery , build CWM recovery

if $1 = anything else , a help message is displayed

if $2 = clean , "make clean" before building

if $2 = kernel , we build only kernel

if $2 = kernel & $3 clean , we "make clean" before building

Repositories fetching
---------------

The script automatically syncs the required projects from github.
If the racermod manifest is missing or needs update, the script deletes any local manifests,
copies the racermod manifest and syncs with github.
