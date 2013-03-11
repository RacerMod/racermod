#!/sbin/sh
check_gen1=`cat /proc/mtd | grep "mtd1: 0048"`
if [ "$check_gen1" != "" ]
then
    echo "generation=1" > /tmp/gen.prop
else
    echo "generation=2" > /tmp/gen.prop
fi
