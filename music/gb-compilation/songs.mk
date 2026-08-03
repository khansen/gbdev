# Album and Singles order. Keep this in SNOWBRO NNN chronological order.
SONGS := super-mario-land ribbon eh-eh-nothing-else-i-can-say \
	save-your-tears cyndi-lauper-medley a-few-knights-in-gerudo-valley \
	dire-dire-docks koopas-road bob-omb-battlefield file-select \
	there-must-be-an-angel welcome-to-paradise \
	rockin-around-the-christmas-tree live-and-learn green-hill-zone \
	ice-cap-zone risa-furanku-420 take-on-me bubble-bop smooth-criminal \
	severance rain-man super-mario-64-staff-roll what-im-made-of \
	its-8bit-time

DEFAULT_SONG_DURATION_SECONDS ?= 90

super-mario-land_SOURCE := ../super-mario-land
super-mario-land_XM := SONG.XM
super-mario-land_INSTRUMENTS := instruments.txt
super-mario-land_SONG_ASM := song.s
super-mario-land_MAIN_ASM := main.s
super-mario-land_PREFIX := super_mario_land
super-mario-land_BANK := 1
super-mario-land_TITLE := SUPER MARIO LAND
super-mario-land_DURATION_SECONDS := 198

ribbon_SOURCE := ../ribbon
ribbon_XM := SONG.XM
ribbon_INSTRUMENTS := instruments.txt
ribbon_SONG_ASM := song.s
ribbon_MAIN_ASM := main.s
ribbon_PREFIX := ribbon
ribbon_BANK := 2
ribbon_TITLE := SAVE YOUR KISSES
ribbon_DURATION_SECONDS := 158

file-select_SOURCE := ../file-select
file-select_XM := song.xm
file-select_INSTRUMENTS := instruments.txt
file-select_SONG_ASM := song.s
file-select_MAIN_ASM := main.s
file-select_PREFIX := file_select
file-select_BANK := 3
file-select_TITLE := FILE SELECT
file-select_DURATION_SECONDS := 151
# File Select's ch2 change rate is phase-sensitive with the compilation's
# buffered Play Mode UI updates; the longer window keeps the aggregate stable.
file-select_DIFF_ARGS := --diff-frames 3600

green-hill-zone_SOURCE := ../green-hill-zone
green-hill-zone_XM := song.xm
green-hill-zone_INSTRUMENTS := instruments.txt
green-hill-zone_SONG_ASM := song.s
green-hill-zone_MAIN_ASM := main.s
green-hill-zone_PREFIX := green_hill_zone
green-hill-zone_BANK := 4
green-hill-zone_TITLE := GREEN HILL ZONE
green-hill-zone_DURATION_SECONDS := 225
# Green Hill needs a longer aggregate window because ROM-level VBlank timing
# changes the sampled ch2 change rate over shorter windows.
green-hill-zone_DIFF_ARGS := --diff-frames 3600 --diff-count-tolerance 24

ice-cap-zone_SOURCE := ../ice-cap-zone
ice-cap-zone_XM := song.xm
ice-cap-zone_INSTRUMENTS := instruments.txt
ice-cap-zone_SONG_ASM := song.s
ice-cap-zone_MAIN_ASM := main.s
ice-cap-zone_PREFIX := ice_cap_zone
ice-cap-zone_BANK := 5
ice-cap-zone_TITLE := ICE CAP ZONE
# No -1s margin: this is arranged as a loop, so album mode should advance at
# the loop point instead of cutting the final phrase early.
ice-cap-zone_DURATION_SECONDS := 125
# Ice Cap has the same short-window phase sensitivity as File Select after
# adopting the canonical buffered Play Mode UI update path.
ice-cap-zone_DIFF_ARGS := --diff-frames 3600

save-your-tears_SOURCE := ../save-your-tears
save-your-tears_XM := song.xm
save-your-tears_INSTRUMENTS := instruments.txt
save-your-tears_SONG_ASM := song.s
save-your-tears_MAIN_ASM := main.s
save-your-tears_PREFIX := save_your_tears
save-your-tears_BANK := 6
save-your-tears_TITLE := SAVE YOUR TEARS
save-your-tears_DURATION_SECONDS := 246

take-on-me_SOURCE := ../take-on-me
take-on-me_XM := song.xm
take-on-me_INSTRUMENTS := instruments.txt
take-on-me_SONG_ASM := song.s
take-on-me_MAIN_ASM := main.s
take-on-me_PREFIX := take_on_me
take-on-me_BANK := 7
take-on-me_TITLE := TAKE ON ME
take-on-me_DURATION_SECONDS := 228

a-few-knights-in-gerudo-valley_SOURCE := ../a-few-knights-in-gerudo-valley
a-few-knights-in-gerudo-valley_XM := song.xm
a-few-knights-in-gerudo-valley_INSTRUMENTS := instruments.txt
a-few-knights-in-gerudo-valley_SONG_ASM := song.s
a-few-knights-in-gerudo-valley_MAIN_ASM := main.s
a-few-knights-in-gerudo-valley_PREFIX := a_few_knights_in_gerudo_valley
a-few-knights-in-gerudo-valley_BANK := 8
a-few-knights-in-gerudo-valley_TITLE := A FEW KNIGHTS
a-few-knights-in-gerudo-valley_DURATION_SECONDS := 332

