#
# Copyright 2014 radix Kernel
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# radix Makeconfig.mk
#

PROJECT		:= radix
ARCH		?= x86_64
TCPREFIX	?=
HOSTARCH	?= $(shell uname -m)
HOSTOS		?= $(shell echo $(shell uname) | tr A-Z a-z)

AS		?= as
CC		?= gcc
LD		?= ld
OBJCOPY		?= objcopy
GDB		?= gdb

ifneq ($(ARCH),$(HOSTARCH))
	AS := $(TCPREFIX)/$(ARCH)-$(HOSTOS)-$(AS)
	CC := $(TCPREFIX)/$(ARCH)-$(HOSTOS)-$(CC)
	LD := $(TCPREFIX)/$(ARCH)-$(HOSTOS)-$(LD)
	OBJCOPY := $(TCPREFIX)/$(ARCH)-$(HOSTOS)-$(OBJCOPY)
	GDB := $(TCPREFIX)/$(ARCH)-$(HOSTOS)-$(GDB)
endif

DIRPREFIX	?=
SRCDIR		:= $(DIRPREFIX)src
ARCHDIR		:= $(DIRPREFIX)src/arch/$(ARCH)
BUILDIR		:= $(DIRPREFIX)build
BINDIR		:= $(DIRPREFIX)bin
TESTDIR		:= $(DIRPREFIX)tests

CMDQUIET	= $(if $(V$(strip $(1))),&> /dev/null)
BASEPWD		= $(shell basename `pwd`)

KERNELIMG	:= $(BINDIR)/$(PROJECT)-image
LDSCRIPT	:= $(ARCHDIR)/ldscript.ld
LOOPDEV		:= $(shell losetup -f)
LOOPDEVPART	:= /dev/mapper/loop$(shell echo $(LOOPDEV) | awk '{print substr($$0, length($$0), 1)}')p1
HDAIMG		:= $(TESTDIR)/$(PROJECT)-hda.img
HDAIMGSIZE	:= 256M
QEMU		:= qemu-system-$(ARCH)
QEMUOPTIONS	= -hda $(HDAIMG)

SYSTOOLS	:= fallocate parted losetup kpartx mkfs grub-install sudo mount $(QEMU)
TCTOOLS		:= $(AS) $(CC) $(LD) $(OBJCOPY) $(GDB)

# Default verbose flags
V	 	?= 0
CFLAGS		:= \
		-c \
		-w \
		-ffreestanding \
		-fno-builtin \
		-fno-stack-protector \
		-nostdlib \
		-nostartfiles \
		-mno-red-zone \
		-mcmodel=large
ASFLAGS		:= --no-warn
LDFLAGS		:= -T $(LDSCRIPT) -nodefaultlibs #-z max-page-size=0x1000

ifneq (,$(filter $(V),1 2 3 4))
	ifneq (,$(findstring s,$(MAKEFLAGS)))
		override MAKEFLAGS := $(subst s,,$(MAKEFLAGS))
	endif
else
	override MAKEFLAGS += -s
endif

ifeq ($(V),1)
	override V1 :=
endif

ifeq ($(V),2)
	override V1 :=
	override V2 :=
	CFLAGS += -Wall -Wextra
	ASFLAGS := --warn
	LDFLAGS +=
endif

ifeq ($(V),3)
	override V1 :=
	override V2 :=
	override V3 :=
	CFLAGS += -Wall -Wextra -Werror
	ASFLAGS := --warn --fatal-warnings
	LDFLAGS +=
endif

ifeq ($(V),4)
	override V1 :=
	override V2 :=
	override V3 :=
	override V4 :=
	CFLAGS += -Wall -Wextra -Werror --verbose
	ASFLAGS := --warn --fatal-warnings --verbose
	LDFLAGS += --verbose
endif

V1		?= @
V2		?= @
V3		?= @
V4		?= @

# Verbose colors
COLOR	 	?= y

