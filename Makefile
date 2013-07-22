ARCHS = armv7
TARGET = iPhone:latest:4.3

include theos/makefiles/common.mk

TWEAK_NAME = SpringWallpaper
SpringWallpaper_FILES = Tweak.xm MFBatchRenderer.m MFGLImage.m MFShaderLoader.m MFStringRenderer.m MFGLConfig.m MFSpringSimulator.m MFOpenGLController.m MFStructs.m

SpringWallpaper_FRAMEWORKS = UIKit CoreGraphics GLKit OpenGLES QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk
