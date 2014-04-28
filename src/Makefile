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
# radix src/ Makefile
#

DIRPREFIX	:= ../
include $(DIRPREFIX)Makeconfig.mk

.PHONY: before-build after-build clean

PHONY: before-build $(SRCOBJ) $(LDSCRIPT) after-build
before-build:
	$(call check_env)
	$(call v_exec, 1, $(MAKE) -C $(ARCHDIR))
	$(call print_init, Compiling $(BASEPWD) objects,, WHITE)
after-build:
	$(call print_done, Compiling $(BASEPWD) objects,, WHITE)
%.o: %.s
	$(call print, Compiling $<)
	$(call v_exec, 2, $(AS) $(ASFLAGS) --64 $< -o $@)
	$(call print, $(notdir $@) compiled, GREEN)
%.o: %.c
	$(call print, Compiling $<)
	$(call v_exec, 2, $(CC) $(CFLAGS) -m64 -I./include $< -o $@)
	$(call print, $@ compiled, GREEN)
clean:
	$(call v_exec, 1, $(MAKE) -C $(ARCHDIR) $@)
	$(call print_init, Cleaning $(BASEPWD),, WHITE)
	$(call v_exec, 2, rm -f -v $(SRCOBJ))
	$(call print_done, Cleaning $(BASEPWD))