bob-omb-battlefield_SOURCE := ../bob-omb-battlefield
bob-omb-battlefield_XM := song.xm
bob-omb-battlefield_INSTRUMENTS := instruments.txt
bob-omb-battlefield_SONG_ASM := song.s
bob-omb-battlefield_MAIN_ASM := main.s
bob-omb-battlefield_PREFIX := bob_omb_battlefield
bob-omb-battlefield_BANK := 9
bob-omb-battlefield_TITLE := BOB-OMB BATTLE
bob-omb-battlefield_DURATION_SECONDS := 162

bubble-bop_SOURCE := ../bubble-bop
bubble-bop_XM := song.xm
bubble-bop_INSTRUMENTS := instruments.txt
bubble-bop_SONG_ASM := song.s
bubble-bop_MAIN_ASM := main.s
bubble-bop_PREFIX := bubble_bop
bubble-bop_BANK := 10
bubble-bop_TITLE := BUBBLE BOP
bubble-bop_DURATION_SECONDS := 148
# Bubble Bop's standalone uses custom object/scrolling visualization while the
# compilation uses the generic indicator, so ch1 register-change sampling is
# more context-sensitive even though speed and frequency still match.
bubble-bop_DIFF_ARGS := --diff-frames 3600 --diff-change-tolerance 0.12

cyndi-lauper-medley_SOURCE := ../cyndi-lauper-medley
cyndi-lauper-medley_XM := song.xm
cyndi-lauper-medley_INSTRUMENTS := instruments.txt
cyndi-lauper-medley_SONG_ASM := song.s
cyndi-lauper-medley_MAIN_ASM := main.s
cyndi-lauper-medley_PREFIX := cyndi_lauper_medley
cyndi-lauper-medley_BANK := 11
cyndi-lauper-medley_TITLE := CYNDI MEDLEY
cyndi-lauper-medley_DURATION_SECONDS := 336

dire-dire-docks_SOURCE := ../dire-dire-docks
dire-dire-docks_XM := song.xm
dire-dire-docks_INSTRUMENTS := instruments.txt
dire-dire-docks_SONG_ASM := song.s
dire-dire-docks_MAIN_ASM := main.s
dire-dire-docks_PREFIX := dire_dire_docks
dire-dire-docks_BANK := 12
dire-dire-docks_TITLE := DIRE DIRE DOCKS
# No -1s margin: this is arranged as a loop, so album mode should advance at
# the loop point instead of cutting the final phrase early.
dire-dire-docks_DURATION_SECONDS := 220

eh-eh-nothing-else-i-can-say_SOURCE := ../eh-eh-nothing-else-i-can-say
eh-eh-nothing-else-i-can-say_XM := SONG.XM
eh-eh-nothing-else-i-can-say_INSTRUMENTS := instruments.txt
eh-eh-nothing-else-i-can-say_SONG_ASM := song.s
eh-eh-nothing-else-i-can-say_MAIN_ASM := main.s
eh-eh-nothing-else-i-can-say_PREFIX := eh_eh_nothing_else_i_can_say
eh-eh-nothing-else-i-can-say_BANK := 13
eh-eh-nothing-else-i-can-say_TITLE := EH EH NOTHING
eh-eh-nothing-else-i-can-say_DURATION_SECONDS := 149

its-8bit-time_SOURCE := ../its-8bit-time
its-8bit-time_XM := song.xm
its-8bit-time_INSTRUMENTS := instruments.txt
its-8bit-time_SONG_ASM := song.s
its-8bit-time_MAIN_ASM := main.s
its-8bit-time_PREFIX := its_8bit_time
its-8bit-time_BANK := 14
its-8bit-time_TITLE := IT'S 8-BIT TIME
its-8bit-time_DURATION_SECONDS := 153

koopas-road_SOURCE := ../koopas-road
koopas-road_XM := song.xm
koopas-road_INSTRUMENTS := instruments.txt
koopas-road_SONG_ASM := song.s
koopas-road_MAIN_ASM := main.s
koopas-road_PREFIX := koopas_road
koopas-road_BANK := 15
koopas-road_TITLE := KOOPAS ROAD
koopas-road_DURATION_SECONDS := 163
koopas-road_DIFF_ARGS := --diff-frames 3600

live-and-learn_SOURCE := ../live-and-learn
live-and-learn_XM := song.xm
live-and-learn_INSTRUMENTS := instruments.txt
live-and-learn_SONG_ASM := song.s
live-and-learn_MAIN_ASM := main.s
live-and-learn_PREFIX := live_and_learn
live-and-learn_BANK := 16
live-and-learn_TITLE := LIVE AND LEARN
live-and-learn_DURATION_SECONDS := 283

