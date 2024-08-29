; ======================================================
; Macros for Sprinter-WiFi utilities
; By Roman Boykov. Copyright (c) 2024
; https://github.com/romychs
; License: BSD 3-Clause
; ======================================================

	IFNDEF	_MACRO
	DEFINE	_MACRO

	; Transmit data|command via UART and check response
	MACRO	SEND_CMD	data
	LD		HL, data
	CALL	@WIFI.UART_TX_CMD
	CALL	CHECK_ERROR
	ENDM	

	; Print data forn HL - pointer to ASCIIZ string to screen
	MACRO 	PRINT_HL
    LD      C,DSS_PCHARS
    RST     DSS
	ENDM

	; Print data forn HL - pointer to ASCIIZ string to screen, and <CR><LF>
	MACRO 	PRINTLN_HL
    PRINT_HL
	LD		HL, WCOMMON.LINE_END
	PRINT_HL
	ENDM

	; Print data ASCIIZ string to screen
	MACRO 	PRINT	data
	LD		HL,data
	PRINT_HL
	ENDM

	; Print data ASCIIZ string to screen and <CR><LF>
	MACRO 	PRINTLN	data
	LD		HL,data
	PRINTLN_HL
	ENDM

	; Print data ASCIIZ string to screen if TRACE enabled
	MACRO 	TRACELN	data
		IFDEF	TRACE
			PUSH BC,DE
			PRINTLN data
			POP DE,BC
		ENDIF
	ENDM

	; Execute specified DSS function
	MACRO	DSS_EXEC	func
		IF func>255
			LD		BC,func
		ELSE
		 	LD		C,func
		ENDIF
		RST		DSS
	ENDM

	; If current work mode is upload, go to label
	MACRO	IF_UPLOAD_GO lbl
		LD		A,(WORK_MODE)
		;CP		WM_UPLOAD
		DEC		A
		JR		Z,lbl
	ENDM

	ENDIF