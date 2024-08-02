; ======================================================
; ISA-Test to test ISA-Bus
; For Sprinter computer DSS
; By Roman Boykov. Copyright (c) 2024
; https://github.com/romychs
; License: BSD 3-Clause
; ======================================================

; Set to 1 to turn debug ON with DeZog VSCode plugin
; Set to 0 to compile .EXE
DEBUG               EQU 0

; Set to 1 to output TRACE messages
TRACE               EQU 1

; Version of EXE file, 1 for DSS 1.70+
EXE_VERSION         EQU 0

; Timeout to wait ESP response
DEFAULT_TIMEOUT		EQU	2000

    SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION

    DEVICE NOSLOT64K
	
	INCLUDE "macro.inc"
	INCLUDE "dss.inc"
	INCLUDE "sprinter.inc"

	MODULE	MAIN

    ORG	0x8080
; ------------------------------------------------------
EXE_HEADER
    DB  "EXE"
    DB  EXE_VERSION                                     ; EXE Version
    DW  0x0080                                          ; Code offset
    DW  0
    DW  0                                               ; Primary loader size
    DW  0                                               ; Reserved
    DW  0
    DW  0
    DW  START                                           ; Loading Address
    DW  START                                           ; Entry Point
    DW  STACK_TOP                                       ; Stack address
    DS  106, 0                                          ; Reserved

    ORG 0x8100
@STACK_TOP
	
; ------------------------------------------------------
START
	
    IFDEF	DEBUG
    	; LD 		IX,CMD_LINE1
		LD		SP, STACK_TOP
		JP 		MAIN_LOOP
    ENDIF

	CALL	@WCOMMON.INIT_VMODE

    PRINTLN MSG_START

	
	XOR		A
	LD		(ISA.ISA_SLOT),A

	CALL	ISA.ISA_OPEN
	
	; --------- IOW/IOR/A0-A7/D0-D7 --------------
; 	LD	D,0
; L_DATA
; 	LD	HL, PORT_UART_A
; 	LD	B,0x08
; L_PORT		
; 	LD	(HL), D
; 	LD	E,(HL)
; 	INC HL
; 	DJNZ L_PORT
; 	INC D

	CALL	ISA.ISA_OPEN

	LD	HL, REG_SCR
	LD  D,0x55

	LD		BC, PORT_ISA
	LD		A, ISA_AEN							; AEN=1	 (for sync  LA by front)
	OUT 	(C), A
	
	;
	LD	(HL), D
	LD	D,(HL)	

	LD  D,0xAA
	LD	(HL), D
	LD	D,(HL)	

	LD		BC, PORT_ISA
	LD		A, 0								; AEN=0	
	OUT 	(C), A

	CALL	ISA.ISA_CLOSE


	; --------- RESET & AEN --------------
	; LD		BC, PORT_ISA
	; LD		A,ISA_RST | ISA_AEN							; RESET=1 AEN=1	
	; OUT 	(C), A
	; CALL 	UTIL.DELAY_100uS
	; XOR 	A
	; OUT 	(C), A										; RESET=0 AEN=0

	;JR  L_DATA

	; XOR		A
	; LD		(Q_POS),A

MAIN_LOOP


; ------------------------------------------------------
; Do Some
; ------------------------------------------------------

OK_EXIT
	LD		B,0
	JP		@WCOMMON.EXIT


; ------------------------------------------------------
; Custom messages
; ------------------------------------------------------

MSG_START
	DB "ISA test for ISA-BUS by Sprinter Team. v1.0.b1, ", __DATE__, "\r\n", 0

MSG_EXIT
	DB "Bue!",0

; ------------------------------------------------------
; Custom commands
; ------------------------------------------------------

	ENDMODULE

	INCLUDE "wcommon.asm"
	INCLUDE "util.asm"
	INCLUDE "isa.asm"
	INCLUDE "esplib.asm"

    END MAIN.START
