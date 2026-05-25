export THEOS=~/theos
export TARGET = iphone:latest:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CameraTweak
CameraTweak_FILES = Tweak.xm
CameraTweak_FRAMEWORKS = UIKit AVFoundation CoreMedia

include $(THEOS)/makefiles/tweak.mk
