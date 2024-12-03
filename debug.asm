; ------------- debug.asm ------------


%ifndef __DEBUG_ASM
%define __DEBUG_ASM


%include "tools.asm"


%macro DEBUG_STR 1
%ifdef DEBUG
section .data
	%%str: db %1, 0
	%%len: equ $ - %%str

section .text
	MULTI_PUSH rax, rcx, rdi, rsi, rdx, r10

	mov rax, 1
	mov rdi, 1
	mov rsi, %%str
	mov rdx, %%len
	syscall

	mov rax, 0xA
	push rax
	mov rax, 1
	mov rdi, 1
	mov rsi, rsp
	mov rdx, 1
	syscall
	pop rax

	MULTI_POP rax, rcx, rdi, rsi, rdx, r10
%endif
%endmacro


%macro DEBUG_CALL 1-*
%ifdef DEBUG
%rep %0
	call %1
%rotate 1
%endrep
%endif
%endmacro


%endif
