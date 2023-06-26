print MACRO text    ; print bufferdata
mov ah, 9h
mov dx, offset text        
int 21h
ENDM print

textmode MACRO
    mov ah, 0
    mov al, 3h
    int 10h
ENDM textmode

CHECKBUFFER MACRO
MOV AH,1H
INT 16h
ENDM CHECKBUFFER

exit MACRO
    mov ah, 4ch
    int 21h
ENDM exit

clearscreen MACRO
    MOV AH,0
    MOV AL,3
    INT 10H
ENDM clearscreen

; GETCURSOR PROC NEAR 
; PUSHA
;     mov ah,3h 
;     mov bh,0h 
;     int 10h    
; MOV CurR,DH
; MOV CurC,DL
; POPA
; RET
; GETCURSOR ENDP
getkeypress MACRO 
    mov ah, 0
    int 16h
ENDM getkeypress


GETCHAR MACRO STORAGE
    LOCAL NOTRETURN
    PUSHA 
    MOV AH,07H ;was 01H
    INT 21H
    MOV STORAGE,AL
   ;We want to check that the pressed key was not F4, in which case we want to exit the game
    CMP AL,1BH
    JNE NOTRETURN
    MOV ESCWASPRESSED,1H 
    NOTRETURN:
    POPA 
    ENDM GETCHAR

      PRINTSTR MACRO STRING ; stops printint at $
     LOCAL P_LOOP,STRING_END
     PUSHA
     MOV SI,OFFSET STRING
     P_LOOP:
     MOV DL,[SI]
     CMP DL,0
     JE STRING_END
     INC SI
     MOV AH,02H
     INT 21H
     JMP P_LOOP
     STRING_END:
     POPA
     ENDM PRINTSTR

	videomode MACRO
    mov ax,19
    int 16h
    ENDM videomode

  graphicalmode MACRO 
    mov ah,00h
    mov al,13h
    int 10h
   ENDM graphicalmode

     PRINTCHAR MACRO TheArg
        PUSHA;;ADDED ON 16/3/2023
        mov dl, TheArg
        mov ah, 02h    ; DOS.PrintCharacter
        int 21h
        POPA;;ADDED ON 16/3/2023
        ENDM PRINTCHAR     

		movecursor MACRO x,y
        PUSHA  ;;ADDED ON 16/3/2023
        MOV AH,2
        MOV Dh,x
        mov dl,y
        INT 10H
        POPA;;ADDED ON 16/3/2023
       ENDM movecursor

	       PRINTCHAR MACRO TheArg
     PUSHA;;ADDED ON 16/3/2023
  mov dl, TheArg
  mov ah, 02h    ; DOS.PrintCharacter
  int 21h
  POPA;;ADDED ON 16/3/2023
ENDM   
  
   COLOREDCHAR MACRO CHARA
        PUSHA
        MOV AH,09H
        MOV AL,CHARA
        MOV BH,0
        ; MOV BL,4H;COMMENTED ON 12/4 REPLACED WITH 1 BELOW
        MOV BL,THECOLOR
        MOV CX,1 
        INT 10H
        POPA
        ENDM

READNAME MACRO
                    MOV CX,15                           ; LOOP TILL THE TOTAL VALID CHARACTERS INPUT ARE 15
                    MOV SI,0                            ; INITIALIZE SI WITH 0 TO USE IT AS A POINTER 
        CHECK_FIRST_CHARACTER: MOV AH,0                  ; WAIT FOR KEY TO BE PRESSED 
                    INT 16H 
                    CMP AL,41H                          ; CHECK IF IT WITHIN THE ALPHABET LETTERS  'A' = 41H
                    JB CHECK_FIRST_CHARACTER                             
                    CMP AL,5AH                          ; IF IT WAS LESS THAN 'Z' = 5AH, SO IT IS A VALID FIRST CHARACTER 
                    JB VALID_FIRST_CHAR
                    CMP AL,61H                          ; IF IT IS LESS THAN 'a' = 61H, then it is not a valid first character
                    JB CHECK_FIRST_CHARACTER
                    CMP AL,7AH
                    JA CHECK_FIRST_CHARACTER            ; IF IT IS MORE THAN 'z' = 7AH, then it is not a valid first character
                    JBE VALID_FIRST_CHAR ; MY ADDITION
        TAKE_ANOTHER_INPUT: MOV AH,0
                    INT 16H
                    CMP AH,Enterscancode                        ; CHECK IF THE PRESSED KEY IS ENTER TO END ENTERING NAME 
                    JE END_TYPING 
                    CMP AH, 0Eh                       ; CHECK IF THE PRESSED KEY IS BACKSPACE
                    JE  DELETE_CHAR
        VALID_FIRST_CHAR: MOV [BX+SI],AL                 ; AFTER ALL VALIDATIONS ADD THE LETTER TO THE PLAYER NAME 
                    INC SI
                    INC p1nameactualsize   
                    MOV DL,AL                           ; PRINT THE VALID INPUT CHARACTER 
                    MOV AH,2
                    INT 21H
                    LOOP TAKE_ANOTHER_INPUT
                    JMP END_TYPING
        DELETE_CHAR: 
                    DEC p1nameactualsize
                    DEC SI
                    INC CX
                    MOV DL,08H                          ; IN ORDER TO REMOVE THE CHARACTER 
                    MOV AH,2                            ; BACKSPACE WAS FIRST PRINTED 
                    INT 21H
                    MOV DL,' '                          ; THEN SPACE WAS PRINTED 
                    MOV AH,2
                    INT 21H
                    MOV DL, "$"
                    MOV [BX+SI],DL                      ; OVERRIDE THE DATA SAVED PREVIUOSY 
                    MOV DL,08H                          ; THEN BACKSPACE AGAIN "NOTE: BACKSPACE ONLY BRING THE CURSOR OF TYPING ONE CHAR BACK WITHOUT DELETING" 
                    MOV AH,2
                    INT 21H
                    CMP CX, 15
                    JZ CHECK_FIRST_CHARACTER
                    JMP TAKE_ANOTHER_INPUT
        END_TYPING: 
ENDM READNAME



OpenFile MACRO Filehandle, Filename ; Open file
    MOV AH, 3Dh
    MOV AL, 0 ; read only
    LEA DX, Filename
    INT 21h
    
    ; you should check carry flag to make sure it worked correctly
    ; carry = 0 -> successful , file Handle -> AX
    ; carry = 1 -> failed , AX -> error code 
    MOV [Filehandle], AX
ENDM OpenFile

