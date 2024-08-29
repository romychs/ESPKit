; ======================================================
; Utility code for Sprinter-WiFi utilities
; By Roman Boykov. Copyright (c) 2024
; https://github.com/romychs
; License: BSD 3-Clause
; ======================================================

	IFNDEF _UTIL
	DEFINE	_UTIL

	MODULE UTIL

	include "dss_error.asm"
	
; ------------------------------------------------------
; Small delay
; Inp:	HL - number of cycles, if HL=0, then 2000
; ------------------------------------------------------
DELAY
	PUSH	AF,BC,HL

    LD		A,H
    OR		L
    JR		NZ,.DELAY_NXT
    LD		HL,20

.DELAY_NXT
	CALL	.DELAY_1MS_INT
   	DEC		HL
    LD		A,H
    OR		L
    JP		NZ,.DELAY_NXT

	POP		HL,BC,AF
	RET

.DELAY_1MS_INT
	LD		BC,400
.SBD_NXT
	DEC		BC
	LD		A, B
	OR		C
	JR		NZ, .SBD_NXT
	RET

; ------------------------------------------------------
; Delay for about 1ms
; ------------------------------------------------------
DELAY_1MS
	PUSH	BC
	CALL	DELAY.DELAY_1MS_INT
	POP		BC
	RET

; ------------------------------------------------------
; Delay for about 100us
; ------------------------------------------------------
DELAY_100uS
	PUSH	BC
	LD		BC,40
	CALL	DELAY.SBD_NXT
	POP		BC
	RET

; ------------------------------------------------------
; Calc length of zero ended string
;	Inp: 	HL - pointer to string
;	Out: 	BC - length of string
; ------------------------------------------------------
	;;IFUSED STRLEN
STRLEN
	PUSH	DE,HL,HL
	LD		BC,MAX_BUFF_SIZE
	XOR		A
	CPIR
	POP		DE
	SBC		HL,DE										; length of zero ended string
	LD		BC,HL
	LD		A, B
	OR		C
	JR		Z, .STRL_NCOR
	DEC		BC
.STRL_NCOR	
	POP		HL,DE
	RET
	;ENDIF

; ------------------------------------------------------
; Compare strings
; 	Inp: 	HL, DE - pointers to asciiz strings to compare
; 	Out: 	CF=0 - equal, CF=1 - not equal
; ------------------------------------------------------
	;;IFUSED STRCMP
STRCMP
	PUSH	DE,HL
.STC_NEXT
	LD		A, (DE)
	CP		(HL)
	JR		NZ,.STC_NE
	AND		A
	JR		Z,.STC_EQ	
	INC		DE
	INC		HL
	JR		.STC_NEXT
.STC_NE
	SCF
.STC_EQ
	POP		HL,DE
	RET
	;;ENDIF



; ------------------------------------------------------
; Compare first BC chars for two zero-ended strings
; Inp: HL, DE - pointers to strings to compare
;	   BC - Number of chars to compare
; Out: ZF=0 - not equal, ZF=1 - equal
; ------------------------------------------------------
	;IFUSED STRNCMP
STRNCMP
	PUSH	HL,DE,BC
.STRN_NXT
	LD  	A,(DE)
    SUB 	(HL)
    JR  	NZ,.STRN_NE
    LD  	A,(DE)
    OR  	A
    JR  	Z,.STRN_NE
    INC 	DE
    INC 	HL
    DEC 	BC
    LD  	A,B
    OR 		C
    JP  	NZ,.STRN_NXT
.STRN_NE
	POP 	BC,DE,HL
    RET
	;ENDIF

; ------------------------------------------------------
; Checks whether a string (HL) starts with the strinf (DE)
; Inp: DE - points to start string
;	   HL - points to string
; Out: ZF=0 - not equal, ZF=1 - equal
; ------------------------------------------------------
	;;IFUSED	STARTSWITH
STARTSWITH
	PUSH	HL,DE
.STRW_NXT
	LD		A,(DE)
	OR		A
	JR		Z,.STRW_END
	LD		A,(DE)
	CP		(HL)
	JR		NZ,.STRW_END
	INC		HL
	INC		DE
	JR		.STRW_NXT
.STRW_END
	POP 	DE,HL
    RET
	;;ENDIF


; ------------------------------------------------------
; Skip spaces at start of zero ended string
; Inp: HL - pointer to string
; Out: HL - points to first non space symbol
; ------------------------------------------------------
	;;IFUSED	LTRIM
LTRIM
	LD	A, (HL)
	OR	A
	RET Z
	CP  0x21
	RET P
	INC HL
	JR	LTRIM
	;;ENDIF

; ------------------------------------------------------
; Convert string to number
; Inp: DE - ptr to zero ended string
; Out: HL - Result
; ------------------------------------------------------
	;;IFUSED ATOU
ATOU
	PUSH	BC
  	LD		HL,0x0000
