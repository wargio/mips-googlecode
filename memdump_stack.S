############################################################################
#                                                                          #
# This program is free software: you can redistribute it and/or modify     #
# it under the terms of the GNU General Public License as published by     #
# the Free Software Foundation, either version 3 of the License, or        #
# (at your option) any later version.                                      #
#                                                                          #
# This program is distributed in the hope that it will be useful,          #
# but WITHOUT ANY WARRANTY; without even the implied warranty of           #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            #
# GNU General Public License for more details.                             #
#                                                                          #
# You should have received a copy of the GNU General Public License        #
# along with this program.  If not, see <http://www.gnu.org/licenses/>.    #
#                                                                          #
# This program was created by Grazioli Giovanni Dante <wargio@libero.it>.  #
#                                                                          #
############################################################################
#                         Memdump pcSPIM/QtSPIM                            #
############################################################################

.data
.align 0
info1:		.asciiz "\nMemdump pcSPIM/QtSPIM 0.4\n[0x90000000 | -1879048192  ker]\n[0x10008000 | 268468224   data]\n[0x"
info2:		.asciiz " | "
info3:		.asciiz " stack]\n"
offstr:		.asciiz "Inserisci l'offset di partenza: "
btrstr:		.asciiz "Inserisci i bytes da leggere:   "
offstr_hex:	.asciiz "Offset di partenza: 0x"
btrstr_hex:	.asciiz "Bytes da leggere:   0x"
endl:		.asciiz "\n"
barra:		.asciiz "|"
space:		.asciiz " "
space3:		.asciiz "   "
hex:		.asciiz	"0123456789abcdef"
offset:		.asciiz	"offset      0  1  2  3  4  5  6  7   8  9  a  b  c  d  e  f"
.align 2
i2hch:		.space	8	# solo per char
.text
.globl main

jal	main					# per testarlo su mars
nop
li	$v0	10
syscall						# esci

print_str:
#IN : char* $a0
#OUT: void
	subu	$sp,	$sp,	8		# richiedo stack 2 word
	sw	$ra,	0($sp)			# salvo $ra
	sw	$v0,	4($sp)			# salvo $v0
	li	$v0,	4			# print str
	syscall					# exec
	lw	$fp,	0($sp)			# carico $ra
	lw	$v0,	4($sp)			# carico $v0
	addu	$sp,	$sp,	8		# libero stack 2 word
	jr	$fp				# return

print_int:
#IN : int $a0
#OUT: void
	subu	$sp,	$sp,	8		# richiedo stack 2 word
	sw	$ra,	0($sp)			# salvo $ra
	sw	$v0,	4($sp)			# salvo $v0
	li	$v0,	1			# print int
	syscall					# exec
	lw	$fp,	0($sp)			# carico $ra
	lw	$v0,	4($sp)			# carico $v0
	addu	$sp,	$sp,	8		# libero stack 2 word
	jr	$fp				# return

read_word:
#IN : void
#OUT: int $v0
	subu	$sp,	$sp,	4		# richiedo stack 1 word
	sw	$ra,	0($sp)			# salvo $ra
	li	$v0,	5			# read word
	syscall					# exec
	lw	$fp,	0($sp)			# carico $ra
	addu	$sp,	$sp,	4		# libero stack 1 word
	jr	$fp				# return

