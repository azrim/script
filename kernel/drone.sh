#!/bin/bash
#
# Copyright (C) 2020 azrim.
# All rights reserved.

# Init
KERNEL_DIR="${PWD}"
DTB_TYPE="" # define as "single" if want use single file
KERN_IMG="${KERNEL_DIR}"/out/arch/arm64/boot/Image.gz-dtb             # if use single file define as Image.gz-dtb instead
KERN_DTB="${KERNEL_DIR}"/out/arch/arm64/boot/dtbo.img # and comment this variable
ANYKERNEL="${HOME}"/anykernel

# Repo URL
ANYKERNEL_REPO="https://github.com/azrim/kerneltemplate.git"
ANYKERNEL_BRANCH="master"

# Repo info
PARSE_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
PARSE_ORIGIN="$(git config --get remote.origin.url)"
COMMIT_POINT="$(git log --pretty=format:'%h : %s' -1)"

# Compiler
COMP_TYPE="clang" # unset if want to use gcc as compiler
CLANG_DIR="/mnt/workdir/proton-clang"
GCC_DIR="" # Doesn't needed if use proton-clang
GCC32_DIR="" # Doesn't needed if use proton-clang

if [[ "${COMP_TYPE}" =~ "clang" ]]; then
    CSTRING=$("$CLANG_DIR"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
    COMP_PATH="$CLANG_DIR/bin:${PATH}"
else
    COMP_PATH="${GCC_DIR}/bin:${GCC32_DIR}/bin:${PATH}"
fi

# Defconfig
DEFCONFIG="silont-perf_defconfig"
REGENERATE_DEFCONFIG="" # unset if don't want to regenerate defconfig

# Costumize
KERNEL="SiLonT"
DEVICE="Ginkgo"
KERNELTYPE="10"
KERNELNAME="${KERNEL}-${DEVICE}-${KERNELTYPE}-$(date +%y%m%d-%H%M)"
TEMPZIPNAME="${KERNELNAME}-unsigned.zip"
ZIPNAME="${KERNELNAME}.zip"

# Telegram
CHANNEL="-1001156668998"
CHATID="-1001468720637" # Group/channel chatid (use rose/userbot to get it)
TELEGRAM_TOKEN="1022672063:AAHZ-S-phBWflX98glW6obUKWSvwGZLmb-U"

BANNER_LINK="https://github.com/silont-project/silont-project/raw/master/Ginkgay.png"
BANNER="${TELEGRAM_FOLDER}"/logokernel.jpg
#curl -o $BANNER $BANNER_LINK

# Export Telegram.sh
TELEGRAM_FOLDER="${HOME}"/telegram
if ! [ -d "${TELEGRAM_FOLDER}" ]; then
    git clone https://github.com/fabianonline/telegram.sh/ "${TELEGRAM_FOLDER}"
fi

TELEGRAM="${TELEGRAM_FOLDER}"/telegram

tg_cast() {
    "${TELEGRAM}" -t "${TELEGRAM_TOKEN}" -c "${CHANNEL}" -H \
    "$(
		for POST in "${@}"; do
			echo "${POST}"
		done
    )"
}

tg_pub() {
    "${TELEGRAM}" -t "${TELEGRAM_TOKEN}" -c "${CHANNEL}" -i "$BANNER" -H \
    "$(
                for POST in "${@}"; do
                        echo "${POST}"
                done
    )"
}

# Regenerating Defconfig
regenerate() {
    cp out/.config arch/arm64/configs/"${DEFCONFIG}"
    git add arch/arm64/configs/"${DEFCONFIG}"
    git commit -m "defconfig: Regenerate"
}