ReadData MACRO Filehandle, Width, Height, Data
    MOV AH,3Fh
    MOV BX, [Filehandle]
    MOV CX, Width* Height ; number of bytes to read
    LEA DX, Data
    INT 21h
ENDM ReadData 

CloseFile MACRO Filehandle
	MOV AH, 3Eh
	MOV BX, [Filehandle]
	INT 21h
ENDM CloseFile


draw MACRO Width, Height, startingcolumn, color
    LOCAL drawLoop,drawnot
    mov AH, 0CH
    XOR BH,BH 
    MOV BL,0;
    drawLoop:
    MOV AL,[SI]
    cmp al,color
    je drawnot
    INT 10h 
    drawnot:
    INC CX
    INC SI
    CMP CX,Width
    JNE drawLoop	
    MOV CX , startingcolumn
    INC DX
    CMP DX , Height
    JNE drawLoop
ENDM draw

drawGate MACRO GATEfilename,piecerow_par,piececol_par,omitcolor 
OpenFile GateFileHandle,GATEfilename
ReadData GateFileHandle,GateWidth,GateHeight,GateData
LEA SI, GateData
; MOV CH, 0D
;     MOV CL,piecerow_par; X-direction
;     MOV DH, 0D
;     MOV DL,piececol_par; Y-direction
    MOV CX,PIECEROW_PAR 
    MOV DX,piececol_par
    MOV scol, CX
    MOV HorizontalDimension, GATEWIDTH
    MOV VerticalDimension, GATEHEIGHT
    ADD HorizontalDimension, CX
    ADD VerticalDimension, DX
    draw HorizontalDimension, VerticalDimension, scol,omitcolor
    CloseFile GateFileHandle

ENDM drawGate

DRAWSLANTEDLEFT MACRO XN,YN,XF,YF
LOCAL DRAWLOOP
PUSHA 
MOV CX,XN
MOV DX,YN
DRAWLOOP:
MOV AH,0CH
MOV AL,4
INT 10H
INC DX
DEC CX
CMP CX,XF 
JNZ DRAWLOOP
POPA 
ENDM DRAWSLANTEDLEFT

 DrawDiagonal_LEFT MACRO XNODE,YNODE,LENGTH
      LOCAL d1
      PUSHA
      MOV CX,XNODE
      MOV DX,YNODE 
      MOV xf_drawlen,LENGTH
      ADD xf_drawlen,CX
      MOV yf_drawlen,LENGTH
      ADD yf_drawlen,DX
      d1:
       MOV AH, 0CH
       MOV AL,1
       INT 10H
       DEC CX
       INC DX
       CMP CX,0
       CMP DX,yf_drawlen
       JNE d1
       MOV XF_DRAWLEN,0
       MOV YF_DRAWLEN,00h
      POPA
      ENDM DrawDiagonal_LEFT

 Drawsquare MACRO xnote,ynote,color,sizeofbox
   local first, second, third, fourth
    
    mov ah, 0ch
    mov al,color
    mov cx,xnote
    mov dx,ynote
    int 10h
    
   mov bl,sizeofbox
   first:
   int 10h
   inc cx
   dec bl
   jnz first 
   
     mov bl,sizeofbox
   second:
   int 10h
   inc dx
   dec bl
   jnz second
     
     
     mov bl,sizeofbox
   third:
   int 10h
   dec cx
   dec bl
   jnz third
   
     mov bl,sizeofbox
   fourth:
   int 10h
   dec dx
   dec bl
   jnz fourth
     
   
   ENDM Drawsquare
PRINTCHARACTER PROC NEAR
PUSHA
  mov ah, 02h    ; DOS.PrintCharacter
  int 21h
POPA
RET
PRINTCHARACTER ENDP
drawline MACRO   xp,yp,xf,yf,color
LOCAL DRAWLOOP
    mov cx,xp
    mov dx,yp
    mov ah,2ch
    drawloop:
    int 10h
    inc cx
    cmp cx, xf
    jnz drawloop
ENDM drawline
;an old MACRO called draws was here
     drawhorizon MACRO xnode, ynode, xfinal,yfinal                       
       local BACK
               ; TO DRAW A HORIZONTAL LINE
       MOV CX, xnode
       MOV DX, ynode 
       BACK:
       MOV AH, 0CH
       MOV AL,1
       INT 10H
       INC CX
       CMP CX, xfinal
       JNZ BACK  
             ENDM drawhorizon


ChooseLevel PROC NEAR 
PUSHA
    movecursor 2,0
    print pickLevelMsg
    ; CALL ChooseLevel
 

VALID_LEVEL:
GetKeyPress 
CMP AL,31H
JE PICKED
CMP AL,32H
JE PICKED
JMP VALID_LEVEL
PICKED:
MOVECURSOR 5,4
MOV VR2,AL
PRINTCHAR VR2 
SUB AL,30H
MOV CHOSENLEVEL,AL

   MOV DELAY,1
    CALL my_delay
    MOV DELAY,5
    CLEARSCREEN
POPA
RET
 ChooseLevel ENDP    

 my_delay proc 
PUSHA 
delaying:   
;GET SYSTEM TIME.
  mov  ah, 2ch
  int  21h ;RETURN SECONDS IN DH.
;CHECK IF ONE SECOND HAS PASSED. 
  cmp  dh, seconds
  je   delaying
;IF NO JUMP, ONE SECOND HAS PASSED. VERY IMPORTANT : PRESERVE
;SECONDS TO USE THEM TO COMPARE WITH NEXT SECONDS. THIS IS HOW
;WE KNOW ONE SECOND HAS PASSED.
  mov  seconds, dh
  dec  delay   
  jnz  delaying  ;IF DELAY IS NOT ZERO, REPEAT.
POPA
  ret 
