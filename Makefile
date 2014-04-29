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
# radix Makefile
#

include Makeconfig.mk

.PHONY: $(OBJECTS) before-build hda-img copy-kernel test test-gdb clean clean-all

PHONY: before-build $(KERNELIMG)

all: before-build copy-kernel

before-build:
	$(call check_env)
$(KERNELIMG): $(SOURCES) $(OBJECTS) $(BINDIR) $(LDSCRIPT)
	$(call print_init, Compiling objects,,WHITE)
	$(call v_exec, 1, $(MAKE) -C $(SRCDIR))
	$(call print_done, Compiling objects)
	$(call print_init, Linking $(notdir $@),,WHITE)
	$(call v_exec, 2, $(LD) $(LDFLAGS) $(OBJECTS) -o $@)
	$(call print_done, Linking $(notdir $@))
$(BINDIR):
	$(call v_exec_null, 2, mkdir -p -v $(BINDIR))
$(TESTDIR):
	$(call v_exec_null, 2, mkdir -p -v $(TESTDIR)/mnt)

	$(call v_exec_no_strip, 2, echo -e "set timeout=7" > $@/grub.cfg)
	$(call v_exec_no_strip, 2, echo -e "set default=0" >> $@/grub.cfg)
	$(call v_exec_no_strip, 2, echo -e "" >> $@/grub.cfg)
	$(call v_exec_no_strip, 2, echo -e "menuentry $(PROJECT) {" >> $@/grub.cfg)
	$(call v_exec_no_strip, 2, echo -e "   set root=(hd0,1)" >> $@/grub.cfg)
	$(call v_exec_no_strip, 2, echo -e "   multiboot2 /boot/$(notdir $(KERNELIMG))" >> $@/grub.cfg)
	$(call v_exec_no_strip, 2, echo -e "}" >> $@/grub.cfg)
$(HDAIMG): $(TESTDIR)
	$(call check_test_tools)
	$(call print_init, Creating $(notdir $(HDAIMG)),,WHITE)

	$(call print, Creating image)
	$(call v_exec, 2, fallocate -l $(HDAIMGSIZE) $(HDAIMG))

	$(call print, Partitioning)
	$(call v_exec, 2, parted --script $@ mklabel msdos mkpart primary ext4 1 100%)

	$(call print, Attaching loop device)
	$(call v_exec, 2, sudo losetup $(LOOPDEV) $@)

	$(call print, Adding partition mappings)
	$(call v_exec_null, 2, sudo kpartx -a $(LOOPDEV) -s)

	$(call print, Making ext4 file system)
	$(call v_exec_null, 2, sudo mkfs -t ext4 $(LOOPDEVPART))

	$(call print, Mounting loop device partition $(LOOPDEVPART) to $(TESTDIR)/mnt)
	$(call v_exec, 2, sudo mount $(LOOPDEVPART) $(TESTDIR)/mnt)

	$(call print, Creating GRUB folders and copying its config files)
	$(call v_exec_null, 2, sudo mkdir -p -v $(TESTDIR)/mnt/boot/grub)
	$(call v_exec_null, 2, sudo cp -u -v $(TESTDIR)/grub.cfg $(TESTDIR)/mnt/boot/grub/)

	$(call print, Installing GRUB in $@)
	$(call v_exec_null, 2, sudo grub-install --no-floppy			\
              --modules="biosdisk part_msdos ext2 configfile normal multiboot"	\
              --root-directory=$(abspath $(TESTDIR)/mnt)			\
              $(LOOPDEV))

	$(call print, Umounting loop device partition $(TESTDIR)/mnt)
	$(call v_exec, 2, sudo umount $(TESTDIR)/mnt)

	$(call print, Deleting partition mappings)
	$(call v_exec_null, 2, sudo kpartx -d $(LOOPDEV) -s)

	$(call print, Detaching $(LOOPDEV))
	$(call v_exec, 2, sudo losetup -d $(LOOPDEV))

	$(call print_done, Creating $(notdir $(HDAIMG)))
hda-img: $(HDAIMG)
copy-kernel: $(KERNELIMG) $(HDAIMG)
	$(call print_init, Copying $(notdir $(KERNELIMG)) to $(notdir $(HDAIMG)),,WHITE)

	$(call print, Attaching loop device)
	$(call v_exec, 2, sudo losetup $(LOOPDEV) $(HDAIMG))

	$(call print, Adding partition mappings)
	$(call v_exec_null, 2, sudo kpartx -a $(LOOPDEV) -s)

	$(call print, Mounting loop device partition $(LOOPDEVPART) to $(TESTDIR)/mnt)
	$(call v_exec, 2, sudo mount $(LOOPDEVPART) $(TESTDIR)/mnt)

	$(call print, Copying $(basename $(KERNELIMG)) to $(HDAIMG))
	$(call v_exec_null, 2, sudo cp -u -v $(KERNELIMG) $(TESTDIR)/mnt/boot/)

	$(call print, Umounting loop device partition $(TESTDIR)/mnt)
	$(call v_exec, 2, sudo umount $(TESTDIR)/mnt)

	$(call print, Deleting partition mappings)
	$(call v_exec_null, 2, sudo kpartx -d $(LOOPDEV) -s)

	$(call print, Detaching $(LOOPDEV))
	$(call v_exec, 2, sudo losetup -d $(LOOPDEV))

	$(call print_done, Copying $(notdir $(KERNELIMG)) to $(notdir $(HDAIMG)))
test: copy-kernel
	$(call print_init, $@)
	$(call print, Running $(QEMU))
	$(call v_exec, 2, $(QEMU) $(QEMUOPTIONS))
	$(call print_done, $@)
test-gdb: copy-kernel
	$(call print_init, $@)
	$(call print, Running $(QEMU) whit "$(QEMUOPTIONS)" options)
	$(call print, Run gdb and type -> "target remote localhost:55555")
	$(call v_exec, 2, $(QEMU) $(QEMUOPTIONS) -serial mon:stdio -gdb tcp::55555 -S)
	$(call print_done, $@)
clean:
	$(call print_init, Cleaning object files,, WHITE)
	$(call v_exec_null, 2, rm -rf -v $(OBJECTS) $(BINDIR))
	$(call v_exec, 2, sudo umount $(TESTDIR)/mnt)
	$(call print_done, Cleaning object files)
clean-all: clean
	$(call print_init, Cleaning test files,, WHITE)
	$(call v_exec_null, 2, rm -rf -v $(TESTDIR))
	$(call print_done, Cleaning test files)
