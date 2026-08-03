.DELETE_ON_ERROR:

PROGRAM := Notube4meMusic
BUILD_DIR := build
GENERATED_DIR := $(BUILD_DIR)/generated
VENV := $(BUILD_DIR)/venv
MANIFEST := songs.mk
SONGS_PER_PAGE ?= 12
SONG_DURATION_SECONDS_OVERRIDE ?=
DURATION_MARGIN_SECONDS ?= -1
SHARED_ENGINE_DIR := ../../lib/gb
VERIFY_BUILD_DIR := $(BUILD_DIR)/verify-paging
VERIFY_ROM := $(VERIFY_BUILD_DIR)/$(PROGRAM).gb
VERIFY_SYM := $(VERIFY_BUILD_DIR)/$(PROGRAM).sym
VERIFY_AUTO_BUILD_DIR := $(BUILD_DIR)/verify-auto
VERIFY_AUTO_ROM := $(VERIFY_AUTO_BUILD_DIR)/$(PROGRAM).gb
VERIFY_AUTO_SYM := $(VERIFY_AUTO_BUILD_DIR)/$(PROGRAM).sym

RGBASM := rgbasm
RGBLINK := rgblink
RGBFIX := rgbfix
XM2GB := xm2gb
RUBY := ruby
RGBASM_INCLUDES := -I src/ -I $(SHARED_ENGINE_DIR)/
SOUND_ENGINE_FLAGS := \
	-D NO_SONG_SPEED_ADJUSTMENT \
	-D SOUND_ENGINE_ENABLE_PAUSE \
	-D SOUND_ENGINE_ENABLE_STOP \
	-D SOUND_ENGINE_ENABLE_SFX
SOUND_ENGINE_OBJS := \
	$(BUILD_DIR)/sound_engine.o \
	$(BUILD_DIR)/sfx.o
SOUND_ENGINE_S := $(SHARED_ENGINE_DIR)/sound-engine.s
SOUND_ENGINE_INC := $(SHARED_ENGINE_DIR)/sound-engine.inc

include $(MANIFEST)

SONG_OBJS := $(foreach song,$(SONGS),$(GENERATED_DIR)/$(song).o)
SONG_INCS := $(foreach song,$(SONGS),$(GENERATED_DIR)/$(song).inc)
SONG_SOURCE_FILES := $(foreach song,$(SONGS),\
	$($(song)_SOURCE)/Makefile \
	$($(song)_SOURCE)/$($(song)_XM) \
	$($(song)_SOURCE)/$($(song)_INSTRUMENTS) \
	$($(song)_SOURCE)/$($(song)_SONG_ASM) \
	$($(song)_SOURCE)/$($(song)_MAIN_ASM))

OBJS := \
	$(BUILD_DIR)/main.o \
	$(SOUND_ENGINE_OBJS) \
	$(SONG_OBJS)

ROM := $(BUILD_DIR)/$(PROGRAM).gb
MAP := $(BUILD_DIR)/$(PROGRAM).map
SYM := $(BUILD_DIR)/$(PROGRAM).sym

$(ROM): $(GENERATED_DIR)/sources.ok $(OBJS)
	$(RGBLINK) -n $(SYM) -m $(MAP) -o $@ $(OBJS)
	$(RGBFIX) -v -p 0xFF -m MBC5 -r 0 -t "NOTUBE4ME MUSIC" $@

$(BUILD_DIR)/main.o: src/main.s src/hardware.inc $(SOUND_ENGINE_INC) \
		src/ui/font.bin src/ui/ball.bin src/ui/udlr.bin \
		src/ui/mute.bin \
		$(GENERATED_DIR)/catalog.inc
	mkdir -p $(BUILD_DIR)
	$(RGBASM) $(RGBASM_INCLUDES) -I $(GENERATED_DIR)/ -o $@ $<

$(BUILD_DIR)/sound_engine.o: $(SOUND_ENGINE_S) $(SOUND_ENGINE_INC) src/hardware.inc Makefile
	mkdir -p $(BUILD_DIR)
	$(RGBASM) $(RGBASM_INCLUDES) $(SOUND_ENGINE_FLAGS) -o $@ $<