my_delay endp       
;-------------------------------------------BASSEM FUNCTIONS FOR DRAWING SCREEN-----------------------------------------------------
    ;function that draw horizontal line used in changebackgroundcolor
    DrawScreen PROC
        PUSHA
        ;drawing pixel
        MOV CX,0 ; coloumn
        ;MOV DX,0    ; row
        mov al,0FH ; color
        MOV AH,0ch  ; draw pixel  
        
    drawLoop:
        INT 10h   
        INC CX
        CMP CX,640
    JNE drawLoop 
        POPA
        RET
    DrawScreen ENDP
    ;function that change background color but by texting white color on the screen
    changeBackgroundColorbyText PROC
        ;mov ax,06ffh
        ;mov bh,05h
        ;mov cx,0000h
        ;mov dx,0ffffh
    ; int 10
        ;method 1 writing white characters in the background
            mov ah,9
            mov bh,0
            mov al,0
            mov cx,0ffffh
            mov bl,0000
            int 10h
    changeBackgroundColorbyText ENDP
    ;function that change background color to white
    changeBackgroundColor PROC    
                    PUSHA 
                MOV DX,0    ; row
                loop1:
                        CALL DrawScreen
                        inc dx  
                        cmp dx,480d
                jne loop1     
                    POPA
                        RET
    changeBackgroundColor ENDP 
    ;function that write guideline the statement in the middle of the screen
    WriteGuidline PROC    
                PUSHA        
            ;changing curser position 
        mov ah,2h
        mov dx,0067h
        int 10h

        ;draw statment
        mov di,offset Guideline
        mov si,0h
        loopString:
            ;draw one character 
            mov ah,09h  ;setting mode for int 10 to draw character       
            mov al,[di] ; Put the character in address bp
            inc di      ;getting the next character from array of characters
            mov bh, 00h   ;page 0
            mov bl, 03Eh ;E is yello (background) 0 is black (font)
            mov cx,1h  
            int 10h
            ;moving curser     
            
            mov ah,2h
            inc dx
            int 10h
            
            inc si
            cmp si,36
        jne loopString
        POPA
                        RET
    WriteGuidline ENDP 
    ;function that draw Horizontal line  like in the image of main game
    ;takes row in DX as i input just specify the row you want to draw in before calling it
    DrawHorizontal PROC
        PUSHA
        ;drawing pixel
        MOV CX,20 ; coloumn
        ;MOV DX,0    ; row
        mov al,00H ; color
        MOV AH,0ch  ; draw pixel  
        
    drawLoop1:
        INT 10h   
        INC CX
        CMP CX,620
    JNE drawLoop1 
        POPA
        RET
    DrawHorizontal ENDP
    ;takes coloumn and draw vertical line between the two horizontal lines takes cx as input for coloumn
    DrawVertical PROC
        PUSHA
        ;drawing pixel
        MOV DX,20 ; row
        ;MOV CX,0    ; col
        mov al,00H ; color
        MOV AH,0ch  ; draw pixel  
        
    drawLoop2:
        INT 10h   
        INC DX
        CMP DX,420
    JNE drawLoop2 
        POPA
        RET
    DrawVertical ENDP
    ;that function will take place col in RowNum and row in ColNum  and will draw the nodes and
    DrawNode PROC
        PUSHA
        ;drawing pixel
        MOV DX,RowNum ; row
        MOV CX,ColNum    ; coloumn
        MOV si,3 ;THATS THE number that LINE get DRAWN AND GET DOWN TO CREATE THE THICKNESS
        BIGLOOP:
                ;draw width
                MOV di,CX ; BX is just a register to compare with the relative width whatever the place
                ADD di,15 ;width is 15 pixels
            drawLoop5:
                mov al,00H ; color
                MOV AH,0ch  ; draw pixel  
                INT 10h   
                INC CX
                CMP CX,di
            JNE drawLoop5
            INC DX
            MOV CX,ColNum 
            DEC si
        JNZ BIGLOOP		
        POPA
        RET
    DrawNode ENDP
    ;draw lines of start and end with width equal 15 set row by DX
    DrawSourceAndDestination PROC
            PUSHA
            ;drawing pixel
            MOV CX,0 ; coloumn
            ;MOV DX,0    ; row
            CMP GameScr_LogicValue,0
            JE DRAWINRED
            MOV AL,02H
            JMP IP_COLOR_SET
            DRAWINRED:
            mov al,4H ; color
            IP_COLOR_SET:
            MOV AH,0ch  ; draw pixel  
            
        drawLoop9:
            INT 10h   
            INC CX
            CMP CX,15
        JNE drawLoop9 
        POPA
        RET
    DrawSourceAndDestination ENDP
    ;its literally the same function as DrawSourceAndDestination but its for the destination 
    ;thats because when i tried to set cx outside function it gets an error 
    DrawSourceAndDestination1 PROC
            PUSHA
    
            ;drawing pixel
            MOV CX,625 ; coloumn
            ;MOV DX,0    ; row
            mov al,00H ; color
            MOV AH,0ch  ; draw pixel  
            
        drawLoop11:
            INT 10h   
            INC CX
            CMP CX,640
        JNE drawLoop11 
        POPA
        RET
    DrawSourceAndDestination1 ENDP
    ;function that draw the numbers of coloumns below
    DrawNumberBelow PROC
        PUSHA
        ;printing zero 
        
        ;changing curser position 
        mov ah,2h
        mov dx,1a01h ; y is dh  and x is dl
        int 10h

        ;printing zero
        mov ah,09h  ;setting mode for int 10 to draw character   
        mov bh, 00h   ;page 0    
        mov al,'0' ; Put the character in address bp
        mov bl, 0f2h ;E is yello (background) 0 is black (font)
        mov cx,1h  
        int 10h



            ;changing curser position 
        mov ah,2h
        mov dx,1a07h ; y is dh  and x is dl
        int 10h

        ;draw statment
        mov di,offset Numbersfrom0to9
        mov si,0h
        inc di
        loopNumbers:
            ;draw one character 
            mov ah,09h  ;setting mode for int 10 to draw character   
            mov bh, 00h   ;page 0    
            mov al,[di] ; Put the character in address bp
        inc di      ;getting the next character from array of characters
        
            mov bl, 0f2h ;E is yello (background) 0 is black (font)
            mov cx,1h  
            int 10h
            ;moving curser     
            
            mov ah,2h
            add dl,04d
        int 10h
            
            inc si
            cmp si,17
        jne loopNumbers
            
        ;printing 9
        ;changing curser position 
        mov ah,2h
        mov dx,1aeeh ; y is dh  and x is dl
        int 10h

        ;printing zero
        mov ah,09h  ;setting mode for int 10 to draw character   
        mov bh, 00h   ;page 0    
        mov al,'9' ; Put the character in address bp
        mov bl, 0f2h ;E is yello (background) 0 is black (font)
        mov cx,1h  
        int 10h
        POPA
                        RET
    DrawNumberBelow ENDP
    ;take the number of coloumn and draw the numbers in that coloumn takes number if coloumn at DX x axis
    DrawverticalNumbers PROC
        PUSHA
        ;changing curser position 
        mov ah,2h
        mov dh,01d ; y is dh  and x is dl
        int 10h

    
        
        mov al,48d ;changing counter to print numbers from 0 to 9
        loopNumberss:
            ;draw one character 
            mov bh, 00h   ;page 0    
        mov bl, 0f2h ;E is yello (background) 0 is black (font)
        mov cx,1h  ; print it one time
            mov ah,09h  ;setting mode for int 10 to draw character 
            int 10h
            
            ;moving curser     
            mov ah,2h   ; setting mode for int 10 to move curser
            add dh,003h ; shift curser down by one character
            int 10h
            
            inc al  ;increment counter to print the next number
            cmp al,58 ; if its 10 then dont print it
        jne loopNumberss
        POPA
        RET  
    DrawverticalNumbers ENDP                   
    ;DRAW numbers
    draw_timer_0 proc

                                                    PUSHA

                                                ; add   di, 33d
                                                ;  add   si, 31d

                                                    mov   bp, di
                                                    mov   bx, si

                                                    add   bp, 08d
                                                    add   bx, 9d

                                                    mov   cx, di
                                                    mov   dx, si
                                                    mov   al, 00h
                                                    mov   ah, 0ch

                                                    mov   si, 0

        timer_0_y:                                  
        timer_0_x:                                  
                                                    cmp   timer_0 + [si],1
                                                    je    draw_the_timer_0
        back_from_timer_0:                          
                                                    inc   si
                                                    inc   cx
                                                    cmp   cx, bp
                                                    jnz   timer_0_x
                                                    mov   cx, di
                                                    inc   dx
                                                    cmp   dx, bx
                                                    jnz   timer_0_y

                                                    jmp   end_timer_0

        draw_the_timer_0:                           
                                                    int   10h
                                                    jmp   back_from_timer_0

        end_timer_0:                                

                                                    POPA

                                                    ret

    draw_timer_0 endp
    draw_timer_1 proc

                                                    PUSHA

                                                ; add   di, 33d
                                                ;  add   si, 31d

                                                    mov   bp, di
                                                    mov   bx, si

                                                    add   bp, 08d
                                                    add   bx, 9d

                                                    mov   cx, di
                                                    mov   dx, si
                                                    mov   al, 00h
                                                    mov   ah, 0ch

                                                    mov   si, 0

        timer_1_y:                                  
        timer_1_x:                                  
                                                    cmp   timer_1 + [si],1
                                                    je    draw_the_timer_1
        back_from_timer_1:                          
                                                    inc   si
                                                    inc   cx
                                                    cmp   cx, bp
                                                    jnz   timer_1_x
                                                    mov   cx, di
                                                    inc   dx
                                                    cmp   dx, bx
                                                    jnz   timer_1_y

                                                    jmp   end_timer_1

        draw_the_timer_1:                           
                                                    int   10h
                                                    jmp   back_from_timer_1

        end_timer_1:                                

                                                    POPA

                                                    ret

    draw_timer_1 endp
    draw_timer_2 proc

                                                    PUSHA

                                                ; add   di, 33d
                                                ;  add   si, 31d

                                                    mov   bp, di
                                                    mov   bx, si

                                                    add   bp, 08d
                                                    add   bx, 9d

                                                    mov   cx, di
                                                    mov   dx, si
                                                    mov   al, 00h
                                                    mov   ah, 0ch

                                                    mov   si, 0

        timer_2_y:                                  
        timer_2_x:                                  
                                                    cmp   timer_2 + [si],1
                                                    je    draw_the_timer_2
        back_from_timer_2:                          
                                                    inc   si
                                                    inc   cx
                                                    cmp   cx, bp
                                                    jnz   timer_2_x
                                                    mov   cx, di
                                                    inc   dx
                                                    cmp   dx, bx
                                                    jnz   timer_2_y

                                                    jmp   end_timer_2

        draw_the_timer_2:                           
                                                    int   10h
                                                    jmp   back_from_timer_2

        end_timer_2:                                

                                                    POPA

                                                    ret

    draw_timer_2 endp
    draw_timer_3 proc

                                                    PUSHA

                                                ; add   di, 33d
                                                ;  add   si, 31d

                                                    mov   bp, di
                                                    mov   bx, si

                                                    add   bp, 08d
                                                    add   bx, 9d

                                                    mov   cx, di
                                                    mov   dx, si
                                                    mov   al, 00h
                                                    mov   ah, 0ch

                                                    mov   si, 0

        timer_3_y:                                  
        timer_3_x:                                  
                                                    cmp   timer_3 + [si],1
                                                    je    draw_the_timer_3
        back_from_timer_3:                          
                                                    inc   si
                                                    inc   cx
                                                    cmp   cx, bp
                                                    jnz   timer_3_x
                                                    mov   cx, di
                                                    inc   dx
                                                    cmp   dx, bx
                                                    jnz   timer_3_y

                                                    jmp   end_timer_3

        draw_the_timer_3:                           
                                                    int   10h
                                                    jmp   back_from_timer_3

        end_timer_3:                                

                                                    POPA

                                                    ret

    draw_timer_3 endp
    draw_timer_4 proc

                                                    PUSHA

                                                ; add   di, 33d
                                                ;  add   si, 31d

                                                    mov   bp, di
                                                    mov   bx, si

                                                    add   bp, 08d
                                                    add   bx, 9d

                                                    mov   cx, di
                                                    mov   dx, si
                                                    mov   al, 00h
                                                    mov   ah, 0ch

                                                    mov   si, 0

        timer_4_y:                                  
        timer_4_x:                                  
                                                    cmp   timer_4 + [si],1
                                                    je    draw_the_timer_4
        back_from_timer_4:                          
                                                    inc   si
                                                    inc   cx
                                                    cmp   cx, bp
                                                    jnz   timer_4_x
                                                    mov   cx, di
                                                    inc   dx
                                                    cmp   dx, bx
                                                    jnz   timer_4_y

                                                    jmp   end_timer_4

        draw_the_timer_4:                           
                                                    int   10h
                                                    jmp   back_from_timer_4

        end_timer_4:                                

                                                    POPA

                                                    ret

    draw_timer_4 endp
    draw_timer_5 proc

                                                    PUSHA

                                                ; add   di, 33d
                                                ;  add   si, 31d

                                                    mov   bp, di
                                                    mov   bx, si

                                                    add   bp, 08d
                                                    add   bx, 9d

                                                    mov   cx, di
                                                    mov   dx, si
                                                    mov   al, 00h
                                                    mov   ah, 0ch

                                                    mov   si, 0

        timer_5_y:                                  
        timer_5_x:                                  
                                                    cmp   timer_5 + [si],1
                                                    je    draw_the_timer_5
        back_from_timer_5:                          
                                                    inc   si
                                                    inc   cx
                                                    cmp   cx, bp
                                                    jnz   timer_5_x
                                                    mov   cx, di
                                                    inc   dx
                                                    cmp   dx, bx
                                                    jnz   timer_5_y

                                                    jmp   end_timer_5

        draw_the_timer_5:                           
                                                    int   10h
                                                    jmp   back_from_timer_5

        end_timer_5:                                

                                                    POPA

                                                    ret

    draw_timer_5 endp
    draw_timer_6 proc

                                                    PUSHA

                                                ; add   di, 33d
                                                ;  add   si, 31d

                                                    mov   bp, di
                                                    mov   VarToCompare, si

                                                    add   bp, 08d
                                                    add   VarToCompare, 9d

                                                    mov   cx, di
                                                    mov   dx, si
                                                    mov   al, 00h
                                                    mov   ah, 0ch

                                                    mov   si, 0

        timer_6_y:                                  
        timer_6_x:                                  
                                                    cmp   timer_6 + [si],1
                                                    je    draw_the_timer_6
        back_from_timer_6:                          
                                                    inc   si
                                                    inc   cx
                                                    cmp   cx, bp
                                                    jnz   timer_6_x
                                                    mov   cx, di
                                                    inc   dx
                                                    cmp   dx, VarToCompare
                                                    jnz   timer_6_y

                                                    jmp   end_timer_6

        draw_the_timer_6:                           
                                                    int   10h
                                                    jmp   back_from_timer_6

        end_timer_6:                                

                                                    POPA

                                                    ret

    draw_timer_6 endp
    draw_timer_7 proc

                                                    PUSHA

                                                ; add   si, 33d
                                                ;  add   di, 31d

                                                    mov   bp, si
                                                    mov   VarToCompare, di

                                                    add   bp, 08d
                                                    add   VarToCompare, 9d

                                                    mov   cx, si
                                                    mov   dx, di
                                                    mov   al, 00h
                                                    mov   ah, 0ch

                                                    mov   di, 0

        timer_7_y:                                  
        timer_7_x:                                  
                                                    cmp   timer_7 + [di],1
                                                    je    draw_the_timer_7
        back_from_timer_7:                          
                                                    inc   di
                                                    inc   cx
                                                    cmp   cx, bp
                                                    jnz   timer_7_x
                                                    mov   cx, si
                                                    inc   dx
                                                    cmp   dx, VarToCompare
                                                    jnz   timer_7_y

                                                    jmp   end_timer_7

        draw_the_timer_7:                           
                                                    int   10h
                                                    jmp   back_from_timer_7

        end_timer_7:                                

                                                    POPA

                                                    ret

    draw_timer_7 endp
    draw_timer_8 proc

                                                    PUSHA

                                                ; add   si, 33d
                                                ;  add   di, 31d

                                                    mov   bp, si
                                                    mov   VarToCompare, di

                                                    add   bp, 08d
                                                    add   VarToCompare, 9d

                                                    mov   cx, si
                                                    mov   dx, di
                                                    mov   al, 00h
                                                    mov   ah, 0ch

                                                    mov   di, 0

        timer_8_y:                                  
        timer_8_x:                                  
                                                    cmp   timer_8 + [di],1
                                                    je    draw_the_timer_8
        back_from_timer_8:                          
                                                    inc   di
                                                    inc   cx
                                                    cmp   cx, bp
                                                    jnz   timer_8_x
                                                    mov   cx, si
                                                    inc   dx
                                                    cmp   dx, VarToCompare
                                                    jnz   timer_8_y

                                                    jmp   end_timer_8

        draw_the_timer_8:                           
                                                    int   10h
                                                    jmp   back_from_timer_8

        end_timer_8:                                

                                                    POPA

                                                    ret

    draw_timer_8 endp
    draw_timer_9 proc

                                                    PUSHA

                                                ; add   si, 33d
                                                ;  add   di, 31d

                                                    mov   bp, si
                                                    mov   VarToCompare, di

                                                    add   bp, 08d
                                                    add   VarToCompare, 9d

                                                    mov   cx, si
                                                    mov   dx, di
                                                    mov   al, 00h
                                                    mov   ah, 0ch

                                                    mov   di, 0

        timer_9_y:                                  
        timer_9_x:                                  
                                                    cmp   timer_9 + [di],1
                                                    je    draw_the_timer_9
        back_from_timer_9:                          
                                                    inc   di
                                                    inc   cx
                                                    cmp   cx, bp
                                                    jnz   timer_9_x
                                                    mov   cx, si
                                                    inc   dx
                                                    cmp   dx, VarToCompare
                                                    jnz   timer_9_y

                                                    jmp   end_timer_9

        draw_the_timer_9:                           
                                                    int   10h
                                                    jmp   back_from_timer_9

        end_timer_9:                                

                                                    POPA

                                                    ret

    draw_timer_9 endp
    ;function that calls all drawnumbers
    DrawAllNumber PROC
        PUSHA
        ;FOR ODD COLOUMN
        mov di,85 ; mov right or left
             mov si,25 ; mov up or down
        LOOP00:
            CALL draw_timer_0
            add di,70
            cmp di,645
        jne LOOP00
        
        ;FOR ODD COLOUMN
        mov di,85 ; mov right or left
        mov si,65 ; mov up or down
        LOOP12:
            CALL draw_timer_1
            add di,70
            cmp di,645
        jne LOOP12

        ;FOR ODD COLOUMN
        mov di,85 ; mov right or left
        mov si,65+40 ; mov up or down
        LOOP13:
            CALL draw_timer_2
            add di,70
            cmp di,645
        jne LOOP13
        ;FOR ODD COLOUMN
        mov di,85 ; mov right or left
        mov si,65+40+40 ; mov up or down
        LOOP14:
            CALL draw_timer_3
            add di,70
            cmp di,645
        jne LOOP14
            ;FOR ODD COLOUMN
        mov di,85 ; mov right or left
        mov si,65+40+40+40 ; mov up or down
        LOOP15:
            CALL draw_timer_4
            add di,70
            cmp di,645
        jne LOOP15

        mov di,85 ; mov right or left
        mov si,65+40+40+40+40; mov up or down
        LOOP16:
            CALL draw_timer_5
            add di,70
            cmp di,645
        jne LOOP16
        mov di,85 ; mov right or left
        mov si,65+40+40+40+40+40; mov up or down
        LOOP17:
            CALL draw_timer_6
            add di,70
            cmp di,645
        jne LOOP17
    PUSHA
        mov si,85 ; mov right or left
        mov di,65+40+40+40+40+40+40; mov up or down
        LOOP18:
            CALL draw_timer_7
            add si,70
            cmp si,645
        jne LOOP18
    POPA
    PUSHA
        mov si,85 ; mov right or left
        mov di,65+40+40+40+40+40+40+40; mov up or down
        LOOP19:
            CALL draw_timer_8
            add si,70
            cmp si,645
        jne LOOP19
    POPA
    PUSHA
        mov si,85 ; mov right or left
        mov di,65+40+40+40+40+40+40+40+40; mov up or down
        LOOP20:
            CALL draw_timer_9
            add si,70
            cmp si,645
        jne LOOP20
    POPA

        ;FOR ODD COLOUMN
        mov di,20 ; mov right or left
        mov si,25 ; mov up or down
        
        LOOP0z:
            CALL draw_timer_0
            add di,590
            cmp di,1200
        jne LOOP0z
    
        mov di,20 ; mov right or left
        mov si,25+40 ; mov up or down
        
        LOOP1z:
            CALL draw_timer_1
            add di,590
            cmp di,1200
        jne LOOP1z

        mov di,20 ; mov right or left
        mov si,25+40+40 ; mov up or down
        LOOP2z:
            CALL draw_timer_2
            add di,590
            cmp di,1200
        jne LOOP2z

            mov di,20 ; mov right or left
        mov si,25+40+40+40 ; mov up or down
        LOOP3z:
            CALL draw_timer_3
            add di,590
            cmp di,1200
        jne LOOP3z
        
            mov di,20 ; mov right or left
        mov si,25+40+40+40+40 ; mov up or down
        LOOP4z:
            CALL draw_timer_4
            add di,590
            cmp di,1200
        jne LOOP4z

            mov di,20 ; mov right or left
        mov si,25+40+40+40+40+40 ; mov up or down
        LOOP5z:
            CALL draw_timer_5
            add di,590
            cmp di,1200
        jne LOOP5z

        mov di,20 ; mov right or left
        mov si,25+40+40+40+40+40+40 ; mov up or down
        LOOP6z:
            CALL draw_timer_6
            add di,590
            cmp di,1200
        jne LOOP6z

        mov si,20 ; mov right or left
        mov di,25+40+40+40+40+40+40+40 ; mov up or down
        LOOP7z:
            CALL draw_timer_7
            add si,590
            cmp si,1200
        jne LOOP7z

                mov si,20 ; mov right or left
        mov di,25+40+40+40+40+40+40+40+40; mov up or down
        LOOP8z:
            CALL draw_timer_8
            add si,590
            cmp si,1200
        jne LOOP8z

                mov si,20 ; mov right or left
        mov di,25+40+40+40+40+40+40+40+40+40 ; mov up or down
        LOOP9z:
            CALL draw_timer_9
            add si,590
            cmp si,1200
        jne LOOP9z
        POPA
        ret
    DrawAllNumber ENDP 
