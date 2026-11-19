SHELL := /bin/bash

export HOST_UID := $(shell id -u)
export HOST_GID := $(shell id -g)
export KVM_GID  := $(shell getent group kvm | cut -d: -f3)

DC   := docker compose
EXEC := $(DC) exec dev
NAME ?= shot
# Extra emulator flags (also used to exercise the failure path of "make emulator").
EMU_ARGS ?=

.PHONY: build up down shell doctor get test analyze emulator emulator-stop android web apk \
        screenshot firebase-login rules-deploy

build:
	$(DC) build

# XAUTHORITY changes on every login, so it is read from the environment here. The wildcard-host
# copy (family ffff) lets the container authenticate to the host X server without xhost.
up:
	@test -n "$$XAUTHORITY" || { echo "XAUTHORITY is not set"; exit 1; }
	rm -f .docker.xauth
	touch .docker.xauth && chmod 600 .docker.xauth
	xauth nlist "$$DISPLAY" | sed 's/^..../ffff/' | xauth -f .docker.xauth nmerge -
	$(DC) up -d --force-recreate dev

down:
	$(DC) down

shell:
	docker compose exec -it dev bash

doctor:
	$(EXEC) flutter doctor -v

get:
	$(EXEC) flutter pub get

test:
	$(EXEC) flutter test

analyze:
	$(EXEC) flutter analyze

emulator:
	$(EXEC) bash -c 'avdmanager list avd | grep -q "Name: poc" || echo no | avdmanager create avd -n poc -k "system-images;android-34;google_apis_playstore;x86_64" -d pixel_6'
	$(DC) exec -d dev bash -c 'mkdir -p -m 700 /tmp/xdg; emulator -avd poc $(EMU_ARGS) -no-boot-anim -no-snapshot-save -gpu swiftshader_indirect -allow-host-audio > /tmp/emulator.log 2>&1'
	@# Fail fast: stop if the emulator process is gone or does not boot within 300 s.
	$(EXEC) bash -c 'end=$$((SECONDS+300)); seen=0; while [ $$SECONDS -lt $$end ]; do if pgrep -f "[q]emu-system" >/dev/null; then seen=1; elif [ $$seen = 1 ] || [ $$SECONDS -gt 20 ]; then echo "emulator died at start; tail of /tmp/emulator.log:"; tail -n 30 /tmp/emulator.log; exit 1; fi; [ "$$(timeout 10 adb shell getprop sys.boot_completed 2>/dev/null | tr -d "\r")" = "1" ] && { echo "emulator booted"; exit 0; }; sleep 3; done; echo "emulator did not boot in 300 s; tail of /tmp/emulator.log:"; tail -n 30 /tmp/emulator.log; exit 1'

emulator-stop:
	$(EXEC) adb emu kill

android:
	$(EXEC) flutter run -d emulator-5554

web:
	$(EXEC) flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080

apk:
	$(EXEC) flutter build apk --debug

screenshot:
	mkdir -p docs/screenshots
	$(DC) exec -T dev adb exec-out screencap -p > docs/screenshots/$(NAME).png.tmp
	mv docs/screenshots/$(NAME).png.tmp docs/screenshots/$(NAME).png

firebase-login:
	docker compose exec -it dev firebase login --no-localhost

rules-deploy:
	$(EXEC) firebase deploy --only firestore:rules