# Building
makekernel() {
    export PATH="${COMP_PATH}"
    rm -rf "${KERNEL_DIR}"/out/arch/arm64/boot # clean previous compilation
    mkdir -p out
    make O=out ARCH=arm64 ${DEFCONFIG}
    if [[ "${REGENERATE_DEFCONFIG}" =~ "true" ]]; then
        regenerate
    fi
    if [[ "${COMP_TYPE}" =~ "clang" ]]; then
        make -j$(nproc --all) CC=clang CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- O=out ARCH=arm64  AS=llvm-as AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip
    else
      	make -j$(nproc --all) O=out ARCH=arm64 CROSS_COMPILE="${GCC_DIR}/bin/aarch64-elf-" CROSS_COMPILE_ARM32="${GCC32_DIR}/bin/arm-eabi-"
    fi
    git clone https://android.googlesource.com/platform/system/libufdt "$KERNEL_DIR"/scripts/ufdt/libufdt
    python2 "$KERNEL_DIR/scripts/ufdt/libufdt/utils/src/mkdtboimg.py" \
    create "$KERNEL_DIR/out/arch/arm64/boot/dtbo.img" --page_size=4096 "$KERNEL_DIR/out/arch/arm64/boot/dts/xiaomi/ginkgo-trinket-overlay.dtbo"
    # Check If compilation is success
    if ! [ -f "${KERN_IMG}" ]; then
        if ! [ -f "${DTBO_IMG}" ]; then
	    END=$(date +"%s")
	    DIFF=$(( END - START ))
	    echo -e "Kernel compilation failed, See buildlog to fix errors"
	    tg_cast "Build for ${DEVICE} <b>failed</b> in $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)! Check Instance for errors @azrim89"
	    ls "${KERNEL_DIR}"/out/arch/arm64/boot | tee "${KERNEL_DIR}"/ls.txt
	    "${TELEGRAM}" -f "${KERNEL_DIR}"/ls.txt -t "${TELEGRAM_TOKEN}" -c "${CHATID}"
	    exit 1
	fi
    fi
}

# Packing kranul
packingkernel() {
    # Copy compiled kernel
    if [ -d "${ANYKERNEL}" ]; then
        rm -rf "${ANYKERNEL}"
    fi
    git clone "$ANYKERNEL_REPO" -b "$ANYKERNEL_BRANCH" "${ANYKERNEL}"
    if [[ "${DTB_TYPE}" =~ "single" ]]; then
        cp "${KERN_IMG}" "${ANYKERNEL}"/Image.gz-dtb
    else
        cp "${KERN_IMG}" "${ANYKERNEL}"/Image.gz-dtb
        cp "${KERN_DTB}" "${ANYKERNEL}"/dtbo.img
    fi

    # Zip the kernel, or fail
    cd "${ANYKERNEL}" || exit
    zip -r9 "${TEMPZIPNAME}" ./*

    # Sign the zip before sending it to Telegram
    curl -sLo zipsigner-3.0.jar https://raw.githubusercontent.com/baalajimaestro/AnyKernel2/master/zipsigner-3.0.jar
    java -jar zipsigner-3.0.jar "${TEMPZIPNAME}" "${ZIPNAME}"

    # Ship it to the CI channel
    "${TELEGRAM}" -f "$ZIPNAME" -t "${TELEGRAM_TOKEN}" -c "${CHATID}"
}

# Starting
#tg_cast "test"
tg_cast "<b>$DRONE_BUILD_NUMBER CI Build Triggered</b>" \
        "Compiling with $(nproc --all) CPUs" \
        "Compiler: <code>${CSTRING}</code>" \
	"Device: ${DEVICE}" \
	"Kernel: <code>${KERNEL}</code>" \
	"Linux Version: <code>$(make kernelversion)</code>" \
	"Branch: <code>${DRONE_BRANCH}</code>" \
	"Commit point: <code>${COMMIT_POINT}</code>" \
	"Clocked at: <code>$(date +%Y%m%d-%H%M)</code>"
START=$(date +"%s")
makekernel
packingkernel
END=$(date +"%s")
DIFF=$(( END - START ))
tg_cast "Build for ${DEVICE} with ${CSTRING} <b>succeed</b> took $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)! @azrim89"
