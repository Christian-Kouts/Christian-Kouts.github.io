	.globl main

	.data
KEYBOARD_EVENT_PENDING:
	.word	0x0
KEYBOARD_EVENT:
	.word   0x0
KEYBOARD_COUNTS:
	.space  128
NEWLINE:
	.asciiz "\n"
SPACE:
	.asciiz " "
	
	.eqv  LETTER_a 97
	.eqv  LETTER_space 32
	
	
	.text  
main:
# STUDENTS MAY MODIFY CODE BELOW
# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvv	
	la $s0, 0xffff0000	# control register for MMIO Simulator "Receiver"
	lb $s1, 0($s0)
	ori $s1, $s1, 0x02	# Set bit 1 to enable "Receiver" interrupts (i.e., keyboard)
	sb $s1, 0($s0)
	
check_for_event:
	la $s7, KEYBOARD_EVENT_PENDING
    	lw $s1, 0($s7)
    	beq $s1, $zero, check_for_event
	
	la $s2, KEYBOARD_EVENT
	lw $s3, ($s2)
	
	li $s6, 32
	beq $s3, $s6, check_for_event_space  #if space char dump_array()
	
	li $s4, 97
	slt $t0, $s3 ,$s4
	beq $t0, 1, check_for_event_end #brach if letter less than a
	
	li $s4, 122
	slt $t0, $s4 ,$s3
	beq $t0, 1, check_for_event_end	#branch if letter greater than z
	
	subi $s3, $s3, 97
	la $s5, KEYBOARD_COUNTS
	sll $s3, $s3, 2
	add $s5, $s5, $s3
	
	lw $s6, ($s5)
	addi $s6, $s6, 1
	sw $s6, ($s5)
	b check_for_event_end
	
check_for_event_space:
	la $a0, KEYBOARD_COUNTS
	addi $a1, $zero, 26
	jal dump_array
	
check_for_event_end:	
	li $s5, 0
	sw $s5, ($s7)	#set KEYBOARD_EVENT_PENDING back to 0 and repeat
	b check_for_event 
	
dump_array:
	move $s0, $a0
dump_array_loop:	
	lw $a0, ($s0)
	li $v0, 1
	syscall

	addi $s0, $s0, 4	#moving to next index
	subi $a1, $a1, 1	#subtracting 1 from array length
	beq $a1, $zero, dump_array_end #if last element don't print the space
	
	la $a0, SPACE
	li $v0, 4
	syscall
	
	b dump_array_loop
dump_array_end:	
	la $a0, NEWLINE
	li $v0, 4
	syscall	#if last element, append newline char
	
	jr $ra

	.kdata
	
	# No data in the kernel-data section (at present)

	.ktext 0x80000180	# Required address in kernel space for exception dispatch
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
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# STUDENTS MAY MODIFY CODE ABOVE	
