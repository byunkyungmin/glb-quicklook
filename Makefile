XCODE_DIR := /Applications/Xcode.app/Contents/Developer
BUILD_DIR := build
INSTALL_DIR := $(HOME)/Applications
SCHEME := GLBQuickLook
CONFIGURATION := Release

export DEVELOPER_DIR := $(XCODE_DIR)

.PHONY: all clean install uninstall

all:
	xcodebuild -project GLBQuickLook.xcodeproj \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-derivedDataPath $(BUILD_DIR) \
		build

install: all
	@mkdir -p $(INSTALL_DIR)
	@rm -rf "$(INSTALL_DIR)/GLBQuickLook.app"
	@cp -R "$$(find $(BUILD_DIR) -name 'GLBQuickLook.app' -type d | head -1)" "$(INSTALL_DIR)/"
	@pluginkit -e use -i com.byunkyungmin.GLBQuickLook.PreviewExtension 2>/dev/null || true
	@echo ""
	@echo "==> Installed to $(INSTALL_DIR)/GLBQuickLook.app"
	@echo "==> Finder에서 .glb 파일 선택 후 스페이스바를 누르세요."

uninstall:
	@rm -rf "$(INSTALL_DIR)/GLBQuickLook.app"
	@pluginkit -e ignore -i com.byunkyungmin.GLBQuickLook.PreviewExtension 2>/dev/null || true
	@echo "==> Uninstalled."

clean:
	@rm -rf $(BUILD_DIR)
