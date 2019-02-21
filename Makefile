
export FW_VER := 1.0.cp932

PROJ := FlashFloppy
VER := v$(FW_VER)

SUBDIRS += src bootloader reloader standalone

.PHONY: all clean flash start serial gotek

ifneq ($(RULES_MK),y)

.DEFAULT_GOAL := gotek
export ROOT := $(CURDIR)

all:
	$(MAKE) -f $(ROOT)/Rules.mk all

clean:
	rm -f bin/*.hex bin/*.upd bin/*.rld bin/*.dfu *.html
	$(MAKE) -f $(ROOT)/Rules.mk $@

gotek: export gotek=y
gotek: all
	mv FF.dfu bin/FF_Gotek-$(VER).dfu
	mv FF.upd bin/FF_Gotek-$(VER).upd
	mv FF.hex bin/FF_Gotek-$(VER).hex
	mv BL.rld bin/FF_Gotek-Bootloader-$(VER).rld
	mv RL.upd bin/FF_Gotek-Reloader-$(VER).upd
	mv ST.hex bin/FF_Gotek-Standalone-$(VER).hex
	mv ST.dfu bin/FF_Gotek-Standalone-$(VER).dfu

HXC_FF_URL := https://www.github.com/keirf/HxC_FF_File_Selector
HXC_FF_URL := $(HXC_FF_URL)/releases/download
HXC_FF_VER := v1.75-ff

dist:
	rm -rf flashfloppy-*
	mkdir -p flashfloppy-$(VER)/reloader
	$(MAKE) clean
	$(MAKE) gotek
	cp -a FF_Gotek-$(VER).dfu flashfloppy-$(VER)/
	cp -a FF_Gotek-$(VER).upd flashfloppy-$(VER)/
	cp -a FF_Gotek-$(VER).hex flashfloppy-$(VER)/
	cp -a FF_Gotek-Reloader-$(VER).upd flashfloppy-$(VER)/reloader/
	cp -a FF_Gotek-Bootloader-$(VER).rld flashfloppy-$(VER)/reloader/
	$(MAKE) clean
	cp -a COPYING flashfloppy-$(VER)/
	cp -a README.md flashfloppy-$(VER)/
	cp -a RELEASE_NOTES flashfloppy-$(VER)/
	cp -a examples flashfloppy-$(VER)/
	[ -e HxC_Compat_Mode-$(HXC_FF_VER).zip ] || \
	wget -q --show-progress $(HXC_FF_URL)/$(HXC_FF_VER)/HxC_Compat_Mode-$(HXC_FF_VER).zip
	rm -rf index.html
	unzip -q HxC_Compat_Mode-$(HXC_FF_VER).zip
	mv HxC_Compat_Mode flashfloppy-$(VER)
	zip -r flashfloppy-$(VER).zip flashfloppy-$(VER)

mrproper: clean
	rm -rf flashfloppy-*
	rm -rf HxC_Compat_Mode-$(HXC_FF_VER).zip

else

all:
	$(MAKE) -C src -f $(ROOT)/Rules.mk $(PROJ).elf $(PROJ).bin $(PROJ).hex
	nobootloader=y $(MAKE) -C standalone -f $(ROOT)/Rules.mk $(PROJ).elf $(PROJ).bin $(PROJ).hex
	bootloader=y $(MAKE) -C bootloader -f $(ROOT)/Rules.mk \
		Bootloader.elf Bootloader.bin Bootloader.hex
	reloader=y $(MAKE) -C reloader -f $(ROOT)/Rules.mk \
		Reloader.elf Reloader.bin Reloader.hex
	srec_cat bootloader/Bootloader.hex -Intel src/$(PROJ).hex -Intel \
	-o FF.hex -Intel
	cp standalone/$(PROJ).hex ST.hex
	$(PYTHON) ./scripts/mk_update.py src/$(PROJ).bin FF.upd
	$(PYTHON) ./scripts/mk_update.py bootloader/Bootloader.bin BL.rld
	$(PYTHON) ./scripts/mk_update.py reloader/Reloader.bin RL.upd
	$(PYTHON) ./scripts/dfu-convert.py -i FF.hex FF.dfu
	$(PYTHON) ./scripts/dfu-convert.py -i ST.hex ST.dfu

endif

BAUD=115200

flash:
	sudo stm32flash -b $(BAUD) -w FF_Gotek-$(VER).hex /dev/ttyUSB0

start:
	sudo stm32flash -b $(BAUD) -g 0 /dev/ttyUSB0

serial:
	sudo miniterm.py /dev/ttyUSB0 3000000
