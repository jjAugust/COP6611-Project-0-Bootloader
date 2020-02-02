/*
 * Filename: boot0.S
 * Description:
 *  - Sets up the machine registers (including the stack pointers) properly
 *    for execution in 16-bit mode.
 *  - Utilizes the BIOS interrupt mechanism to output messages to the screen.
 *  - Reads the second stage bootloader from the disk into appropriate location.
 *    (boot1 is put just after MBR and before the first partition, i.e. from
 *    sector 2 to sector 63.)
 *  - Correctly transfers execution to the loaded second stage bootloader.
 */

    .globl start
start:
    /* assemble the file in 16-bit mode *

    /**
      * Clear the interrupts flag, disabling the interrupts.
      * Clear the direction flag, to configure auto-increment mode.
      */
    cli
    cld


    .code16
/*******************************************************************************
*   YOUR 16-bit CODE
*******************************************************************************/
/***Clear Segment Register***/
    movw $0x0000, %ax
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %fs
    movw %ax, %gs
    movw %ax, %ss
    
    /***Setup Stack***/
    movw $0x7bfc, %sp

    /***Setup video mode and print msg***/
    mov $0, %ah
    mov $0x3, %al
    int $0x10

    movw $STARTUP_MSG, %si
    movb $0xe, %ah
print_boot0_startup_msg:
    lodsb
    cmp $0, %al
    je print_boot0_done
    int $0x10
    jmp print_boot0_startup_msg
print_boot0_done:
    ret

    /*Jump to Boot1*/
load_boot1:
    push $0x10
    push $0
    push $62
    push $0x1
    push $0x7e00

    mov $0x0000, %eax
    mov $0x42, %ah
    mov %sp, %si
    int $0x13
    jmp 0x7e00
 
/*******************************************************************************
*   DATA STRUCTURES
*******************************************************************************/

STARTUP_MSG:
    .ascii    "Start boot0 ...\r\n\0"

LOAD_FAIL_MSG:
    .ascii    "Error during loading boot1.\r\n\0"
