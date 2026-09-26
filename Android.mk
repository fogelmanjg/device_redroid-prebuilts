
LOCAL_PATH := $(call my-dir)

# $(1): module name; required
# $(2): module stem name if non-empty
# $(3): source file name 
# $(4): relative install dir
# $(5): create symbolic links
# $(6): depend modules
define define-redroid-prebuilt-lib
include $$(CLEAR_VARS)
LOCAL_MODULE := $1
ifneq ($2,)
LOCAL_INSTALLED_MODULE_STEM := $2
endif

ifneq ($3,)
src := $3
else
src := $1
endif
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES_$$(TARGET_ARCH) := prebuilts/$$(TARGET_ARCH)/lib/$$(src)
ifneq ($$(TARGET_2ND_ARCH),)
LOCAL_SRC_FILES_$$(TARGET_2ND_ARCH) := prebuilts/$$(TARGET_2ND_ARCH)/lib/$$(src)
endif
#LOCAL_STRIP_MODULE := false
LOCAL_MODULE_SUFFIX := .so
LOCAL_MODULE_RELATIVE_PATH := $4
LOCAL_MULTILIB := both
LOCAL_PROPRIETARY_MODULE := true
LOCAL_MODULE_SYMLINKS := $5
LOCAL_CHECK_ELF_FILES := false
LOCAL_REQUIRED_MODULES := $6
include $$(BUILD_PREBUILT)
endef


# $(1): module name; required
# $(2): module stem name if non-empty
# $(3): source file name 
# $(4): relative install dir
# $(5): create symbolic links
# $(6): depend modules
define define-redroid-prebuilt-etc
include $$(CLEAR_VARS)
LOCAL_MODULE := $1
ifneq ($2,)
LOCAL_INSTALLED_MODULE_STEM := $2
endif

ifneq ($3,)
src := $3
else
src := $1
endif
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := prebuilts/$$(TARGET_ARCH)/share/$$(src)
LOCAL_MODULE_RELATIVE_PATH := $4
LOCAL_PROPRIETARY_MODULE := true
LOCAL_MODULE_SYMLINKS := $5
LOCAL_REQUIRED_MODULES := $6
include $$(BUILD_PREBUILT)
endef


# NDK libs
ndk_libs_cxx := libc++_shared
libs := $(ndk_libs_cxx)
$(foreach lib,$(libs),\
    $(eval $(call define-redroid-prebuilt-lib,$(lib)_p,$(lib).so,$(lib).so)))


# DRI
dri_libs := libgallium_dri
drv_libs := libgallium_drv_video
ifneq (,$(filter $(TARGET_ARCH),x86 x86_64))
# "Baklava" is this branch's PLATFORM_VERSION during Android 16 development
# (a codename, not yet the numeric "16") - added alongside 15/16 so this
# skip still fires and doesn't collide with external/intel-media-driver's
# own iHD_drv_video build (MODULE.TARGET.SHARED_LIBRARIES.iHD_drv_video
# already defined by external/intel-media-driver).
ifeq (,$(filter $(PLATFORM_VERSION), 15 16 Baklava))
$(eval $(call define-redroid-prebuilt-lib,libigdgmm,,libigdgmm.so))
drv_libs_intel := i965_drv_video iHD_drv_video
$(foreach lib,$(drv_libs_intel),\
    $(eval $(call define-redroid-prebuilt-lib,$(lib),,dri/$(lib).so,dri,,libigdgmm)))

drv_libs += $(drv_libs_intel)
endif
endif
dri_links := $(shell cd $(LOCAL_PATH)/prebuilts/$(TARGET_ARCH)/lib/dri && find * -name '*_dri.so' -type l)
drv_links := $(shell cd $(LOCAL_PATH)/prebuilts/$(TARGET_ARCH)/lib/dri && find * -name '*_drv_video.so' -type l)
$(eval $(call define-redroid-prebuilt-lib,libgallium_dri,,dri/libgallium_dri.so,dri,$(dri_links)))
$(eval $(call define-redroid-prebuilt-lib,libgallium_drv_video,,dri/libgallium_drv_video.so,dri,$(drv_links)))


## amdgpu.ids
$(eval $(call define-redroid-prebuilt-etc,amdgpu.ids.redroid,,libdrm/amdgpu.ids,hwdata))


