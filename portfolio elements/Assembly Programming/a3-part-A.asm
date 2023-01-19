
	.data
ARRAY_A:
	.word	21, 210, 49, 4

#22 was initially 21
ARRAY_B:
	.word	22, -314159, 0x1000, 0x7fffffff, 3, 1, 4, 1, 5, 9, 2
ARRAY_Z:
	.space	28
NEWLINE:
	.asciiz "\n"
SPACE:
	.asciiz " "
		
	
	.text  
main:	
	la $a0, ARRAY_A
	addi $a1, $zero, 4
	jal dump_array
	
	la $a0, ARRAY_B
	addi $a1, $zero, 11
	jal dump_array
	
	la $a0, ARRAY_Z
	lw $t0, 0($a0)
	addi $t0, $t0, 1
	sw $t0, 0($a0)
	addi $a1, $zero, 9
	jal dump_array
		
	addi $v0, $zero, 10
	syscall

# STUDENTS MAY MODIFY CODE BELOW
# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
	
	
dump_array:
	#protecting $ra
	subi $sp, $sp, 4
	sw $ra, 0($sp)

	move $s0, $a0
dump_array_loop:	
	lw $a0, ($s0)
	li $v0, 1
	syscall

	addi $s0, $s0, 4	#moving to next index
	subi $a1, $a1, 1	#subtracting 1 from array length
	beq $a1, $zero, dump_array_end #if last element don't print the space
	jal print_space
	b dump_array_loop
dump_array_end:	
	jal print_nl	#if last element, append newline char
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
#Helper functions	
print_space:
	la $a0, SPACE
	li $v0, 4
	syscall
	jr $ra
	
print_nl:
	la $a0, NEWLINE
	li $v0, 4
	syscall
	jr $ra	
	
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# STUDENTS MAY MODIFY CODE ABOVE
