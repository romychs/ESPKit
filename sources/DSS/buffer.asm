; ======================================================
; Circular buffer implementation
; By Roman Boykov. Copyright (c) 2024
; https://github.com/romychs
; ======================================================
	IFNDEF	_BUFFER
	DEFINE	_BUFFER
	
	MODULE BUFFER

SIZE_MASK	EQU	0x1FFF

; ------------------------------------------------------
; Init circular buffer before use
; Reset pointers and allocate memory
; ------------------------------------------------------
INIT
	; reset buffer pointers
	LD		HL,0x0000
	LD		(PTR_SET), HL
	LD		(PTR_GET), HL

	DI
	IN		A,(PAGE_1)
	LD		(SAVE_P1), A

	; request one 16k page
	LD		B,1
	DSS_EXEC	DSS_GETMEM
	JR		C,MAL_ERROR
	; save handler
	LD		(MEMHND),A
	; map allocated mem to p1
	LD		HL,PAGE1_ADDR
	LD		B,0
	LD		A,(MEMHND)
	DSS_EXEC	DSS_SETMEM
	JR		C,MAL_ERROR
	;LD  	(SAVE_P1),A
	RET

MAL_ERROR
	LD		DE,MSG_MAL_VAL
	LD		C, A
	CALL 	UTIL.HEXB

MSG_MAL
	DB "Memory allocation error: 0x"
MSG_MAL_VAL
	DB "xx",0

; ------------------------------------------------------
; Deallocate memory, allocated by INIT. Call this before 
; exit to DSS
; ------------------------------------------------------
FREE
	; free allocated memory
	LD		A,(MEMHND)
	CP		0xFF
	JR		Z, NO_MA
	DSS_EXEC	DSS_FREEMEM
NO_MA
	; restore page
	LD		A,(SAVE_P1)
	CP		0xFF
	JR		Z, NO_PA
	OUT		(PAGE_1),A
NO_PA
	RET

; ------------------------------------------------------
; PUT Data to buffer
; Inp: C - byte to place
; Out: CF=1 if no space
; ------------------------------------------------------
PUT 
	PUSH	HL,DE
	LD		HL,(PTR_HEAD_P)
	LD  	DE,(PTR_TAIL)
	LD		A,L
	CP		E
	JP		NZ, P_NOTF
	LD  	A, H
	CP		D
	JP		NZ, P_NOTF
	SCF
	JR		P_RET
P_NOTF
	; put value to buffer
	OR		D,0x40										; p1
	LD		(DE),C
	; increment and wrap tail ptr
	INC		DE
	LD		A, D
	AND		0x1F
	LD		D, A
	LD  	(PTR_TAIL), DE
P_RET	
	POP		DE,HL
	RET
		
; ------------------------------------------------------
; GET Data from buffer
; Out: CF=1 if empty
; 	   else A - byte from buffer
; ------------------------------------------------------
GET
	PUSH	HL,DE
	LD		HL,(PTR_HEAD)
	LD  	DE,(PTR_TAIL)
	LD		A,L
	CP		E
	JP		NZ, G_NOTE
	LD  	A, H
	CP		D
	JP		NZ, G_NOTE
	SCF
	JR		G_RET
G_NOTE
	; store previous head ptr
	LD		(PTR_HEAD_P), HL
	; get value
	LD		A,H
	OR		0x40
	LD		H,A
	LD		C, (HL)
	; inc and wrap head ptr
	INC		HL
	LD		A, H
	AND		0x1F
	LD		H, A
	LD		(PTR_HEAD),  HL
G_RET	
	POP		DE,HL
	RET

; ------------------------------------------------------
; Check buffer is full
; Out: CF=1 if full
; ------------------------------------------------------
IS_FULL
	PUSH	HL,DE
	LD		HL,(PTR_HEAD_P)
	LD  	DE,(PTR_TAIL)
	SBC		HL,DE
	JP		NZ, ISF_NOTF
	SCF
	JR		ISF_RET
ISF_NOTF
	AND		A
ISF_RET	
	POP		DE,HL
	RET

; ------------------------------------------------------
; Check buffer is empty
; Out: CF=1 if empty
; ------------------------------------------------------
IS_EMPTY
	PUSH	HL,DE
	LD		HL,(PTR_HEAD)
	LD  	DE,(PTR_TAIL)
	SBC		HL,DE
	JR		NZ, ISF_NOTF
	SCF
	JR		ISF_RET

; buffer set position
PTR_TAIL
	DW	0x0000

; buffer get position
PTR_HEAD
	DW	0x0000

; buffer previous head position
PTR_HEAD_P
	DW	0x0000

; habler for allocated memory
MEMHND
	DB  0xFF

; storage for old mem page	
SAVE_P1
	DB	0xFF

	ORG 0x5000
RX_BUFFER

	ENDMODULE

	ENDIF