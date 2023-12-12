ENTRY(main);

SECTIONS {
    . = 0x80000000;
    .text : {
        *(.text)
    }

    .rodata : {
        *(.rodata)
    }

    .data : {
        *(.data)
    }

    .bss : {
        __bss_start = .;
        *(.bss)
        _end = .;
    }
}
