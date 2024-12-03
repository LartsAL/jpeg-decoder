%define DEBUG

%include "common.asm"
%include "memory.asm"
%include "tools.asm"
%include "debug.asm"


%macro TEST_MARKERS_MSG 1
	DEBUG_STR {"Found ", %1}
%endmacro


section .rodata	
	; errors
	ERROR_CANNOT_OPEN_FILE: db "ERROR: Cannot open file.", 0
	ERROR_UNKNOWN_MARKER: db "ERROR: Marker with unknown value found.", 0
	ERROR_ALLOC_FAILED: db "ERROR: Memory allocation failed.", 0
	
	FILENAME: db "test.jpg", 0
	BLOCK_SIZE: equ 1024
	
	; switch labels
	MARKER_TABLE: dq marker_SOI, marker_APP0, marker_DQT, marker_SOF0, marker_DHT, marker_SOS, marker_EOI, marker_ESCAPED
	
	; switch values
	;		  SOI,  APP0, DQT,  SOF0, DHT,  SOS,  EOI,  ESC
	MARKER_VALUES: db 0xD8, 0xE0, 0xDB, 0xC0, 0xC4, 0xDA, 0xD9, 0x00
	MARKER_COUNT: equ $ - MARKER_VALUES

section .data
	marker_flag: db 0

	quantisation_tables: times 16 dq 0

section .bss
	descriptor: resq 1
	
	block: resb BLOCK_SIZE
	bytes_read: resq 1

	section_size: resw 1

section .text
	global _start


read_block:
	push rax
	push rdx

	mov rax, 0			; sys_read
	mov rdi, [descriptor]
	mov rsi, block
	mov rdx, BLOCK_SIZE
	syscall
	
	mov [bytes_read], rax		; save number of bytes read
	test rax, rax
	jz .quit.close_file		; all file read
	
	xor r15, r15
	mov rsi, block
	
	pop rdx
	pop rax

	ret

.quit.close_file:
	mov rax, 3			; sys_close
	mov rdi, [descriptor]
	syscall

	pop rdx
	pop rax

	call quit
	ret


read_byte:
	xor rax, rax

	cmp r15, [bytes_read]
	jge .next_block

	lodsb
	inc r15
	ret

.next_block:
	call read_block
	lodsb
	inc r15
	ret


read_section_size:
	xor rbx, rbx

	call read_byte
	add rbx, rax

	shl rbx, 8

	call read_byte
	add rbx, rax
	sub rbx, 2
	
	mov [section_size], rbx
	mov rax, rbx
	ret


marker_SOI:
	TEST_MARKERS_MSG "SOI"
	ret


marker_APP0:
	TEST_MARKERS_MSG "APP0"

	call read_section_size			; skipping APP0 section

	add r15, [section_size]
	add rsi, [section_size]
	ret


marker_DQT:
	TEST_MARKERS_MSG "DQT"

	call read_section_size
	
	call read_byte				; precision + table ID
	
	mov rbx, rax

	mov rdx, rbx
	and rdx, 0xF0				; most significant nibble: precision
	
	test rdx, rdx
	mov rax, 64
	cmovnz rdi, rax				; single precision
	mov rax, 128
	cmovz rdi, rax				; double precision
	
	push rsi
	call alloc
	pop rsi
	
	cmp rax, 0
	jnz .valid_pointer
	mov rdi, ERROR_ALLOC_FAILED
	jmp _start.quit.error

.valid_pointer:
	mov rdx, rbx
	and rdx, 0x0F				; least significant nibble: ID

	mov [quantisation_tables+rdx], rax	; save pointer to new QT

%ifdef DEBUG
	mov rdi, rax
	push rsi
	call dealloc
	pop rsi
%endif

	ret


marker_SOF0:
	TEST_MARKERS_MSG "SOF0"
	ret


marker_DHT:
	TEST_MARKERS_MSG "DHT"
	ret


marker_SOS:
	TEST_MARKERS_MSG "SOS"
	ret


marker_EOI:
	TEST_MARKERS_MSG "EOI"
	ret


marker_ESCAPED:
	TEST_MARKERS_MSG "escaped FF byte"
	ret


_start:
	mov rax, 2				; sys_open
	mov rdi, FILENAME
	mov rsi, 0
	syscall

	cmp rax, 0
	jge .setup.valid_descriptor
	mov rdi, ERROR_CANNOT_OPEN_FILE
	jmp .quit.error

.setup.valid_descriptor:
	mov [descriptor], rax			; save file descriptor

.read.read_block:
	call read_block

.read.read_byte:
	call read_byte
	cmp [marker_flag], byte 1		; check value from splitted marker
	je .parse.switch_setup

	cmp al, 0xFF
	jne .parse.not_marker
	mov [marker_flag], byte 1		; found marker

	call read_byte				; check what marker is it

.parse.switch_setup:
	lea r12, [MARKER_VALUES]
	mov r13, MARKER_COUNT
	xor rbx, rbx

.parse.switch:
	cmp al, byte [r12+rbx]
	je .parse.case
	
	inc rbx
	dec r13
	test r13, r13
	jnz .parse.switch
		
	mov rdi, ERROR_UNKNOWN_MARKER		; marker type not recognized
	jmp .quit.error

.parse.case:
	lea r12, [MARKER_TABLE]
	mov rdx, [r12+rbx*8]
	call rdx

.parse.not_marker:
	mov [marker_flag], byte 0
	jmp .read.read_byte

.quit.error:
	call sprintLF
	mov rdi, 1
	call quiterr