# libs with SOVERSION
gbm_libs := libgbm.so.1
glapi_libs := libglapi.so.0
libs = $(gbm_libs) $(glapi_libs)
drm_libs := $(shell cd $(LOCAL_PATH)/prebuilts/$(TARGET_ARCH)/lib && find * -name 'libdrm*.so.*' -type l)
libs += $(drm_libs)
$(foreach lib,$(libs),\
    $(eval $(call define-redroid-prebuilt-lib,$(lib),$(lib))))


## VA
ifeq (,$(filter $(PLATFORM_VERSION), 15 16))
va_libs := libva.so.2 libva-drm.so.2
$(foreach lib,$(va_libs),\
    $(eval $(call define-redroid-prebuilt-lib,$(lib),$(lib),,,,$(drv_libs) $(drm_libs))))
endif


## LLVM
llvm_libs := $(shell cd $(LOCAL_PATH)/prebuilts/$(TARGET_ARCH)/lib && find * -name 'libLLVM*' -type f)
llvm_libs := $(llvm_libs:.so=)
$(foreach lib,$(llvm_libs),\
    $(eval $(call define-redroid-prebuilt-lib,$(lib),,$(lib).so)))


# GLES
libs := libEGL_mesa libGLESv1_CM_mesa libGLESv2_mesa
$(foreach lib,$(libs),\
    $(eval $(call define-redroid-prebuilt-lib,$(lib),,egl/$(lib).so,egl,,\
		$(dri_libs) $(glapi_libs) $(drm_libs))))


# Vulkan
vulkan_libs := $(shell cd $(LOCAL_PATH)/prebuilts/$(TARGET_ARCH)/lib/hw && find * -name 'libvulkan_*.so' -type f)
$(foreach lib,$(vulkan_libs),\
	$(eval $(call define-redroid-prebuilt-lib,$(lib:libvulkan_%.so=vulkan.%),,hw/$(lib),hw,,$(ndk_libs_cxx:%=%_p))))


# minigbm gralloc
$(eval $(call define-redroid-prebuilt-lib,gralloc.cros,,hw/gralloc.cros.so,hw))


# gbm gralloc
$(eval $(call define-redroid-prebuilt-lib,gralloc.gbm,,hw/gralloc.gbm.so,hw,,$(gbm_libs)))


# redroid audio
$(eval $(call define-redroid-prebuilt-lib,audio.primary.redroid,,hw/audio.primary.redroid.so,hw))


# redroid hwcomposer
$(eval $(call define-redroid-prebuilt-lib,hwcomposer.redroid,,hw/hwcomposer.redroid.so,hw))


## libOmxCore
$(eval $(call define-redroid-prebuilt-lib,libOmxCore,,libOmxCore.so, , ,$(va_libs) ))


## libevdev
evdev_libs := libevdev.so.2
$(foreach lib,$(evdev_libs),\
    $(eval $(call define-redroid-prebuilt-lib,$(lib),$(lib))))


## libvncserver
vncserver_libs := libvncserver
$(eval $(call define-redroid-prebuilt-lib,$(vncserver_libs),,$(vncserver_libs).so))

# $(1): module name (and file name)
# $(2): depended modules
# $(3): init.rc
define define-redroid-prebuilt-bin
include $$(CLEAR_VARS)
LOCAL_MODULE := $1
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_SRC_FILES_$$(TARGET_ARCH) := prebuilts/$$(TARGET_ARCH)/bin/$1
#LOCAL_STRIP_MODULE := false
LOCAL_MULTILIB := first
LOCAL_MODULE_TAGS := optional
LOCAL_PROPRIETARY_MODULE := true
LOCAL_CHECK_ELF_FILES := false
LOCAL_REQUIRED_MODULES := $2
ifneq ($3,)
LOCAL_INIT_RC := prebuilts/$$(TARGET_ARCH)/share/$3
endif
include $$(BUILD_PREBUILT)
endef

# vaapi
ifeq (,$(filter $(PLATFORM_VERSION), 15 16))
bins:=avcenc h264encode hevcencode jpegenc vp8enc vp9enc vainfo
$(foreach i,$(bins),\
    $(eval $(call define-redroid-prebuilt-bin,$(i),$(va_libs))))
endif

$(eval $(call define-redroid-prebuilt-bin,uinputd,$(evdev_libs),uinputd/uinputd.rc))

