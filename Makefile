APP  := Tuck
DEST := build/$(APP).app

.PHONY: all run clean install

all: $(DEST)

$(DEST): Sources/$(APP)/*.swift Resources/Info.plist Package.swift
	swift build -c release
	rm -rf $(DEST)
	mkdir -p $(DEST)/Contents/MacOS $(DEST)/Contents/Resources
	cp Resources/Info.plist $(DEST)/Contents/Info.plist
	cp .build/release/$(APP) $(DEST)/Contents/MacOS/$(APP)
	codesign --force --deep --sign - $(DEST)
	@echo "built $(DEST)"

run: all
	open $(DEST)

install: all
	rm -rf /Applications/$(APP).app
	cp -R $(DEST) /Applications/

clean:
	rm -rf .build build
