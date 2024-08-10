; ======================================================
; TFTP-protocol support module for WTFTP app
; By Roman Boykov. Copyright (c) 2024
; https://github.com/romychs
; License: BSD 3-Clause
; ======================================================

	MODULE TFTP

; ------------------------------------------------------
; Operation codes 2b for tftp packet header
; ------------------------------------------------------

; Opcode Read Request
OP_RRQ		EQU '01'
; Opcode Write Request
OP_WRQ		EQU	'02'
; Opcode Data packet
OP_DATA		EQU '03'
; Opcode Acknowledge packet
OP_ACK		EQU '04'
; Opcode Error packet
OP_ERROR	EQU '05'

; ------------------------------------------------------
; Build packet for request file from TFTF-server
; Out:	HL - pointer to buffer to send
; ------------------------------------------------------
BUILD_RRQ_PACKET	
	PUSH	DE
	LD		DE,OP_RRQ									; opcode
	CALL	.BUILD_RW_PACKET
	POP		HL,DE
	RET

; ------------------------------------------------------
; Build packet for write file to TFTF-server
; ------------------------------------------------------
!BUILD_WRQ_PACKET
	PUSH	DE
	LD		DE,OP_WRQ									; opcode
	CALL	.BUILD_RW_PACKET
	POP		HL,DE
	RET

; ------------------------------------------------------
; Build packet for write file or receive form TFTF-server
; ------------------------------------------------------
.BUILD_RW_PACKET	
	LD		HL,TFTP_BUFF
	PUSH	HL
	LD		(HL), DE
	INC		HL
	INC		HL
	LD		DE,MAIN.REM_FILE
	; filename
.BRP_NXT_RF
	LD		A, (DE)
	LD		(HL), A
	OR		A
	JR		Z,.BRP_MOD
	INC		HL
	INC		DE
	JR		.BRP_NXT_RF
	; Mode 'octet'Z
.BRP_MOD
	INC 	HL
	LD		DE,'ct'
	LD		(HL),DE
	INC 	HL
	LD		DE,'et'
	LD		(HL),DE
	INC 	HL
	LD		DE,'t'
	LD		(HL),DE
	RET

; ------------------------------------------------------
; Check TFTP Error, out error message if '05' packet
; type received
; Out: CF set if Error
;	   A - packet type, second byte if no errors
; ------------------------------------------------------
CHK_ERROR
	LD		HL,TFTP_BUFF
	LD		A, (HL)
	CP		'0'
	JR		NZ, .CKE_UNKNOWN
	INC		HL
	LD		A, (HL)
	CP		'5'
	JR		Z, .CKE_ERR
	OR		A
	RET
.CKE_ERR
	INC		HL
	LD		DE,(HL)										; ErrorCode
	LD		A, D
	OR		E
	; check for 1..7 range for defined error codes
	JR		Z,.CKE_UNDEF_ERR
	LD		A,E
	CP		8
	JP		P,.CKE_UNDEF_ERR
	; defined error
	ADD		A
	LD		E,A
	LD		HL,.TFTPE_T
	ADD		HL,DE
	LD		A,(HL)
	INC		HL
	LD		H,(HL)
	LD		L,A
	; print error message, HL - pointer to message
.CKE_PRINT_ERR
	PUSH 	HL
	PRINT	.MSG_TFTP_ERR								; Protocol error: ...
	POP		HL
	PRINTLN_HL
	JR		.CKE_ERR_EXIT

	; undefined error, message in datagram
.CKE_UNDEF_ERR
	INC		HL
	INC		HL
	JR		.CKE_PRINT_ERR

.CKE_UNKNOWN
	; unknown packet type
	PRINTLN .MSG_ERR_UPT
.CKE_ERR_EXIT	
	SCF
	RET

; ------------------------------------------------------
; Defined TFTP Protocol Error messages
; ------------------------------------------------------

;MSG_TFTPE_0	DB "Not defined, see error message (if any)."Z
.MSG_TFTPE_1	DB "File not found."Z
.MSG_TFTPE_2	DB "Access violation."Z
.MSG_TFTPE_3	DB "Disk full or allocation exceeded."Z
.MSG_TFTPE_4	DB "Illegal TFTP operation."Z
.MSG_TFTPE_5	DB "Unknown transfer ID."Z
.MSG_TFTPE_6	DB "File already exists."Z
.MSG_TFTPE_7	DB "No such user."Z

; Table with error messages offsets
.TFTPE_T 
	DW	.MSG_TFTPE_1,.MSG_TFTPE_1,.MSG_TFTPE_2,.MSG_TFTPE_3
	DW 	.MSG_TFTPE_4,.MSG_TFTPE_5,.MSG_TFTPE_7,.MSG_TFTPE_7

.MSG_TFTP_ERR
	DB "Protocol error: "Z

.MSG_ERR_UPT
	DB "Unknown TFTP packet received!"Z

; Buffer for UDP datagram with TFTP payload
TFTP_BUFF
	DS 516,0

	ENDMODULE