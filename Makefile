HOST_TRIPLET_PREFIX := arm-linux-androideabi-

CC := $(HOST_TRIPLET_PREFIX)clang
CFLAGS := -DANDROID -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16 -mthumb -Os -Wall -fPIC -ffunction-sections -fdata-sections
LDFLAGS := -fuse-ld=gold -Wl,--fix-cortex-a8 -Wl,--icf=safe -Wl,--gc-sections -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now
STRIP := $(HOST_TRIPLET_PREFIX)strip --strip-all

frida_version := 12.1.2
frida_os_arch := android-arm
FRIDA_CORE_DEVKIT_URL := https://github.com/frida/frida/releases/download/$(frida_version)/frida-core-devkit-$(frida_version)-$(frida_os_arch).tar.xz
FRIDA_GUM_DEVKIT_URL := https://github.com/frida/frida/releases/download/$(frida_version)/frida-gum-devkit-$(frida_version)-$(frida_os_arch).tar.xz

all: bin/inject bin/agent.so bin/victim

deploy: bin/inject bin/agent.so bin/victim
	adb shell "rm -rf /data/local/tmp/android-inject-example"
	adb push bin/* /data/local/tmp/android-inject-example

bin/inject: inject.c ext/frida-core/.stamp
	@mkdir -p $(@D)
	$(CC) -Wl,-pie $(CFLAGS) -I./ext/frida-core inject.c -o $@ -L./ext/frida-core -lfrida-core $(LDFLAGS)
	$(STRIP) $@

bin/agent.so: agent.c ext/frida-gum/.stamp
	@mkdir -p $(@D)
	$(CC) -shared $(CFLAGS) -I./ext/frida-gum agent.c -o $@ -L./ext/frida-gum -lfrida-gum -Wl,--version-script,agent.version $(LDFLAGS)
	$(STRIP) $@

bin/victim: victim.c
	@mkdir -p $(@D)
	$(CC) -Wl,-pie $(CFLAGS) victim.c -o $@ $(LDFLAGS)
	$(STRIP) $@

ext/frida-core/.stamp:
	@mkdir -p $(@D)
	@rm -f $(@D)/*
	curl -Ls $(FRIDA_CORE_DEVKIT_URL) | xz -d | tar -C $(@D) -xf -
	@touch $@

ext/frida-gum/.stamp:
	@mkdir -p $(@D)
	@rm -f $(@D)/*
	curl -Ls $(FRIDA_GUM_DEVKIT_URL) | xz -d | tar -C $(@D) -xf -
	@touch $@

.PHONY: all deploy
