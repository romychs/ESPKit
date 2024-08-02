; ======================================================
; WTFTP client for trivial file transfer protocol
; for Sprinter-WiFi ISA Card
; By Roman Boykov. Copyright (c) 2024
; https://github.com/romychs
; License: BSD 3-Clause
; ======================================================

; Set to 1 to turn debug ON with DeZog VSCode plugin
; Set to 0 to compile .EXE
	DEFINE			DEBUG

; Set to 1 to output TRACE messages
	DEFINE 			TRACE


WM_DOWNLOAD			EQU 0

WM_UPLOAD			EQU 1


; Version of EXE file, 1 for DSS 1.70+
EXE_VERSION         EQU 1

; Timeout to wait ESP response
DEFAULT_TIMEOUT		EQU	2000

	DEVICE NOSLOT64K

    IFDEF	DEBUG
		INCLUDE "dss.asm"
		DB 0
		ALIGN 16384, 0
        DS 0x80, 0
    ENDIF

	INCLUDE "macro.inc"
	INCLUDE "dss.inc"
	;INCLUDE "sprinter.inc"

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
	
    IFDEF DEBUG
    	LD 		IX,CMD_LINE_TFTP_D1
		LD		SP, STACK_TOP		
    ENDIF
	
	CALL	PARSE_CMD_LINE

	CALL	OPEN_LOCAL_FILE
	
	CALL	DISPLAY_MODE

	CALL	CLOSE_LOCAL_FILE

	IFDEF	DEBUG
		JP 		MAIN_LOOP
	ENDIF

	CALL 	ISA.ISA_RESET
	
	CALL	@WCOMMON.INIT_VMODE

    PRINTLN MSG_START

	CALL	@WCOMMON.FIND_SWF

	PRINTLN WCOMMON.MSG_UART_INIT
	CALL	@WIFI.UART_INIT

	PRINTLN WCOMMON.MSG_ESP_RESET
	CALL	@WIFI.ESP_RESET

	CALL	@WCOMMON.INIT_ESP

	PRINTLN MSG_HLP

	CALL	@WIFI.UART_EMPTY_RS

MAIN_LOOP

; ------------------------------------------------------
; Do Some
; ------------------------------------------------------

OK_EXIT
	LD		B,0
	JP		WCOMMON.EXIT

; ------------------------------------------------------
; IX - points to cmd line
; ------------------------------------------------------
PARSE_CMD_LINE
	PUSH 	IX
	POP		HL
	LD		A,(HL)
	OR		A
	JR		Z, OUT_USAGE_MSG
	CALL	SKIP_SPACES

	
	; check first parameter for tftp url pattern
	LD		DE,TFTF_START
	CALL	@UTIL.STARTSWITH
	JR		NZ,.PLC_UPLOAD

	; Work Mode "Download"

	; handle parameter URL
	CALL	GET_SRV_PARAMS
	CALL	SKIP_SPACES
    
	; handle lfn
	CALL	GET_LFN
	CALL	COPY_LFN
	RET
	
.PLC_UPLOAD
	; Work mode "Upload"
	LD		A, WM_UPLOAD
	LD		(WORK_MODE),A

	CALL	GET_LFN
	CALL	SKIP_SPACES

	LD		DE,TFTF_START
	CALL	@UTIL.STARTSWITH
	JR		NZ,OUT_USAGE_MSG

	CALL	GET_SRV_PARAMS

	RET

; ------------------------------------------------------
OUT_ERR_CMD_MSG
	PRINTLN	MSG_ERR_CMD

; ------------------------------------------------------
OUT_USAGE_MSG
	PRINTLN	MSG_HLP
	JP		OK_EXIT


; ------------------------------------------------------
; Move srv name and port number from (HL) to (DE)
; ------------------------------------------------------
GET_SRV_PARAMS
	PUSH	BC,DE

	LD		DE,0x0007
	ADD 	HL,DE

	LD		DE,SRV_NAME
.GSN_NEXT
	LD		A,(HL)
	OR		A											; end of url?
	JR		Z,.GSN_END					
	CP		'/'											; end of server name?
	JR		Z,.GSN_END					
	CP		':'											; end of server name and has port?
	JR		Z,.GSN_PORT
	LD		(DE), A										; move and get next
	INC		HL
	INC		DE
	JR		.GSN_NEXT
	; has port number
.GSN_PORT
	LD		DE,SRV_PORT
	LD		B,6