$(BUILD_DIR)/sfx.o: src/sfx.s
	mkdir -p $(BUILD_DIR)
	$(RGBASM) $(RGBASM_INCLUDES) -o $@ $<

$(GENERATED_DIR)/%.o: $(GENERATED_DIR)/%.s $(GENERATED_DIR)/%.inc
	$(RGBASM) $(RGBASM_INCLUDES) -o $@ $<

define SONG_RULES
$(GENERATED_DIR)/$(1).s: $($(1)_SOURCE)/$($(1)_SONG_ASM) $($(1)_SOURCE)/$($(1)_MAIN_ASM) tools/generate_song_asm.rb Makefile $(GENERATED_DIR)/$(1).inc | $(GENERATED_DIR)/sources.ok
	mkdir -p $(GENERATED_DIR)
	$(RUBY) tools/generate_song_asm.rb $(1) $($(1)_PREFIX) $($(1)_BANK) \
		$($(1)_SOURCE)/$($(1)_SONG_ASM) \
		$($(1)_SOURCE)/$($(1)_MAIN_ASM) \
		$(GENERATED_DIR)/$(1).inc $$@ \
		$(or $($(1)_SOURCE_ASSEMBLER),rgbasm)

$(GENERATED_DIR)/$(1).inc: $($(1)_SOURCE)/$($(1)_XM) $($(1)_SOURCE)/$($(1)_INSTRUMENTS) Makefile | $(GENERATED_DIR)/sources.ok
	mkdir -p $(GENERATED_DIR)
	$(XM2GB) --label-prefix=$($(1)_PREFIX) --instruments-map=$($(1)_SOURCE)/$($(1)_INSTRUMENTS) $$< > $$@
endef

$(foreach song,$(SONGS),$(eval $(call SONG_RULES,$(song))))

$(GENERATED_DIR)/sources.ok: $(MANIFEST) Makefile tools/verify_sources.rb tools/catalog_lib.rb $(SONG_SOURCE_FILES) FORCE
	mkdir -p $(GENERATED_DIR)
	$(RUBY) tools/verify_sources.rb $(MANIFEST) $@

$(GENERATED_DIR)/catalog.inc: $(MANIFEST) Makefile tools/generate_catalog_asm.rb tools/catalog_lib.rb FORCE
	mkdir -p $(GENERATED_DIR)
	$(RUBY) tools/generate_catalog_asm.rb $(MANIFEST) $(SONGS_PER_PAGE) $@ \
		$(SONG_DURATION_SECONDS_OVERRIDE)

.PHONY: all clean duration-report size-report verify verify-diff verify-env FORCE

FORCE:

all: $(ROM)

size-report: $(ROM)
	$(RUBY) tools/report_sizes.rb $(MAP)

duration-report: $(SONG_INCS)
	$(RUBY) tools/analyze_durations.rb \
		--margin-seconds=$(DURATION_MARGIN_SECONDS) $(MANIFEST) $(GENERATED_DIR)

verify-env:
	@test -d $(VENV) || python3 -m venv $(VENV)
	@$(VENV)/bin/python -c "import pyboy, numpy" 2>/dev/null || $(VENV)/bin/pip install -q pyboy numpy

verify: $(ROM) verify-env
	@$(VENV)/bin/python tools/verify_playback.py $(ROM) --sym $(SYM)
	@$(MAKE) BUILD_DIR=$(VERIFY_BUILD_DIR) SONGS_PER_PAGE=1 $(VERIFY_ROM)
	@$(VENV)/bin/python tools/verify_playback.py $(VERIFY_ROM) --sym $(VERIFY_SYM) \
		--expect-songs-per-page=1 --require-page-turn
	@$(MAKE) BUILD_DIR=$(VERIFY_AUTO_BUILD_DIR) SONG_DURATION_SECONDS_OVERRIDE=1 \
		$(VERIFY_AUTO_ROM)
	@$(VENV)/bin/python tools/verify_playback.py $(VERIFY_AUTO_ROM) \
		--sym $(VERIFY_AUTO_SYM) --require-auto-advance

verify-diff: $(ROM) verify-env tools/verify_diff.rb
	@$(RUBY) tools/verify_diff.rb $(MANIFEST) $(ROM) $(SYM) $(VENV)/bin/python

clean:
	rm -rf $(BUILD_DIR)
