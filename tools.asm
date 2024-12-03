; ------------- tools.asm ------------


%ifndef __TOOLS_ASM
%define __TOOLS_ASM


%macro MULTI_PUSH 1-*
%rep %0
	push %1
%rotate 1
%endrep
%endmacro


%macro MULTI_POP 1-*
%rep %0
%rotate -1
	pop %1
%endrep
%endmacro


%endif
