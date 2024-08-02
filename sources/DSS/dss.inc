; ======================================================
; Defines for DSS Estex for Sprinter computer
; By Roman Boykov. Copyright (c) 2024
; https://github.com/romychs
; ======================================================

	IFNDEF	_DSS_INC
	DEFINE	_DSS_INC

; DSS RST Entry
DSS                 EQU 0x10

; DSS Functions
DSS_CURDISK         EQU 0x02
DSS_CREATE_FILE     EQU 0x0B
DSS_OPEN_FILE       EQU 0x11
DSS_CLOSE_FILE      EQU 0x12
DSS_READ_FILE       EQU 0x13
DSS_WRITE           EQU 0x14
DSS_MOVE_FP_CP      EQU 0x0115
DSS_FIND_FIRST      EQU 0x0119
DSS_FIND_NEXT       EQU 0x011A
DSS_MKDIR           EQU 0x1B
DSS_CHDIR           EQU 0x1D
DSS_CURDIR          EQU 0x1E
DSS_SCANKEY			EQU 0x31
DSS_ECHOKEY			EQU	0x32
DSS_SETMEM			EQU 0x38
DSS_GETMEM			EQU 0x3D
DSS_FREEMEM			EQU	0x3E
DSS_EXIT            EQU 0x41
DSS_WAITKEY			EQU 0x48
DSS_SETVMOD			EQU 0x50
DSS_GETVMOD			EQU 0x51
DSS_CLEAR			EQU 0x56
DSS_PUTCHAR			EQU 0x5B
DSS_PCHARS          EQU 0x5C


DSS_VMOD_T40		EQU 0x02							; text 40x32, 16 colors
DSS_VMOD_T80		EQU 0x03							; text 80x32, 16 colors
DSS_VMOD_G320		EQU 0x81							; graphics 320x256, 256 colors
DSS_VMOD_G640		EQU 0x82							; graphics 640x256, 16 colors


; DSS Error codes
E_FILE_EXISTS       EQU 7
E_FILE_NOT_FOUND    EQU 3

; Keyboard Shift key status bits
KB_R_ALT			EQU 0x01
KB_R_CTRL			EQU 0x02
KB_L_ALT			EQU 0x04
KB_L_CTRL			EQU 0x08
KB_ALT				EQU 0x10
KB_CTRL				EQU 0x20
KB_R_SHIFT			EQU 0x40
KB_L_SHIFT			EQU 0x80


; File attributes
FA_READONLY			EQU 0x01
FA_HIDDEN			EQU 0x02
FA_SYSTEM			EQU 0x04
FA_LABEL			EQU 0x08
FA_DIRECTORY		EQU 0x10
FA_ARCHIVE			EQU 0x20

; File Access mode
FM_READ_WRITE		EQU 0x00
FM_READ				EQU 0x01
FM_WRITE			EQU 0x02

	ENDIF 
