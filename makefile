build/game.love: main.lua conf.lua lib ressource thread_led_controller.lua UI
	zip -r build/game.love  main.lua conf.lua lib ressource thread_led_controller.lua UI

build/game.apk: build/game.love
	cp build/game.love ../love2apk/love_decoded/assets/
	cp ressource/AndroidManifest.xml ../love2apk/love_decoded/
	apktool b -o build/game.apk ../love2apk/love_decoded

build/game.exe: build/game.love
	cat ../love-11.3-win64/love.exe build/game.love > build/game.exe

build/game_win.zip: build/game.exe
	zip -r -j build/game_win.zip build/game.exe ../love-11.3-win64/SDL2.dll ../love-11.3-win64/OpenAL32.dll ../love-11.3-win64/license.txt ../love-11.3-win64/love.dll ../love-11.3-win64/lua51.dll ../love-11.3-win64/mpg123.dll ../love-11.3-win64/msvcp120.dll ../love-11.3-win64/msvcr120.dll

build/game-aligned-debugSigned.apk: build/game.apk
	java -jar ~/dev/prog/uber-apk-signer.jar --apks build/game.apk

clean:
	rm -f build/*.apk build/*.love build/*.exe build/*.zip

apk_install: build/game-aligned-debugSigned.apk
	adb install build/game-aligned-debugSigned.apk

apk_run: apk_install
	adb shell am force-stop org.spectre.ledmaster
	adb shell am start -n org.spectre.ledmaster/org.love2d.android.GameActivity

apk_log:
	adb logcat --pid=`adb shell pidof -s org.spectre.ledmaster`

debug_install:
	~/dev/git/adb-sync/adb-sync main.lua ressource UI conf.lua lib frame thread_led_controller.lua /sdcard/lovegame

debug_run: debug_install
	adb shell am force-stop org.love2d.android
	adb shell am start -n org.love2d.android/.GameActivity

debug_log:
	adb logcat --pid=`adb shell pidof -s org.love2d.android`

all: build/game.love build/game-aligned-debugSigned.apk build/game_win.zip


.PHONY: clean debug apk_install apk_run apk_log debug_install debug_run debug_log all