$(eval $(call define-redroid-prebuilt-bin,vncserver,$(vncserver_libs),vncserver/vncserver.rc))


# NDK translation (ARM-on-x86_64 native bridge). Extracted from a known-working
# erstt-based redroid 15 build since the upstream AOSP redroid device tree does
# not ship this proprietary Google component.
#
# Installed to /system (NOT /vendor) on purpose: the extracted binfmt_misc
# registration files and ro.dalvik.vm.native.bridge property both hardcode
# /system/... paths (copied as-is from the known-working erstt image), so
# these modules must NOT set LOCAL_PROPRIETARY_MODULE (which the shared
# define-redroid-prebuilt-* macros above default to true, installing to
# /vendor instead — confirmed broken by testing: binfmt_misc registered fine,
# but the kernel found nothing at /system/bin/ndk_translation_program_runner_binfmt_misc_arm64
# at actual exec time since the real file had landed in /vendor/bin/).
define define-redroid-prebuilt-lib-64
include $$(CLEAR_VARS)
LOCAL_MODULE := $1
ifneq ($2,)
LOCAL_INSTALLED_MODULE_STEM := $2
endif
ifneq ($3,)
src := $3
else
src := $1
endif
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES_$$(TARGET_ARCH) := prebuilts/$$(TARGET_ARCH)/lib/$$(src)
LOCAL_MODULE_SUFFIX := .so
LOCAL_MODULE_RELATIVE_PATH := $4
LOCAL_MULTILIB := 64
LOCAL_CHECK_ELF_FILES := false
include $$(BUILD_PREBUILT)
endef

define define-redroid-prebuilt-bin-system
include $$(CLEAR_VARS)
LOCAL_MODULE := $1
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_SRC_FILES_$$(TARGET_ARCH) := prebuilts/$$(TARGET_ARCH)/bin/$1
LOCAL_MULTILIB := first
LOCAL_MODULE_TAGS := optional
LOCAL_CHECK_ELF_FILES := false
ifneq ($2,)
LOCAL_INIT_RC := prebuilts/$$(TARGET_ARCH)/share/$2
endif
include $$(BUILD_PREBUILT)
endef

define define-redroid-prebuilt-etc-system
include $$(CLEAR_VARS)
LOCAL_MODULE := $1
ifneq ($2,)
src := $2
else
src := $1
endif
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := prebuilts/$$(TARGET_ARCH)/share/$$(src)
LOCAL_MODULE_RELATIVE_PATH := $3
include $$(BUILD_PREBUILT)
endef

ndk_translation_proxy_libs := $(shell cd $(LOCAL_PATH)/prebuilts/$(TARGET_ARCH)/lib && find * -maxdepth 0 -name 'libndk_translation_proxy_*.so' -type f)
$(foreach lib,$(ndk_translation_proxy_libs),\
    $(eval $(call define-redroid-prebuilt-lib-64,$(lib:.so=),,$(lib))))

$(eval $(call define-redroid-prebuilt-lib-64,libndk_translation,,libndk_translation.so))
# libndk_translation.so dlopens this berberis exec-region companion at runtime
# (not a DT_NEEDED). Without it, native bridge init aborts with
# 'Couldn't load "/system/lib64/libberberis_exec_region.so"'.
# NOTE: now provided by frameworks/libs/binary_translation/exec_region (built from
# source via native_bridge_support.mk) - do not redeclare as a prebuilt here, it
# collides with that module (MODULE.TARGET.SHARED_LIBRARIES.libberberis_exec_region
# already defined).
# libnative_bridge_vdso.so is an ARM64 (guest-arch) binary, not an x86_64 host
# library, so it can't go through the normal Soong prebuilt SHARED_LIBRARIES
# module (which disables it due to the arch mismatch). Installed as a plain
# file via PRODUCT_COPY_FILES in device.mk instead.

$(eval $(call define-redroid-prebuilt-bin-system,ndk_translation_program_runner_binfmt_misc_arm64,ndk_translation/ndk_translation.rc))

binfmt_misc_files := arm_exe arm_dyn arm64_exe arm64_dyn
$(foreach f,$(binfmt_misc_files),\
    $(eval $(call define-redroid-prebuilt-etc-system,$(f),binfmt_misc/$(f),binfmt_misc)))
