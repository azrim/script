#!/bin/bash
#
# Kanged From Inception



# Init Script
ROM_DEVICE=aim_ginkgo
TARGET=userdebug
ROM=aim
DEVICE=ginkgo
BUILD_START=$(date +"%s")
FOLDER=$HOME/aim
OUT=$FOLDER/out/target/product/ginkgo

TOKEN="1022672063:AAEQkscD_uo_Ls_PSofE6oCCeE0u7YaumC4"
CHAT_ID="-1001468720637"


# Color Code Script
black='\e[0;30m'        # Black
red='\e[0;31m'          # Red
green='\e[0;32m'        # Green
yellow='\e[0;33m'       # Yellow
blue='\e[0;34m'         # Blue
purple='\e[0;35m'       # Purple
cyan='\e[0;36m'         # Cyan
white='\e[0;37m'        # White
nocol='\033[0m'         # Default

# Tweakable Stuff

#COMPILATION SCRIPTS


echo -e "${green}"
echo "--------------------------------------------------------"
echo "      Cleaning environment     "
echo "--------------------------------------------------------"

cd $FOLDER
rm *.txt
rm *.url
rm $OUT/*.zip
rm $OUT/*.zip.md5sum


echo -e "$cyan***********************************************"  
echo "         Setting up Environment     "
echo -e "***********************************************$nocol"

. build/envsetup.sh
export AIM_BUILD_TYPE=HWC
export KBUILD_BUILD_USER="azrim"
export KBUILD_BUILD_HOST="BuildBot"
lunch $ROM_DEVICE-$TARGET

echo -e "$cyan***********************************************"
echo "          Building the Bitch       "
echo -e "***********************************************$nocol"

msg1=$(mktemp)
{
  echo "*Building $ROM for $DEVICE*"
  echo "Start Time: $(date +"%Y-%m-%d"-%H%M)"
  echo "Build Type: $AIM_BUILD_TYPE"
} > "${msg1}"
MESSAGE1=$(cat "$msg1")

curl -s -X POST -d chat_id=$CHAT_ID -d parse_mode=markdown -d text="$MESSAGE1" https://api.telegram.org/bot${TOKEN}/sendMessage
brunch ginkgo | tee log.txt
#mka bacon -j$(nproc --all) |  tee log.txt

if ! [ -f $OUT/*$AIM_BUILD_TYPE*.zip ]; then
    echo -e "Build compilation failed, See buildlog to fix errors"
    curl -F chat_id=$CHAT_ID -F document=@"$FOLDER/log.txt" -F caption="Build Failed, check log" https://api.telegram.org/bot${TOKEN}/sendDocument
    exit 1
fi

# If compilation was successful

echo -e "$green***********************************************"
echo "          UPLOADING    "
echo -e "***********************************************$nocol"

gd upload $OUT/*$AIM_BUILD_TYPE*.zip | tee -a gd-up.txt


echo -e "$green***********************************************"
echo "          Fetching info    "
echo -e "***********************************************$nocol"

FILEID=$(cat gd-up.txt | tail -n 1 | awk '{ print $2 }')
gd share $FILEID
gd info $FILEID | tee -a gd-info.txt
MD5SUM=$(cat gd-info.txt | grep 'Md5sum' | awk '{ print $2 }')
NAME=$(cat gd-info.txt | grep 'Name' | awk '{ print $2 }')
SIZE=$(cat gd-info.txt | grep 'Size' | awk '{ print $2 }')
DLURL=$(cat gd-info.txt | grep 'DownloadUrl' | awk '{ print $2 }')
LINKBUTTON="[GDrive]($DLURL)"

echo -e "$green***********************************************"
echo "          Copied Successfully        "
echo -e "***********************************************$nocol"



# BUILD TIME
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))


msg=$(mktemp)
{
  echo "*BUILD SUCCESS*"
  echo ""
  echo "*Build took* $(($DIFF / 60)) minutes and $(($DIFF % 60)) seconds"
  echo ""
  echo "*Name:* $NAME"
  echo "*Date:* $(date +"%Y-%m-%d")"
  echo "*Size:* $SIZE"
  echo "*MD5:* $MD5SUM"
  echo "*Link:* $LINKBUTTON"
} > "${msg}"
MESSAGE=$(cat "$msg")


curl -s -X POST -d chat_id=$CHAT_ID -d parse_mode=markdown -d text="$MESSAGE" https://api.telegram.org/bot${TOKEN}/sendMessage
curl -F chat_id=$CHAT_ID -F document=@"$FOLDER/log.txt" -F caption="log" https://api.telegram.org/bot${TOKEN}/sendDocument
#END
