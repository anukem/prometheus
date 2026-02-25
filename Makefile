build:
	swift build

run: build
	mkdir -p Parchment.app/Contents/MacOS
	mkdir -p Parchment.app/Contents/Resources
	cp .build/debug/Parchment Parchment.app/Contents/MacOS/Parchment
	cp Sources/Parchment/Info.plist Parchment.app/Contents/Info.plist
	cp -r .build/debug/Parchment_Parchment.bundle Parchment.app/Contents/Resources/
	open Parchment.app

open: build
	mkdir -p Parchment.app/Contents/MacOS
	mkdir -p Parchment.app/Contents/Resources
	cp .build/debug/Parchment Parchment.app/Contents/MacOS/Parchment
	cp Sources/Parchment/Info.plist Parchment.app/Contents/Info.plist
	cp -r .build/debug/Parchment_Parchment.bundle Parchment.app/Contents/Resources/
	open -a $(PWD)/Parchment.app $(FILE)

install: build
	mkdir -p Parchment.app/Contents/MacOS
	mkdir -p Parchment.app/Contents/Resources
	cp .build/debug/Parchment Parchment.app/Contents/MacOS/Parchment
	cp Sources/Parchment/Info.plist Parchment.app/Contents/Info.plist
	cp -r .build/debug/Parchment_Parchment.bundle Parchment.app/Contents/Resources/
	cp -r Parchment.app /Applications/Parchment.app
	@echo "Installed to /Applications/Parchment.app"

clean:
	swift package clean
	rm -rf Parchment.app

.PHONY: build run clean
