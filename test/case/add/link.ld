ENTRY(_start);

SECTIONS {
    . = 0x80000000;
    .init : {
        *(.init)
    }
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
