.section .text.init
.global _start

_start:
    # ----------------------------------------
    # UART OUTPUT TEST
    # ----------------------------------------
    li t0, 0x10000000
    li t1, 0x58
    sb t1, 0(t0)

    # ----------------------------------------
    # STACK INITIALIZATION
    # ----------------------------------------
    lui sp, %hi(_stack_top)
    addi sp, sp, %lo(_stack_top)

    # ----------------------------------------
    # ENTER MAIN
    # ----------------------------------------
    jal ra, main

1:
    j 1b
