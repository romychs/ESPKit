; ======================================================
; DSS Estex dumb for debug code in VSC with DEZOG plugin 
; By Roman Boykov. Copyright (c) 2024
; https://github.com/romychs
; ======================================================
	IFNDEF	_DSS
	DEFINE	_DSS

    ORG 0x0000

RESET:
    JP NOT_IMPL
    DS 5, 0xFF
    
RST08:
    JP NOT_IMPL
    DS 5, 0xFF

    ORG 0x0010    
RST10:
    JP DSS_HANDLER
    DS 5, 0xFF

RST18:
    JP NOT_IMPL
    DS 5, 0xFF

RST20:
    JP NOT_IMPL
    DS 5, 0xFF

RST28:
    JP NOT_IMPL
    DS 5, 0xFF

RST30:
    JP NOT_IMPL
    DS 5, 0xFF

RST38:
    JP NOT_IMPL
    DS 5, 0xFF

DSS_HANDLER
    
    //PUSH    HL
    PUSH    BC
    LD      A, C
    CP      DSS_CURDISK
    JP      Z, _CURDISK
    CP      0x0B
    JP      Z, _CREATE_FILE
    CP      0x11
    JP      Z, _OPEN_FILE
    CP      0x12
    JP      Z, _CLOSE_FILE
    CP      0x13
    JP      Z, _READ_FILE
    CP      0x14
    JP      Z, _WRITE_FILE
	CP		0x19
	JP		Z, _FIND_FIRST
	CP		0x1D
	JP      Z, _CH_DIR
	CP		0x1E
	JP      Z, _CURDIR

	CP		DSS_WAITKEY
	JP      Z, _WAITKEY

	CP		DSS_SCANKEY
	JP      Z, _SCANKEY

	CP		DSS_ECHOKEY
	JP      Z, _ECHOKEY

	CP		DSS_SETVMOD
	JP		Z, _SETVMOD


	CP		DSS_GETVMOD
	JP		Z, _GETVMOD

	CP		low DSS_CLEAR
	JP		Z, _CLEAR

	CP		DSS_PUTCHAR
    JP      Z, _PUTCHAR

    CP      DSS_PCHARS    
    JP      Z, _PCHARS

    CP      0x41
    JP      Z, _EXIT

    POP     BC
    POP     HL
    

NOT_IMPL
    LD A,0x01
    SCF
    RET

_PUTCHAR
	LD BC, 0x9000
	OUT (C),A
	JR	NORM_EXIT
	

_PCHARS
    LD BC, 0x9000

NXT_PCHAR    
    LD A, (HL)
    OUT (C),A
    INC HL
    OR A
    JR	NZ, NXT_PCHAR

NORM_EXIT
	AND A												; CF=0
    POP BC
    //POP HL    
    RET

BAD_EXIT
    SCF
    POP BC
    //POP HL    
    RET


_CURDISK
	LD A, 3
	JP      NORM_EXIT

; Входные значения:
; HL - указатель на файловую спецификацию
; A - атрибут файла
; Выходные значения:
; A — код  ошибки, если CF=1
; A - файловый манипулятор, если CF=0
_CREATE_FILE
    JP  _OPEN_FILE

; Входные значения:
;   HL - указатель на файловую спецификацию
;   A - режим доступа
;   A=0 чтение/запись
;   A=1 чтение
;   A=2 запись
; Выходные значения:
;   A - код ошибки, если CF=1
;   A - файловый манипулятор, если CF=0
CUR_FILE_MAN
    DB  0x4F

CUR_DIR
    DB "\\FOLDER",0
CUR_DIR_END
CUR_DIR_SIZE 	EQU 	CUR_DIR_END-CUR_DIR

_OPEN_FILE
    LD      HL, CUR_FILE_MAN
    INC     (HL)
    LD      A, (HL)
    JP      NORM_EXIT

_CLOSE_FILE
    JP      NORM_EXIT

CUR_F_PTR
    DW  IN_FILE

REMAINS_IN_ZIP
    DW  0

; Входные значения:
; A - файловый манипулятор
; HL - адрес в памяти
; DE - количество читаемых байт
; Выходные значения:
; A - код ошибки, если CF=1
; DE - реальное количество прочитанных байт
; если CF=0:
; A = 0 прочитаны все байты
; A = 0FFh прочитано меньшее число байт
_READ_FILE
    OR      A
    JP	    Z, BAD_EXIT
	LD		B,D											; BC - bytes to read
	LD		C,E
    PUSH    HL                                          

    LD      HL, (CUR_F_PTR)                             ; HL -> IN ZIP_FILE
    LD      DE, IN_FILE_END
    EX      HL, DE
    SUB     HL, DE                                      ; HL = remain bytes
    LD      (REMAINS_IN_ZIP), HL
    SBC     HL, BC
    LD	    A, 0
    JR      NC, NO_OUT_OF_ZIP
    DEC     A
    LD      HL,(REMAINS_IN_ZIP)
    LD      BC, HL

NO_OUT_OF_ZIP
    LD      HL, (CUR_F_PTR)
    POP     DE                                          ; DE - Buffer to write
    PUSH    BC
    LDIR
    POP     DE                                          ; DE = bytes read, A = 0 or 0xFF
    LD      (CUR_F_PTR), HL
    
    JP      NORM_EXIT


; Входные значения:
; A - файловый манипулятор
; HL - адрес в памяти
; DE - количество записываемых байт
; Выходные значения:
; A - код ошибки, если CF=1
; DE - реальное количество записанных байт
_WRITE_FILE
    
	LD		B, D
	LD		C, E
    LD      DE,OUT_FILE

    PUSH    BC
    LDIR
    POP     DE
    JP      NORM_EXIT

; Входные значения:
; HL - указатель на файловую спецификацию
; Выходные значения:
; A - код ошибки, если CF=1
_CH_DIR
    JP      NORM_EXIT


; 1Eh (30) CURDIR (Информация о текущем каталоге)
; Входные значения:
; HL - буфер в памяти 256 байт
; Выходные значения:
; A - код ошибки, если CF=1
_CURDIR
	PUSH	DE
	LD		DE, CUR_DIR
	EX		HL,DE
	LD		BC, CUR_DIR_SIZE
	LDIR
	POP 	DE
	JP		NORM_EXIT

_ECHOKEY
	PUSH	HL
	LD		HL,EC
    LD      C,DSS_PCHARS
    RST     DSS
	POP		HL
	LD		A,(EC)
	JP		NORM_EXIT

EC 	DB "3",0

; Входные значения:
; HL - указатель на файловую спецификацию
; DE - рабочий буфер 44 байта, если B=0, иначе 256 байт
; A - атрибуты, используемые при поиске
; B = 0 - имя найденного файла в формате 11 байт "FilenameExt"
; B = 1 - имя найденного файла в формате DOS "filename.ext",0
; C - 19h
; Выходные значения:
; A - код ошибки, если CF=1
_FIND_FIRST
	PUSH	DE
	LD 		HL, 33										; offset of file name
	ADD 	HL, DE				
	EX 		HL, DE
	LD 		HL, IN_FILE_NAME
	LD 		BC,9
	LDIR
	POP 	DE
    JP      NORM_EXIT


_SCANKEY
    POP 	BC
    POP 	HL    
	LD		A,1
	AND		A
	LD		E, 'x'
	LD 		B, KB_ALT | KB_L_ALT
    RET


; Выходные значения:
; A - код символа
; D - позиционный код
; Е - ASCII код
; C - режим клавиатуры:
_WAITKEY
	XOR		A
	LD		D, A
	;LD		C, A
	LD		E,65
	LD		A,E
    JP      NORM_EXIT


CUR_VMOD
	DB 1

; 50h (80) SETVMOD (Выбор режима экрана)
; Входные значения:
; A - режим экрана:
; 02h - текстовый 40x32x16 цветов;
; 03h - текстовый 80x32x16 цветов;
; 81h - графический 320x256x256 цветов;
; 82h - графический 640x256x16 цветов;
; B - страница экрана 0/1
; C - 50h
; Выходные значения:
; A - код ошибки, если CF=1
_SETVMOD
	LD		(CUR_VMOD),A
	JP      NORM_EXIT

; 51h (81) GETVMOD (Получить текущий режим экрана)
; Входные значения:
; C - 51h
; Выходные значения:
; A - код ошибки, если CF=1
; A - текущий режим экрана, если CF=0
; B - страница экрана 0/1
_GETVMOD
	LD		A,(CUR_VMOD)
	JP      NORM_EXIT

; 56h (86) CLEAR (Очистка окна)
; Входные значения:
; D - строка левого верхнего угла окна
; E - столбец левого верхнего угла окна
; H - высота окна
; L - ширина окна
; B - атрибут заполнитель
; A - символ заполнитель
; C - 56h
; Выходные значения:
; нет
_CLEAR
	JP      NORM_EXIT


_EXIT
;   LOGPOINT STOPPED!    

    HALT
    JP _EXIT

CMD_LINE_TFTP_D
	DB " tftp://tftp.server.ru:1024/file_in.asm  c:\\tmp\\file_out.asm",0

CMD_LINE_TFTP_D1
	DB " tftp://server.ru/file.src sss.dst",0

CMD_LINE_TFTP_U
	DB " file_from.asm tftp://server.ru:9999/file_to.asm",0

CMD_LINE_TFTP_U1
	DB " file_up.txt",0


IN_FILE
	DS 1024,0
IN_FILE_END
IN_FILE_NAME
	DB "infile.txt"
OUT_FILE
	DS 1024,0

    ALIGN 16384, 0

	ENDIF