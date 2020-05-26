host_arch := arm64
host_compiler_triplet := aarch64-linux-android21-
host_tool_triplet := aarch64-linux-android-
host_cflags :=
host_ldflags := -landroid

ndk_toolchain_bindir := $(ANDROID_NDK_ROOT)/toolchains/llvm/prebuilt/$(shell uname -s | tr '[A-Z]' '[a-z]')-$(shell uname -m)/bin

CC := $(ndk_toolchain_bindir)/$(host_compiler_triplet)clang
CFLAGS := -DANDROID -Os -Wall -fPIC -ffunction-sections -fdata-sections $(host_cflags)
LDFLAGS := -fuse-ld=gold -Wl,--icf=all -Wl,--gc-sections -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now $(host_ldflags)
STRIP := $(ndk_toolchain_bindir)/$(host_tool_triplet)strip --strip-all

frida_version := 12.9.4
frida_os_arch := android-$(host_arch)
frida_core_devkit_url := https://github.com/frida/frida/releases/download/$(frida_version)/frida-core-devkit-$(frida_version)-$(frida_os_arch).tar.xz
frida_gum_devkit_url := https://github.com/frida/frida/releases/download/$(frida_version)/frida-gum-devkit-$(frida_version)-$(frida_os_arch).tar.xz

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
	curl -Ls $(frida_core_devkit_url) | xz -d | tar -C $(@D) -xf -
	@touch $@

ext/frida-gum/.stamp:
	@mkdir -p $(@D)
	@rm -f $(@D)/*
	curl -Ls $(frida_gum_devkit_url) | xz -d | tar -C $(@D) -xf -
	@touch $@

.PHONY: all deploy
