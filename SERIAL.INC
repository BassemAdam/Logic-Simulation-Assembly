SendAByte macro data  ; data transferred is in BL (8 bits)
local againM
            ;Check that Transmitter Holding Register is Empty
            mov dx , 3FDH		        ; Line Status Register
            AGAINM:
                In al, dx 			    ; Read Line Status
                test al, 00100000b
            JZ AGAINM                    ; Not empty

            ;If empty put the VALUE in Transmit data register
            mov dx, 3F8H		        ; Transmit data register
            mov al, data
            out dx, al

            ; ret
        endm SendAByte ;ENDP

        RecieveAByte macro data ; data is saved in BL
local CHK_RecieveByteM
            ;Check that Data is Ready
            mov dx , 3FDH		; Line Status Register
            CHK_RecieveByteM:
                in al , dx 
                test al , 1
            JZ CHK_RecieveByteM              ; Not Ready

            ; If Ready read the VALUE in Receive data register
            mov dx , 03F8H
            in al , dx 
            ; mov bl , al
            mov data,al

            ; Return_RecieveByte:
                ; ret
        endm RecieveAByte ;ENDP

initializeserial macro
    ;initialze port
    mov dx,3FbH         
    mov al,10000000b
    out dx,al

    mov dx,3f8h
    mov al,0ch
    out dx,al

    mov dx,3f9h
    mov al,00h
    out dx,al

    ;configuration
    mov dx,3fbh
    mov al,00011011b
    out dx,al
endm initializeserial


 SendMsg PROC  ; Sent string offset is saved in si, ended with '$'
           PUSHA
            SendMessage:
                CALL SendData
                inc si
                mov dl, '$'
                cmp dl , byte ptr [si]-1
                jnz SendMessage
                POPA
            RET
        SendMsg ENDP

        SendData PROC  ; data transferred is pointed to by si (8 bits)
           PUSHA

            ;Check that Transmitter Holding Register is Empty
            mov dx , 3FDH		        ; Line Status Register
            AGAIN_SendData:
                In al, dx 			    ; Read Line Status
                test al, 00100000b
            JZ AGAIN_SendData                    ; Not empty

            ;If empty put the VALUE in Transmit data register
            mov dx, 3F8H		        ; Transmit data register
            mov al, [si]
            out dx, al
POPA
            ret
        SendData ENDP
        
        RecMsg PROC     ; Recieved string offset is saved in di
           PUSHA
            
            RecieveMsg:
                CALL RecieveByte
                mov [di], bl
                inc di
                cmp bl, '$'
                jnz RecieveMsg
POPA
            RET
        RecMsg ENDP
        
        RecieveData PROC ; data is saved in BL
PUSHA
            ;Check that Data is Ready
            mov dx , 3FDH		; Line Status Register
            CHK_RecieveData:
                in al , dx 
                test al , 1
            JZ Return_RecieveData              ; Not Ready

            ; If Ready read the VALUE in Receive data register
            mov dx , 03F8H
            in al , dx 
            mov bl , al

            Return_RecieveData:
                POPA
                ret
        RecieveData ENDP


                SendByte PROC  ; data transferred is in BL (8 bits)
            ;Check that Transmitter Holding Register is Empty
            mov dx , 3FDH		        ; Line Status Register
            AGAIN:
                In al, dx 			    ; Read Line Status
                test al, 00100000b
            JZ AGAIN                    ; Not empty

            ;If empty put the VALUE in Transmit data register
            mov dx, 3F8H		        ; Transmit data register
            mov al, BL
            out dx, al

            ret
        SendByte ENDP
        RecieveByte PROC ; data is saved in BL

            ;Check that Data is Ready
            mov dx , 3FDH		; Line Status Register
            CHK_RecieveByte:
                in al , dx 
                test al , 1
            JZ CHK_RecieveByte              ; Not Ready

            ; If Ready read the VALUE in Receive data register
            mov dx , 03F8H
            in al , dx 
            mov bl , al

            Return_RecieveByte:
                ret
        RecieveByte ENDP


; CommunicateInitialPoints PROC NEAR
; PUSHA
; XOR BX,BX
; CMP HOST,'Y'
; JNZ RECEIVING
; CALL Randomize
; XOR SI,SI
; SENDINGRANDOMVALUES:
; MOV AL,[LogicValue+SI]
; MOV VR2,AL
; PUSHA
; SENDABYTE VR2 
; POPA
; INC SI
; CMP SI,10D
; JNZ SENDINGRANDOMVALUES
; JMP BOTHDONE
; XOR BX,BX
; RECEIVING:
; PUSHA
; RecieveAByte VR2
; POPA
; MOV AL,VR2
; MOV [LogicValue+BX],AL
; INC BX
; CMP BX,10D
; JNZ RECEIVING
; LEA DX,OUTOFHERER
; CALL WSTRING
; BOTHDONE:

; POPA
; RET
; CommunicateInitialPoints ENDP

; DETECT PROC NEAR
; progloop:
; MOV AH,1    ;check if a key is pressed
; INT 16h
; JZ dummy2   ; if not then JMP to recieving mode
; JNZ SENDLABEL    ;if yes JMP to SENDLABEL mode
; SENDLABEL:
; MOV AH,0   ;clear the keyboard buffer
; INT 16h 
; MOV value,AL  ; save the key ascii code IN AL
; JMP R01
; ;----------------------------
; dummy2:JMP recieve
; ;----------------------------
  
;   progloop_INTER:
;   JMP progloop
;   R01:
; PRINTSTR INHERE
; ; LEA DX,INHERE
; ; CALL WSTRING
; MOV HOST,'Y'
; MOV DX,3FDH 		; Line Status Register
; AGAINLOOP:In AL , DX 	;Read Line Status
; test AL , 00100000b
; JZ recieve                    ;Not empty
; MOV DX , 3F8H		; Transmit data register
; MOV AL,value        ; put the data into AL
; OUT DX , AL         ; sending the data
; CMP AL,'0'
; JNZ HOST_NOT_DETERMINED_YET
; JMP EXITLABEL
; HOST_NOT_DETERMINED_YET:
; ; saveCursorS         ; we need to save the cursor here 
; JMP progloop        ; loop again
;    dummy:JMP EXITLABEL
;    dummy3:JMP SENDLABEL
; recieve:
; MOV AH,1            ;check if there is key pressed then go to the sending mode
; INT 16h
; JNZ dummy3

; MOV DX , 3FDH		; Line Status Register
; IN AL , DX 
; TEST AL , 1
; JZ recieve       
; ; LEA DX, RECEIVED 
; ; CALL WSTRING  
; PRINTSTR received
; MOV value,AL
; COLOREDCHAR value 

; MOV DX , 03F8H
; IN AL , DX 
; MOV value,AL              ;check if the recieved data is sec key then terminate the programe 
; CMP value,27
; JZ  dummy
; CMP AL,'0'
; JNE progloop_INTER 
; MOV HOST,'N'
; MOV HOSTDETERMINED,1
; JMP EXITLABEL
; JMP progloop 
; EXITLABEL:
; PRINTSTR EXITING
; RET
; DETECT ENDP
; SendAByte PROC NEAR;data  ; data transferred is in SendTemp
; ; local again
; PUSHA
;             ;Check that Transmitter Holding Register is Empty
;             mov dx , 3FDH		        ; Line Status Register
;             AGAIN_:
;                 In al, dx 			    ; Read Line Status
;                 test al, 00100000b
;             JZ AGAIN_                    ; Not empty

;             ;If empty put the VALUE in Transmit data register
;             mov dx, 3F8H		        ; Transmit data register
;             mov al, sendTemp
;             out dx, al
; POPA
;         RET
; SendAByte ENDP


; RecieveAByte PROC NEAR; data is saved in RecTemp
; PUSHA
; ;Check that Data is Ready
; mov dx , 3FDH		; Line Status Register
; CHK_RecieveAByte:
; in al , dx 
; test al , 1
; JZ CHK_RecieveAByte              ; Not Ready

; ; If Ready read the VALUE in Receive data register
; mov dx , 03F8H
; in al , dx 
; ; mov bl , al
; mov RecTemp,al

; ; Return_RecieveByte:
; POPA
; RET
; RecieveAByte ENDP

; ReceiveData PROC NEAR; IT RECEIVES THE SIZE OF THE DATA IN DSIZE
; PUSHA
; XOR BX,BX
; Rec_Loop:
; CALL RecieveAByte
; MOV AL,RecTemp
; MOV [DataPtr+BX],AL
; INC BX
; CMP BL,DSIZE
; JNZ Rec_Loop
; POPA
; RET
; ReceiveData ENDP

; SendData PROC NEAR; IT RECEIVES THE SIZE OF THE DATA IN DSIZE, THE OFFSET OF THE DATA IN DataPtr
; PUSHA
; XOR BX,BX
; Send_Loop:
; MOV AL,[DataPtr+BX]
; MOV sendTemp,AL
; CALL SendAByte
; INC BX
; CMP BL,DSIZE
; JNZ Send_Loop
; POPA
; RET
; SendData ENDP