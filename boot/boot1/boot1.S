/*
  * Filename: boot1.S

 * Description:
 * - boot1 enables the A20 line, reads the physical memory map, and
 *   configures and switches the CPU into 32-bit protected mode.
 *   Then correctly sets up the arguments on the stack and calls boot1main().
 *
 *   the memory layout at start is as described in following figure:
 *      :                              : (stack starts from here)
 *      +------------------------------+ <- BOOT0 (0x7c00)
 *      |             BOOT0            |
 *      |     (partition table)  0x55aa|
 *      +------------------------------+ <- BOOT1 
 *      |                              |
 *      |                        [smap]|
 *      +------------------------------+
 *      :                              :
 */

    /* Definitions you will use in your code below. */
    .set PROT_MODE_CSEG, 0x8     # GDT code segment selector
    .set PROT_MODE_DSEG, 0x10    # GDT data segment selector

    /* Definition used in provided code below. */
    .set SMAP_SIG, 0x0534D4150


    /* define the global start symbol, code execution will begin here. */
    .globl start
 start:
    /* assemble the following instructions in 16-bit mode */
    .code16

    cli
    cld

    /***************************************************************************
    *   YOUR 16-bit CODE
    ***************************************************************************/

    /* TODO: PRINT STARTUP MESSAGE HERE */
    mov $STARTUP_MSG, %si
    mov $0xe, %ah
print_boot1_startup_msg:
    lodsb
    cmp $0, %al
    je print_boot1_startup_done
    int $0x10
    jmp print_boot1_startup_msg
print_boot1_startup_done:
    ret

    /* enable A20
     * This is done because of a quirk in the x86 architecture.
     * See http://wiki.osdev.org/A20 for more information.
     */     
seta20.1:
    inb    $0x64, %al
    testb    $0x2, %al
    jnz    seta20.1
    movb    $0xd1, %al
    outb    %al, $0x64
seta20.2:
    inb    $0x64, %al
    testb    $0x2, %al
    jnz    seta20.2
    movb    $0xdf, %al
    outb    %al, $0x60

    /*
     * detect the physical memory map
     *
     * This code is making a series of calls to the BIOS to retrieve a map
     * of the physical memory. This is how the kernel will know what
     * memory is usable, reserved, or possibly bad.
     *
     * For more information: http://wiki.osdev.org/Detecting_Memory_(x86)
     */
e820:
    xorl    %ebx, %ebx        # ebx must be 0 when first calling e820
    movl    $SMAP_SIG, %edx   # edx must be 'SMAP' when calling e820
    movw    $(smap+4), %di    # set the address of the output buffer
e820.1:
    movl    $20, %ecx         # set the size of the output buffer
    movl    $0xe820, %eax     # set the BIOS service code
    int    $0x15              # call BIOS service e820h
e820.2:
    jc    e820.fail           # error during e820h
    cmpl    $SMAP_SIG, %eax   # check eax, which should be 'SMAP'
    jne    e820.fail
e820.3:
    movl    $20, -4(%di)
    addw    $24, %di
    cmpl    $0x0, %ebx        # whether it's the last descriptor
    je    e820.4
    jmp    e820.1
e820.4:                       # zero the descriptor after the last one
    xorb    %al, %al
    movw    $20, %cx
    rep    stosb
    jmp    switch_prot
e820.fail:
    /***************************************************************************
     * TODO: PRINT FAILURE MESSAGE HERE
     **************************************************************************/
    mov $E820_FAIL_MSG, %si
    mov $0xe, %ah
print_boot1_fail_msg:
    lodsb
    cmp $0, %al
    je print_boot1_fail_msg_done
    int $0x10
    jmp print_boot1_fail_msg
print_boot1_fail_msg_done:
    ret

    jmp    spin16

spin16:
    hlt

switch_prot:
    /***************************************************************************
    *TODO: SETUP JUMP TO PROTECTED MODE
    ***************************************************************************/
    /*Config GDT Descriptor*/
    lgdt gdtdesc
    mov %cr0, %eax
    or $1, %eax
    mov %eax, %cr0

    ljmp $PROT_MODE_CSEG, $protected_mode
    

    /* assemble the following instructions in 32-bit mode */
    .code32
    /* We are now in protected mode! */

    /***************************************************************************
    * YOUR 32-bit mode code here
    ***************************************************************************/
protected_mode:    
    /*setup the rest of the segment registers*/
    mov $PROT_MODE_DSEG, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs
    mov %ax, %ss

    /*Jump to Boot1main*/
    pushl $smap
    pushl $0x7c00
    call boot1main
    /*add $0x10, %esp*/
    

    /* It shall never reach here! */
spin:
    hlt

/*******************************************************************************
*   DATA STRUCTURES
*******************************************************************************/

STARTUP_MSG:
    .ascii    "Start boot1 ...\r\n\0"

E820_FAIL_MSG:
    .ascii    "error when detecting memory map\r\n\0"

NO_BOOTABLE_MSG:
    .ascii    "No bootable partition.\r\n\0"

    .p2align    2    /* force 4-byte alignment */



/* The Global Descriptor Table (GDT)
 *
 *
 * This data structure tells the processor where the memory segments are located.
 * We provide the GDT table entries below.
 *
 * Reference this table by using the gdt label.
 */
gdt:
    /* null segment */
    .word    0, 0
    .byte    0, 0, 0, 0

    /* code segment */
    .word    0xFFFF, 0
    .byte    0, 0x9A, 0xCF, 0

    /* data segment */
    .word    0xFFFF, 0
    .byte    0, 0x92, 0xCF, 0



/* GDT descriptor to be loaded the GDTR register */

gdtdesc:
    .word    0x27           /* limit */
    .long    gdt            /* addr */


/* reserve space for memory map */
smap:
    .space 0xc00, 0
