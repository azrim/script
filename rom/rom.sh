#!/bin/bash
# Copyrights (c) 2020 azrim.
#

# Init
FOLDER="${PWD}"
OUT="${FOLDER}/out/target/product/ginkgo"

# ROM
ROMNAME="FlokoROM"                   # This is for filename
ROM="lineage"                        # This is for build
DEVICE="ginkgo"
TARGET="user"
VERSIONING="FLOKO_BUILD_TYPE"
VERSION="OFFICIAL"
CLEANING=""                          # set "clean" for make clean, "clobber" for make clean && make clobber, don't set for dirty build

# TELEGRAM
CHATID=""                            # Group/channel chatid (use rose/userbot to get it)
TELEGRAM_TOKEN=""                    # Get from botfather

# Export Telegram.sh
TELEGRAM_FOLDER="${HOME}"/telegram
if ! [ -d "${TELEGRAM_FOLDER}" ]; then
    git clone https://github.com/fabianonline/telegram.sh/ "${TELEGRAM_FOLDER}"
fi

TELEGRAM="${TELEGRAM_FOLDER}"/telegram

tg_cast() {
    "${TELEGRAM}" -t "${TELEGRAM_TOKEN}" -c "${CHATID}" -H \
    "$(
		for POST in "${@}"; do
			echo "${POST}"
		done
    )"
}

# cleaning env
cleanup() {
    if [ -f "$OUT"/*.zip ]; then
        rm "$OUT"/*.zip
    fi
    if [ -f gd-up.txt ]; then
        rm gd-up.txt
    fi
    if [ -f gd-info.txt ]; then
        rm gd-info.txt
    fi
    if [[ "${CLEANING}" =~ "clean" ]]; then
        make clean
	build
    elif [[ "${CLEANING}" =~ "clobber" ]]; then
        make clean && make clobber
	build
    else
        build
    fi
}

# Build
build() {
    export "${VERSIONING}"="${VERSION}"
    source build/envsetup.sh
    lunch "${ROM}"_"${DEVICE}"-"${TARGET}"
    brunch "${DEVICE}" 2>&1 | tee log.txt
}

# Checker
check() {
    if ! [ -f "$OUT"/*$VERSION*.zip ]; then
        END=$(date +"%s")
        DIFF=$(( END - START ))
        tg_cast "${ROMNAME} Build for ${DEVICE} <b>failed</b> in $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)!" \
	        "Check log below"
        "${TELEGRAM}" -f log.txt -t "${TELEGRAM_TOKEN}" -c "${CHATID}"
	self_destruct
    else
        gdrive
    fi
}

# Self destruct
self_destruct() {
    tg_cast "I will shutdown myself in 30m, catch me if you can :P"
    sleep 30m
    sudo shutdown -h now
}

# Gdrive
gdrive() {
    gd upload "$OUT"/*$VERSION*.zip | tee -a gd-up.txt
    FILEID=$(cat gd-up.txt | tail -n 1 | awk '{ print $2 }')
    gd share "$FILEID"
    gd info "$FILEID" | tee -a gd-info.txt
    MD5SUM=$(cat gd-info.txt | grep 'Md5sum' | awk '{ print $2 }')
    NAME=$(cat gd-info.txt | grep 'Name' | awk '{ print $2 }')
    SIZE=$(cat gd-info.txt | grep 'Size' | awk '{ print $2 }')
    DLURL=$(cat gd-info.txt | grep 'DownloadUrl' | awk '{ print $2 }')
    success
}

# done
success() {
    END=$(date +"%s")
    DIFF=$(( END - START ))
    curl -H "Content-Type: application/json" -X POST -d '{"chat_id":${CHATID}, "text":"<b>ROM Build Completed Successfully</b>\nBuild took $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)!\n------------------------------------------------\nROM: <code>${ROMNAME}</code> ${DEVICE} ${VERSION}\nFilename: ${NAME}\nDate: ${BUILD_DATE}\nSize: <code>${SIZE}</code>\nMD5: <code>${MD5SUM}</code>, "reply_markup": {"inline_keyboard": [[{"text":"Download", "url": ${DLURL}}]]} }' https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage
    self_destruct
}

# Let's start
BUILD_DATE="$(date)"
START=$(date +"%s")
tg_cast "<b>STARTING ROM BUILD</b>" \
        "ROM: <code>${ROMNAME}</code>" \
        "Device: ${DEVICE}" \
        "Version: <code>${VERSION}</code>" \
        "Build Start: <code>${BUILD_DATE}</code>"
cleanup
check
