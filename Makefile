LOVE_ANDROID = ${HOME}/srcbuilds/love-android/
.PHONY: all
all: builds/foreplay.love builds/foreplay.apk

builds/foreplay.love: main.lua conf.lua network.lua lume.lua gspot.lua resources
	zip -r $@ $^

builds/foreplay.apk: builds/foreplay.love AndroidManifest.xml
	mkdir -p $(LOVE_ANDROID)/love_decoded/assets
	cp $< $(LOVE_ANDROID)/love_decoded/assets/game.love
	cp AndroidManifest.xml $(LOVE_ANDROID)/love_decoded/
	cd $(LOVE_ANDROID) && \
	apktool b -o foreplay.apk love_decoded && \
	signapk.sh foreplay.apk
	mv $(LOVE_ANDROID)/signed_foreplay.apk $@