.ATOU_L1
  	LD		A,(DE)
  	AND		A
  	JR		Z, .ATOU_LE
  	SUB		0x30
  	CP		10
  	JR		NC, .ATOU_LE
  	INC 	DE
  	LD 		B,H
  	LD 		C,L
  	ADD 	HL,HL
  	ADD 	HL,HL
  	ADD 	HL,BC
  	ADD 	HL,HL
  	ADD 	A,L
  	LD 		L,A
  	JR 		NC,.ATOU_L1
  	INC 	H
  	JP 		.ATOU_L1
.ATOU_LE
	POP		BC
	RET
	;;ENDIF

; ------------------------------------------------------
; Convert 16 bit unsigned number to string
; Inp: HL - number
; 	   DE - ptr to buffer
; Out: DE -> asciiz string representing a number
; ------------------------------------------------------
	;;IFUSED 	UTOA
UTOA:
	PUSH	BC, HL
	XOR		A
	PUSH	AF											; END MARKER A=0, Z
.UTOA_L1
	CALL	DIV_10
	ADD		'0'
	PUSH	AF											; DIGIT: A>0, NZ
	LD		A,H
	OR		L
	JR		NZ,.UTOA_L1
.UTOA_L2
	POP		AF
	LD		(DE),A
	INC		DE
	JR		NZ,.UTOA_L2
	POP		HL, BC
	RET

; ------------------------------------------------------
; Division by 10
; Inp: HL - number
; Out: HL - quotient
;		A - remainder
; ------------------------------------------------------
DIV_10:
	PUSH	BC
	LD 		BC,0x0D0A
	XOR 	A
	ADD 	HL,HL
	RLA
	ADD 	HL,HL
	RLA
	ADD 	HL,HL
	RLA
.DDL1
	ADD 	HL,HL
	RLA	
	CP 		C
	JR 		C,.DDL2
	SUB 	C
	INC 	L
.DDL2
	DJNZ 	.DDL1
	POP		BC
	RET
	;;ENDIF
; ------------------------------------------------------
; FAST_UTOA
;	Inp:	HL - number
;			DE - Buffer 
;			CF is set to write leading zeroes
;	Out:	DE - address of strinf 
; ------------------------------------------------------
	;;IFUSED	FAST_UTOA
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
	;;ENDIF	

; ------------------------------------------------------
; Find char in string
;	Inp: 	HL - ptr to zero endeds string
;		 	A  - char to find
;	Outp: 	CF=0, HL points to char if found
;		  	CF=1 - Not found
; ------------------------------------------------------
	;;IFUSED	STRCHR
STRCHR
	PUSH	BC
.STCH_NEXT	
	LD		C,A
	LD		A,(HL)
	AND		A
	JR		Z, .STCH_N_FOUND
	CP		C
	JR		Z, .STCH_FOUND
	INC		HL
	JR		.STCH_NEXT
.STCH_N_FOUND
	SCF
.STCH_FOUND
	POP		BC
	RET
	;;ENDIF

; ------------------------------------------------------
; Convert Byte to hex
;	Inp: C
;	Out: (DE)
; ------------------------------------------------------
	;;IFUSED HEXB
HEXB
	LD		A,C
	RRA
	RRA
	RRA
	RRA
	CALL	.CONV_NIBLE
	LD		A,C

.CONV_NIBLE
	AND		0x0f
	ADD		A,0x90
	DAA
	ADC		A,0x40
	DAA
	LD		(DE), A
	INC		DE
	RET
	;;ENDIF


; ----------------------------------------------------
;  Get full current path
;  Inp: HP - pointer to buffer for path
; ----------------------------------------------------
	
GET_CUR_DIR
	PUSH    HL
	LD      C, DSS_CURDISK
	RST     DSS
	CALL	@DSS_ERROR.CHECK
	ADD     A, 65
	LD      (HL),A
	INC     HL
	LD      (HL),':'
	INC     HL
	LD      C, DSS_CURDIR
	RST     DSS
	CALL	@DSS_ERROR.CHECK
	POP     HL
	JP    	ADD_BACK_SLASH
	;RET

; ----------------------------------------------------
; Add back slash to path string
; Inp: HL - pointer to zero ended string with path
; Out: HL - point to end
; ----------------------------------------------------
ADD_BACK_SLASH
    XOR     A
    ; find end of path
.FIND_EOS
    CP      (HL)
    JR      Z,.IS_EOS
    INC     HL
    JR      .FIND_EOS
	; check last symbol is '\'' and add if not
.IS_EOS
	DEC     HL
    LD      A,(HL)
    CP      "\\"
    JR      Z,.IS_SEP
    INC     HL
    LD      (HL),"\\"
.IS_SEP
	; mark new end of string
    INC     HL
    LD      (HL),0x0
    RET
	
	ENDMODULE
	
	ENDIF