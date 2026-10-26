ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DriveHUD
DriveHUD_FILES = Tweak.x DHLayoutEngine.m DHSpeedProvider.m DHAppLauncher.m
DriveHUD_CFLAGS = -fobjc-arc -Wall
DriveHUD_FRAMEWORKS = UIKit Foundation CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk
