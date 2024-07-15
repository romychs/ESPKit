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
		JP MAIN_LOOP
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

MAIN_LOOP
	; handle key pressed
	LD		C,DSS_SCANKEY
	RST		DSS
	JP		Z,HANDLE_RECEIVE							; if no key pressed
	LD		A,D
	CP		0xAB
	JR		NZ, NO_QUIT
	LD		A,B
	AND		KB_ALT
	JP		NZ, OK_EXIT

NO_QUIT

OUT_CHAR
	LD		A, E
	CP		CR
	JR		NZ, CHK_PRINTABLE
	CALL	PUT_A_CHAR
	LD		A,LF
	CALL	PUT_A_CHAR
	JR		TX_SYMBOL

CHK_PRINTABLE
	CP		0x20
	JP		M, HANDLE_RECEIVE							; do not print < ' '	
	CALL	PUT_A_CHAR

	; transmitt symbol
TX_SYMBOL
	CALL    WIFI.UART_TX_BYTE
	JP		C,TX_WARN
	LD		A, E
	CP		CR
	JR		NZ,HANDLE_RECEIVE
	; Transmitt LF after CR
	LD		E,LF
	CALL    WIFI.UART_TX_BYTE
	JP		C,TX_WARN
 
	; check receiver and handle received bytes
HANDLE_RECEIVE
	; check receiver status
	LD		HL,REG_LSR
	CALL	WIFI.UART_READ
	LD		D,A
	AND		LSR_RCVE
	JP		NZ, RX_WARN
	LD		A,D
	AND		LSR_DR
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

	; check for printable symbol, and print
CHK_1F
	CP		0x20
	CALL	P, PUT_A_CHAR
	
	; reset error counter if received symbol withoud error
	XOR		A
	LD		(RX_ERR),A

CHECK_FOR_END
	; LD		A,(Q_POS)
	; CP		5
	; JP		Z, OK_EXIT
	JP		MAIN_LOOP

RX_WARN
	LD		C,A
	LD		DE,MSG_LSR_VALUE
	CALL	UTIL.HEXB
	PRINTLN	MSG_RX_ERROR
	CALL	WIFI.UART_EMPTY_RS
	LD		HL,RX_ERR
	INC		(HL)
	LD		A,(HL)
	CP		100	
	JP		M,MAIN_LOOP
	; too many RX errors
	PRINTLN MSG_MANY_RX_ERROR
	LD		B,5
	JP		WCOMMON.EXIT
	


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
	DB "Terminal for Sprinter-WiFi by Sprinter Team. v1.0 beta3, ", __DATE__, "\r\n"Z
MSG_HLP
	DB"\r\nEnter ESP AT command or Alt+x to close terminal."Z
MSG_EXIT

MSG_TX_ERROR
	DB "Transmitter not ready"Z

MSG_RX_ERROR
	DB "Receiver error LSR: 0x"
MSG_LSR_VALUE	
	DB "xx"Z

MSG_MANY_RX_ERROR
	DB "Too many receiver errors!"Z


MSG_ALT
	DB "Pressed ALT+"
MSG_ALT_KEY
	DB "xx"Z

; TX_DATA
; 	DB  " ",0
; ------------------------------------------------------
; Custom commands
; ------------------------------------------------------
CMD_QUIT 
    DB "QUIT\r"Z

RX_ERR
	DB 0

	IF DEBUG == 1
CMD_TEST1	DB "ATE0\r\n"Z
BUFF_TEST1	DS RS_BUFF_SIZE,0
	ENDIF

	ENDMODULE

	INCLUDE "wcommon.asm"
	INCLUDE "util.asm"
	INCLUDE "isa.asm"
	INCLUDE "esplib.asm"

    END MAIN.START
