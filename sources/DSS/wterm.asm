; ======================================================
; WTERM terminal for Sprinter-WiFi ISA Card
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
	
    IF  DEBUG == 1
		INCLUDE "dss.asm"
		DB 0
		ALIGN 16384, 0
        DS 0x80, 0
    ENDIF

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
	
    IF DEBUG == 1
    	; LD 		IX,CMD_LINE1
		LD		SP, STACK_TOP
    ENDIF

	CALL 	ISA.ISA_RESET
	
	CALL	WCOMMON.INIT_VMODE

    PRINTLN MSG_START

	CALL	WCOMMON.FIND_SWF

	PRINTLN WCOMMON.MSG_UART_INIT
	CALL	WIFI.UART_INIT

	PRINTLN WCOMMON.MSG_ESP_RESET
	CALL	WIFI.ESP_RESET

	CALL	WCOMMON.INIT_ESP

	PRINTLN MSG_HLP

	CALL	WIFI.UART_EMPTY_RS

	XOR		A
	LD		(Q_POS),A

MAIN_LOOP
	; handle key pressed
	LD		C,DSS_SCANKEY
	RST		DSS
	JP		Z,HANDLE_RECEIVE							; if no key pressed

	; check for QUIT command
	LD		A,(Q_POS)
	CP		4
	JP		P,NO_QUIT

	LD 		IX, CMD_QUIT
Q_POS		EQU $+2
	LD		A,(IX+0x00)
	; compare current char with "QUIT" str
	CP		E
	JR		NZ,NO_QUIT

	LD		HL,Q_POS
	INC		(HL)
	LD		A,(HL)
	CP		5
	JP		Z,OK_EXIT
	JR		OUT_CHAR

NO_QUIT
	XOR		A
	LD		(Q_POS), A

OUT_CHAR
	LD		A, E
	CP		CR
	JR		Z, PUT_CHAR
	CP		0x20
	JP		M, HANDLE_CR_LF

PUT_CHAR
	CALL	PUT_A_CHAR

HANDLE_CR_LF
	CALL    WIFI.UART_TX_BYTE
	JP		C,TX_WARN
	LD		A, E
	CP		CR
	JR		NZ,NO_TX_LF
	LD		E,LF
	CALL    WIFI.UART_TX_BYTE
	JP		C,TX_WARN
	JR		HANDLE_RECEIVE

NO_TX_LF
	CP		LF
	JR		NZ,HANDLE_RECEIVE
	LD		E,CR
	CALL    WIFI.UART_TX_BYTE
	JP		C,TX_WARN

	; check receiver and handle received bytes
HANDLE_RECEIVE
	; check receiver status
	LD		HL,REG_LCR
	CALL	WIFI.UART_READ
	CP		LSR_RCVE
	JP		NZ, RX_WARN
	CP		LSR_DR
	JP		Z, CHECK_FOR_END
	; rx queue is not empty, read
	LD		HL,REG_RBR
	CALL	WIFI.UART_READ
	LD		E,A
	CP		CR
	JR		NZ, CHK_1F
	; print CR+LF
	CALL	PUT_A_CHAR
	LD		A,LF
	CALL	PUT_A_CHAR
	JP		CHECK_FOR_END

CHK_1F
	CP		0x20
	CALL	P, PUT_A_CHAR

CHECK_FOR_END
	LD		A,(Q_POS)
	CP		5
	JP		Z, OK_EXIT	
	JP		MAIN_LOOP

RX_WARN
	LD		C,A
	LD		DE,MSG_LSR_VALUE
	CALL	UTIL.HEXB
	PRINTLN	MSG_RX_ERROR
	JP		MAIN_LOOP

TX_WARN
	PRINTLN MSG_TX_ERROR
	JP		MAIN_LOOP

PUT_A_CHAR
	PUSH	BC,DE
	LD		C,DSS_PUTCHAR
	RST		DSS	
	POP		DE,BC
	RET


; ------------------------------------------------------
; Do Some
; ------------------------------------------------------

OK_EXIT
	LD		B,0
	JP		WCOMMON.EXIT


; ------------------------------------------------------
; Custom messages
; ------------------------------------------------------

MSG_START
	DB "Terminal for Sprinter-WiFi by Sprinter Team. v1.0.1, ", __DATE__, "\r\n", 0
MSG_HLP
	DB"\r\nEnter ESP AT command or QUIT to close terminal.",0

MSG_TX_ERROR
	DB "Transmitter not ready",0

MSG_RX_ERROR
	DB "Receiver error LSR: 0x"
MSG_LSR_VALUE	
	DB "xx",0

; TX_DATA
; 	DB  " ",0
; ------------------------------------------------------
; Custom commands
; ------------------------------------------------------
CMD_QUIT 
    DB "QUIT\r",0

	IF DEBUG == 1
CMD_TEST1	DB "ATE0\r\n",0	
BUFF_TEST1	DS RS_BUFF_SIZE,0
	ENDIF

	ENDMODULE

	INCLUDE "wcommon.asm"
	INCLUDE "util.asm"
	INCLUDE "isa.asm"
	INCLUDE "esplib.asm"

    END MAIN.START
