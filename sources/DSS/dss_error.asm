; ======================================================
; DSS Error handler for Sprinter computer
; By Roman Boykov. Copyright (c) 2024
; https://github.com/romychs
; License: BSD 3-Clause
; ======================================================
	MODULE DSS_ERROR

ERR_MAX		EQU  0x26


CHECK
	RET		NC

PRINT
	PUSH	AF
	PRINT	GET_ERR_MSG.MSG_DSS_ERROR
	POP		AF
	CALL	GET_ERR_MSG
	DSS_EXEC	DSS_PCHARS
	LD		HL, WCOMMON.LINE_END
    DSS_EXEC	DSS_PCHARS
	POP 	BC											; clear add from stack
	DSS_EXEC	0x0200+DSS_EXIT							; and exit

; ------------------------------------------------------
; Return pointer to DSS error message
; Inp: A - error code
; Out: HL -> message
; ------------------------------------------------------
GET_ERR_MSG
    CP		ERR_MAX+1
	JP		C,.GEM_IN_RANGE
	LD		A,ERR_MAX 	
.GEM_IN_RANGE
	LD		HL,.ERR_OFFSETS
    PUSH	AF
    ADD		A,A
	LD		D,0
	LD		E,A
	ADD		HL,DE
    LD      A,(HL)
    INC		HL
	LD		H,(HL)
    LD      L,A
	POP		AF
	RET

.MSG_DSS_ERROR
			DB " Error: "Z

.MSG_E01	DB	"Invalid function"Z
.MSG_E02	DB	"Invalid drive number"Z
.MSG_E03	DB	"File not found"Z
.MSG_E04	DB	"Path not found"Z
.MSG_E05	DB	"Invalid handle"Z
.MSG_E06	DB	"Too many open files"Z
.MSG_E07	DB	"File exist"Z
.MSG_E08	DB	"File read only"Z
.MSG_E09	DB	"Root overflow"Z
.MSG_E0A	DB	"No free space"Z
.MSG_E0B	DB	"Directory not empty"Z
.MSG_E0C	DB	"Attempt to remove current directory"Z
.MSG_E0D	DB	"Invalid media"Z
.MSG_E0E	DB	"Invalid operation"Z
.MSG_E0F	DB	"Directory exist"Z
.MSG_E10	DB	"Invalid filename"Z
.MSG_E11	DB	"Invalid EXE-file"Z
.MSG_E12	DB	"Not supported EXE-file"Z
.MSG_E13	DB	"Permission denied"Z
.MSG_E14	DB	"Not ready"Z
.MSG_E15	DB	"Seek error"Z
.MSG_E16	DB	"Sector not found"Z
.MSG_E17	DB	"CRC error"Z
.MSG_E18	DB	"Write protect"Z
.MSG_E19	DB	"Read error"Z
.MSG_E1A	DB	"Write error"Z
.MSG_E1B	DB	"Drive failure"Z
.MSG_E1C	DB	"Unknown error: 28"Z
.MSG_E1D	DB	"Unknown error: 29"Z
.MSG_E1E	DB	"No free memory"Z
.MSG_E1F	DB	"Invalid memory block"Z
.MSG_E20	DB	"Unknown error: 32"Z
.MSG_E21	DB	"Extended error: 33"Z
.MSG_E22	DB	"Extended error: 34"Z
.MSG_E23	DB	"Too many files"Z
.MSG_E24	DB	"Too many or too nested folders (>1024)"Z
.MSG_E25	DB	"User abort"Z
.MSG_E26	DB	"Unknown error"Z

.ERR_OFFSETS
	DW	.MSG_E01,.MSG_E02,.MSG_E03,.MSG_E04,.MSG_E05,.MSG_E06,.MSG_E07,.MSG_E08
    DW	.MSG_E09,.MSG_E0A,.MSG_E0B,.MSG_E0C,.MSG_E0D,.MSG_E0E,.MSG_E0F,.MSG_E10
    DW	.MSG_E11,.MSG_E12,.MSG_E13,.MSG_E14,.MSG_E15,.MSG_E16,.MSG_E17,.MSG_E18
    DW	.MSG_E19,.MSG_E1A,.MSG_E1B,.MSG_E1C,.MSG_E1D,.MSG_E1E,.MSG_E1F,.MSG_E20
    DW	.MSG_E21,.MSG_E22,.MSG_E23,.MSG_E24,.MSG_E25,.MSG_E26

	ENDMODULE
	