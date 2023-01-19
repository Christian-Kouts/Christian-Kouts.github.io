# This code assumes the use of the "Bitmap Display" tool.
#
# Tool settings must be:
#   Unit Width in Pixels: 32
#   Unit Height in Pixels: 32
#   Display Width in Pixels: 512
#   Display Height in Pixels: 512
#   Based Address for display: 0x10010000 (static data)
#
# In effect, this produces a bitmap display of 16x16 pixels.


	.include "bitmap-routines.asm"

	.data
TELL_TALE:
	.word 0x12345678 0x9abcdef0	# Helps us visually detect where our part starts in .data section
KEYBOARD_EVENT_PENDING:
	.word	0x0
KEYBOARD_EVENT:
	.word   0x0
DIAMOND_ROW:
	.word	9
DIAMOND_COLUMN:
	.word	9
	
DIAMOND_COLOUR_1:
	.word 0x00db93c0
	
	.eqv LETTER_a 97
	.eqv LETTER_d 100
	.eqv LETTER_w 119
	.eqv LETTER_s 115
	.eqv LETTER_space 32
	
	.globl main
	
	.text	
main:
# STUDENTS MAY MODIFY CODE BELOW
# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

	# initialize variables
	la $s6, 0xffff0000	# control register for MMIO Simulator "Receiver"
	lb $s7, 0($s6)
	ori $s7, $s7, 0x02	# Set bit 1 to enable "Receiver" interrupts (i.e., keyboard)
	sb $s7, 0($s6)
	
	
	la $s3, DIAMOND_ROW
	lw $a0, ($s3)
	la $s3, DIAMOND_COLUMN
	lw $a1, ($s3)
	li $a2, 0x00db93c0
	jal draw_bitmap_diamond
		
check_for_event:
	la $s0, KEYBOARD_EVENT_PENDING
    	lw $s1, 0($s0)
    	beq $s1, $zero check_for_event
    
    	la $s1, KEYBOARD_EVENT
	lw $s2, ($s1)
	
	li $s1, 32
	beq $s1, $s2, check_for_event_space
	
	li $s1, 119
	beq $s1, $s2, check_for_event_w
	
	li $s1, 97
	beq $s1, $s2, check_for_event_a
	
	li $s1, 115
	beq $s1, $s2, check_for_event_s
	
	li $s1, 100
	beq $s1, $s2, check_for_event_d
	
	b check_for_event_end
	
check_for_event_space:
	la $s3, DIAMOND_ROW
	lw $a0, ($s3)
	la $s3, DIAMOND_COLUMN
	lw $a1, ($s3)
	
	beq $a2, 0x00db93c0, check_for_event_colour_toggle
	
	li $a2, 0x00db93c0
	jal draw_bitmap_diamond
	
	b check_for_event_end
	
check_for_event_colour_toggle:
	
	li $a2, 0x00942793 
	jal draw_bitmap_diamond
	
	b check_for_event_end
	
check_for_event_w:
	move $s7, $a2
	
	la $s3, DIAMOND_COLUMN
	lw $a1, ($s3)
	la $s3, DIAMOND_ROW
	lw $a0, ($s3)
	
	li $a2, 0x0
	jal draw_bitmap_diamond
	
	lw $s4, ($s3)	#move 1 row up
	subi $s4, $s4, 1
	sw $s4, ($s3)
	
	la $s3, DIAMOND_ROW
	lw $a0, ($s3)
	la $s3, DIAMOND_COLUMN
	lw $a1, ($s3)
	move $a2, $s7 
	jal draw_bitmap_diamond
	b check_for_event_end
	
check_for_event_a:
	move $s7, $a2
	
	la $s3, DIAMOND_ROW
	lw $a0, ($s3)
	la $s3, DIAMOND_COLUMN
	lw $a1, ($s3)
	li $a2, 0x0
	jal draw_bitmap_diamond
	
	lw $s4, ($s3)	#move 1 col left
	subi $s4, $s4, 1
	sw $s4, ($s3)
	
	la $s3, DIAMOND_ROW
	lw $a0, ($s3)
	la $s3, DIAMOND_COLUMN
	lw $a1, ($s3)
	move $a2, $s7 
	jal draw_bitmap_diamond
	
	b check_for_event_end
	
check_for_event_s:
	move $s7, $a2
	
	la $s3, DIAMOND_COLUMN
	lw $a1, ($s3)
	la $s3, DIAMOND_ROW
	lw $a0, ($s3)
	li $a2, 0x0
	jal draw_bitmap_diamond
	
	lw $s4, ($s3)	#move 1 row down
	addi $s4, $s4, 1
	sw $s4, ($s3)
	
	la $s3, DIAMOND_ROW
	lw $a0, ($s3)
	la $s3, DIAMOND_COLUMN
	lw $a1, ($s3)
	move $a2, $s7 
	jal draw_bitmap_diamond
	b check_for_event_end
	
