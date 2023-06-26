.286
; .386
.Model small
.Stack 256
.Data
include vars.txt
ANDGATENAME DB "AND$"
C1 DB 0
Resurrected DB 0
StartingMesg DB "The game has just started!$"
INHERE DB "In here$"
HOST DB ?
VALUE DB 0
; HOSTDETERMINED DB ?
received db "received$"
; ALINSENDIS DB "AL IN SEND IS $"
HOSTDETERMINED DB 0
sent db "sent$"
.Code
INCLUDE PROC1.INC
INCLUDE SERIAL.INC
; INCLUDE MACROS.INC
MAIN PROC FAR
    MOV AX , @DATA
    MOV DS , AX
initializeserial; initialize the serial ports and set the configuration (baud rate, parity,etc.)
CLEARSCREEN
graphicalmode
XOR SI,SI
XOR DX,DX
XOR BX,BX
XOR AX,AX
; for two players with serial 
; CALL NAMESCREEN
; CALL MAINSCREEN_SERIAL

; for a single PC without serial 
CALL MAINSCREEN

; CALL GAMESCREEN
; CALL KEEP_PLAYING
exit
RET

MAIN ENDP

DRAWVERTICALUP PROC NEAR;XNODE,YNODE,YFINAL ;YFINAL MUST BE < YNODE
        PUSHA
        MOV CX, xnode
        MOV DX, ynode 
        BACK_VUP:
        MOV AH, 0CH
        MOV AL,1
        INT 10H
        DEC DX
        CMP DX, Yfinal
        JNZ BACK_VUP
        POPA
        RET
DRAWVERTICALUP ENDP 
DRAWVERTICALDOWN PROC NEAR;XNODE,YNODE,YFINAL ;YFINAL MUST BE < YNODE
        PUSHA
        MOV CX, xnode
        MOV DX, ynode 
        BACK_VDOWN:
        MOV AH, 0CH
        MOV AL,1
        INT 10H
        INC DX
        CMP DX, Yfinal
        JNZ BACK_VDOWN
        POPA
        RET
DRAWVERTICALDOWN ENDP 

StatusBarUpdate PROC NEAR
        PUSHA
        movecursor 27,0
        LEA DX,StartingMesg
        CALL WSTRING
        MOV CLEARSTATUSBAR,1H
        POPA
        RET
StatusBarUpdate ENDP

CleanStr PROC NEAR; a procedure to convert any lower case to upper for ease of use, it's also copied into another var
        LOWER_TO_UPPER RECEIVED_COMMAND
        LEA SI,Received_Command
        LEA DI,Store_Command
        MOV COPYSTRING_SIZE,7
        CALL COPYSTRING
        RET
CleanStr ENDP


RESETSTRINGS2 PROC NEAR
        PUSHA
        XOR SI,SI
        R092:
        MOV [MYCOMMAND+SI],'$'
        MOV [HISCOMMAND+SI],'$'
        INC SI
        CMP SI,7
        JNZ R092
        POPA
        RET
RESETSTRINGS2 ENDP

ResetRegisters:
        XOR AX,AX
        XOR BX,BX
        XOR CX,CX
        XOR DX,DX
        XOR DI,DI
        XOR SI,SI
RET
LevelTwo Proc                 ;Same logic as level 1, but checks if the entire string is 1's or 0's before declaring the winner
MOV ax,ds
MOV es,ax

 compP1_1:  ;check if player 1 has all ones
MOV si,offset LogicValue+90
MOV di,offset ones
MOV cx,5
repe cmpsb
JE cond2
back1:
MOV si,offset LogicValue+95 ;check if player 2 has all ones
MOV di,offset ones
MOV cx,5
repe cmpsb
JE cond3
JMP SKIP


cond2:
MOV si,offset LogicValue+95
MOV di,offset zeroes
MOV cx,5
repe cmpsb
JE PrintWinner1
jmp back1

cond3:
MOV si,offset LogicValue+90
MOV di,offset zeroes
MOV cx,5
repe cmpsb
 JE PrintWinner2
 jmp skip


PrintWinner1:
;ShowMessage winner1
lea dx,winner1
MOV ah,9
int 21h
jmp skip

PrintWinner2:
 ;ShowMessage winner2
lea dx,winner2
MOV ah,9
int 21h


skip:
ret
LevelTwo endp
KEEP_PLAYING PROC NEAR
PUSHA
CALL ResetRegisters
mov firgame,1
RestartLoop:
CALL ResetStrings2
MOV myBufferCount,0
MOV hisBufferCount,0
INFINITELOOP:
CMP CHOSENLEVEL,1H
JNZ LEVELTWO_CHECK1
CALL LEVELONE
JMP P095
LEVELTWO_CHECK1:
CALL LevelTwo
; XOR BX,BX
p095:
CHECKBUFFER
JZ CheckSerial_intr

CheckMyKeyboard:
GetKeyPress
MOV CHAR_BUFFER, AL
MOV DX,3FDH 		; Line Status Register
IN AL,DX 	;Read Line Status
TEST AL,00100000b
JZ CheckSerial_intr                    ;Not empty
MOV DX,3F8H		; Transmit data register
MOV AL,CHAR_BUFFER        ; put the data into al
OUT DX,AL         ; sending the data
jmp justintr
;intermediate label
CheckSerial_intr:
JMP CHECKSERIAL

justintr:
CMP AL,'F'
JE RestartLoop
CMP AL,'f'
JE RestartLoop
CMP AH,F2scancode; would need to be edited to accomodate for the exitto mainscreen request
JNE RT10
MOV Resurrected,1h
JMP ExitFromGameScreenRequested
RT10:
CMP AL,27D
JNZ NOT_ESC
EXIT
NOT_ESC:
CMP AH,42H
JNZ NOT_SENDING_GAMECHAT_INVITATION
MOV BL,0C9H
CALL SENDBYTE
WAITING_FOR_HIM_TO_ACCEPT_INGAME_CHAT:
CALL RECIEVEBYTE
CMP BL,0C9H
JNZ WAITING_FOR_HIM_TO_ACCEPT_INGAME_CHAT
CALL detectGameChat
JMP RESTARTLOOP
NOT_SENDING_GAMECHAT_INVITATION:
MOV BL,myBufferCount
MOV [MYCOMMAND+BX],AL
INC BL
MOV myBufferCount,BL
CMP [MYCOMMAND],'W'
JE CMP4FORW
CMP [MYCOMMAND],'w'
JE CMP4FORW
CMP [MYCOMMAND],'M'
JE CMP2FORM
CMP [MYCOMMAND],'m'
JE CMP2FORM
;ELSE COMPARE AGAINST 7
CMP BL,7
JMP CONDITION_CHECK
CMP2FORM:
CMP BL,5
JMP CONDITION_CHECK
CMP4FORW:
CMP BL,5
CONDITION_CHECK:
; CMP BL,7
JNZ NOT_7YET
MOV COPYSTRING_SIZE,7
LEA SI,MYCOMMAND
; LEA DI,STORE_COMMAND
LEA DI,RECEIVED_COMMAND
CALL COPYSTRING
CALL CleanStr
;ADD STRING AND COMMAND VALIDATION FUNCTIONS HERE
CALL ParseCommand
MOVECURSOR 28,0
MOV myBufferCount,0
JMP CHECKSERIAL ; VERY SUSPICIOUS LINE
NOT_7YET:
JMP INFINITELOOP
CheckMyKeyboard_intr:
jmp CheckMyKeyboard

CheckSerial:
CheckBuffer 
JNZ CheckMyKeyboard_intr
; CALL RecieveData
MOV DX,3FDH		; Line Status Register
IN AL,DX 
TEST AL,1
JZ CHECKSERIAL   

; If Ready read the VALUE in Receive data register
MOV DX,03F8H
IN AL,DX 
MOV CHAR_BUFFER,AL 

CMP AL,'F'
JE NOT_7YET
CMP AL,'f'
JE NOT_7YET
CMP AH,F2scancode; would need to be edited to accomodate for the exitto mainscreen request
JNE RT67
; WE WOULDN'T DISCARD HIS F2 THOUGH
MOV Resurrected,1H
; JMP ExitFromGameScreenRequested
RT67:
CMP AL,27D; Escscancode
JNZ NOT_ESC2
EXIT
NOT_ESC2:
CMP AL,0C9H
JNZ THEY_DONT_WANNA_CHAT
MOVECURSOR 27,0
LEA DX,ReceiverGameChatInvite
CALL WSTRING
RE45:
CHECKBUFFER
CMP AL,'F'
JZ NOT_INTERESTED
CMP AL,'f'
JZ NOT_INTERESTED
CMP AL,0C9H
JNZ RE45 ;CHECKBUFFER
JMP WOULD_I_ACCEPT_GAMECHAT

NOT_INTERESTED:
JMP RestartLoop

WOULD_I_ACCEPT_GAMECHAT:
MOV BL,0C9H; F10
CALL SENDBYTE
CALL detectGameChat
JMP NOT_INTERESTED
THEY_DONT_WANNA_CHAT:
MOV BL,hisBufferCount
MOV [HISCOMMAND+BX],AL
INC BL
MOV hisBufferCount,BL
CMP [HISCOMMAND],'W'
JE CMP4FORW2
CMP [HISCOMMAND],'w'
JE CMP4FORW2
CMP [HISCOMMAND],'M'
JE CMP2FORM2
CMP [HISCOMMAND],'m'
JE CMP2FORM2
;ELSE COMPARE AGAINST 7
CMP BL,7
JMP CONDITION_CHECK2
CMP2FORM2:
CMP BL,5
JMP CONDITION_CHECK2
CMP4FORW2:
CMP BL,5
CONDITION_CHECK2:
JNZ NOT7YET2
MOV COPYSTRING_SIZE,7
LEA SI,HISCOMMAND
LEA DI,RECEIVED_COMMAND
CALL COPYSTRING
CALL CleanStr
CALL ParseCommand
MOV hisBufferCount,0
; MOVECURSOR 29,0
; LEA DX,STORE_COMMAND
; CALL WSTRING
NOT7YET2:
JMP INFINITELOOP
ExitFromGameScreenRequested:
MOV ExitToMainScreen,1
POPA
RET
KEEP_PLAYING ENDP

