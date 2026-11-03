DEV_FRAMEWORKS := $(shell xcode-select -p)/Library/Developer/Frameworks
DEV_LIB := $(shell xcode-select -p)/Library/Developer/usr/lib
TEST_FLAGS := --build-system native -Xswiftc -F -Xswiftc $(DEV_FRAMEWORKS) \
	-Xlinker -F -Xlinker $(DEV_FRAMEWORKS) -Xlinker -rpath -Xlinker $(DEV_FRAMEWORKS) -Xlinker -rpath -Xlinker $(DEV_LIB)

.PHONY: build test

build:
	swift build -c release --build-system native --product agent-session-bridge

test:
	swift test $(TEST_FLAGS)
