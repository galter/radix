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
# radix 'x86_64' setup file
#

.set MULTIBOOT_HDR_MAGIC,	0xE85250D6
.set MULTIBOOT_HDR_ARCH,	0
.set MULTIBOOT_HDR_LEN,		mbhdr_end - mbhdr_start
.set MULTIBOOT_HDR_CHECKSUM,	-(MULTIBOOT_HDR_MAGIC + MULTIBOOT_HDR_ARCH + MULTIBOOT_HDR_LEN)
.set KERNEL_STACK_SIZE,		8192

# Multiboot 2 header section
# http://download-mirror.savannah.gnu.org/releases/grub/phcoder/multiboot.pdf
.section .mbhdr
.code32
.balign 8

mbhdr_start:
	# Multiboot2 header
	.long MULTIBOOT_HDR_MAGIC
	.long MULTIBOOT_HDR_ARCH
	.long MULTIBOOT_HDR_LEN
	.long MULTIBOOT_HDR_CHECKSUM


	# Tags

	# Sections override
	.word 2
	.word 0
	.long 24
	.long mbhdr_start
	.long mbl_start
	.long mbl_end
	.long mbl_bss_end

	# Entry point override
	.word 3
	.word 0
	.long 12
	.long _setup
	.long 0		# align next tag to 8 byte boundary

	# End of multiboot header tags
	.word 0		# type
	.word 0		# flags
	.long 8 	# size
mbhdr_end:

# Setup section
.section .setup
.code32
.globl _setup
_setup:
	# Cleaning screen
	xor %edi, %edi
	movl $0xb8000, %edi
	mov $2000, %ecx			# 80 columns x 25 lines = 2.000
	mov $0x0000, %ax
	cld
	rep stosw

	mov $0xcafebabe, %eax
	movw $0x0272, (0x000b8000)
	movw $0x0261, (0x000b8002)
	movw $0x0264, (0x000b8004)
	movw $0x0269, (0x000b8006)
	movw $0x0278, (0x000b8008)

	movw $0x0200, (0x000b800a)

	movw $0x024b, (0x000b800c)
	movw $0x0265, (0x000b800e)
	movw $0x0272, (0x000b8010)
	movw $0x026e, (0x000b8012)
	movw $0x0265, (0x000b8014)
	movw $0x026c, (0x000b8016)
	jmp .


# Text section
.section .text
.code64
.globl _start
_start:
	mov kstack_bottom, %rsp
	mov $0xdeadc0de, %rax
	jmp .

# Bss section (Block started by symbol)
.section .bss
.align 4
.lcomm kstack_top,		KERNEL_STACK_SIZE
.lcomm kstack_bottom,		0