# \e[0;30m # Black - Regular
# \e[0;31m # Red
# \e[0;32m # Green
# \e[0;33m # Yellow
# \e[0;34m # Blue
# \e[0;35m # Purple
# \e[0;36m # Cyan
# \e[0;37m # White
# \e[1;30m # Black - Bold
# \e[1;31m # Red
# \e[1;32m # Green
# \e[1;33m # Yellow
# \e[1;34m # Blue
# \e[1;35m # Purple
# \e[1;36m # Cyan
# \e[1;37m # White
# \e[4;30m # Black - Underline
# \e[4;31m # Red
# \e[4;32m # Green
# \e[4;33m # Yellow
# \e[4;34m # Blue
# \e[4;35m # Purple
# \e[4;36m # Cyan
# \e[4;37m # White
# \e[40m   # Black - Background
# \e[41m   # Red
# \e[42m   # Green
# \e[43m   # Yellow
# \e[44m   # Blue
# \e[45m   # Purple
# \e[46m   # Cyan
# \e[47m   # White
# \e[0m    # Text Reset

# In the print* functions, use only the first name. Eg. RED, GREEN, YELLOW.
ifeq (,$(filter $(COLOR),n N))
	NO_COLOR	:= \e[0m
	BACK_COLOR	:= \e[40m
	RED_COLOR	:= \e[0;31m$(BACK_COLOR)
	GREEN_COLOR	:= \e[0;32m$(BACK_COLOR)
	YELLOW_COLOR	:= \e[0;33m$(BACK_COLOR)
	BLUE_COLOR	:= \e[0;34m$(BACK_COLOR)
	PURPLE_COLOR	:= \e[0;35m$(BACK_COLOR)
	CYAN_COLOR	:= \e[0;36m$(BACK_COLOR)
	WHITE_COLOR	:= \e[0;37m$(BACK_COLOR)
endif

# Default colors. Eg. WHITE_COLOR.
TITLE_STR_COLOR	:=
SUB_STR_COLOR	:=

# Verbose strings
LEAD_STR	:= '\> '
TRAIL_STR	:= ' \<'
LEAD_SUB_STR	:= '  +'

# Functions
# Use 'v_exec' to execute a command after strip it, through choosen verbose level
# $(1) - Verbose level (1, 2, 3, 4)
# $(2) - Command
v_exec		= $(V$(strip $(1)))$(strip $(2))

# Functions
# Use 'v_exec_no_strip' to execute a command without strip it, through choosen verbose level
# $(1) - Verbose level (1, 2, 3, 4)
# $(2) - Command
v_exec_no_strip	= $(V$(strip $(1)))$(2)

# Functions
# Use 'v_exec_null' to execute a command added by '&> /dev/null' if '$(V)' is the choosen verbose level
# $(1) - Verbose level (1, 2, 3, 4)
# $(2) - Command
v_exec_null	= $(V$(strip $(1)))$(strip $(2)) $(CMDQUIET)

# Use 'print' to print substrings with specific lead string.
# $(1) - Substring
# $(2) - Color
define print
	$(eval local_color := $(if $(strip $(2)),$($(strip $(2))_COLOR),$($(SUB_STR_COLOR))))
	@echo -e '$(local_color)$(LEAD_SUB_STR) $(strip $(1)) $(NO_COLOR)'
endef

# Use 'print_lt' to print titles between lead and trail strings.
# $(1) - Title between lead and trail strings
# $(2) - Description
# $(3) - Title region color
define print_lt
	$(eval local_color := $(if $(strip $(3)),$($(subst _COLOR,,$(strip $(3)))_COLOR),$($(TITLE_STR_COLOR))))
	@echo -e '$(local_color)$(LEAD_STR)$(strip $(1))$(TRAIL_STR)$(NO_COLOR) $(strip $(2))'
endef

# 'print_ok', 'print_warn' and 'print_error' displays defined titles between lead and trail strings.
# $(1) - Description
print_ok	= $(call print_lt, OK, $(1), GREEN)
print_warn	= $(call print_lt, WARN, $(1), YELLOW)
print_error	= $(call print_lt, ERROR, $(1), RED)

# Use 'print_init' in recipe's first line to assure the environment check.
# $(1) - Title between lead and trail strings
# $(2) - Description
# $(3) - Set title region color for all 'print_lt' calls
# $(4) - Set substrings region color for all 'print' calls
define print_init
	$(call check_env)
	$(eval TITLE_STR_COLOR := $(if $(strip $(3)),$(strip $(3))_COLOR,$(TITLE_STR_COLOR)))
	$(eval SUB_STR_COLOR := $(if $(strip $(4)),$(strip $(4))_COLOR,$(SUB_STR_COLOR)))
	$(call print_lt, $(1), $(2), $(TITLE_STR_COLOR))
endef

# Used automatically through 'print_init', however can be called from any place.
# 'check_env' exits Makefile with 'error 1' when:
#  * '$(ERROR)' is not empty, or;
#  * '$(ARCH)' is not supported, or;
#  * '$(TCTOOLS)' has a tool that wasn't found in the binary path (PATH) or,
#     if '$(TCPREFIX)', in the toolchain directory
define check_env
	$(if $(ERROR),$(call print_error, $(ERROR)); exit 1)
	$(if $(filter x86, $(ARCH)),$(call print_warn, $(PROJECT) will never support "$(ARCH)" architecture); exit 1)
	$(if $(wildcard $(ARCHDIR)),,$(call print_warn, $(PROJECT) is not still designed for "$(ARCH)" architecture); exit 1)
	$(foreach tool, $(TCTOOLS), \
		$(if $(wildcard $(if $(TCPREFIX),$(tool), \
				$(shell which $(tool) 2> /dev/null))), \
		, \
		$(call print_error, \
		Toolchain tool "$(tool)" not found. Please install it or set \
		"TCPREFIX" with the correct toolchain path.); exit 1 \
		) \
	)
endef

# Use 'check_test_tools' to check if the test tools are available in the system.
# 'check_env_test_tools' exits Makefile with 'error 1' when:
#  * '$(SYSTOOLS)' has a tool that wasn't found in the binary path (PATH).
define check_test_tools
	$(foreach tool, $(SYSTOOLS), \
		$(if $(wildcard $(shell which $(tool) 2> /dev/null)), \
		, \
		$(call print_error, System tool "$(tool)" not found. \
		Please install it or set "PATH" correctly.); exit 1 \
		) \
	)
endef

# Use 'print_done' in the last line of all recipe for maintain a pattern.
# $(1) - Title between lead and trail strings
# $(2) - Description
print_done	= $(call print_lt, $(1) $(GREEN_COLOR)DONE$(value $(TITLE_STR_COLOR)), $(2))

ASFILES		:= $(shell find $(SRCDIR) -name '*.s')
CFILES		:= $(shell find $(SRCDIR) -name '*.c')

ASFILES_SRC	:= $(filter-out $(ARCHDIR)%, $(ASFILES))
CFILES_SRC	:= $(filter-out $(ARCHDIR)%, $(CFILES))

ASFILES_ARCH	:= $(filter $(ARCHDIR)%, $(ASFILES))
CFILES_ARCH	:= $(filter $(ARCHDIR)%, $(CFILES))

SOURCES		:= $(sort $(ASFILES) $(CFILES))

SRCOBJ		:= $(patsubst %.c,%.o,$(patsubst %.s,%.o,$(ASFILES_SRC) $(CFILES_SRC)))
ARCHOBJ		:= $(patsubst %.c,%.o,$(patsubst %.s,%.o,$(ASFILES_ARCH) $(CFILES_ARCH)))

OBJECTS		:= $(sort $(patsubst %.c,%.o,$(patsubst %.s,%.o,$(SOURCES))))
