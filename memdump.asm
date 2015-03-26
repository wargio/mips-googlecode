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
#                             Memdump pcSPIM                               #
############################################################################
.data
.align 0
info:		.asciiz "\n\nMemdump pcSPIM 0.3\n[0x90000000 | -1879048192  ker]\n[0x10008000 | 268468224   data]\n[0x7ffff000 | 2147479552 stack]\n"
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
h2cch:		.space	8	# solo per char
i2hch:		.space	8	# solo per char
.text
j	main

exit:
	la	$a0 endl	# print END LINE
	jal	print_str	
	li	$v0 10		# set to exit
	syscall			# exec

print_str:			# $a0 = char*
	li	$v0 4		# set to print
	syscall			# exec
	jr	$ra

read_word:			# $v0 = int
	li	$v0 5		# read
	syscall			# exec
	jr	$ra

# ------------------------------------------- Usato per debugging ------------------------------------------
print_int:			# $a0 = int
	li	$v0 1		# set to print
	syscall			# exec
	jr	$ra
	
# -------------------------------------------- HEX TO CHAR -------------------------------------------------
hex_to_char:
# $a0	indirizzo dei 16 byte (non modificabile)
# $a2	numero di byte da leggere (non modificabile)
# $t0	indirizzo dei 16 byte ($a0) modificabile
# $t1	word dell'indirizzo ($a0)
# $t2	veriabile temporanea usata per gestire il char
# $t9	contatore i
	move	$t0 $a0
	lw	$t1 0($t0)
	addiu	$t9 $zero 0
	la	$a0 h2cch
	sw	$zero 4($a0)
	loopH2C:
		divu	$t7 $t0 4
		mfhi	$t7		# $t7 = $t0%4
		
		bne	$t7 $zero wordH2C
			lw	$t1 0($t0)
		wordH2C:
		
		srl	$t2 $t1 8	# $t2 = $t1 >> 8
		sll	$t2 $t2 8	# $t2 <<= 8
		subu	$t2 $t1 $t2	# $t1 = $t1 - $t2		
		
		blt	$t2 0x20 set_point
			bgt	$t2 0x7E set_point
			j	no_point
		set_point:
			addiu	$t2 $zero 0x2E
		no_point:
		# . (0x2E) se <s 0x20 e > 0x7e
		
		sw	$t2 h2cch
		
		li	$v0 4		# set to print
		syscall			# exec
		addiu	$t0 $t0 1
		addiu	$t9 $t9 1
		srl	$t1 $t1 8
	blt	$t9 $a2 loopH2C
	jr	$ra
	
# -------------------------------------------- INT TO HEX -------------------------------------------------
int_to_hex:	# $a0 int da convertire. $a1 sizeof(var). restituisce indirizzo in $v0
# $a0	numero da convertire
# $a1	dimensione numero
# $v0	indirizzo in memoria
# $t0	numero che inserisco ($a0)
# $t1	char word che salvo
# $t2	variabile temporanea per shifts
# $t3	variabile temporanea per shifts
# $t4	variabile temporanea
# $t6	contatore da 0 -> $a1 (sizeof($a0))
# $t7	indirizzo dove scrivere
# $t8	contatore j -> dim int (sizeof($a0))
# $t9	char

	move	$t0 $a0			
	addiu	$t1 $zero 0		
	addiu	$t6 $zero 0		
	addiu	$t8 $zero 0		
	la	$t7 i2hch		
	sw	$t1 0($t7)		# cancello 64 bit
	sw	$t1 4($t7)		# cancello 64 bit

# controllo se devo usare 64 bit
	addu	$t3 $zero $a1
	divu	$t3 $t3 2
	bne	$t3 4 no_64		# if $t3 != 4 goto no_64
		addiu	$t7 $t7 4	# aggiungo 4 all'indirizzo se 64 bit, per usare prima i 32bit a dx poi i 32 a sx
	no_64:
	addiu	$t3 $zero 0		# setto a 0 $t3
	loopI2H:
		srl	$t2 $t0 4	# $t2 = $t0 >> 4
		sll	$t2 $t2 4	# $t2 <<= 4
		subu	$t3 $t0 $t2	# $t3 = $t1 - $t2
		addu	$t9 $zero $t3	# $t9 = 0
		
		# leggo il char dalla lista
		la	$t4 hex
		addu	$t4 $t4 $t9
		lb	$t4 0($t4)
		
		bne	$t6 32 no_sw	# if $t6 != 32 goto no_sw 64bit only
			sw	$t1 0($t7)
			addiu	$t6 $zero 0
			subu	$t7 $t7 4
		no_sw:
		
		sll	$t1 $t1 8	# $t1 <<= 8
		or	$t1 $t4 $t1	# $t1 |= $t4
		
		addiu	$t6 $t6 8
		addiu	$t8 $t8 1
		srl	$t0 $t0 4
	blt	$t8 $a1 loopI2H		# if $t8 < $a1 goto loopH2C

	sw	$t1 0($t7)
	move	$v0 $t7
