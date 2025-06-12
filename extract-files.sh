#!/bin/bash
#
# SPDX-FileCopyrightText: 2016 The CyanogenMod ProjectMore actions
# SPDX-FileCopyrightText: 2017-2024 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=selene
VENDOR=xiaomi

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

export TARGET_ENABLE_CHECKELF=true

# If XML files don't have comments before the XML header, use this flag
# Can still be used with broken XML files by using blob_fixup
export TARGET_DISABLE_XML_FIXING=true

export PATCHELF_VERSION=0_17_2

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

ONLY_FIRMWARE=
KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        --only-firmware)
            ONLY_FIRMWARE=true
            ;;
        -n | --no-cleanup)
            CLEAN_VENDOR=false
            ;;
        -k | --kang)
            KANG="--kang"
            ;;
        -s | --section)
            SECTION="${2}"
            shift
            CLEAN_VENDOR=false
            ;;
        *)
            SRC="${1}"
            ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup {
    case "${1}" in
        system_ext/priv-app/ImsService/ImsService.apk)
            [ "$2" = "" ] && return 0
            apktool_patch "${2}" "${MY_DIR}/blob-patches/ImsService.patch" -r
            ;;
	system_ext/lib64/libsink-mtk.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --add-needed "libaudioclient_shim.so" "${2}"
            ;;
        system_ext/lib64/libimsma.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "libsink.so" "libsink-mtk.so" "${2}"
            ;;
        vendor/lib*/hw/vendor.mediatek.hardware.pq@2.13-impl.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "libutils.so" "libutils-v32.so" "${2}"
            "${PATCHELF}" --replace-needed "libsensorndkbridge.so" "android.hardware.sensors@1.0-convert-shared.so" "${2}"
            ;;
        vendor/bin/hw/camerahalserver)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "libutils.so" "libutils-v32.so" "${2}"
            ;;
	vendor/bin/hw/android.hardware.gnss-service.mediatek | \
        vendor/lib64/hw/android.hardware.gnss-impl-mediatek.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "android.hardware.gnss-V1-ndk_platform.so" "android.hardware.gnss-V1-ndk.so" "${2}"
            ;;
	vendor/bin/hw/android.hardware.memtrack-service.mediatek)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "android.hardware.memtrack-V1-ndk_platform.so" "android.hardware.memtrack-V1-ndk.so" "${2}"
            ;;
        vendor/etc/init/vendor.mediatek.hardware.mtkpower@1.0-service.rc)
            [ "$2" = "" ] && return 0
            echo "$(cat ${2}) input" > "${2}"
            ;;
	vendor/etc/vintf/manifest/manifest_media_c2_V1_2_default.xml)
            [ "$2" = "" ] && return 0
	    sed -i 's/1.1/1.2/' "${2}"
            ;;
        vendor/lib64/libmnl.so)
            "${PATCHELF}" --add-needed "libcutils.so" "${2}"
            ;;
        vendor/lib64/libalLDC.so|\
        vendor/lib64/libalhLDC.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --clear-symbol-version "AHardwareBuffer_allocate" "${2}"
            "${PATCHELF}" --clear-symbol-version "AHardwareBuffer_describe" "${2}"
            "${PATCHELF}" --clear-symbol-version "AHardwareBuffer_lock" "${2}"
            "${PATCHELF}" --clear-symbol-version "AHardwareBuffer_release" "${2}"
            "${PATCHELF}" --clear-symbol-version "AHardwareBuffer_unlock" "${2}"
            ;;
        vendor/lib/libvcodec_oal.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --clear-symbol-version "__aeabi_memcpy" "${2}"
            "${PATCHELF}" --clear-symbol-version "__aeabi_memset" "${2}"
            "${PATCHELF}" --clear-symbol-version "__gnu_Unwind_Find_exidx" "${2}"
            ;;
	vendor/lib*/libmtkcam_stdutils.so|\
        vendor/lib64/hw/android.hardware.camera.provider@2.6-impl-mediatek.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "libutils.so" "libutils-v32.so" "${2}"
            ;;
        vendor/lib*/hw/audio.primary.mt6768.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "libalsautils.so" "libalsautils-v31.so" "${2}"
            ;;
        vendor/lib64/libSQLiteModule_VER_ALL.so | \
        vendor/lib64/lib3a.flash.so | \
        vendor/lib*/libteei_daemon_vfs.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --add-needed "liblog.so" "${2}"
            ;;
	vendor/bin/mnld | \
	vendor/lib*/libaalservice.so | \
	vendor/lib64/libcam.utils.sensorprovider.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "libsensorndkbridge.so" "android.hardware.sensors@1.0-convert-shared.so" "${2}"
            ;;
	vendor/bin/hw/android.hardware.media.c2@1.2-mediatek)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --add-needed "libstagefright_foundation-v33.so" "${2}"
            ;;
        vendor/lib/libnvram.so | \
        vendor/lib64/libnvram.so | \
        vendor/lib64/libsysenv.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --add-needed "libbase_shim.so" "${2}"
            ;;
        vendor/lib64/hw/hwcomposer.mt6768.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --add-needed "libprocessgroup_shim.so" "${2}"
            ;;
        system_ext/lib64/libsource.so)
            [ "$2" = "" ] && return 0
            grep -q "libui_shim.so" "${2}" || "${PATCHELF}" --add-needed "libui_shim.so" "${2}"
            ;;
        *)
            return 1
            ;;
    esac

    return 0
}

function blob_fixup_dry() {
    blob_fixup "${1}" ""
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

if [ -z "${ONLY_FIRMWARE}" ]; then
    extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
fi

if [ -z "${SECTION}" ]; then
    extract_firmware "${MY_DIR}/proprietary-firmware.txt" "${SRC}"
fi

"${MY_DIR}/setup-makefiles.sh"
