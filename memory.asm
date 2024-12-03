; ------------ memory.asm ------------


%ifndef __MEMORY_ASM
%define __MEMORY_ASM


; ------------------------------------
; void* alloc(uint64 size)
; Allocates %size number of bytes and
; return pointer to allocated memory
alloc:
	mov rsi, rdi			; size
	add rsi, 8			; 8 bytes to store allocated size
	mov rax, 9			; mmap
	mov rdi, 0
	mov rdx, 0x3			; PROT_READ | PROT_WRITE
	mov r10, 0x22			; MAP_PRIVATE | MAP_ANONYMOUS
	mov r8, -1
	mov r9, 0
	syscall

	cmp rax, -1			; mmap failed
	je .failed
	
	mov [rax], rsi			; save size before block
	add rax, 8
	ret

.failed:
	xor rax, rax			; return nullptr
	ret


; ------------------------------------
; void dealloc(void* mem)
; Frees memory pointed by %mem
dealloc:
	test rdi, rdi			; freeing nullptr has no effect
	jz .exit

	sub rdi, 8
	mov rsi, [rdi]			; number of bytes to free
	mov rax, 11			; sys_munmap
	syscall

.exit:
	ret


; ------------------------------------
; void* realloc(void* mem, uint64 size)
; Reallocates memory pointed by %mem
; to %size size and returns new
; pointer. Old pointer becomes invalid.
realloc:
	push rdi

	mov rdi, rsi
	call alloc
	
	cmp rax, 0
	jz .failed
	
	pop rdi
	mov rsi, rax
	mov rdx, [rdi-8]
	call memcpy

	call dealloc
	ret

.failed:
	xor rax, rax
	ret


; ------------------------------------
; void memset(void* mem, uint64 amount,
;	      uint8 byte)
; Sets %amount of bytes to %byte in
; memory pointed by %mem
memset:
	cld
	mov al, dl
	mov rcx, rsi
	rep stosb
	ret


; ------------------------------------
; void memcpy(void* dest, void* src,
;	      uint64 amount)
; Copies %amount of bytes from memory
; pointed by %src to memory pointed by
; %dest
memcpy:
	cld
	mov rcx, rdx
	rep movsb
	ret


%endif