wString proc NEAR; this was near in original,edited on 21/4/2023
;expects a string's offset to be loaded into dx and it terminated with a $
    PUSHA 
    mov ah,09h
    mov AL,02h
    mov bx,1
    int 21h
    POPA
    RET 
    wString endp

COPYSTRING PROC NEAR; EXPECTS SI TO HAVE OFFSET TO SOURCE AND DI TO HAVE OFFSET TO DESTINATION
    PUSHA
    XOR BX,BX
    COPY101:
    MOV CL,[SI]
    MOV [BX+DI],CL
    INC BX
    INC SI
    CMP BL,COPYSTRING_SIZE
    JNZ COPY101
    POPA
    RET
    COPYSTRING ENDP    


    LOWER_TO_UPPER MACRO STRING
    LOCAL NOTVALID
        PUSHA          
        MOV AL,[STRING]
        CMP AL,97
        JL NOTVALID
        CMP AL,122
        JG NOTVALID
        SUB AL,32D
        MOV [STRING],AL
        NOTVALID:
        POPA
        ENDM LOWER_TO_UPPER


GAMESCREEN PROC NEAR 
; graphicalmode ; I COMMENTED THIS OUT ON 24/4/2023 3:11 PM
   ;change video mode to 640x480
    MOV AH, 00h
    MOV AL, 12h ;12
    INT 10h
	
 ;RELATED TO SCREEN GAME   
        ;CALL changeBackgroundColorbyText
        CALL changeBackgroundColor 
        CALL WriteGuidline

        ;set row 
        MOV dx, 20
        CALL DrawHorizontal
        ;set row 
        MOV dx, 420
        CALL DrawHorizontal
        
        MOV cx,75d ;thats the first coloumn
        CALL DrawVertical

        MOV cx,565d ; thats the last coloumn
        CALL DrawVertical
        drawLoop3:
            CALL DrawVertical
            sub cx,70d         
            cmp cx, 75d ;first coloum
        jne drawLoop3
    

    ;drawing sources & Destination nodes
    MOV dx,30
    XOR BX,BX
    drawLoop8:
    MOV AL,[LogicValue+BX]
    MOV GameScr_LogicValue,AL
    PUSH BX
            CALL DrawSourceAndDestination
            POP BX 
            INC BX
            add dx,40       
            cmp dx, 430 ;last coloum
        jne drawLoop8

    MOV dx,30
    drawLoop10:
            CALL DrawSourceAndDestination1
            add dx,40       
            cmp dx, 430 ;last coloum
    jne drawLoop10

    ;drawing numbers below the nodes
    CALL DrawNumberBelow
   
        PUSHA
        ;FOR ODD COLOUMN
        ;you should specify the RowNum and ColNum  before calling DrawNode
        MOV ColNum ,67d ; move right or left note its 67 not 75 because i want to center the nodes so shifted 8px to the left
        MOV RowNum,30d ; move up or down
        ;thats has an issue will be just fixed with imperative way    
        BIGLOOP1:
            MOV di,0d ; counter

            drawLoop6:
                CALL DrawNode
                add RowNum,40d
                inc di
                cmp di, 10d ;last coloumn
            jne drawLoop6

            MOV RowNum,30d ; reset to start drawing nodes from the top
            add ColNum,70d ; shifting every loop to the next odd coloumn          
            CMP ColNum,627d ;627
        JNE BIGLOOP1
        POPA
        CALL DrawAllNumber
        

