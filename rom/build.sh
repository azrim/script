#!/bin/bash
# Copyrights (c) 2020 azrim.
#



# Init Script
ROM_DEVICE=lineage_ginkgo
TARGET=userdebug
ROM=floko
DEVICE=ginkgo
BUILD_START=$(date +"%s")
FOLDER=$PWD
OUT=$FOLDER/out/target/product/ginkgo

export BUILD_TYPE=OFFICIAL
TYPE=$BUILD_TYPE


TOKEN="1022672063:AAEQkscD_uo_Ls_PSofE6oCCeE0u7YaumC4"
CHAT_ID="-1001254060097"


# Color Code Script
red='\e[0;31m'          # Red
green='\e[0;32m'        # Green
yellow='\e[0;33m'       # Yellow
purple='\e[0;35m'       # Purple
cyan='\e[0;36m'         # Cyan
white='\e[0;37m'        # White
nocol='\033[0m'         # Default

# Tweakable Stuff

#COMPILATION SCRIPTS


echo -e "${red}"
echo "--------------------------------------------------------"
echo "      Cleaning environment     "
echo "--------------------------------------------------------"

cd "$FOLDER"
rm ./*.txt
rm "$OUT"/*.zip
rm "$OUT"/*.zip.md5sum


echo -e "$yellow***********************************************"  
echo "         Setting up Environment     "
echo -e "***********************************************$nocol"

. build/envsetup.sh
lunch $ROM_DEVICE-$TARGET

echo -e "$purple***********************************************"
echo "          Building the Bitch       "
echo -e "***********************************************$nocol"

msg1=$(mktemp)
{
  echo "*Building $ROM for $DEVICE*"
  echo "Start Time: $(date +"%Y-%m-%d"-%H%M)"
  echo "Build Type: $TYPE"
} > "${msg1}"
MESSAGE1=$(cat "$msg1")

curl -s -X POST -d chat_id=$CHAT_ID -d parse_mode=markdown -d text="$MESSAGE1" https://api.telegram.org/bot${TOKEN}/sendMessage
brunch ginkgo 2>&1 | tee log.txt
#mka api-stubs-docs -j24 && mka hiddenapi-lists-docs -j24 && mka system-api-stubs-docs -j24 && mka test-api-stubs-docs -j24
#mka bacon -j$(nproc --all) |  tee log.txt

if ! [ -f "$OUT"/*$TYPE*.zip ]; then
    echo -e "Build compilation failed, I will shutdown instance if @azrim89 not stop me"
    curl -F chat_id=$CHAT_ID -F document=@"$FOLDER/log.txt" -F caption="Build Failed, check log" https://api.telegram.org/bot${TOKEN}/sendDocument
    sleep 30m
    sudo shutdown -h now
fi

# If compilation was successful

echo -e "$cyan***********************************************"
echo "          UPLOADING    "
echo -e "***********************************************$nocol"

gd upload "$OUT"/*$TYPE*.zip | tee -a gd-up.txt


echo -e "$white***********************************************"
echo "          Fetching info    "
echo -e "***********************************************$nocol"

FILEID=$(cat gd-up.txt | tail -n 1 | awk '{ print $2 }')
gd share "$FILEID"
gd info "$FILEID" | tee -a gd-info.txt
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

#shutdown instance to save credits :P
sleep 30m
sudo shutdown -h now
