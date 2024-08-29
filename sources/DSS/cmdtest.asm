DSS			EQU 0x10
DSS_PCHARS	EQU 0x5C
DSS_EXIT	EQU 0x41
EXE_VERSION EQU 0x01


	; Print data ASCIIZ string to screen and CR+LF
	MACRO 	PRINTLN	data
	LD		HL,data
    LD      C,DSS_PCHARS
    RST     DSS
    LD      C,DSS_PCHARS
	LD		HL, MSG_LINE_END
	RST     DSS
	ENDM	

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
	
	PRINTLN MSG_CMDLINE
	PUSH	IX
	POP		HL
	INC		HL
    LD      C,DSS_PCHARS
    RST     DSS

	PRINTLN MSG_CURPATH
	PUSH	IY
	POP		HL
    LD      C,DSS_PCHARS
    RST     DSS

	LD		BC,DSS_EXIT
	RST     DSS


MSG_CMDLINE
	DB "\r\nCommandline:",0

MSG_CURPATH
	DB "\r\nExePath:",0

MSG_LINE_END
	DB "\r\n",0	

	ENDMODULE
