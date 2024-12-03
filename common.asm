; ------------ common.asm ------------


%ifndef __COMMON_ASM
%define __COMMON_ASM


; ------------------------------------
; void quit()
; Exits the program with exit code 0
quit:
	mov rax, 60
	xor rdi, rdi
	syscall
	ret


; ------------------------------------
; void quiterr(int code)
; Exits the programm with error code
; specified by %code
quiterr:
	mov rax, 60
	syscall
	ret


; ------------------------------------
; void printLF()
; Prints linefeed
printLF:
	push rcx
	push rdx

	mov rax, 0xA			; \n
	push rax
	
	mov rax, 1
	mov rdi, 1
	mov rsi, rsp
	mov rdx, 1
	syscall

	pop rax

	pop rdx
	pop rcx
	ret


; ------------------------------------
; int strlen(String msg)
; Calculates string length
strlen:
	mov rax, rdi

.nextchr:
	cmp byte [rax], 0
	jz .finished
	inc rax
	jmp .nextchr

.finished:
	sub rax, rdi
	ret


; ------------------------------------
; void sprint(String msg)
; Prints string
sprint:
	push rcx
	push rdx

	call strlen
	
	mov rdx, rax			; msg length
	mov rsi, rdi			; msg pointer
	mov rdi, 1			; stdout
	mov rax, 1			; sys_write
	syscall

	pop rdx
	pop rcx
	ret


; ------------------------------------
; void sprintLF(String msg)
; Prints string and LF
sprintLF:
	call sprint			; print msg
	call printLF
	ret


; ------------------------------------
; void iprint(int n)
; Prints integer
iprint:
	push rbx
	push rcx
	push rdx

	mov rax, rdi
	mov rbx, 10			; base
	xor rcx, rcx

.divloop:
	xor rdx, rdx
	idiv rbx
	add rdx, 48
	push rdx
	inc rcx
	cmp rax, 0
	jnz .divloop

.printloop:
	mov rdi, rsp
	push rcx
	call sprint
	pop rcx
	pop rdi				; pop digit
	loop .printloop
	
	pop rdx
	pop rcx
	pop rbx
	ret


; ------------------------------------
; void iprintLF(int n)
; Prints integer and LF
iprintLF:
	call iprint
	call printLF
	ret


%endif