.GSNP_NXT	
	INC		HL											
	LD		A,(HL)
	CP		A,'/'										; end slash
	JR		Z,.GSN_EN
	CP		A,'0'
	JP		M,.GSN_EPN
	CP		A,0x3A										; >'9'?
	JP		P,.GSN_EPN
	LD		(DE),A
	INC		DE
	DJNZ	.GSNP_NXT
	; too long number


.GSN_EPN
	PRINTLN MSG_ERR_PORT
	JP		OUT_USAGE_MSG

.GSN_EN
	LD		DE,SRV_PORT
	LD		A,(DE)
	OR		A											; ':/' - no port number specified
	JR		Z,.GSN_EPN
	PUSH	HL
	CALL	@UTIL.ATOU
	LD		(SRV_PORT),HL
	POP		HL

.GSN_END
	; get file name from url
	LD		DE,REM_FILE
	LD		B,127
.GDNF_NXT	
	INC		HL
	LD		A,(HL)
;	OR		A
;	JR		Z,.GDNF_END
	CP		0x21
	JP		M,.GDNF_END
	LD		(DE),A
	INC		DE
	DEC		B
	JR		NZ,.GDNF_NXT
	JR		.GDNF_ERR									; file name too long
	; check file name is not empty
.GDNF_END
	LD		DE,REM_FILE
	LD		A,(DE)
	OR		A
	JR		NZ,.GSN_RET
	; out error about invalid file name
.GDNF_ERR	
	PRINTLN MSG_ERR_RFN
	JP		OUT_USAGE_MSG
.GSN_RET
	POP		DE,BC
	RET

; ------------------------------------------------------
; Get local file name from command string
;
; ------------------------------------------------------
GET_LFN
	PUSH	BC,DE
	LD		DE,LOC_FILE

.GLF_NXT	
	LD		A,(HL)
	OR		A
	JR		Z,.GLF_END
	CP      ' '
	JR		Z,.GLF_END
	CP		0x21
	JP		M,.GLF_IFN
	CP		'*'
	JP		Z,.GLF_IFN
	CP		':'
	CALL	.GLF_HAVE_PATH
	CP		"\\"
	CALL	.GLF_HAVE_PATH

	LD		(DE),A
	INC		HL
	INC		DE
	JR		.GLF_NXT

.GLF_END
	POP		DE,BC
	RET

	; set flag to not add current dir
.GLF_HAVE_PATH
	JR		NZ, .GLF_NHP
	LD		IY,HAVE_PATH
	INC		(IY+0)
.GLF_NHP	
	RET

	; Illegal file name
.GLF_IFN
	PRINTLN MSG_ERR_LFN
	JP		OUT_USAGE_MSG

; ------------------------------------------------------
; Check local file name for empty and fill it from 
; remote file name
; ------------------------------------------------------
COPY_LFN
	LD		HL,LOC_FILE
	LD		A, (HL)
	OR		A
	RET		NZ											; ok, it is not empty
	CALL	UTIL.GET_CUR_DIR
	//LD		DE,HL
	LD		IX,HAVE_PATH
	INC		(IX+0)
			
	LD		DE,REM_FILE
.CLFN_NXT	
	LD		A,(DE)
	LD		(HL),A
	OR		A
	RET		Z
	INC		HL
	INC		DE
	JR		.CLFN_NXT




; ------------------------------------------------------
; Open local file for upload or download
; RO - for upload
; WR - for download
; ------------------------------------------------------
OPEN_LOCAL_FILE
	LD		HL,LOC_FILE
	LD 		A,(HAVE_PATH)
	OR		A
	JR		NZ,.OLF_SKP_CP
	
	LD		HL, WIFI.RS_BUFF
	PUSH	HL
	CALL	UTIL.GET_CUR_DIR
	LD		DE,LOC_FILE
	LD		B,128
.OLF_NXT	
	LD		A, (DE)
	LD		(HL),A
	OR		A
	JR		Z, .OLF_EFN
	INC 	HL
	INC		DE
	DJNZ	.OLF_NXT	
.OLF_EFN
	POP		HL

	; HL - points to file path name
.OLF_SKP_CP
	LD		A, (WORK_MODE)
	CP		WM_UPLOAD
	JR		Z,.OLF_UPL

	; create new file for write
	XOR		A
	LD		C,DSS_CREATE_FILE
	RST		DSS
	JR		NC,.OLF_END
	CP		0x07										; file exists?
	JP		NZ,DSS_ERROR.PRINT							; print error and exit
	LD		A,FM_WRITE
	JR		.OLF_FOW
	; open existing file for read
