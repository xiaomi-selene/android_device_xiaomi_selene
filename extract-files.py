#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: 2024 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

from extract_utils.fixups_blob import (
    blob_fixup,
    blob_fixups_user_type,
)

from extract_utils.fixups_lib import (
    lib_fixup_remove,
    lib_fixups,
    lib_fixups_user_type,
)

from extract_utils.main import (
    ExtractUtils,
    ExtractUtilsModule,
)

import extract_utils.tools
extract_utils.tools.DEFAULT_PATCHELF_VERSION = '0_17_2'

namespace_imports = [
    'device/xiaomi/selene',
    'hardware/google/interfaces',
    'hardware/google/pixel',
    'hardware/lineage/interfaces/power-libperfmgr',
    'hardware/mediatek',
    'hardware/mediatek/libmtkperf_client',
    'hardware/mediatek/libaedv',
    'hardware/xiaomi',
]

blob_fixups: blob_fixups_user_type = {
    ('vendor/lib64/libalLDC.so', 'vendor/lib64/libalhLDC.so'): blob_fixup()
       .clear_symbol_version('AHardwareBuffer_allocate')
       .clear_symbol_version('AHardwareBuffer_describe')
       .clear_symbol_version('AHardwareBuffer_lock')
       .clear_symbol_version('AHardwareBuffer_release')
       .clear_symbol_version('AHardwareBuffer_unlock'),
    'vendor/lib64/hw/vulkan.mt6765.so' : blob_fixup()
        .clear_symbol_version('__aeabi_memcpy')
        .clear_symbol_version('__aeabi_memset')
        .clear_symbol_version('__gnu_Unwind_Find_exidx'),
    ('vendor/bin/hw/camerahalserver', 'vendor/lib64/libmtkcam_stdutils.so', 'vendor/lib64/hw/android.hardware.camera.provider@2.6-impl-mediatek.so', 'vendor/lib64/hw/vendor.mediatek.hardware.pq@2.13-impl.so'): blob_fixup()
        .replace_needed('libutils.so', 'libutils-v32.so'),
    'vendor/bin/hw/mtkfusionrild' : blob_fixup()
        .add_needed('libutils-v32.so'),
    'vendor/lib64/libmnl.so' : blob_fixup()
        .add_needed('libcutils.so'),
    ('vendor/bin/mnld', 'vendor/lib64/libaalservice.so', 'vendor/lib64/libcam.utils.sensorprovider.so', 'vendor/lib64/hw/vendor.mediatek.hardware.pq@2.13-impl.so'): blob_fixup()
        .replace_needed('libsensorndkbridge.so', 'android.hardware.sensors@1.0-convert-shared.so'),
    ('vendor/bin/hw/android.hardware.gnss-service.mediatek', 'vendor/lib64/hw/android.hardware.gnss-impl-mediatek.so'): blob_fixup()
        .replace_needed('android.hardware.gnss-V1-ndk_platform.so', 'android.hardware.gnss-V1-ndk.so'),
    'vendor/bin/hw/android.hardware.memtrack-service.mediatek' : blob_fixup()
        .replace_needed('android.hardware.memtrack-V1-ndk_platform.so', 'android.hardware.memtrack-V1-ndk.so'),
    'vendor/lib/hw/audio.primary.mt6768.so' : blob_fixup()
        .replace_needed('libalsautils.so', 'libalsautils-v31.so'),
    'vendor/lib64/hw/hwcomposer.mt6768.so' : blob_fixup()
        .add_needed('libprocessgroup_shim.so'),
    'vendor/lib64/libgoodixhwfingerprint.so' : blob_fixup()
        .replace_needed('libvendor.goodix.hardware.biometrics.fingerprint@2.1.so', 'vendor.goodix.hardware.biometrics.fingerprint@2.1.so'),
    'vendor/lib64/libvendor.goodix.hardware.biometrics.fingerprint@2.1.so' : blob_fixup()
        .replace_needed('libhidlbase.so', 'libhidlbase-v32.so'),
    ('vendor/lib64/libSQLiteModule_VER_ALL.so', 'vendor/lib64/lib3a.flash.so', 'vendor/lib/libteei_daemon_vfs.so', 'vendor/lib64/libteei_daemon_vfs.so'): blob_fixup()
        .add_needed('liblog.so'),
    ('vendor/lib/libnvram.so', 'vendor/lib64/libnvram.so', 'vendor/lib64/libsysenv.so'): blob_fixup()
        .add_needed('libbase_shim.so'),
}  # fmt: skip

module = ExtractUtilsModule(
    'selene',
    'xiaomi',
    blob_fixups=blob_fixups,
    lib_fixups=lib_fixups,
    namespace_imports=namespace_imports,
    add_firmware_proprietary_file=True,
)

if __name__ == '__main__':
    utils = ExtractUtils.device(module)
    utils.run()