hex_to_char:
#IN : char* $a0, int $a1 /*value size*/, 
#OUT: void
	subu	$sp,	$sp,	16		# richiedo stack word + char[8]
	sw	$ra,	0($sp)			# salvo $ra
	sw	$a0,	4($sp)			# salvo $a0
	sw	$a1,	8($sp)			# salvo $a1
	sw	$zero,	12($sp)			# fast memset(char[4],0,4)
	
	move	$t0,	$a0			# copio $t0 = $a0
	lw	$t1,	0($t0)			# carico l'indirizzo in $t1
	addiu	$t9,	$zero,	0		# metto a 0 il contatore $t9
	
	la	$a0,	12($sp)			# carico $a0 per usarlo per stampare a schermo
	loopH2C:				# do{
		
		divu	$t7,	$t9,	4	# $t7 = $t0%4
		mfhi	$t7			# 
		
		bne	$t7,	$zero,	wordH2C	# if($t7 != 0) jump wordH2C;
			lw	$t1,	0($t0)	# else $t1 = $t0[0]
		wordH2C:			#
		
		srl	$t2,	$t1,	8	# $t2 = $t1 >> 8
		sll	$t2,	$t2,	8	# $t2 <<= 8
		subu	$t2,	$t1,	$t2	# $t2 = $t1 - $t2		
		
		blt	$t2 0x20 point		# if($t2 >= ' '){
			bgt	$t2 0x7E point	#    if($t2 <= '~'){
			j	no_point	#       jump no_point;
		point:				#    }else
			addiu	$t2 $zero 0x2E	#       $t2 = '.';
		no_point:			# }
		
		sw	$t2,	12($sp)		# salvo $t2
		
		jal	print_str		# $a0 e' stato gia' caricato dell'indirizzo
		
		addiu	$t0,	$t0,	1	# $t0++;
		addiu	$t9,	$t9,	1	# $t9++;
		srl	$t1,	$t1,	8	# $t1 >>= 8;
		
	blt	$t9,	$a1,	loopH2C		# } while($t9 < $a1);
	
	lw	$fp,	0($sp)			# carico $ra
	lw	$a0,	4($sp)			# carico $a0
	lw	$a1,	8($sp)			# carico $a1
	addu	$sp,	$sp,	16		# libero stack 1 word
	jr	$fp				# return

int_to_hex:
#IN : int $a0, int $a1 /*value size*/, 
#OUT: void
	subu	$sp,	$sp,	24		# richiedo stack word + char[9] + 3 byte per align 2
	sw	$ra,	0($sp)			# salvo $ra
	sw	$a0,	4($sp)			# salvo $a0
	sw	$a1,	8($sp)			# salvo $a1
	sw	$zero,	12($sp)			# fast memset(char[9],0,9)
	sw	$zero,	16($sp)			# 
	sb	$zero,	20($sp)			# 

	move	$t0,	$a0			
	addiu	$t1,	$zero,	0		
	addiu	$t6,	$zero,	0		
	addiu	$t8,	$zero,	0		
	la	$t7,	12($sp)

# controllo se devo usare 64 bit
	addu	$t3,	$zero,	$a1
	divu	$t3,	$t3,	2
	bne	$t3,	4,	no_64		# if $t3 != 4 goto no_64
		addiu	$t7,	$t7,	4	# aggiungo 4 all'indirizzo se 64 bit, per usare prima i 32bit a dx poi i 32 a sx
	no_64:
	addiu	$t3,	$zero,	0		# setto a 0 $t3
	loopI2H:
		srl	$t2,	$t0,	4	# $t2 = $t0 >> 4
		sll	$t2,	$t2,	4	# $t2 <<= 4
		subu	$t3,	$t0,	$t2	# $t3 = $t1 - $t2
		addu	$t9,	$zero,	$t3	# $t9 = 0
		
		# leggo il char dalla lista
		la	$t4,	hex
		addu	$t4,	$t4,	$t9
		lb	$t4,	0($t4)
		
		bne	$t6,	32,	no_sw	# if $t6 != 32 goto no_sw 64bit only
			sw	$t1,	0($t7)
			addiu	$t6,	$zero,	0
			subu	$t7,	$t7,	4
		no_sw:
		
		sll	$t1,	$t1,	8	# $t1 <<= 8
		or	$t1,	$t4,	$t1	# $t1 |= $t4
		
		addiu	$t6,	$t6,	8
		addiu	$t8,	$t8,	1
		srl	$t0,	$t0,	4
	blt	$t8,	$a1,	loopI2H		# if $t8 < $a1 goto loopH2C

	sw	$t1,	0($t7)
	move	$a0,	$t7
	jal	print_str

	lw	$fp,	0($sp)			# carico $ra
	lw	$a0,	4($sp)			# carico $a0
	lw	$a1,	8($sp)			# carico $a1
	addu	$sp,	$sp,	24		# libero stack 1 word
	jr	$fp				# return


main:
#IN : int argc, char** argv, char** envp
#OUT: void
	subu	$sp,	$sp,	16		# richiedo stack 4 word
	sw	$ra,	0($sp)			# salvo $ra
	sw	$a0,	4($sp)			# salvo $a0 (int argc)
	sw	$a1,	8($sp)			# salvo $a1 (char** argv)
	sw	$a2,	12($sp)			# salvo $a2 (char** envp)

	
	la	$a0,	info1
	jal	print_str

	move	$a0,	$sp
	addu	$a1,	$zero,	8
	jal	int_to_hex
	addiu	$a1,	$zero,	0

	la	$a0,	info2
	jal	print_str

	move	$a0,	$sp
	jal	print_int

	la	$a0,	info3
	jal	print_str


	la	$a0,	offstr
	jal	print_str