WhichSpecial PROC NEAR
;NOTE, for ease of sending serial data and without the overhead of sending the scan codes of the special function
;keys F1->F9, I have chosen the ASCII code of some characters (characters that aren't even available on the standard 
;keyboard to be sent on the serial port instead of the scancodes of the function keys,starting from 3BH 
; PUSHA
MOV BH,AH; MOV THE SCANCODE THAT WE GOT 
CMP BH,3BH;
JZ itwasF1
CMP BH,3CH
JZ ITWASF2
CMP BH,3DH
JZ itwasF3
CMP BH,3EH
JZ ITWASF4
CMP BH,3FH
JZ itwasF5
JMP WhichSpecial_end
itwasF1:
MOV AL,0C0H; for F1 of scancode 3BH I chose to send the ASCII 0C0H over the serial port 
JMP WhichSpecial_end
ITWASF2:
MOV AL,0C1H
JMP WhichSpecial_end
itwasF3:
MOV AL,0C2H
JMP WhichSpecial_end
itwasF4:
MOV AL,0C3H
JMP WhichSpecial_end
itwasF5:
MOV AL,0C4H
WhichSpecial_end:
; POPA
RET
WhichSpecial ENDP

MAINSCREEN_SERIAL PROC NEAR
MAIN_LOOP:
CLEARSCREEN
movecursor 09h, 10h
LEA DX,MES1
CALL WSTRING
movecursor 0bh,10h
LEA DX,MES2
CALL WSTRING
movecursor 0dh,10h
LEA DX,MES3
CALL WSTRING
CMP NOTFIRSTGAME,1H
JNZ FIRSTGAME_MAIN_SEND
movecursor 0fh,10h
LEA DX,StrNewGame
CALL WSTRING
FIRSTGAME_MAIN_SEND:
movecursor 15h,00h
LEA DX,MES5
CALL WSTRING
; waitforuseractionMS:
RECHECK_MY_BUFFER:
CheckBuffer 
JZ CheckSerial_MAIN_intr 
CheckMyKeyboard_main:
GetKeyPress
MOV CHAR_BUFFER, AL
MOV SCAN_BUFFER,AH
MOV DX,3FDH 		; Line Status Register
IN AL,DX 	;Read Line Status
TEST AL,00100000b
JZ CheckSerial_MAIN_intr                    ;Not empty
MOV DX,3F8H		; Transmit data register
MOV AL,CHAR_BUFFER        ; put the data into al
CMP AL,0
JZ SPECIAL_KEY_WAS_PRESSED
OUT DX,AL       ; sending the data           
JMP NOTSPECIALKEY
SPECIAL_KEY_WAS_PRESSED:
CALL WhichSpecial ; BT7OT FEL AL EL VALUE ELY 7T-CHECK BEH 3LA EL SPECIAL FUNCTION B3DEN
OUT DX,AL; SEND THE SCANCODE INSTEAD OF THE ASCII
JMP NOTSPECIALKEY ; THIS IS JUST TO SKIP THE INTERMEDIATE LABEL
MAIN_LOOP_INTR:
JMP MAIN_LOOP
NOTSPECIALKEY:
CMP AL, 27D;        
JNE CHECKF3FORNEWGAME_MAIN
clearscreen
JMP ESC_WAS_PRESSED
CHECKF3FORNEWGAME_MAIN:
JMP checkf1_MAIN_SEND ; should be deleted
;--shouldn't be here, just an intermedite label
CheckSerial_MAIN_intr:
JMP CHECKSERIAL_IN_MAIN
RECHECK_MY_BUFFER_INTR:
JMP RECHECK_MY_BUFFER
;--------------------------
; check if key is F1 FOR CHATTING                    
checkf1_MAIN_SEND:
CMP AH,3EH; actually this if f4
JNE checkf2_MAIN
MOV IamChatHost,'y'
MOVECURSOR 27,0
LEA DX,SENDCHATINVITATIONMSG
CALL WSTRING 
WAITING_FOR_HIM_TO_ACCEPT_CHAT_INVITATION:
CALL RECIEVEBYTE
CMP BL,0C3H
JNZ WAITING_FOR_HIM_TO_ACCEPT_CHAT_INVITATION
CLEARSCREEN
XOR SI,SI
XOR BX,BX
TEXTMODE
CALL chatSCREEN
; CODE WOULD NEED TO BE ADDED HERE TO RESTORE THE LAST MESSAGES AND THE CURSOR POSITION
JMP MAIN_LOOP_INTR

checkf2_MAIN:
cmp ah, F2scancode
JNE RECHECK_MY_BUFFER_INTR;MAIN_LOOP_INTR
CMP IamHost,0
JNZ HOST_WAS_ALREADY_DETERMINED; M3NAH ENO MSH AWL MRA W ENO FL CASE 3AWZ YRG3 TANI LEL GAME
MOV IamHost,'y'
JMP SEND_HIM_AN_INVITATION
HOST_WAS_ALREADY_DETERMINED: ;eh ely elmfroud y7sl?
SEND_HIM_AN_INVITATION:
MOVECURSOR 27,0
LEA DX,SendGameInvitationMsg; teststr2
CALL WSTRING
WAITING_FOR_HIM_TO_ACCEPT:
CALL RecieveByte
CMP BL,0C1H
JNZ WAITING_FOR_HIM_TO_ACCEPT
I_WILL_DETERMINE_THE_LEVEL:
cmp firgame,0
JnZ STARTTHEFUN_MAIN_SEND
CLEARSCREEN
TEXTMODE
CALL ChooseLevel
MOV BL,CHOSENLEVEL
ADD BL,30H
mov DX, 3F8H		        ; Transmit data register
mov al, BL
out DX, al
STARTTHEFUN_MAIN_SEND:
XOR SI,SI
XOR BX,BX
CALL GAMESCREEN; gamescreen is drawn here
; CMP RESURRECTED,1H
; JZ RESURRECTED_SEND
CALL KEEP_PLAYING
; JMP NOT_RESURRECTED0
; RESURRECTED_SEND:
; MOV RESURRECTED,1H
; CALL RESURRECTGAME
; NOT_RESURRECTED0:
JMP MAIN_LOOP
; some variables would need a nice reset here
; RET
; MOV midgame,1H
; MOV NOTFIRSTGAME,1H

CheckMyKeyboard_MAIN_INTR:
JMP CheckMyKeyboard_MAIN
;-------------------------------------Receiver's Side------------------------------
CHECKSERIAL_IN_MAIN:
CheckBuffer
JNZ CheckMyKeyboard_MAIN_INTR
MOV DX,3FDH		; Line Status Register
IN AL,DX 
TEST AL,1
JZ CHECKSERIAL_IN_MAIN   
; If Ready read the VALUE IN Receive data register
MOV DX,03F8H
IN AL,DX 
MOV CHAR_BUFFER , AL
CALL CheckSpecial
CMP AL,27D
JE ESC_WAS_PRESSED_INTR
CMP AL,0C3H
JE HE_SENT_A_CHAT_INVITATION
CMP AL,0C1H
JE HE_SENT_A_GAME_INVITATION
;---------WHAT HAPPENS IF HE PRESSED ANYTHING ELSE??? TO BE ADDED
                             HE_SENT_A_CHAT_INVITATION:
CMP IamChatHost,0; if true, he had just sent me a chat invitation
JNZ ITS_NOT_HIS_FIRST_F4
MOV IamChatHost,'n'
JMP AcceptChatInvitationLoop
ITS_NOT_HIS_FIRST_F4:
MOVECURSOR 27,0 
LEA DX,AcceptChatInvitationMSg
CALL WSTRING
AcceptChatInvitationLoop:
getkeypress
CMP AH,3EH
JNZ AcceptChatInvitationLoop
MOV BL,0C3H
CALL SENDBYTE
CLEARSCREEN
XOR SI,SI
XOR BX,BX
TEXTMODE
CALL chatSCREEN
JMP MAIN_LOOP_INTR
ESC_WAS_PRESSED_INTR:
JMP ESC_WAS_PRESSED
                                  HE_SENT_A_GAME_INVITATION:
                                  CMP FIRGAME,0
                                  JNZ ER4
MOVECURSOR 27,0
LEA DX,AcceptGameInvitationMSg
CALL WSTRING
CMP IAMHOST,0 ; IF TRUE M3NAH ENO HWA LESA BA3TLY GAME INVITATION
JNZ ITS_NOT_HIS_FIRST_F2
MOV IAMHOST,'n'
JMP AcceptingGameInvitationLoop
ITS_NOT_HIS_FIRST_F2:;eh ely elmfroud y7sl?
XOR BX,BX
AcceptingGameInvitationLoop:
MOVECURSOR 27,0
LEA DX,AcceptGameInvitationMSg
CALL WSTRING
getkeypress
CMP AH,F2SCANCODE
JNZ AcceptingGameInvitationLoop
MOV BL,0C1H
CALL SENDBYTE; Notify him that I've accepted his game invitation, we should both now go the GAMESCREEN
LEA DX,WaitForLevelMsg
CALL WSTRING
WAITING_HIM_TO_DETERMINE_LEVEL:
CALL RECIEVEBYTE
CMP BL,'1'
JZ HE_CHOSE_THE_LEVEL
CMP BL,'2'
JZ HE_CHOSE_THE_LEVEL
JMP WAITING_HIM_TO_DETERMINE_LEVEL
HE_CHOSE_THE_LEVEL:
SUB BL,30H
MOV CHOSENLEVEL,BL

ER4:
XOR BX,BX
XOR SI,SI
CALL GAMESCREEN
; CMP ExitToMainScreen,1H
; JE RESURRECTGAME_L
CMP FIRGAME,0H
JZ STARTPLAYING
MOV RESURRECTED,1H
CALL ResurrectGame
STARTPLAYING:
CALL KEEP_PLAYING
; JMP NOT_RESURRECTED 
; RESURRECTGAME_L:
MOV RESURRECTED,1H
; CALL ResurrectGame
; NOT_RESURRECTED:
JMP MAIN_LOOP_INTR;RECHECK_MY_BUFFER
ESC_WAS_PRESSED:
EXIT
RET
MAINSCREEN_SERIAL ENDP

    CHECKLEVEL2 PROC NEAR           
    PUSHA  
    XOR DX,DX
    MOV SI,90
    ;SUMMING THE FIRST 5 POINTS 90->94
    SUMMINGFIRST:
    MOV AL,[LOGICVALUE+SI]
    CMP AL,85; U ASCII code
    JZ ADD2INSTEAD1
    ADD DL,[LOGICVALUE+SI]
    JMP D12
    ADD2INSTEAD1:
    ADD DL,2
    D12:
    INC SI 
    CMP SI,95
    JNZ SUMMINGFIRST
    MOV SUMFIRST5,DL
    ;SUMMING THE LAST 5 POINTS 95->99
    MOV SI,95
    XOR CX,CX
    SUMMINGSECOND:
    MOV AL,[LOGICVALUE+SI]
    CMP AL,85 
    JZ ADD2INSTEAD2
    ADD CL,[LOGICVALUE+SI]
    JMP C12
    ADD2INSTEAD2:
    ADD CL,2
    C12:
    INC SI
    CMP SI,100D
    JNZ SUMMINGSECOND    
    MOV SUMLAST5,CL
    CMP DL,5
    JNE CHECKPLAYER2   
    CHECK_CL_EQUAL_ZEROES:
    CMP CL,0
    JE PLAYER1WINS
    JMP NONEWINS
    CHECKPLAYER2:
    CMP DL,0
    JNE NONEWINS
    CMP CL,5
    JE PLAYER2WINS
    JMP NONEWINS
    PLAYER2WINS:
    MOV PLAYER2WIN,1
    CALL WinLevelP2
    JMP NONEWINS
    PLAYER1WINS:
    MOV PLAYER1WIN,1
    CALL WinLevelP1
    NONEWINS:
    MOV SUMFIRST5,0
    MOV SUMLAST5,0
    POPA
    RET
CHECKLEVEL2 ENDP

CheckSpecial PROC NEAR


RET
CheckSpecial ENDP

;---------------------Non-Serial Play Function-------------------------
PLAY PROC NEAR
PUSHA
CMP Resurrected,1H
JNE FIRSTIMEGAME
CALL ResurrectGame
XOR BX,BX
JMP R45
FIRSTIMEGAME:
CALL StatusBarUpdate
; CALL RANDOMIZE
XOR BX,BX
R45:
XOR BX,BX
R46: 
PUSH BX
CALL RECEIVECOMMAND
; CMP ExitToMainScreen,1
; JZ ExitRequested
CALL CleanStr
CALL ParseCommand
; ; call sound
CMP CHOSENLEVEL,1H
JNZ LEVELTWO_CHECK
CALL LEVELONE
CMP GAMEENDED,1H
JZ Game_hasEnded
JMP P09
LEVELTWO_CHECK:
CALL CHECKLEVEL2
CMP GAMEENDED,1H
JZ Game_hasEnded
P09:
POP BX 
INC BX 
CMP BX,500
JNZ R46
JMP PLAYED_TILLEND
ExitRequested:
; POP BX
JMP R78
Game_hasEnded:
CALL ResetForNewGame
CALL my_delay
JMP PLAYED_TILLEND
R78:
POP BX
MOV ExitToMainScreen,0H
PLAYED_TILLEND:
POPA
RET
PLAY ENDP

ResurrectGame PROC NEAR
PUSHA
MOV BX,10D
; MOV SpotIsOccupied,0D
MOV RESTORAL,1H
MOV bool,20
ResurrectionLoop:
XOR AX,AX
MOV AL,[ip1ColIndex+BX]
MOV ip1_col,AL
MOV AL,[ip1RowIndex+BX]
MOV ip1_row,AL
MOV AL,[ip2ColIndex+BX]
MOV ip2_col,AL
MOV AL,[ip2RowIndex+BX]
MOV ip2_row,AL
MOV AL,BL
; PUSH BX
MOV DL,10D
DIV DL
MOV OP_COL,AL
MOV OP_ROW,AH
; POP BX
MOV AL,[Operation+BX]
CMP AL,'A'
JE ANDGATER
CMP AL,'O'
JE ORGATER
CMP AL,'D'
JE NANDGATER
CMP AL,'R'
JE NORGATER
CMP AL,'X'
JE XORGATER
CMP AL,'N'
JE XNORGATER
JMP NULLSPACE
MIDRESURRECTIONLABEL:
JMP ResurrectionLoop
ANDGATER:
; MOV RESTORAL,1H
CALL DRAWANDGATE
; CALL RestoreAnd
JMP FINISHED2
ORGATER:
CALL DRAWORGATE
JMP FINISHED2
XORGATER:
CALL DRAWXORGATE
JMP FINISHED2
NANDGATER:
CALL DRAWNANDGATE
JMP FINISHED2
NORGATER:
CALL DRAWNORGATE
JMP FINISHED2
XNORGATER:
CALL DRAWXNORGATE
JMP FINISHED2
FINISHED2:
; PUSH BX
; MOV BL,10D
; CALL NodeRecreation
; POP BX
NULLSPACE:
INC BX
CMP BX,100D
JNZ MIDRESURRECTIONLABEL
MOV Resurrected,0H
MOV RESTORAL,0H
MOV SpotIsOccupied,0D
MOV SpotTaken,0D
MOV BL,10D
CALL NodeRecreation
POPA
RET
ResurrectGame ENDP


CheckWinner PROC NEAR
PUSHA


POPA
RET
CheckWinner ENDP


     DRAW_SQUARE PROC NEAR; RECEIVES IN THE FOLLOWING VARIABLES XNOTE,YNOTE,WIDTH,HEIGHT,Draw_Square_Color
        PUSHA
        MOV AX,YNOTE
        ADD AX,Draw_Square_Height
        MOV VW,AX
        MOV AH,0CH
        MOV AL,Draw_Square_Color
        MOV CX,XNOTE
        MOV DX,YNOTE
        MOV BX,Draw_Square_Width
        DRAW_101:
        INT 10H
        INC CX
        DEC BX
        JNZ DRAW_101
        MOV CX,XNOTE
        INC DX   
        MOV BX,Draw_Square_Width
        CMP DX,VW
        JNZ DRAW_101
        POPA
        RET
     DRAW_SQUARE ENDP   



RANDOMIZE PROC NEAR   
    XOR SI,SI
    R298:
    MOV AH,0
    INT 1AH
    MOV AX,DX
    MOV DX,0
    MOV BX,10
    DIV BX
    CMP DL,5
    JL MOVONE
    MOV [LOGICVALUE+SI],0
    MOVONE:
    JMP A54
    MOV [LOGICVALUE+SI],1
    A54:
    INC SI
    CMP SI,10D
    JNZ R298  
    RET 
    RANDOMIZE ENDP

ResetStrings PROC NEAR
PUSHA
XOR BX,BX
RE934:
MOV[RECEIVED_COMMAND+BX],'$'
MOV [Store_Command+BX],'$'
INC BX
CMP BX,7H
JNZ RE934
POPA
RET
ResetStrings ENDP

ParseCommand PROC NEAR 
PUSHA
MOV AL,Store_Command
CMP AL,'A'; we won't check for lowercase as already any lowercase letter is by now uppercase
JE ANDGATE
CMP AL,'O'
JE ORGATE
CMP AL,'D'
JE NANDGATE
CMP AL,'R'
JE NORGATE
CMP AL,'X'
JE XORGATE
CMP AL,'N'
JE XNORGATE
CMP AL,'W'
JE WIRE_COMMAND_INTR
CMP AL,'M'
JE REMOVE_COMMAND_INTR
CMP AL,'C'
JE CHAT_COMMAND_INTR
ANDGATE:
CALL ValidateCommand
CMP ApprovedCommand,1H
JNE COMMAND_WAS_INVALID_INTERMEDIATE
CALL DRAWANDGATE
JMP X_END505
CHAT_COMMAND_INTR:
JMP CHAT_COMMAND
ORGATE:
CALL ValidateCommand
CMP ApprovedCommand,1H
JNE COMMAND_WAS_INVALID_INTERMEDIATE
CALL DRAWORGATE
JMP X_END505
WIRE_COMMAND_INTR:
JMP WIRE_COMMAND
NANDGATE:
CALL ValidateCommand
CMP ApprovedCommand,1H
JNE COMMAND_WAS_INVALID_INTERMEDIATE
CALL DRAWNANDGATE
JMP X_END505
NORGATE:
CALL ValidateCommand
CMP ApprovedCommand,1H
JNE COMMAND_WAS_INVALID_INTERMEDIATE
CALL DRAWNORGATE
JMP X_END505
XORGATE:
CALL ValidateCommand
CMP ApprovedCommand,1H
JNE COMMAND_WAS_INVALID_INTR
CALL DRAWXORGATE
JMP X_END505
XNORGATE:
CALL ValidateCommand
CMP ApprovedCommand,1H
JNE COMMAND_WAS_INVALID_INTERMEDIATE
CALL DRAWXNORGATE
JMP X_END505
COMMAND_WAS_INVALID_INTR:
JMP COMMAND_WAS_INVALID
REMOVE_COMMAND_INTR:
JMP REMOVE_COMMAND
COMMAND_WAS_INVALID_INTERMEDIATE:
MOVECURSOR 27,0
LEA DX,INVLD_CMD_MSG
CALL WSTRING
JMP COMMAND_WAS_INVALID
WIRE_COMMAND:
CALL ShiftString_Wiring
CALL DRAWWIRE
CMP INVALIDWCOMMAND,1H
JZ WIRECOMMANDSPECIAL_INTER
JMP X_END505
REMOVE_COMMAND:
; TODO: PROHIBIT REMOVING COLUMN ZERO
CALL ShiftString_Remove
MOV AL,[STORE_COMMAND+5]
SUB AL,30H
MOV OP_COL,AL
MOV AL,[STORE_COMMAND+6]
SUB AL,30H
MOV OP_ROW,AL
XOR AH,AH
MOV AL,OP_COL
MOV DL,10
MUL DL
ADD AL,OP_ROW
XOR BX,BX
MOV BL,AL
MOV DL,[SpotOccupied+BX]
CMP DL,0
JZ COMMAND_WAS_INVALID
MOV BX,AX
MOV VR3,BL
CMP [OPERATION+BX],'W'
JNZ ISAGATE
CALL REMOVEWIRE
JMP X_END505
WIRECOMMANDSPECIAL_INTER:
JMP WIRECOMMANDSPECIAL
ISAGATE:
CALL DRAWWHITESPACE 
; CMP SpotIsOccupied,1H
; JNE COMMAND_WAS_INVALID
JMP X_END505
CHAT_COMMAND:
X_END505:;now we highlight the node with the appropriate color, green logic 1, red logic 0, black 'U'
; COMMAND_WAS_INVALID: VERY ORIGINAL PLACE
XOR BX,BX
MOV AL,OP_COL
MOV BL,10D
MUL BL
MOV BL,AL
MOV GameScr_LogicValue,BL
LOOP202:
CALL RetrieveOperands
CALL UpdateAllLogicValues
INC BX
CMP BX,100
JNZ LOOP202
XOR BX,BX
MOV BL,10D
CALL NodeRecreation
COMMAND_WAS_INVALID:
WIRECOMMANDSPECIAL:
MOV INVALIDWCOMMAND,0H
POPA
RET
ParseCommand ENDP
; HighlightFinalNodes PROC NEAR
; PUSHA
; MOV BX,10D
;             MOV CX,625 ; coloumn
;             ;MOV DX,0    ; row
;             MOV al,00H ; color
;             MOV AH,0ch  ; draw pixel  
            
;         drawLoop11:
;             INT 10h   
;             INC CX
;             CMP CX,640
;         JNE drawLoop11 
; POPA
; RET
; HighlightFinalNodes ENDP

;     drawLoop10:
;             CALL DrawSourceAndDestination1
;             add dx,40       
;             cmp dx, 430 ;last coloum
;     JNE drawLoop10
REMOVEWIRE PROC NEAR
PUSHA
MOV VR1,BL
MOV AL,[ip1ColIndex+BX]
MOV ip1_col,AL
MOV AL,[ip1RowIndex+BX]
MOV IP1_ROW,AL
XOR AH,AH
MOV AL,VR1
MOV DL,10D
DIV DL
MOV OP_COL,AL
MOV OP_ROW,AH
MOV THECOLOR,15D
call getWireCoordinates1     ;get coordinates of first wire
MOV ax,y2                ;check which y coordinate is higher to choose which draw fn to call
cmp ax,y1
jg DDOWNLINE2
jmp DUPELINE2
DDOWNLINE2:
call DrawDownTo
jmp after2
DUPELINE2:
call DrawUpto
after2:
call drawTip
MOV BL,VR1
MOV [OPERATION+BX],'?'
MOV OperationType,'M'
Call UpdateLogicValue
MOV SpotTaken,0H
CALL UpdateSpot
MOV THECOLOR,0D
POPA
RET
REMOVEWIRE ENDP

NodeRecreation PROC NEAR
PUSHA
MOV ColNum ,67d ; move right or left note its 67 not 75 because i want to center the nodes so shifted 8px to the left
MOV RowNum,30d ; move up or down
        BIGLOOP12:
                ; MOV di,0 ; counter
                    XOR DI,DI
                    drawLoop61:
                    CMP [LogicValue+BX],1
                    JE SETGREEN2
                    CMP [LogicValue+BX],0
                    JE SETRED2
                    CMP [LogicValue+BX],'U'
                    JE SETBLACK2
                    SETGREEN2:
                    MOV NodeColor,2H
                    JMP COLOR_CHOSEN2
                    SETRED2:
                    MOV NodeColor,4H
                    JMP COLOR_CHOSEN2
                    SETBLACK2:
                    MOV NodeColor,0H
                    COLOR_CHOSEN2:
                    CALL ReDrawNode
                    add RowNum,40d
                    INC BX
                    inc di
                    cmp di, 10d ;last coloumn
                    JNE drawLoop61
                MOV RowNum,30d ; reset to start drawing nodes from the top
                add ColNum,70d ; shifting every loop to the next odd coloumn          
                CMP ColNum,627D
            JNE BIGLOOP12
POPA
RET
NodeRecreation ENDP

 RedrawNode PROC
        PUSHA
        ;upon calling this function will have its 
        ;drawing pixel
        MOV DX,RowNum ; row
        MOV CX,ColNum    ; coloumn
        MOV si,3 ;THATS THE number that LINE get DRAWN AND GET DOWN TO CREATE THE THICKNESS
        BIGLOOP101:
                ;draw width
                MOV di,CX ; BX is just a register to compare with the relative width whatever the place
                ADD di,15 ;width is 15 pixels
            drawLoop501:
                MOV al,NodeColor
                MOV AH,0ch  ; draw pixel  
                INT 10h   
                INC CX
                CMP CX,di
            JNE drawLoop501
            INC DX
            MOV CX,ColNum 
            DEC si
        JNZ BIGLOOP101		
        POPA
        RET
    RedrawNode ENDP

RetrieveOperands PROC NEAR
PUSHA
PUSH BX
MOV AL,[ip1ColIndex+BX]; BX WILL IS PUSHED, BUT STILL RETAINS THE VALUE WHICH IS for e.g. 20 21 22 
MOV DL,10D
MUL DL
ADD AL,[ip1RowIndex+BX]; kda AL feh el value ely 7geb beh el LogicValue bta3 input1 lel node deh
MOV BL,AL
MOV AL,[LogicValue+BX]
MOV Src1Value,AL;
POP BX; RESTORE THE ORIGINAL VALUE OF BX 
PUSH BX
MOV AL,[ip2ColIndex+BX]; BX WILL IS PUSHED, BUT STILL RETAINS THE VALUE
MOV DL,10D
MUL DL
ADD AL,[ip2RowIndex+BX]; kda AL feh el value ely 7geb beh el LogicValue bta3 input1 lel node deh
MOV BL,AL
MOV AL,[LogicValue+BX]
MOV Src2Value,AL
POP BX
; PUSH BX 
MOV AL,[Operation+BX]; BX WILL IS PUSHED, BUT STILL RETAINS THE VALUE
MOV Operation_Was,AL 
POPA
RET
RetrieveOperands ENDP

UpdateAllLogicValues PROC NEAR 
PUSHA
CMP Src1Value,'U'
JE VALUE_ISUNDEFINED_INTERMEDIATE2
CMP Src2Value,'U'
JE VALUE_ISUNDEFINED_INTERMEDIATE2
CMP Operation_Was,'A'
JE ANDING_FUNCTION2
CMP Operation_Was,'O'
JE ORING_FUNCTION2
CMP Operation_Was,'D'
JE NANDING_FUNCTION2
CMP Operation_Was,'R'
JE NORING_FUNCTION2
CMP Operation_Was,'X'
JE XORING_FUNCTION2
CMP Operation_Was,'N'
JE XNORING_FUNCTION2
CMP Operation_Was,'M';we need to be very very...very cautious with removing 
JE VALUE_ISUNDEFINED2;REMOVING_FUNCTION
CMP Operation_Was,'W'
JE WIRING_FUNCTION2
JMP VALUE_ISUNDEFINED2
VALUE_ISUNDEFINED_INTERMEDIATE2:; an intermediate label because jump was too far
JMP VALUE_ISUNDEFINED2
ANDING_FUNCTION2:
MOV AL,Src1Value
AND AL,Src2Value
JMP FUNCTION_DONE2
WIRING_FUNCTION2:
MOV AL,Src1Value
MOV TrgtNodeValue,AL
JMP FUNCTION_DONE2
ORING_FUNCTION2:
MOV AL,Src1Value
OR AL,Src2Value
JMP FUNCTION_DONE2
NANDING_FUNCTION2:
MOV AL,Src1Value
AND AL,Src2Value
NOT AL
JMP FUNCTION_DONE2
NORING_FUNCTION2:
MOV AL,Src1Value
OR AL,Src2Value
NOT AL
JMP FUNCTION_DONE2
XORING_FUNCTION2:
MOV AL,Src1Value
XOR AL,Src2Value
JMP FUNCTION_DONE2
XNORING_FUNCTION2:
MOV AL,Src1Value
XOR AL,Src2Value
NOT AL
FUNCTION_DONE2:
; the output value is actually the bitwise function of the 8 bits, but we only need the lowest bit,
; so we shift left 7 and AND with FFH to test the value of the lowest bit 
SHL AL,7
AND AL,0FFH
JZ RESULTISZERO2
MOV AL,1
JMP UPDATE_LABEL2
RESULTISZERO2:
MOV AL,0
JMP UPDATE_LABEL2
VALUE_ISUNDEFINED2:
MOV AL,'U'
UPDATE_LABEL2:
MOV TrgtNodeValue,AL;STORE OUTPUT HERE
XOR AH,AH
MOV AL,TrgtNodeValue
MOV [LogicValue+BX],AL
POPA
RET
UpdateAllLogicValues ENDP

; TODO
ValidateCommand PROC NEAR ;Validates that the columns in any of the 6 gate commands are consecutive
PUSHA
; TODO ?? extra checks for column 9 not being an input node? and column 0 not being output
;it's already covered since no values of difference more than 1 can be connected, no two in same column?
MOV AL,[Store_Command+1]
MOV DL,[Store_Command+3]
CMP AL,DL
JNZ INVALID_GATE_COMMAND; two input commands must be in same column
MOV DL,[Store_Command+5]
CMP AL,DL
JGE INVALID_GATE_COMMAND ;input column cannot be /greater than/the same as output
; IN THIS PATH WE CHECKED THAT OUTPUT IS > INPUT, NOW CHECK DIFFERENCE IS ONLY 1
MOV BL,DL
SUB BL,AL
CMP BL,1H
JNE INVALID_GATE_COMMAND
MOV ApprovedCommand,1H
JMP ValidateCommand_End
INVALID_GATE_COMMAND:
MOV ApprovedCommand,0H
ValidateCommand_End:
POPA
RET
ValidateCommand ENDP


DRAWWIRE PROC NEAR
PUSHA
CMP RESTORAL,1 
JE IMMEDIATELY
MOV AL,[Store_Command+1]
MOV DL,[Store_Command+5] ; was+3 before shifting
SUB AL,30H
SUB DL,30H
CMP AL,DL
JL SUBSECOND; This might want to be JLE because we cannot connect a wire bet. nodes in the same column
CMP AL,DL
JG INVALID_WIRE_COMMAND ;OUTPUT CANNOT LEAD INPUT
; AT THIS POINT IF IT DIDN'T JUMP IT MEANS SAME COLUMN, WHICH IS INVALID, SO RETURN. This check isn't even needed
;because input node cannot lead output node
JMP INVALID_WIRE_COMMAND
SUBSECOND:
SUB DL,AL
CMP DL,2H 
JG INVALID_WIRE_COMMAND
;-------if control comes here, it means wire command is valid
; we now need to compute the node positions to decide whether the line is going to be slanted left or right
; JMP IMMEDIATELY
MOV AL,[STORE_COMMAND+1]
SUB AL,30H
MOV IP1_COL,AL
MOV AL,[STORE_COMMAND+2]
SUB AL,30H
MOV IP1_ROW,AL
MOV AL,[STORE_COMMAND+5]
SUB AL,30H
MOV OP_COL,AL
MOV AL,[STORE_COMMAND+6]
SUB AL,30H
MOV OP_ROW,AL
IMMEDIATELY:
call getWireCoordinates1     ;get coordinates of first wire
MOV ax,y2                ;check which y coordinate is higher to choose which draw fn to call
cmp ax,y1
jg DDOWNLINE
jmp DUPELINE
DDOWNLINE:
call DrawDownTo
jmp after
DUPELINE:
call DrawUpto
after:
call drawTip
MOV OperationType,'W'
Call UpdateLogicValue
MOV SpotTaken,1H
CALL UpdateSpot
SPOT_NOT_AVAILABLE0LINE:
JMP DRAWWIRE_END
INVALID_WIRE_COMMAND:
MOV INVALIDWCOMMAND,1H
DRAWWIRE_END:
POPA
RET
DRAWWIRE ENDP

ShiftString_Wiring PROC NEAR
PUSHA
MOV AL,[Store_Command+3]
MOV [Store_Command+5],AL
MOV AL,[Store_Command+4]
MOV [Store_Command+6],AL
MOV AL,'$'
MOV [STORE_COMMAND+3],AL
MOV [STORE_COMMAND+4],AL
POPA
RET
ShiftString_Wiring ENDP
ShiftString_Remove PROC NEAR
PUSHA
MOV DL,'M'
CMP [Store_Command],DL
JNE NONEEDFORTHIS
MOV BX,1
MOV DL,[Store_Command+1]
MOV [Store_Command+5],DL
MOV DL,[Store_Command+2]
MOV [Store_Command+6],DL

; JE SHIFT4
;MOV DL,'W'
;CMP [Store_Command],DL
;JNE SHIFT4
;MOV AX,2
;JMP Z_DETERMINED_LENGTH
SHIFT4:
MOV AX,5
MOV DL,'$'
Z_DETERMINED_LENGTH:
MOV [Store_Command+BX],DL
INC BX
CMP AX,BX
JNZ Z_DETERMINED_LENGTH
NONEEDFORTHIS:
POPA
RET
ShiftString_Remove ENDP


ComputeNodePositions PROC NEAR
PUSHA
XOR DX,DX
MOV DL,op_col
MOV AX,TEMPVW1
MOV BX,TEMPVW2
CMP DL,1
JNE NODE_COL2
ADD AX,62D
JMP Z_DETERMINED_NODE
NODE_COL2:
CMP DL,2
JNE NODE_COL3
ADD AX,57D;62D
JMP Z_DETERMINED_NODE
NODE_COL3:
CMP DL,3
JNE NODE_COL4
ADD AX,52D;57D
JMP Z_DETERMINED_NODE
NODE_COL4:
CMP DL,4
JNE NODE_COL5
ADD AX,47D;50D
JMP Z_DETERMINED_NODE
NODE_COL5:
CMP DL,5
JNE NODE_COL6
ADD AX,42D;48D
JMP Z_DETERMINED_NODE
NODE_COL6:
CMP DL,6
JNE NODE_COL7
ADD AX,37D;46D
JMP Z_DETERMINED_NODE
NODE_COL7:
CMP DL,7
JNE NODE_COL8
ADD AX,35D;44D
JMP Z_DETERMINED_NODE
NODE_COL8:
CMP DL,8
JNE NODE_COL9
ADD AX,25D;42D
JMP Z_DETERMINED_NODE
NODE_COL9:
CMP DL,9
JNE Z_DETERMINED_NODE
ADD AX,30D
Z_DETERMINED_NODE:
ADD BX,40D
MOV XNOTE,AX
MOV AX,TEMPVW2
MOV YNOTE,BX
; 57 and add 40 are the pair for column 3, for column 
POPA
RET
ComputeNodePositions ENDP

ComputeLookupValues PROC NEAR
PUSHA
MOV AL,LOOKUPCOL
MOV BL,10D
MUL BL
ADD AL,LOOKUPROW
MOV LOOKUPVALUE,AL
POPA
RET
ComputeLookupValues ENDP

GetLookUpValues PROC NEAR 
PUSH AX
PUSH BX
XOR BX,BX
RE_909:
MOV AL,[Store_Command+BX+1]
SUB AL,30H
MOV [ip1_col+BX],AL
INC BX
CMP BX,6H
JNZ RE_909
POP BX
POP AX
RET
GetLookUpValues ENDP

UpdateSpot PROC NEAR; updates values in the SpotOccupied array to mark whether a spot is occupied or not
; This function now updates all relative parameters of a node, it's only here that is safe to update
; because if control comes over here, it means whatever the operation, it was successful
PUSHA
XOR AX,AX
XOR BX,BX
MOV AL,op_col
MOV BL,10D
MUL BL
ADD AL,op_row
MOV BL,AL
MOV AL,SpotTaken 
MOV[SpotOccupied+BX],AL
MOV AL,ip1_col
MOV [ip1ColIndex+BX],AL
MOV AL,ip1_row
MOV [ip1RowIndex+BX],AL
MOV AL,ip2_col
MOV [ip2ColIndex+BX],AL
MOV AL,ip2_row
MOV [ip2RowIndex+BX],AL
MOV AL,[Store_Command]
CMP AL,'M'
JZ SETUNDEFINED ;OR SET ZERO
MOV [Operation+BX],AL
JMP ENDOFUPDATESPOT
SETUNDEFINED:
MOV AL,'?'
MOV [Operation+BX],AL
ENDOFUPDATESPOT:
POPA
RET
UpdateSpot ENDP

CheckSpot PROC NEAR
PUSH AX
PUSH BX
XOR AX,AX
XOR BX,BX
MOV AL,op_col
MOV BL,10D
MUL BL
ADD AL,op_row
MOV BL,AL
MOV AL,[SpotOccupied+BX]
MOV SpotIsOccupied,AL
POP BX
POP AX
RET
CheckSpot ENDP
OVERRIDE_FOR_RESTORAL PROC NEAR
PUSHA

POPA
RET
OVERRIDE_FOR_RESTORAL ENDP


ComputeOffsets PROC NEAR
; PUSHA

; PUSHA

XOR AH,AH
MOV DL,OP_COL
MOV AL,op_col
CMP OP_COL,1
JNE ADDONLY70
MOV BX,76D
JMP G56
ADDONLY70:
MOV BX,71D
G56:
MUL BX
sub ax,40
; SUB AL,OP_COL ; PROPER VALUE FOR COL1;catastrophe2************
; ADD AL,OP_CSOL
CMP DL,1
JNE COL_2
ADD AL,1
JMP Offset_determined
COL_2:
CMP DL,2 
JNE COL3_
ADD AL,4
JMP Offset_determined
COL3_:
CMP DL,3
JNE COL_4
ADD AL,4
COL_4:
CMP DL,4
JNE COL_5
ADD AL,6
JMP Offset_determined
COL_5:
CMP DL,5
JNE COL_6
ADD AL,7
JMP Offset_determined
COL_6:
CMP DL,6
JNE COL_7
ADD AL,5
JMP Offset_determined
COL_7:
CMP DL,7
JNE COL_8
ADD AL,4
JMP Offset_determined
COL_8:
CMP DL,8
JNE COL_9
ADD AL,3
JMP Offset_determined
COL_9:
CMP DL,9
JNE Offset_determined
ADD AL,4
JMP Offset_determined
Offset_determined:
MOV TEMPVW1,AX; Controls columns (X-direction)



XOR AH,AH
MOV AL,op_row
MOV BX,50D; ORIGINALLY 40D
MUL BX
; sub ax,20d;catastrophe2********************************************************************************
ADD AX,21D
CMP OP_ROW,0
JE MOVEON2
MOV DX,AX
XOR AH,AH
MOV AL,OP_ROW
MOV BL,10d
MUL BL
SUB DX,AX
MOV AX,DX
MOVEON2:
MOV TEMPVW2,AX;Controls rows (Y-direction)
; POPA
RET
ComputeOffsets ENDP

CheckandPrepare PROC NEAR
; CMP RESTORAL,1 
; JE SPOTISAVILABLE
CALL GetLookUpValues
CALL GetLogicValues
CALL CheckSpot
MOV AL,SpotIsOccupied
CMP AL,0H
JE SPOTISAVILABLE
; JMP CheckandPrepare_End 
; ***** THIS WAS COMMENTED OUT TO SOLVE THE REMOVE PROBLEM*********************
SPOTISAVILABLE:
CALL ComputeOffsets
CheckandPrepare_End:
RET
CheckandPrepare ENDP

DRAWWHITESPACE PROC NEAR; for removing a gate 
PUSHA
CALL CheckandPrepare
CMP SpotIsOccupied,1H
JNE SPOT_NOT_OCCUPIED_INT
;---------------------
MOV AX,TEMPVW1
MOV XNOTE,AX;TEMPVW1
MOV AX,TEMPVW2
MOV YNOTE,AX;TEMPVW2
MOV Draw_Square_Color,15
MOV Draw_Square_Height,26
MOV Draw_Square_Width,30
CALL DRAW_SQUARE ; for some reasons this corrupts op_col and op_row
JMP PartExtractedFromParse
SPOT_NOT_OCCUPIED_INT:
JMP SPOT_NOT_OCCUPIED
PartExtractedFromParse:
MOV THECOLOR,15D
MOV AL,VR3
MOV AL,[ip1ColIndex+BX]
MOV ip1_col,AL
MOV AL,[ip1RowIndex+BX]
MOV ip1_row,AL
MOV AL,[ip2ColIndex+BX]
MOV ip2_col,AL
MOV AL,[ip2RowIndex+BX]
MOV ip2_row,AL
XOR AH,AH
MOV AL,VR3
MOV DL,10D
DIV DL
MOV OP_COL,AL
MOV OP_ROW,AH
CALL CONNECT
MOV THECOLOR,0D
;original block
MOV OperationType,'M'
Call UpdateLogicValue
MOV SpotTaken,0H
MOV ip1_col,'?'
MOV ip1_row,'?'
MOV ip2_col,'?'
MOV ip2_row,'?'
CALL UpdateSpot
PUSHA
MOVECURSOR 27,0
LEA DX,SuccessfulRmvl
CALL WSTRING
POPA
JMP DRAWWHITESPACE_END
SPOT_NOT_OCCUPIED:
MOVECURSOR 27,0
LEA DX,CntRmvStr
CALL WSTRING
DRAWWHITESPACE_END:
POPA
RET
DRAWWHITESPACE ENDP

DRAWANDGATE PROC NEAR 
PUSHA
CMP RESTORAL,1 
JE ComputeOffsets_ForRestore_AND
CALL CheckandPrepare
MOV AL,SpotIsOccupied
CMP AL,0H
JNE SPOT_NOT_AVAILABLE0_INT
JMP DRAWINGPART
ComputeOffsets_ForRestore_AND:
CALL ComputeOffsets
DRAWINGPART:
drawGate andgatefilename, TEMPVW1,TEMPVW2,0
JMP RP09
SPOT_NOT_AVAILABLE0_INT:
JMP SPOT_NOT_AVAILABLE0
RP09:
CALL Connect
CMP RESTORAL,1 
JE SPOT_NOT_AVAILABLE0
MOV OperationType,'A'
Call UpdateLogicValue
MOV SpotTaken,1H
XOR AX,AX
CALL UpdateSpot
SPOT_NOT_AVAILABLE0:
POPA
RET
DRAWANDGATE ENDP

DRAWORGATE PROC NEAR 
PUSHA
CMP RESTORAL,1 
JE ComputeOffsets_ForRestore_OR
CALL CheckandPrepare
MOV AL,SpotIsOccupied
CMP AL,0H
JNE SPOT_NOT_AVAILABLE1_INT
JMP DRAWINGPART1
ComputeOffsets_ForRestore_OR:
CALL ComputeOffsets
DRAWINGPART1:
drawGate ORgatefilename, TEMPVW1,TEMPVW2,0
JMP RP091
SPOT_NOT_AVAILABLE1_INT:
JMP SPOT_NOT_AVAILABLE1
RP091:
CALL Connect
CMP RESTORAL,1 
JE SPOT_NOT_AVAILABLE1
MOV OperationType,'O'
Call UpdateLogicValue
MOV SpotTaken,1H
XOR AX,AX
CALL UpdateSpot
SPOT_NOT_AVAILABLE1:
POPA
RET
DRAWORGATE ENDP
Connect PROC NEAR
PUSHA
call getWireCoordinates1     ;get coordinates of first wire
add x2,5
MOV ax,y2                ;check which y coordinate is higher to choose which draw fn to call
cmp ax,y1
jg DDOWNAND
jmp DUPEAND
DDOWNAND:
call DrawDownTo
jmp nextlineAND
DUPEAND:
call DrawUpto
nextlineAND:
call getWireCoordinates2     ;get coordinates of second wire
MOV ax,y2
cmp ax,y1
jg DDOWN2
jmp DUPE2
DDOWN2:
call DrawDownTo
jmp nextline2AND
DUPE2:
call DrawUpto
nextline2AND:
POPA
RET
Connect ENDP


DRAWNANDGATE PROC NEAR 
PUSHA
CMP RESTORAL,1 
JE ComputeOffsets_ForRestore_NAND
CALL CheckandPrepare
MOV AL,SpotIsOccupied
CMP AL,0H
JNE SPOT_NOT_AVAILABLE2_INT
JMP DRAWINGPART2
ComputeOffsets_ForRestore_NAND:
CALL ComputeOffsets
DRAWINGPART2:
drawGate nandgatefilename, TEMPVW1,TEMPVW2,0
JMP RP092
SPOT_NOT_AVAILABLE2_INT:
JMP SPOT_NOT_AVAILABLE2
RP092:
CALL Connect
CMP RESTORAL,1 
JE SPOT_NOT_AVAILABLE2
MOV OperationType,'D'
Call UpdateLogicValue
MOV SpotTaken,1H
XOR AX,AX
CALL UpdateSpot
SPOT_NOT_AVAILABLE2:
POPA
RET
DRAWNANDGATE ENDP

DRAWNORGATE PROC NEAR 
PUSHA
CMP RESTORAL,1 
JE ComputeOffsets_ForRestore_NOR
CALL CheckandPrepare
MOV AL,SpotIsOccupied
CMP AL,0H
JNE SPOT_NOT_AVAILABLE3_INT
JMP DRAWINGPART3
ComputeOffsets_ForRestore_NOR:
CALL ComputeOffsets
DRAWINGPART3:
drawGate NORgatefilename, TEMPVW1,TEMPVW2,0
JMP RP093
SPOT_NOT_AVAILABLE3_INT:
JMP SPOT_NOT_AVAILABLE3
RP093:
CALL Connect
CMP RESTORAL,1 
JE SPOT_NOT_AVAILABLE3
MOV OperationType,'N'
Call UpdateLogicValue
MOV SpotTaken,1H
XOR AX,AX
CALL UpdateSpot
SPOT_NOT_AVAILABLE3:
POPA
RET
DRAWNORGATE ENDP

DRAWXORGATE PROC NEAR 
PUSHA
CMP RESTORAL,1 
JE ComputeOffsets_ForRestore_XOR
CALL CheckandPrepare
MOV AL,SpotIsOccupied
CMP AL,0H
JNE SPOT_NOT_AVAILABLE4_INT
JMP DRAWINGPART4
ComputeOffsets_ForRestore_XOR:
CALL ComputeOffsets
DRAWINGPART4:
drawGate XORgatefilename, TEMPVW1,TEMPVW2,0
JMP RP09
SPOT_NOT_AVAILABLE4_INT:
JMP SPOT_NOT_AVAILABLE4
RP094:
CALL Connect
CMP RESTORAL,1 
JE SPOT_NOT_AVAILABLE4
MOV OperationType,'X'
Call UpdateLogicValue
MOV SpotTaken,1H
XOR AX,AX
CALL UpdateSpot
SPOT_NOT_AVAILABLE4:
POPA
RET
DRAWXORGATE ENDP

DRAWXNORGATE PROC NEAR 
PUSHA
CMP RESTORAL,1 
JE ComputeOffsets_ForRestore_XNOR
CALL CheckandPrepare
MOV AL,SpotIsOccupied
CMP AL,0H
JNE SPOT_NOT_AVAILABLE5_INT
JMP DRAWINGPART
ComputeOffsets_ForRestore_XNOR:
CALL ComputeOffsets
DRAWINGPART5:
drawGate XNORgatefilename, TEMPVW1,TEMPVW2,0
JMP RP095
SPOT_NOT_AVAILABLE5_INT:
JMP SPOT_NOT_AVAILABLE5
RP095:
CALL Connect
CMP RESTORAL,1 
JE SPOT_NOT_AVAILABLE5
MOV OperationType,'N'
Call UpdateLogicValue
MOV SpotTaken,1H
XOR AX,AX
CALL UpdateSpot
SPOT_NOT_AVAILABLE5:
POPA
RET
DRAWXNORGATE ENDP

UpdateLogicValue PROC NEAR
;BY NOW, INPUT1VALUE AND INPUT2VALUE HAVE THE RESPECTIVE VALUES OF THE INPUT NODES 
PUSHA
CMP INPUT1VALUE,'U'
JE VALUE_ISUNDEFINED_INTERMEDIATE
CMP INPUT2VALUE,'U'
JE VALUE_ISUNDEFINED_INTERMEDIATE
CMP OPERATIONTYPE,'A'
JE ANDING_FUNCTION
CMP OPERATIONTYPE,'O'
JE ORING_FUNCTION
CMP OPERATIONTYPE,'D'
JE NANDING_FUNCTION
CMP OPERATIONTYPE,'R'
JE NORING_FUNCTION
CMP OPERATIONTYPE,'X'
JE XORING_FUNCTION
CMP OPERATIONTYPE,'N'
JE XNORING_FUNCTION
CMP OPERATIONTYPE,'M'
JE VALUE_ISUNDEFINED;REMOVING_FUNCTION
VALUE_ISUNDEFINED_INTERMEDIATE:; an intermediate label because jump was too far
JMP VALUE_ISUNDEFINED
ANDING_FUNCTION:
MOV AL,INPUT1VALUE
AND AL,INPUT2VALUE
JMP FUNCTION_DONE
ORING_FUNCTION:
MOV AL,INPUT1VALUE
OR AL,INPUT2VALUE
JMP FUNCTION_DONE
NANDING_FUNCTION:
MOV AL,INPUT1VALUE
AND AL,INPUT2VALUE
NOT AL
JMP FUNCTION_DONE
NORING_FUNCTION:
MOV AL,INPUT1VALUE
OR AL,INPUT2VALUE
NOT AL
JMP FUNCTION_DONE
XORING_FUNCTION:
MOV AL,INPUT1VALUE
XOR AL,INPUT2VALUE
JMP FUNCTION_DONE
XNORING_FUNCTION:
MOV AL,INPUT1VALUE
XOR AL,INPUT2VALUE
NOT AL
FUNCTION_DONE:
; the output value is actually the bitwise function of the 8 bits, but we only need the lowest bit,
; so we shift left 7 and AND with FFH to test the value of the lowest bit 
SHL AL,7
AND AL,0FFH
JZ RESULTISZERO
MOV AL,1
JMP UPDATE_LABEL
RESULTISZERO:
MOV AL,0
JMP UPDATE_LABEL
VALUE_ISUNDEFINED:
MOV AL,'U'
UPDATE_LABEL:
MOV OUTPUTVALUE,AL;STORE OUTPUT HERE
XOR AH,AH
MOV AL,op_col
MOV BL,10D
MUL BL 
ADD AL,op_row
MOV BOOL,AL
XOR BX,BX
MOV BL,AL
MOV AL,OUTPUTVALUE
MOV [LogicValue+BX],AL
POPA
RET
UpdateLogicValue ENDP

GetLogicValues PROC NEAR 
PUSH AX
PUSH BX 
MOV AL,ip1_col
MOV BL,10D
MUL BL 
ADD AL,ip1_row
XOR BX,BX
MOV BL,AL
MOV AL,[LogicValue+BX]
MOV INPUT1VALUE,AL
MOV AL,ip2_col
MOV BL,10D
MUL BL
ADD AL,ip2_row
XOR BX,BX
MOV BL,AL
MOV AL,[LogicValue+BX]
MOV INPUT2VALUE,AL
POP BX
POP AX
RET
GetLogicValues ENDP

RECEIVECOMMAND PROC NEAR
PUSHA 
XOR BX,BX
; note this must be edited to allow the user to press F1 and F2 and perform the respective action
FIRSTTIMEINPUT:
INPUTLOOP: 
getkeypress ; makes AH=scancode, AL=ASCII code 
CMP CLEARSTATUSBAR,1H
JNZ R412
MOVECURSOR 27,0
LEA DX,LARGESPACEMSG
CALL WSTRING
R412:
CMP AH,Escscancode
JNE NO_ESC_PRESSED
exit; Returns control to the operating system
NO_ESC_PRESSED:
CMP AH,3CH
JNE NOTF2
MOV Resurrected,1H
; WE SHOULD EXIT SORT OF "WITH AN EXIT CODE"
MOV ExitToMainScreen,1
JMP TOEND
; JMP MAINSCREEN;---------------------------------------------REAL CATASTROPHE 
NOTF2:
CMP AL,70D
JE FLUSHING
CMP AL,102D
JE FLUSHING
; CMP Ah,14
; CMP AL,8 
; JE FLUSHING
JMP NOTFLUSHING
FLUSHING:
; CALL ResetStrings
; XOR BX,BX
; JMP FIRSTTIMEINPUT
MOVECURSOR 27,0
MOV [RECEIVED_COMMAND+BX],'$'
LEA DX,RECEIVED_COMMAND
CALL WSTRING
JMP FIRSTTIMEINPUT
NOTFLUSHING:
MOV C1,AL 
CALL ISVALIDCOMMAND 
CMP VALID_COMMAND,1H
JNE INPUTLOOP
MOVECURSOR 27,0
PRINTCHAR C1
; reset VALID_COMMAND for next time 
MOV VALID_COMMAND,0H
MOV DL,C1 
MOV Received_Command,DL
INC BX 
DIGITSLOOP:
getkeypress
CMP AH,Escscancode
JNE NO_ESC_PRESSED2
exit; Returns control to the operating system
NO_ESC_PRESSED2:
CMP AH,3CH
JNE NOTF2_2
MOV Resurrected,1H
MOV ExitToMainScreen,1
JMP TOEND
NOTF2_2:
CMP AL,70D
JE FLUSHING2
CMP AL,102D
JE FLUSHING2
JMP NOTFLUSHING2
FLUSHING2:
CALL ResetStrings
XOR BX,BX
JMP FIRSTTIMEINPUT
NOTFLUSHING2:
MOV C1,AL 
CALL ISVALIDDIGIT 
CMP VALID_DIGIT,1H
JNE DIGITSLOOP
MOV VALID_DIGIT,0H
MOV DL,C1 
JMP CheckWorM
DIGITSLOOP_intermediate:
JMP DIGITSLOOP
CheckWorM:
MOV [Received_Command+BX],DL
INC BX 
PUSH DX
MOV DL,'W'
CMP [RECEIVED_COMMAND],DL
JE RECEIVEONLYFOUR
MOV DL,'w'
CMP [RECEIVED_COMMAND],DL
JE RECEIVEONLYFOUR
MOV DL,'M'
CMP [RECEIVED_COMMAND],DL
JE RECEIVEONLYTWO
MOV DL,'m'
CMP [RECEIVED_COMMAND],DL
JE RECEIVEONLYTWO
POP DX
PRINTCHAR C1
CMP BX,07H
JNZ DIGITSLOOP_intermediate
JMP TOEND
RECEIVEONLYFOUR:
POP DX
CMP BX,05H
PRINTCHAR C1
JNZ DIGITSLOOP_intermediate
JMP TOEND
RECEIVEONLYTWO:
POP DX
PRINTCHAR C1
CMP BX,03H
JNZ DIGITSLOOP_intermediate
TOEND:
MOV VALID_COMMAND,0H
MOV VALID_DIGIT,0H
MOVECURSOR 27,0
LEA DX,LARGESPACEMSG
CALL WSTRING
POPA
RET
RECEIVECOMMAND ENDP 

ISVALIDCOMMAND PROC NEAR 
        CMP AL,[command_available]
        JE RECEIVED_FIRST
        CMP [ command_available+1],AL  
        JE RECEIVED_FIRST
        CMP [ command_available+2],AL 
        JE RECEIVED_FIRST  
        CMP [ command_available+3],AL 
        JE RECEIVED_FIRST
        CMP [ command_available+4],AL 
        JE RECEIVED_FIRST
        CMP [ command_available+5],AL  
        JE RECEIVED_FIRST
        CMP [ command_available+6],AL
        JE RECEIVED_FIRST
        CMP [ command_available+7],AL
        JE RECEIVED_FIRST
        CMP [ command_available+8],AL
        JE RECEIVED_FIRST
        CMP [ command_available+9],AL
        JE RECEIVED_FIRST
        CMP [ command_available+10],AL
        JE RECEIVED_FIRST
        CMP [ command_available+11],AL
        JE RECEIVED_FIRST
        CMP [ command_available+12],AL
        JE RECEIVED_FIRST
        CMP [ command_available+13],AL
        JE RECEIVED_FIRST
        CMP [ command_available+14],AL
        JE RECEIVED_FIRST
        CMP [ command_available+15],AL 
        JE RECEIVED_FIRST         
        CMP [ command_available+16],AL
        JE RECEIVED_FIRST
        CMP [ command_available+17],AL
        JE RECEIVED_FIRST
        ; IF NOT EQUAL ANY SO IT'S NOT A VALID CHARACTER
        MOV VALID_COMMAND,0H
        JMP ISVALIDCOMMANDEND
        RECEIVED_FIRST:
        MOV VALID_COMMAND,1H
        ISVALIDCOMMANDEND:
        RET
    ISVALIDCOMMAND ENDP

ISVALIDDIGIT PROC NEAR 
        CMP AL,30H
        JL NOTA_VALID_DIGIT
        CMP AL,39H 
        JG NOTA_VALID_DIGIT
        JMP VALIDDIGIT_LABEL
        NOTA_VALID_DIGIT:
        MOV VALID_DIGIT,0H
        JMP ISVALIDDIGIT_END
        VALIDDIGIT_LABEL:
        MOV VALID_DIGIT,1H 
        ISVALIDDIGIT_END:
        RET 
ISVALIDDIGIT ENDP 
    
        

NAMESCREEN PROC near
    movecursor 01h, 01h
    print enternamemes
    movecursor 02h, 05h
    MOV bx, offset p1name
    READNAME
    MOV bh, 0h ; necessary since bx changes in readname function ; default is bh = 0 for moving cursor
    movecursor 10h, 01h
    print presstocontinuemes
    ; waitforuseractionNS:
    ; MOV ah, 0
    ; int 16h
    ; ; CHECK IF KEY IS ESC
    ; cmp ah, Escscancode
    ; JE exitnamescreen
    ; ; CHECK IF KEY IS ENTER
    ; cmp ah, Enterscancode
    ; JNE waitforuseractionNS
    CALL DETECT

CMP HOST,'Y'
JNZ RECEIVE_RANDOMVALUES; if not host (i.e. guest) then they receive the initial randomized values the host randomizes
CALL RANDOMIZE
XOR BX,BX
R9845:
MOV AL,[LogicValue+BX]
MOV VR1,AL
PUSHA
MOV BL,VR1
CALL SENDBYTE
POPA
INC BX
CMP BX,10
JNZ R9845
JMP BOTHDONE
RECEIVE_RANDOMVALUES:
XOR BX,BX
R9846:
PUSHA
CALL RecieveByte
POPA
MOV AL,BL
MOV [LogicValue+BX],AL
INC BX
CMP BX,10
JNZ R9846
BOTHDONE:




MOV VR2,2
EXCHANGE_LABEL:
XOR SI,SI
CMP VR2,0
JZ ITSOVER
CMP HOST,'Y'
JNZ YOUGETMYNAMEFIRST
R9855:
MOV BL,[P1NAME+SI]
CALL SENDBYTE
INC SI
CMP SI,15
JNZ R9855
DEC VR2
MOV HOST,'N'
JMP EXCHANGE_LABEL
YOUGETMYNAMEFIRST:
XOR SI,SI
R9856:
CALL RECIEVEBYTE
MOV [HISNAME+SI],BL
INC SI
CMP SI,15
JNZ R9856
DEC VR2
MOV HOST,'Y'
JMP EXCHANGE_LABEL
ITSOVER:
    MOVECURSOR 10,2
LEA DX,PLAYINGWITHMSG
CALL WSTRING
    MOVECURSOR 12,2
LEA DX,HISNAME
CALL WSTRING
CALL my_delay
    exitnamescreen:
    clearscreen
 
    RET
    ; exit
NAMESCREEN ENDP







detect proc
Zprogloop:
mov ah,1    ;check if a key is pressed
int 16h
jz Zdummy2   ; if not then jmp to recieving mode
jnz Zsend    ;if yes jmp to send mode
Zsend:
mov ah,0   ;clear the keyboard buffer
int 16h 
mov value,al  ; save the key ascii code in al
CMP al,0Dh    ; check if the key is enter
; jz ENTERS
; jnz notenter
JMP R01
;----------------------------
Zdummy2:jmp Zrecieve
;----------------------------
  R01:
; PRINTS JIMMY
MOV HOST,'Y'
mov dx,3FDH 		; Line Status Register
In al , dx 	;Read Line Status
test al , 00100000b
jz Zrecieve                    ;Not empty
mov dx , 3F8H		; Transmit data register
mov al,value        ; put the data into al
out dx , al         ; sending the data
CMP AL,13D
JNZ HOST_NOT_DETERMINED_YET
JMP ZEXIT
HOST_NOT_DETERMINED_YET:
; saveCursorS         ; we need to save the cursor here 
jmp Zprogloop        ; loop again
   Zdummy:jmp Zexit
   Zdummy3:jmp Zsend

   ; ---------------------------------------Receiver's Side------------------------------
Zrecieve:
mov ah,1            ;check if there is key pressed then go to the sending mode
int 16h
jnz Zdummy3

mov dx , 3FDH		; Line Status Register
in al , dx 
test al , 1
JZ Zrecieve           
mov value,al
mov dx , 03F8H
in al , dx 
mov value,al              ;check if the recieved data is sec key then terminate the programe 
CMP AL,13D
JNE Zprogloop 
MOV HOST,'N'
MOV HOSTDETERMINED,1
JMP ZEXIT
jmp Zprogloop 
ZEXIT:
RET
detect ENDP



MAINSCREEN PROC NEAR
    CALL RANDOMIZE
    displaymainscreen:
    CLEARSCREEN
    movecursor 09h, 10h
    print mes1      
    
    movecursor 0bh,10h
    print mes2
    
    movecursor 0dh,10h
    print mes3
    
    CMP NOTFIRSTGAME,1H
    JNZ FIRSTGAME
    movecursor 0fh,10h
    print StrNewGame
    FIRSTGAME:
    ; CALL RANDOMIZE
    movecursor 15h,00h
    print mes5
    
    waitforuseractionMS:
    getkeypress
                
    ; check if key is ESC                    
    cmp ah, Escscancode        
    ; JNE checkf1
    JNE CHECKF3FORNEWGAME
    clearscreen
    exit
    RET            
    CHECKF3FORNEWGAME:
    CMP AH,3Fh; F5 to start a new game
    JNE CHECKF1
    CALL ResetForNewGame
    CALL ChooseLevel
    JMP STARTTHEFUN

    ; check if key is F1                    
    checkf1:
    cmp ah, 3EH
    JNE checkf2
    clearscreen
    call chatSCREEN
    jmp displaymainscreen
    JMP MAINSCREENEND

    ;  check if key is F2
    checkf2:
    cmp ah, F2scancode
    JNE waitforuseractionMS
    clearscreen
    CMP midgame,1 
    JZ STARTTHEFUN
    CALL ChooseLevel
    STARTTHEFUN:
    PUSHA
    Call GAMESCREEN; gamescreen is drawn here
    CALL PLAY
    MOV midgame,1H
    MOV NOTFIRSTGAME,1H
    POPA
    r0569:
     jmp displaymainscreen
    MAINSCREENEND:
    RET
MAINSCREEN ENDP

ResetForNewGame PROC NEAR
PUSHA
XOR BX,BX
RESET_LOOP:
CMP BX,10D
JL NOTYET
MOV [LogicValue+BX],'U'
NOTYET:
MOV [OPERATION+BX],'?'
MOV [SpotOccupied+BX],0
MOV [ip1ColIndex+BX],0
MOV [ip1RowIndex+BX],0
MOV [ip2ColIndex+BX],0
MOV [ip2RowIndex+BX],0
INC BL
CMP BL,100D
JNZ RESET_LOOP
MOV SpotTaken,0H
MOV SpotIsOccupied,0D
MOV RESTORAL,0H
MOV VALID_COMMAND,0H
MOV VALID_DIGIT,0H
MOV ApprovedCommand,0H
MOV ExitToMainScreen,0H
MOV Resurrected,0H
MOV CHOSENLEVEL,0H
MOV MIDGAME,0H
MOV GAMEENDED,0H
CALL Randomize
POPA
RET
ResetForNewGame ENDP

WinCondition PROC NEAR
PUSHA
CMP CHOSENLEVEL,1h
JNZ WinCondition_END
MOV VR1,1
MOV VR2,0
XOR SI,SI
CHECK_1_WON:
MOV AL,[LogicValue+90D+SI]
CMP AL,VR1
JZ PLAYER1_HAS_VR1
INC SI
CMP SI,5
JNZ CHECK_1_WON
CMP VR1,0
JZ NEITHERWON
JMP EXCHANGE

PLAYER1_HAS_VR1: ; NOW CHECK THE OTHER HAS ANY ZEROES
XOR SI,SI
DoesPlayer2haveVR2:
MOV AL,[LogicValue+95D+SI]
CMP AL,VR2
JZ SOMEBODYWON
INC SI
CMP SI,5
JNZ DoesPlayer2haveVR2
CMP VR2,1H
JZ NEITHERWON
EXCHANGE:
MOV VR1,0H
MOV VR2,1H
JMP CHECK_1_WON

NEITHERWON:
MOV GAMEENDED,0H
JMP WinCondition_END
SOMEBODYWON:
CMP VR1,1
JNZ PLAYER2_WON
PLAYER1_WON:
CALL WinLevelP1
MOV GAMEENDED,1H
JMP WinCondition_END
PLAYER2_WON:
CALL WinLevelP2
MOV GAMEENDED,1H
WinCondition_END:
POPA
RET
WinCondition ENDP

;Mohamed Ashraf's Procedures 
LevelOne Proc      ;checks each players current scores to determine winners
PUSHA
MOV AX,@DATA
MOV ES,AX
CheckPlayer1Win1:
MOV si,offset LogicValue+90       ;load player 1's score
MOV di,offset ones              ;string of 1's to compare player 1's score to
MOV cx,5h
repne cmpsb                     ;check if any of Player 1's nodes == 1
JE CheckPlayer1Win2             ;if yes, jump to check player 2's score
jmp skip1

CheckPlayer1Win2:
MOV si,offset LogicValue+95        ;Load player 2's score
MOV di,offset zeroes            ;string of zeroes to compare player 2's score to
MOV cx,5h
repne cmpsb                     ;try to find any zeroes in player 2's score
JE wincallerP1                  ;if that's the case, declare player1 as the winner
jmp skip1


wincallerP1:
call WinLevelP1
jmp skip2

wincallerP2:
call WinLevelP2
jmp skip2

;Now Check if player 2 wins and repeat the same logic
skip1:
CheckPlayer2Win1:
;MOV si,offset p2score+2
MOV si,offset LogicValue+95D        ;Load player 2's score
MOV di,offset ones
MOV cx,5h
repne cmpsb
JE CheckPlayer2Win2
jmp skip2

CheckPlayer2Win2:
;MOV si,offset p1score+2
MOV si,offset LogicValue+90D        ;Load player 2's score

MOV di,offset zeroes
MOV cx,5h
repne cmpsb
JE wincallerP2


skip2:
POPA
RET
LevelOne ENDP


GetScore PROC
MOV ah,0ah    
int 21h
RET
GetScore ENDP

WinLevelP1 PROC
PUSHA    
; MOV ah,2
; MOV dx,0A23h
; int 10h
MOVECURSOR 27,0
lea dx,Winner1
MOV ah,9
int 21h
MOV GAMEENDED,1H
popa
RET
WinLevelP1 ENDP

WinLevelP2 PROC 
 PUSHA    
MOVECURSOR 27,0
lea dx,Winner2
MOV ah,9
int 21h
MOV GAMEENDED,1H
popa
RET
WinLevelP2 ENDP

DrawDownTo Proc    ;draw a horizontal and vertical line to reach the point
MOV ch,0
 MOV cx,[x1]
 MOV dh,0
 MOV dx,[y1]
 MOV bx,0
 inc [y2]
 drawxdwn:
   MOV al,THECOLOR
   MOV ah,0ch
   int 10h
  
  inc cx
 cmp cx,[x2]
 JNZ drawxdwn 
 
 drawydwn:
   MOV al,THECOLOR
   MOV ah,0ch
   int 10h
  
  inc dx
 cmp dx,[y2]
 JNZ drawydwn  
 RET
DrawDownTo ENDP             


DrawUpTo Proc
 MOV CX,x1
 MOV dx,y1
 dec [y2]
 drawxup:
   MOV al,THECOLOR
   MOV ah,0ch
   int 10h
  
 inc cx
 cmp cx,x2
 JNZ drawxup 
 
 drawyup:
   MOV al,THECOLOR
   MOV ah,0ch
   int 10h
  
  dec dx
 cmp dx,y2
 JNZ drawyup  
 RET    
DrawUpTo ENDP

getWireCoordinates1 Proc
PUSHA
xor ch,ch
;xor dh,dh
MOV ah,0
MOV al,ip1_col;[Store_Command+1] ;col 1    ;A-00-01-10
; MOV al,[Store_Command+1] ;col 1    ;A-00-01-10

; SUB AL,30H
MOV [x1],0d
cmp al,0

JE add0
cmp al,1
JE add75
cmp al,2
JE add145
cmp al,3
JE add215
cmp al,4
JE add285
cmp al,5
JE add355
cmp al,6
JE add425
cmp al,7
JE add495
cmp al,8
JE add570
add0:
MOV [x1],15
jmp exitx1
add75:
add [x1],75
jmp exitx1
add145:
add [x1],145
jmp exitx1
add215:
add [x1],215
jmp exitx1
add285:
add [x1],285
jmp exitx1
add355:
add [x1],355
jmp exitx1
add425:
add [x1],425
jmp exitx1
add495:
add [x1],495
jmp exitx1
add570:
add [x1],570
jmp exitx1


exitx1:


;ADD [X1],15d
xor ah,ah
MOV al,ip1_row;[Store_Command+2] ;row1
; MOV al,[Store_Command+2] ;row1
; SUB AL,30H
MOV Cx,40d
MUL Cx
MOV [y1],ax
add [y1],30d

xor ah,ah
MOV al,op_col;[Store_Command+5] ;col2
; MOV al,[Store_Command+5] ;col2
; SUB AL,30H

MOV [x2],0d
cmp al,1 
JE add02
cmp al,2
JE add752
cmp al,3
JE add1452
cmp al,4
JE add2152
cmp al,5
JE add2852
cmp al,6
JE add3552
cmp al,7
JE add4252
cmp al,8
JE add4952
cmp al,9
JE add5702


add02:
add [x2], 35d
jmp exitx2
add752:
add [x2],105
jmp exitx2
add1452:
add [x2],175
jmp exitx2
add2152:
add [x2],245
jmp exitx2
add2852:
add [x2],315
jmp exitx2
add3552:
add [x2],385
jmp exitx2
add4252:
add [x2],455
jmp exitx2
add4952:
add [x2],525
jmp exitx2
add5702:
add [x2],600
jmp exitx2


exitx2:
; MOV Cx,72d
; MUL Cx
;MOV [x2],ax
;sub [x2],23

xor ah,ah
MOV al,op_row;[Store_Command+6];row2
; MOV al,[Store_Command+6];row2
; SUB AL,30H
MOV Cx,40d
MUL Cx
MOV [y2],ax
add [y2],30d
POPA
RET
getWireCoordinates1 ENDP


getWireCoordinates2 Proc
PUSHA
xor ch,ch
;xor dh,dh
MOV ah,0
MOV al,ip2_col;[Store_Command+3] ;col 1    ;A-00-01-10
; MOV al,[Store_Command+3] ;col 1    ;A-00-01-10
; SUB AL,30H
cmp al,0
MOV [x1],0d
JE add10
cmp al,1
JE add11
cmp al,2
JE add12
cmp al,3
JE add13
cmp al,4
JE add14
cmp al,5
JE add15
cmp al,6
JE add16
cmp al,7
JE add17
cmp al,8
JE add18
add10:
add [x1],15
jmp exitx12
add11:
add [x1],75
jmp exitx12
add12:
add [x1],145
jmp exitx12
add13:
add [x1],215
jmp exitx12
add14:
add [x1],285
jmp exitx12
add15:
add [x1],355
jmp exitx12
add16:
add [x1],425
jmp exitx12
add17:
add [x1],495
jmp exitx12
add18:
add [x1],570
jmp exitx12

exitx12:
;ADD [X1],15d
xor ah,ah
MOV al,ip2_row;[Store_Command+4] ;row1
; MOV al,[Store_Command+4] 
; SUB AL,30H
MOV Cx,40d
MUL Cx
MOV [y1],ax
add [y1],30d

xor ah,ah
MOV al,op_col;[Store_Command+5] ;col2
; MOV al,[Store_Command+5] ;col2
; SUB AL,30H

MOV [x2],0d
cmp al,1 
JE add21
cmp al,2
JE add22
cmp al,3
JE add23
cmp al,4
JE add24 
cmp al,5
JE add25
cmp al,6
JE add26
cmp al,7
JE add27
cmp al,8
JE add28
cmp al,9
JE add29


add21:
add [x2],35
jmp exitx22
add22:
add [x2],105
jmp exitx22
 add23:
add [x2],175
jmp exitx22
add24:
add [x2],245
jmp exitx22
add25:
add [x2],315
jmp exitx22
add26:
add [x2],385
jmp exitx22
add27:
add [x2],455
jmp exitx22
add28:
add [x2],525
jmp exitx22
add29:
add [x2],600
jmp exitx22


exitx22:
; MOV Cx,72d
; MUL Cx
;MOV [x2],ax
;sub [x2],23

xor ah,ah
MOV al,op_row;[Store_Command+6];row2
; MOV al,[Store_Command+6];row2

; SUB AL,30H
MOV Cx,40d
MUL Cx
MOV [y2],ax
add [y2],30d
POPA
RET
getWireCoordinates2 ENDP



Sound Proc
PUSHA
    ; MOV CX,02H
    ; MOV DX,2000d
    ; ;MOV AX,30bEH
    ; MOV BX, AX          ; 1) Preserve the note value by storing it in BX.
    ; MOV AL, 182         ; 2) Set up the write to the control word register.
    ; OUT 43h, AL         ; 2) Perform the write.
    ; MOV AX, BX          ; 2) Pull back the frequency from BX.
    ; OUT 42h, AL         ; 2) Send lower byte of the frequency.
    ; MOV AL, AH          ; 2) Load higher byte of the frequency.
    ; OUT 42h, AL         ; 2) Send the higher byte.
    ; IN AL, 61h          ; 3) Read the current keyboard controller status.
    ; OR AL, 03h          ; 3) Turn on 0 and 1 bit, enabling the PC speaker gate and the data transfer.
    ; OUT 61h, AL         ; 3) Save the new keyboard controller status.
    ; MOV AH, 86h         ; 4) Load the BIOS WAIT, int15h function AH=86h.
    ; INT 15h             ; 4) Immidiately interrupt. The delay is already in CX:DX.
    ; IN AL, 61h          ; 5) Read the current keyboard controller status.
    ; AND AL, 0FCh        ; 5) Zero 0 and 1 bit, simply disabling the gate.
    ; OUT 61h, AL
      MOV ax,30beh
    MOV CX,02H
    MOV DX,2000d
    ;MOV AX,30bEH
    MOV BX, AX          ; 1) Preserve the note value by storing it in BX.
    MOV AL, 182         ; 2) Set up the write to the control word register.
    OUT 43h, AL         ; 2) Perform the write.
    MOV AX, BX          ; 2) Pull back the frequency from BX.
    OUT 42h, AL         ; 2) Send lower byte of the frequency.
    MOV AL, AH          ; 2) Load higher byte of the frequency.
    OUT 42h, AL         ; 2) Send the higher byte.
    IN AL, 61h          ; 3) Read the current keyboard controller status.
    OR AL, 03h          ; 3) Turn on 0 and 1 bit, enabling the PC speaker gate and the data transfer.
    OUT 61h, AL         ; 3) Save the new keyboard controller status.
    MOV AH, 86h         ; 4) Load the BIOS WAIT, int15h function AH=86h.
    INT 15h             ; 4) Immidiately interrupt. The delay is already in CX:DX.
    IN AL, 61h          ; 5) Read the current keyboard controller status.
    AND AL, 0FCh        ; 5) Zero 0 and 1 bit, simply disabling the gate.


    MOV ax,20ceh
    MOV CX,02H
    MOV DX,2000d
    ;MOV AX,30bEH
    MOV BX, AX          ; 1) Preserve the note value by storing it in BX.
    MOV AL, 182         ; 2) Set up the write to the control word register.
    OUT 43h, AL         ; 2) Perform the write.
    MOV AX, BX          ; 2) Pull back the frequency from BX.
    OUT 42h, AL         ; 2) Send lower byte of the frequency.
    MOV AL, AH          ; 2) Load higher byte of the frequency.
    OUT 42h, AL         ; 2) Send the higher byte.
    IN AL, 61h          ; 3) Read the current keyboard controller status.
    OR AL, 03h          ; 3) Turn on 0 and 1 bit, enabling the PC speaker gate and the data transfer.
    OUT 61h, AL         ; 3) Save the new keyboard controller status.
    MOV AH, 86h         ; 4) Load the BIOS WAIT, int15h function AH=86h.
    INT 15h             ; 4) Immidiately interrupt. The delay is already in CX:DX.
    IN AL, 61h          ; 5) Read the current keyboard controller status.
    AND AL, 0FCh        ; 5) Zero 0 and 1 bit, simply disabling the gate.
    OUT 61h, AL
    OUT 61h, AL
    POPA 
    RET
Sound ENDP

drawTip proc
MOV ch,0
 MOV cx,[x2]
 MOV dh,0
 MOV dx,[y2]
 MOV bx,0
 add x2,30
 drawxtip:
   MOV al,THECOLOR
   MOV ah,0ch
   int 10h
  inc cx
 cmp cx,[x2]
 JNZ drawxtip
RET
drawTip ENDP

END MAIN 