check_for_event_d:
	move $s7, $a2
	
	la $s3, DIAMOND_ROW
	lw $a0, ($s3)
	la $s3, DIAMOND_COLUMN
	lw $a1, ($s3)
	li $a2, 0x0
	jal draw_bitmap_diamond
	
	lw $s4, ($s3)	#move 1 col right
	addi $s4, $s4, 1
	sw $s4, ($s3)
	
	la $s3, DIAMOND_ROW
	lw $a0, ($s3)
	la $s3, DIAMOND_COLUMN
	lw $a1, ($s3)
	move $a2, $s7 
	jal draw_bitmap_diamond
	b check_for_event_end
	
check_for_event_end:
	li $s1, 0
	sw $s1, ($s0)	#set KEYBOARD_EVENT_PENDING back to 0 and repeat
	
	b check_for_event
	
    # Should never, *ever* arrive at this point
    # in the code.  

    addi $v0, $zero, 10

.data
    .eqv DIAMOND_COLOUR_BLACK 0x00000000

.text

    addi $v0, $zero, DIAMOND_COLOUR_BLACK
    syscall

	

draw_bitmap_diamond:
 
# You can copy-and-paste some of your code from part (c)
# to provide the procedure body.
#
	subi $sp, $sp, 4
	sw $ra, 0($sp)
    	
    	jal set_pixel
    	addi $a0, $a0, 1
    	jal set_pixel
    	addi $a0, $a0, 1
    	jal set_pixel
    	addi $a0, $a0, 1
    	jal set_pixel
	subi $a0, $a0, 4
    	jal set_pixel
    	subi $a0, $a0, 1
    	jal set_pixel
    	subi $a0, $a0, 1
    	jal set_pixel
    	addi $a0, $a0, 3
    	subi $a1, $a1, 1
    	jal set_pixel
    	subi $a0, $a0, 1
    	jal set_pixel
    	subi $a0, $a0, 1
    	jal set_pixel
    	addi $a0, $a0, 3
    	jal set_pixel
    	addi $a0, $a0, 1
    	jal set_pixel
    	subi $a1, $a1, 1
    	subi $a0, $a0, 1
    	jal set_pixel
    	subi $a0, $a0, 1
    	jal set_pixel 
    	subi $a0, $a0, 1
    	jal set_pixel
    	subi $a1, $a1, 1
    	addi $a0, $a0, 1
    	jal set_pixel
    	addi $a1, $a1, 4
    	jal set_pixel
    	addi $a0, $a0, 1
    	jal set_pixel
    	addi $a0, $a0, 1
    	jal set_pixel
    	subi $a0, $a0, 3
    	jal set_pixel
    	subi $a0, $a0, 1
    	jal set_pixel
    	addi $a1, $a1, 1
    	addi $a0, $a0, 1
    	jal set_pixel
    	addi $a0, $a0, 1
    	jal set_pixel
    	addi $a0, $a0, 1
    	jal set_pixel
    	addi $a1, $a1, 1
    	subi $a0, $a0, 1
    	jal set_pixel
    	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
    	jr $ra

	.kdata

	.ktext 0x80000180
#
# You can copy-and-paste some of your code from part (b)
# to provide elements of the interrupt handler.
#

__kernel_entry:
	mfc0 $k0, $13		# $13 is the "cause" register in Coproc0
	andi $k1, $k0, 0x7c	# bits 2 to 6 are the ExcCode field (0 for interrupts)
	srl  $k1, $k1, 2	# shift ExcCode bits for easier comparison
	beq $zero, $k1, __is_interrupt
	
__is_exception:
	# Something of a placeholder...
	# ... just in case we can't escape the need for handling some exceptions.
	beq $zero, $zero, __exit_exception
	
__is_interrupt:
	andi $k1, $k0, 0x0100	# examine bit 8
	bne $k1, $zero, __is_keyboard_interrupt	 # if bit 8 set, then we have a keyboard interrupt.
	
	beq $zero, $zero, __exit_exception	# otherwise, we return exit kernel
	
__is_keyboard_interrupt:
	la $k0, 0xffff0004
	lw $k1, 0($k0)
	la $k0, KEYBOARD_EVENT
	sw $k1, 0($k0)
	la $k0, KEYBOARD_EVENT_PENDING
	ori $k1, $zero, 1
	sw $k1, 0($k0)
	# Note: We could also take the value obtained from the "lw:
	# and store it someplace in data memory. However, to keep
	# things simple, we're using $t7 immediately above.
	
	beq $zero, $zero, __exit_exception	# Kept here in case we add more handlers.
	
__exit_exception:
	eret
.data

# Any additional .text area "variables" that you need can
# be added in this spot. The assembler will ensure that whatever
# directives appear here will be placed in memory following the
# data items at the top of this file.

    
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# STUDENTS MAY MODIFY CODE ABOVE


.eqv DIAMOND_COLOUR_WHITE 0x00FFFFFF