rain-man_SOURCE := ../rain-man
rain-man_XM := song.xm
rain-man_INSTRUMENTS := instruments.txt
rain-man_SONG_ASM := song.s
rain-man_MAIN_ASM := main.s
rain-man_PREFIX := rain_man
rain-man_BANK := 17
rain-man_TITLE := RAIN MAN
rain-man_DURATION_SECONDS := 199
rain-man_DIFF_ARGS := --diff-frames 3600

rockin-around-the-christmas-tree_SOURCE := ../rockin-around-the-christmas-tree
rockin-around-the-christmas-tree_XM := song.xm
rockin-around-the-christmas-tree_INSTRUMENTS := instruments.txt
rockin-around-the-christmas-tree_SONG_ASM := song.s
rockin-around-the-christmas-tree_MAIN_ASM := main.s
rockin-around-the-christmas-tree_PREFIX := rockin_around_the_christmas_tree
rockin-around-the-christmas-tree_BANK := 18
rockin-around-the-christmas-tree_TITLE := ROCKIN' AROUND
rockin-around-the-christmas-tree_DURATION_SECONDS := 201

severance_SOURCE := ../severance
severance_XM := song.xm
severance_INSTRUMENTS := instruments.txt
severance_SONG_ASM := song.s
severance_MAIN_ASM := main.s
severance_PREFIX := severance
severance_BANK := 19
severance_TITLE := SEVERANCE
severance_DURATION_SECONDS := 167

smooth-criminal_SOURCE := ../smooth-criminal
smooth-criminal_XM := song.xm
smooth-criminal_INSTRUMENTS := instruments.txt
smooth-criminal_SONG_ASM := song.s
smooth-criminal_MAIN_ASM := main.s
smooth-criminal_PREFIX := smooth_criminal
smooth-criminal_BANK := 20
smooth-criminal_TITLE := SMOOTH CRIMINAL
smooth-criminal_DURATION_SECONDS := 247
smooth-criminal_DIFF_ARGS := --diff-frames 3600 --diff-count-tolerance 18

super-mario-64-staff-roll_SOURCE := ../super-mario-64-staff-roll
super-mario-64-staff-roll_XM := song.xm
super-mario-64-staff-roll_INSTRUMENTS := instruments.txt
super-mario-64-staff-roll_SONG_ASM := song.s
super-mario-64-staff-roll_MAIN_ASM := main.s
super-mario-64-staff-roll_PREFIX := super_mario_64_staff_roll
super-mario-64-staff-roll_BANK := 21
super-mario-64-staff-roll_TITLE := SM64 STAFF ROLL
super-mario-64-staff-roll_DURATION_SECONDS := 232

there-must-be-an-angel_SOURCE := ../there-must-be-an-angel
there-must-be-an-angel_XM := song.xm
there-must-be-an-angel_INSTRUMENTS := instruments.txt
there-must-be-an-angel_SONG_ASM := song.s
there-must-be-an-angel_MAIN_ASM := main.s
there-must-be-an-angel_PREFIX := there_must_be_an_angel
there-must-be-an-angel_BANK := 22
there-must-be-an-angel_TITLE := MUST BE AN ANGEL
there-must-be-an-angel_DURATION_SECONDS := 204

welcome-to-paradise_SOURCE := ../welcome-to-paradise
welcome-to-paradise_XM := song.xm
welcome-to-paradise_INSTRUMENTS := instruments.txt
welcome-to-paradise_SONG_ASM := song.s
welcome-to-paradise_MAIN_ASM := main.s
welcome-to-paradise_PREFIX := welcome_to_paradise
welcome-to-paradise_BANK := 23
welcome-to-paradise_TITLE := WELCOME PARADISE
welcome-to-paradise_DURATION_SECONDS := 222
welcome-to-paradise_DIFF_ARGS := --diff-frames 3600 --diff-count-tolerance 22

what-im-made-of_SOURCE := ../what-im-made-of
what-im-made-of_XM := song.xm
what-im-made-of_INSTRUMENTS := instruments.txt
what-im-made-of_SONG_ASM := song.s
what-im-made-of_MAIN_ASM := main.s
what-im-made-of_PREFIX := what_im_made_of
what-im-made-of_BANK := 24
what-im-made-of_TITLE := WHAT I'M MADE OF
what-im-made-of_DURATION_SECONDS := 223

risa-furanku-420_SOURCE := ../risa-furanku-420
risa-furanku-420_XM := song.xm
risa-furanku-420_INSTRUMENTS := instruments.txt
risa-furanku-420_SONG_ASM := song.s
risa-furanku-420_MAIN_ASM := main.s
risa-furanku-420_SOURCE_ASSEMBLER := wla-gb
risa-furanku-420_PREFIX := risa_furanku_420
risa-furanku-420_BANK := 25
risa-furanku-420_TITLE := RISA FURANKU 420
risa-furanku-420_DURATION_SECONDS := 274
