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

# Logo
BANNER_LINK="https://img.xda-cdn.com/GsL53OqVxQLtx_Wk_kqNmL5kQN0=/https%3A%2F%2Fimg.xda-cdn.com%2FZieNkg8j34wm-l7DWWVpPdqwAXc%3D%2Fhttps%253A%252F%252Fwiki.maud.io%252Fuploads%252Ffloko-logo-banner.png"
BANNER="$HOME/logo/floko.png"
if ! [ -f "${BANNER}" ]; then
    wget $BANNER_LINK -O $BANNER
fi

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

tg_pub() {
    "${TELEGRAM}" -t "${TELEGRAM_TOKEN}" -c "${CHATID}" -T "ROM BUILD COMPLETE" -i "$BANNER" -M \
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
    curl -d '{"chat_id":${CHATID}, "text":"Build took *$((DIFF / 60))* minute(s) and *$((DIFF % 60))* second(s)!" \
            "--------------------------------------------------------------------" \
            "ROM: ${NAME}" \
            "Date: ${BUILD_DATE}" \
            "${SIZE}" \
            "MD5: ${MD5SUM}" , "reply_markup": {"inline_keyboard": [[{"text":"Download Link", "url": "https://yourlink"}]]} }' -H "Content-Type: application/json" -X POST https://api.telegram.org/bot${TELEGRAN_TOKEN}/sendMessage
    "${TELEGRAM}" -f log.txt -t "${TELEGRAM_TOKEN}" -c "${CHATID}"
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