#	jal	read_word			# relase
#	addu	$s0,	$zero $v0		# relase
	addu	$s0,	$zero,	0x90000000	# debug
	
	la	$a0,	btrstr
	jal	print_str

#	jal	read_word			# relase
#	addu	$s4,	$zero,	$v0		# relase
	addu	$s4,	$zero,	0x300		# debug


	la	$a0,	offstr_hex
	jal	print_str
	addu	$a0,	$zero,	$s0
	addu	$a1,	$zero,	8
	jal	int_to_hex
	addiu	$a1,	$zero,	0
	la	$a0,	endl
	jal	print_str


	la	$a0,	btrstr_hex
	jal	print_str
	addu	$a0,	$zero $s4
	addu	$a1,	$zero 8
	jal	int_to_hex
	addiu	$a1,	$zero 0
	la	$a0,	endl
	jal	print_str


	addu	$s1,	$zero,	$s0		# $s1 serve per la stringa da 16 byte
	addiu	$s2,	$zero,	0		# variabile di conto prima dello stamp
	addiu	$s6,	$zero,	0		

	la	$a0,	offset
	jal	print_str
	la	$a0,	endl
	jal	print_str
	
#loop hexdump 
	m_loop:					# --------------------- LOOP ----------------------
		divu	$t0,	$s0,	4
		mfhi	$t0			# $t0 = $s0 % 4
		
		bne	$t0,	$zero,	no_lw	# $s7 e' la word che carico
			lw	$s7,	0($s0)
		no_lw:
		
		addi	$s6,	$s6,	8
		srlv	$t0,	$s7,	$s6
		sll	$s3,	$s3,	8
		subu	$s3,	$t0,	$s3
		
		
		bne	$s2,	0,	no_off
		#scrive l'offset
			addu	$a0,	$zero,	$s0
			addu	$a1,	$zero,	8	# specifica a int_to_hex che e' a 32bit
			jal	int_to_hex
			addiu	$a1,	$zero,	0
		#allinea il numero	
			la	$a0,	space3
			jal	print_str
		no_off:
		
		bne	$s2,	8,	m_space
			#allinea il numero	
			la	$a0,	space
			jal	print_str
		m_space:
		
		#legge la word 1
		addu	$a0,	$zero,	$s3	 # inserisco il valore di $s3 in $a0
		addu	$a1,	$zero,	2	 # specifica a int_to_hex che e' a 16bit
		jal	int_to_hex	
		la	$a0,	space
		jal	print_str




		addu	$s2,	$s2,	1
		addu	$s0,	$s0,	1

		blt	$s2,	16,	m_endl
			la	$a0,	space
			jal	print_str
			la	$a0,	barra
			jal	print_str
			addu	$a0,	$zero,	$s1
			addiu	$a1,	$zero,	0x10
			jal	hex_to_char
			la	$a0,	barra
			jal	print_str
			la	$a0,	endl
			jal	print_str
			addiu	$s2,	$zero,	0
			addiu	$s6,	$zero,	0
			addu	$s1,	$s1,	0x10
		m_endl:
		sub	$s4,	$s4,	1
	bgt	$s4,	$zero,	m_loop		# ------------------- END LOOP ---------------------

	addu	$t0,	$zero,	$s2

	beq	$s2,	0,	skip_end
		special_loop:
			la	$a0,	space3
			jal	print_str
			
			bne	$s2,	8,	not_8
				la	$a0,	space
				jal	print_str
			not_8:
			addiu	$s2,	$s2,	1
		bne	$s2,	16,	special_loop
		
		la	$a0,	space
		jal	print_str
		la	$a0,	barra
		jal	print_str
		addu	$a0,	$zero,	$s1
		addu	$a1,	$zero,	$t0
		jal	hex_to_char
		la	$a0,	barra
		jal	print_str
		la	$a0,	endl
		jal	print_str
	skip_end:


	
	lw	$fp,	0($sp)			# carico $ra
	lw	$a0,	4($sp)			# carico $a0
	lw	$a1,	8($sp)			# carico $a1
	lw	$a2,	12($sp)			# carico $a2
	addu	$sp,	$sp,	16		# libero stack 4 word
	jr	$fp				# jump $ra