RET
GAMESCREEN ENDP


;--------chatting procedures--------------

Send Proc near 
	MOV Xsend,AL;if esc was clicked so exit
	cmp AL,27
    jnz continue
	MOV dx ,3FDH		; Line Status Register, to send data check if THR empty or not
	AGAIN11:
  	In AL,dx 			;Read Line Status
	AND AL , 00100000b
	jz AGAIN11

	MOV dx , 3F8H		; (if empty)Transmit data register
    MOV  AL,Xsend
  	out dx , AL 
	MOV Exit_Chat, 1
	RET
	
	CMP AX, 0E08H
	JNZ continue
	MOV Xsend, 08H
	JMP sDisplay
	
	
    continue:	
	MOV ah,79
	cmp byte ptr firs_half,ah
	jb snot_end_x

	MOV ah,09h
	cmp byte ptr firs_half[1],ah
	jb sDisplay

	MOV word ptr firs_half,0900h
	MOV ah,2
	MOV dx,word ptr firs_half   ;setting cursor
	int 10h 
	MOV bl,0
	MOV AX,0601h
	MOV bh,00Fh       ;scrolling one line
	MOV cx,0300h
	MOV dx,094fh
	int 10h
	jmp sDisplay

    snot_end_x:
	MOV ah,09h
	cmp byte ptr firs_half[1],ah 
	jb scheck_enter
	cmp AL,0Dh
	jne sDisplay
	MOV word ptr firs_half,0D00h
	MOV bl,0
	MOV AX,0601h
	MOV bh,00Fh
	MOV cx,0300h
	MOV dx,094fh
    ;add dl,8
	int 10h
	jmp sDisplay

    scheck_enter:
	cmp AL,0dh
	jne sDisplay
	MOV byte ptr firs_half,00h	
	inc byte ptr firs_half[1]
    	
	jmp sDisplay
	
    sDisplay:
	MOV ah,2
	MOV dx,word ptr firs_half
	int 10h 
	CMP Xsend, 08H
	JNZ PRINT_CHAR_MES
	MOV DL,08H                          ; IN ORDER TO REMOVE THE CHARACTER 
    MOV AH,2                            ; BACKSPACE WAS FIRST PRINTED 
    INT 21H
    MOV DL,' '                          ; THEN SPACE WAS PRINTED 
    MOV AH,2
    INT 21H
	MOV DL,08H                          ; IN ORDER TO REMOVE THE CHARACTER 
    MOV AH,2                            ; BACKSPACE WAS FIRST PRINTED 
    INT 21H
	JMP NEXT_STEP
    PRINT_CHAR_MES:
	MOV dl , Xsend;print char
	MOV ah ,2 
  	int 21h
    NEXT_STEP:
	MOV ah,3h 
	MOV bh,0h    ;getting cursor position
	int 10h
	MOV word ptr firs_half,dx

	MOV dx ,3FDH		; Line Status Register, to send data check if THR empty or not
	AGAIN2:
  	In AL,dx 			;Read Line Status
	AND AL , 00100000b
	jz AGAIN2

	MOV dx , 3F8H		; (if empty)Transmit data register
    MOV  AL,Xsend
  	out dx , AL 
	ret