.OLF_UPL
	LD		A,FM_READ
.OLF_FOW	
	LD		C,DSS_OPEN_FILE
	RST		DSS
	CALL    DSS_ERROR.CHECK
.OLF_END
	LD    (LOC_FH),A

	TRACELN MSG_LFN_OPEN	

	RET

	IFDEF	TRACE
MSG_LFN_OPEN
	DB "Local file succes open/created."Z	
	ENDIF

CLOSE_LOCAL_FILE
	LD		A,(LOC_FH)	
	OR		A
	RET		Z
	DSS_EXEC	DSS_CLOSE_FILE
	CALL	DSS_ERROR.CHECK
	RET

; ------------------------------------------------------
; Skip spaces at start of zero ended string
; Inp: HL - pointer to string
; Out: HL - points to first non space symbol
; ------------------------------------------------------
SKIP_SPACES
	LD	A, (HL)
	OR	A
	RET Z
	CP  0x21
	RET P
	INC HL
	JR	SKIP_SPACES


; ------------------------------------------------------
; Display current working mode
; ------------------------------------------------------
DISPLAY_MODE
	LD	A,(WORK_MODE)
	CP  A,WM_UPLOAD
	JR	.DM_UPLOAD
	; Download
	PRINT MSG_MODE_D
	PRINT REM_FILE
	PRINT MSG_MODE_D_S
	PRINT SRV_NAME
	PRINT MSG_MODE_D_T
	PRINTLN LOC_FILE
	RET
	; Upload
.DM_UPLOAD
	PRINT MSG_MODE_U
	PRINT LOC_FILE
	PRINT MSG_MODE_U_S
	PRINT SRV_NAME
	PRINT MSG_MODE_U_T
	PRINTLN REM_FILE
	RET

MSG_MODE_D
	DB "Download file "Z
MSG_MODE_D_S
	DB " from server "Z
MSG_MODE_D_T
	DB " to file "Z

MSG_MODE_U
	DB "Upload file "Z
MSG_MODE_U_S
	DB " to server "Z
MSG_MODE_U_T
	DB " to file "Z

; ------------------------------------------------------
; Custom messages
; ------------------------------------------------------

MSG_START
	DB "TFTP client for Sprinter-WiFi by Sprinter Team. v1.0 beta1, ", __DATE__, "\r\n"Z

MSG_ERR_CMD
	DB "Invalid command line parameters!\r\n"Z

MSG_HLP
	DB "\r\nUse: wtftp.exe tftp://server[:port]/filename filename  - to download file from server;\r\n"
	DB "     wtftp.exe filename tftp://server[:port]/filename  - to upload file to server.\r\n"Z

MSG_TX_ERROR
	DB "Transmitter not ready"Z

MSG_RX_ERROR
	DB "Receiver error LSR: 0x"
MSG_LSR_VALUE	
	DB "xx"Z

MSG_MANY_RX_ERROR
	DB "Too many receiver errors!"Z

MSG_ERR_PORT
	DB "Invalid UDP port in URL, will be number 1..65535"Z

MSG_ERR_RFN
	DB "Remote file name not specified in URL, or too long!"Z

MSG_ERR_LFN
    DB "Invalid local file name!"Z

; Start of tftf URL
TFTF_START
	DB "tftp://"Z


; Work Mode
WORK_MODE
	DB	WM_DOWNLOAD

; Name/IP of the tftp server
SRV_NAME
	DS 128,0

; UDP port of the tftp server
SRV_PORT
	DB 69,0,0,0,0,0										; udp port number 0..65535

; Name of the source file
REM_FILE
	DS 128,0

; Name of the local file
LOC_FILE	
	DS 128,0

; Local file handle
LOC_FH
	DW	0

; Not null if local file name contains path
HAVE_PATH
	DB	0

; ------------------------------------------------------
; Custom commands
; ------------------------------------------------------
RX_ERR
	DB 0

; 	IFDEF	DEBUG
; CMD_TEST1	DB "ATE0\r\n"Z
; BUFF_TEST1	DS RS_BUFF_SIZE,0
; 	ENDIF

	ENDMODULE

	INCLUDE "wcommon.asm"
	INCLUDE "dss_error.asm"
	;INCLUDE "util.asm"
	INCLUDE "isa.asm"
	INCLUDE "esplib.asm"


    END MAIN.START
