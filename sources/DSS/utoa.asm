
; ------------------------------------------------------
; FAST_UTOA
;	Inp: 	HL - number
;			A - Radix 2,8,10,16
;         	DE - Buffer 
;         	CF is set to write leading zeroes
;	Out:	DE - address of strinf 
; ------------------------------------------------------
FAST_UTOA
	LD		BC,0+256
	PUSH 	BC
	LD 		BC,-10+256
	PUSH 	BC
	INC 	H
	DEC 	H
	JR 		Z, .EIGHT_BIT

	LD 		C,0XFF & (-100+256)
	PUSH 	BC

	LD 		BC,-1000+256
	PUSH 	BC

	LD 		BC,-10000

	JR 		C,.LEADING_ZEROES

.NO_LEADING_ZEROES

	CALL   .DIVIDE
	CP		'0'
	JR 		NZ,.WRITE

	POP 	BC
	DJNZ 	.NO_LEADING_ZEROES

	JR 		.WRITE1S

.LEADING_ZEROES
	CALL	.DIVIDE

.WRITE
   LD		(DE),A
   INC		DE

   POP		BC
   DJNZ 	.LEADING_ZEROES


.WRITE1S
	LD 		A,L
	ADD 	A,'0'

	LD 		(DE),A
	INC 	DE
	RET

.DIVIDE
	LD 		A,'0'-1

.DIVLOOP
	INC 	A
	ADD 	HL,BC
	JR		C, .DIVLOOP

	SBC		HL,BC
	RET

.EIGHT_BIT
	LD		BC,-100
	JR		NC, .NO_LEADING_ZEROES

	; write two leading zeroes to output string
	LD 		A,'0'
	LD		(DE),A
	INC		DE
	LD		(DE),A
	INC		DE

	JR 		.LEADING_ZEROES