Send endp


Receive proc near 
        MOV dx , 03F8H
        IN AL , dx 
        MOV Yrecieve , AL
        CMP AH,F3scancode
        JNZ GO_ON
RET
GO_ON:
        cmp AL,27               ; esc was clicked 
        jz buffer
        
        MOV ah,79
        cmp byte ptr sec_half,ah
        jb rnot_end_x

        MOV ah,15h
        cmp byte ptr sec_half[1],ah
        jb rDisplay

        MOV word ptr sec_half,1500h
        MOV ah,2
        MOV dx,word ptr sec_half
        int 10h 

        MOV bl,0
        MOV AX,0601h
        MOV bh,00Fh
        MOV cx,0C00h      ;scrolling one line
        MOV dx,154fh
        int 10h
        jmp rDisplay
    buffer:
        MOV Exit_Chat, 1
        RET
    rnot_end_x:

        MOV ah,15h
        cmp byte ptr sec_half[1],ah
        jb rcheck_enter
        cmp AL,0Dh
        jne rDisplay
        MOV word ptr sec_half,1800h
        MOV bl,0
        MOV AX,0601h
        MOV bh,00Fh
        MOV cx,0C00h
        MOV dx,154fh
        int 10h
        jmp rDisplay

    rcheck_enter:
        cmp AL,0Dh
        jne rDisplay
        MOV byte ptr sec_half,00h	
        inc byte ptr sec_half[1]	
        jmp rDisplay
        
    rDisplay:
        MOV ah,2
        MOV dx,word ptr sec_half
        int 10h 
        CMP Yrecieve, 08H
        JNZ PRINT_CHAR_2
        MOV DL,08H                          ; IN ORDER TO REMOVE THE CHARACTER 
        MOV AH,2                            ; BACKSPACE WAS FIRST PRINTED 
        INT 21H
        MOV DL,' '                          ; THEN SPACE WAS PRINTED 
        MOV AH,2
        INT 21H
        MOV DL,08H                          ; IN ORDER TO REMOVE THE CHARACTER 
        MOV AH,2                            ; BACKSPACE WAS FIRST PRINTED 
        INT 21H
        JMP NEXT_STEP_2
    PRINT_CHAR_2:
    MOV dl , Yrecieve
        MOV ah ,2 
        int 21h
    NEXT_STEP_2:	
        MOV ah,3h 
        MOV bh,0h 
        int 10h
        MOV word ptr sec_half,dx
        ret
		Receive ENDP


