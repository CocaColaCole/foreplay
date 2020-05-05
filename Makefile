.PHONY: all
all: builds/foreplay.love

builds/foreplay.love: main.lua conf.lua network.lua lume.lua gspot.lua resources
	zip -r $@ $^