#	la	$v0 0($gp)
	jr	$ra

# -------------------------------------------- CLEAR MEM ------------------------------------------------
#                                     (non e' usato nel programma)
clear_mem:
# $t0 offset dell'user space
	la	$t0 0($gp)
	loop_cls:
		sw	$zero 0($t0)
		addu	$t0 $t0 4
		blt	$t0 0x10010000 loop_cls
	jr	$ra
	
# -------------------------------------------- MAIN -----------------------------------------------------
main:
	la	$a0 info
	jal	print_str

	la	$a0 offstr
	jal	print_str
	jal	read_word
	addu	$s0 $zero $v0
	
	la	$a0 btrstr
	jal	print_str
	jal	read_word
	addu	$s4 $zero $v0


	la	$a0 offstr_hex
	jal	print_str
	addu	$a0 $zero $s0
	addu	$a1 $zero 8
	jal	int_to_hex
	move	$a0 $v0
	addiu	$a1 $zero 0
	jal	print_str
	la	$a0 endl
	jal	print_str


	la	$a0 btrstr_hex
	jal	print_str
	addu	$a0 $zero $s4
	addu	$a1 $zero 8
	jal	int_to_hex
	move	$a0 $v0
	addiu	$a1 $zero 0
	jal	print_str
	la	$a0 endl
	jal	print_str


#	addu	$s0 $zero 0x90000000	# offset iniziale (manuale) [0x90000000 ker] [0x10008000 data] [0x7ffff000 stack]
#	la	$s0 0($sp)		# offset iniziale
	addu	$s1 $zero $s0		# $s1 serve per la stringa da 16 byte
	addiu	$s2 $zero 0		# variabile di conto prima dello stamp
	addiu	$s6 $zero 0		
#	addu	$s4 $zero 0x200		# numero di byte da leggere
	la	$a0 offset
	jal	print_str
	la	$a0 endl
	jal	print_str
	
#loop hexdump 
	main_loop:			# --------------------- LOOP ----------------------
		divu	$t0 $s0 4
		mfhi	$t0			# $t0 = $s0 % 4
		
		bne	$t0 $zero main_no_lw	# $s7 e' la word che carico
			lw	$s7 0($s0)
		main_no_lw:
		
		addi	$s6 $s6 8
		srlv	$t0 $s7 $s6
		sll	$s3 $s3 8
		subu	$s3 $t0 $s3
		
		
		bne	$s2 0 main_no_off
		#scrive l'offset
			addu	$a0 $zero $s0
			addu	$a1 $zero 8	# specifica a int_to_hex che e' a 32bit
			jal	int_to_hex
			move	$a0 $v0
			addiu	$a1 $zero 0
			jal	print_str
		#allinea il numero	
			la	$a0 space3
			jal	print_str
		main_no_off:
		
		bne	$s2 8 main_space
			#allinea il numero	
			la	$a0 space
			jal	print_str
		main_space:
		
		#legge la word 1
		addu	$a0 $zero $s3	 # inserisco il valore di $s3 in $a0
		addu	$a1 $zero 2	 # specifica a int_to_hex che e' a 16bit
		jal	int_to_hex	
		move	$a0 $v0 	 # sposto il valore di $v0 in $a0
		jal	print_str
		la	$a0 space
		jal	print_str

		addu	$s2 $s2 1
		addu	$s0 $s0 1

		blt	$s2 16 main_endl
			la	$a0 space
			jal	print_str
			la	$a0 barra
			jal	print_str
			addu	$a0 $zero $s1
			addiu	$a2 $zero 0x10
			jal	hex_to_char
			la	$a0 barra
			jal	print_str
			la	$a0 endl
			jal	print_str
			addiu	$s2 $zero 0
			addiu	$s6 $zero 0
			addu	$s1 $s1 0x10
		main_endl:
		sub	$s4 $s4 1
	bgt	$s4 $zero main_loop # ------------------- END LOOP ---------------------
	addu	$t0 $zero $s2
	beq	$s2 0 skip_end
		special_loop:
			la	$a0 space3
			jal	print_str
			
			bne	$s2 8 not_8
				la	$a0 space
				jal	print_str
			not_8:
			addiu	$s2 $s2 1
		bne	$s2 16 special_loop
		
		la	$a0 space
		jal	print_str
		la	$a0 barra
		jal	print_str
		addu	$a0 $zero $s1
		addu	$a2 $zero $t0
		jal	hex_to_char
		la	$a0 barra
		jal	print_str
		la	$a0 endl
		jal	print_str
	skip_end:

	
	j	exit
	
