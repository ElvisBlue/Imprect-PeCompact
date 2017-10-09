.386

.MODEL flat,stdcall

OPTION CASEMAP:NONE

Include windows.inc
Include user32.inc
Include kernel32.inc

IncludeLib user32.lib
IncludeLib kernel32.lib

.DATA


.code
DllEntry proc hInstance:HINSTANCE, reason:DWORD, reserved1:DWORD
	mov  eax,TRUE
	ret
DllEntry Endp
; Exported function to use
;
; Parameters:
; -----------
; <hFileMap>    : HANDLE of the mapped file
; <dwSizeMap>   : Size of that mapped file
; <dwTimeOut>   : TimeOut of ImpREC in Options
; <dwToTrace>   : Pointer to trace (in VA)
; <dwExactCall> : EIP of the exact call (in VA)
;
; Returned value (in eax):
; ------------------------
; Use a value greater or equal to 200. It will be shown by ImpREC if no output were created

; ##########################################################################

Trace proc hFileMap:DWORD, dwSizeMap:DWORD, dwTimeOut:DWORD, dwToTrace:DWORD, dwExactCall:DWORD

    LOCAL dwPtrOutput : DWORD
    LOCAL dwErrorCode : DWORD
    
    push ebx

    ; Map the view of the file (3rd parameter : 6 = FILE_MAP_READ | FILE_MAP_WRITE)
    invoke MapViewOfFile, hFileMap, 6, 0, 0, 0
    test eax, eax
    jnz map_ok

    mov eax, 201                ; Can't map the view
    pop ebx
    ret

map_ok:

    mov dwPtrOutput, eax                ; Get the returned address of the mapped file
    
    cmp dwSizeMap, 4
    jae map_ok2;
    
    mov dwErrorCode, 203                ; Invalid map size
    jmp end2
    
map_ok2:

    ; Check if the given pointer to trace is a valid address
    ; ------------------------------------------------------
    
    mov ebx, dwToTrace
    invoke IsBadReadPtr, ebx, 4
    test eax, eax
    jz ptr_ok1

    mov dwErrorCode, 205                ; Invalid pointer
    jmp end2

ptr_ok1:

    ; Check if we have a mov eax, API_Address
    ; ----------------------------------------------------------------------------------------
    
    cmp byte ptr[ebx], 0B8h
    jnz end_ok



    ; Now write in the mapped file the found pointer
    ; ----------------------------------------------
    
    mov ebx, [ebx+1]
    mov eax, dwPtrOutput;
    mov [eax], ebx;

end_ok:

    mov dwErrorCode, 200                ; All seems to be OK
    
end2:
    invoke UnmapViewOfFile, dwPtrOutput ; Unmap the view
    invoke CloseHandle, hFileMap;       ; Close the handle of the mapped file
    mov eax, dwErrorCode                ; Set error code as returned value

    pop ebx
    ret

Trace endp


End DllEntry