chatSCREEN PROC NEAR
        MOV firs_half, 0300h
        MOV sec_half,  0d00h

        movecursor 18h,02h
        print mes4

        movecursor 00h, 00h
        print border

        movecursor 01h, 00h
        print p1name
        ; PRINTSTR MYNAME
        ; LEA DX,MYNAME
        ; CALL WSTRING
        ; print host
        print space
        movecursor 0AH, 00h  
        print line
        movecursor 0bh,00h

        print hisname
        ; PRINTSTR HISNAME
        ; LEA DX,HISNAME
        ; CALL WSTRING
        print space

        movecursor 03h, 00h
        
        MOV bl,0
        MOV AX,0600h
        MOV bh,00fh         ; font and screen colour
        MOV cx,0300H        ;first half
        MOV dx,094fh		
        int 10h	

        MOV bl,0
        MOV AX,0600h
        MOV bh,00Fh       ;font and screen colour
        MOV cx,0C00h      ;second half
        MOV dx,154fh
        int 10h
        MOV bh,0  
        ; call configuration;first thing to do
    IsSenT:
        MOV dx , 3FDH    ; check Line Status Register 
        IN AL , dx 
        AND AL , 1
        JZ next          ; There is no recieved data
        call Receive     ;if ready read the value in received data register
        CMP Exit_Chat, 1
        JZ exitchat
        MOV AL,1 
        MOV dx , 3FDH 
        out dx,AL   
    next:
        MOV ah,1
        int 16h			 ;check if character available in buffer
        jz IsSenT        ; no char is written
        getkeypress ;lw buffer not empty asci in AL,scan in ah
        cmp ah, F3scancode
        JE exitchat
        call Send
        CMP Exit_Chat, 1
        JZ exitchat
        jmp IsSenT
  	
    exitchat:
        ; a3tkd hena hykon fe shwyt cleanup
        CLEARSCREEN 	
		ret  	
