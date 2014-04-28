/*
 * Copyright 2014 radix Kernel
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * radix 'x86_64' ld script file
 */

OUTPUT_FORMAT("elf64-x86-64")
OUTPUT_ARCH(i386:x86-64)
ENTRY(_setup)

KERNEL_VMA = 0xFFFFFFFF80000000;
KERNEL_LMA = 0x00100000;

SECTIONS
{
	. = KERNEL_LMA;

	.mbhdr : AT(ADDR(.mbhdr) - KERNEL_VMA)
	{
		*(.mbhdr)
		. = ALIGN(0x1000);
	}

	.setup : AT(ADDR(.setup) - KERNEL_VMA)
	{
		mbl_start = .;
		*(.setup)
	}

	. += KERNEL_VMA;

	.text ALIGN(0x1000) : AT(ADDR(.text) - KERNEL_VMA)
	{
		*(.text)
	}

	.data ALIGN(0x1000) : AT(ADDR(.data) - KERNEL_VMA)
	{
		*(.data)
	}

	.rodata ALIGN(0x1000) : AT(ADDR(.rodata) - KERNEL_VMA)
	{
		*(.rodata*)
	}

	mbl_end = . - KERNEL_VMA;

	.bss ALIGN(0x1000) : AT(ADDR(.bss) - KERNEL_VMA)
	 {
		*(.bss)
		*(COMMON)
	}

	mbl_bss_end = . - KERNEL_VMA;

	/DISCARD/ :
	{
		*(.comment)
		*(.eh_frame)
	}
}