chatSCREEN ENDP

    ;that function will take place col in RowNum and row in ColNum  and will draw the nodes and
   
    ;draw lines of start and end with width equal 15 set row by DX
   

detectGameChat proc
MOVECURSOR 27,0
LEA DX, LARGESPACEMSG
CALL WSTRING
movecursor 28,0
CALL WSTRING
movecursor 29,0
CALL WSTRING
movecursor 27,0
lea dx,p1name
call wstring
movecursor 27,30
LEA DX,HISNAME
call wstring
CHECKKEYPRESSED:
	
	;CHECK IF THERE IS A KEY PRESSESD SEND TO THE OTHER USER
	MOV AH,01h
	INT 16H			;check keyboard buffer
	JZ CHECKKEYSENT
	MOV AH,00
	INT 16H
	CMP AL,1BH
	JE ET
	call WRITEINPUT
	CALL SENDKEY
	

	CHECKKEYSENT:   ;recieving
	;CHECK STATE IF THERE IS DATA RECIVED
	;IF THERE IS NO DATA RECIVED
	MOV DX,3FDH
	IN AL,DX      ;if there is nothing in 3fd , AL==0
	AND AL,1	  ;check if AL ==0
	JZ CHECKKEYPRESSED
	;IF THERE IS DATA RECIVED
	;RECIVE DATA AND CALL WRITE IN OUTPUT PROC
	MOV DX,03F8H
	IN AL,DX
	CALL WRITEOUTPUT

	JMP CHECKKEYPRESSED
	;END CODE   
     ET:
     call cleargamechat

RET
detectGameChat endp


WRITEINPUT proc
cmp al,13d
jne cont1
cmp Iy,29d
jb cont1
cmp ix,37d
jb cc
CALL newILine
mov AH,2
mov DL,IX
MOV DH,IY
int 10h
call clearInputScreen
RET
cc:
call clearInputScreen
call newILine
mov IY,29d
mov AH,2
mov DL,IX
MOV DH,IY
int 10h
ret
cont1:
CMP IX,37d
je IENTER2
CMP AL,13d
JE IENTER
CMP ix,37
jb p1c
mov IX,0
inc IY

p1c:
mov AH,2
mov DL,IX
MOV DH,IY
int 10h

mov ah,2
mov dl,AL
int 21h
INC IX
RET
IENTER:
CALL newILine
mov AH,2
mov DL,IX
MOV DH,IY
int 10h
ret
IENTER2:
;CALL newILine
cmp IY,28
jne clearInput
jmp continueinput
clearinput:
call clearInputScreen
continueInput:
mov AH,2
MOV IX,0
MOV IY,29

mov DL,IX
MOV DH,IY
int 10h

; CMP IY,10d
; JE GETNEWLINE
; JMP DONE
; GETNEWLINE:
; CALL newILine
DONE:

ret
WRITEINPUT endp

WRITEOUTPUT proc
cmp al,13d
jne cont2
cmp oy,29d
jb cont2
cmp ox,76d
jb cc1
call clearOutputScreen
RET
cc1:
call clearOutputScreen
call newOLine
mov oY,29d
mov AH,2
mov DL,oX
MOV DH,oY
int 10h
ret
cont2:
cmp OX,76d
je OENTER2
CMP AL,13d
JE OENTER
CMP ox,76
jb p2c
mov oX,39
inc oY
p2c:
mov AH,2
mov DL,oX
MOV DH,oy
int 10h

mov ah,2
mov dl,AL
int 21h
INC oX
RET
OENTER:
CALL newOLine
mov AH,2
mov DL,OX
MOV DH,OY
int 10h

OENTER2:
;CALL newILine
cmp OY,28
jne clearOutput
jmp continueOutput
clearOutput:
call clearOutputScreen
continueOutput:
mov AH,2
MOV OX,39
MOV OY,29

mov DL,OX
MOV DH,OY
int 10h


ret
WRITEOUTPUT endp

clearInputScreen proc
	pusha
	mov al,1h     ; function 6
	mov ah,6h
   mov bh,00h       ; normal video attribute         
   mov ch,28    ; upper left Y
   mov cl,0        ; upper left X
   mov dh,29 ; lower right Y
   mov dl,37      ; lower right X 
   int 10h  
mov ah,3
mov bh,0
int 10h   
mov ah,2
mov dl,' '
int 21h
popa
ret
clearInputScreen endp


clearOutputScreen proc
pusha
	mov al,1h     ; function 6  ;scroll one line
	mov ah,6h
   mov bh,00h       ; normal video attribute         
   mov ch,28       ; upper left Y
   mov cl,39        ; upper left X
   mov dh,29   ; lower right Y
   mov dl,79      ; lower right X 
   int 10h  
mov ah,3
mov bh,0
int 10h   
mov ah,2
mov dl,' '
int 21h
popa
ret
clearOutputScreen endp

SENDKEY PROC
MOV DX,3F8H
OUT DX,AL
RET
SENDKEY ENDP

newILine proc
mov IX,0
inc IY
ret
newILine endp

newOLine proc
mov OX,39
inc OY
ret
newOLine endp


cleargamechat proc
pusha
	mov al,3h     ; function 6
	mov ah,6h
   mov bh,0FFh       ; normal video attribute         
   mov ch,27    ; upper left Y
   mov cl,0        ; upper left X
   mov dh,29 ; lower right Y
   mov dl,77      ; lower right X 
   int 10h  
mov ah,3
mov bh,0
int 10h   
mov ah,2
mov dl,' '
int 21h
popa
ret
cleargamechat endp