;; -*- mode: asm; coding: utf-8; -*-
;; nasm -f elf64 chocoforth.asm
;; ld -s -o chocoforth chocoforth.o
;; ./chocoforth
;;
;;
;; <<Direct Threaded Code>>
;; DOUBLE:
;;         PUSHRSP rsi
;;         mov     rsi,    DOUBLE_code
;;         NEXT
;; DOUBLE_code:
;;         DUP
;;         PLUS
;;         EXIT
;; DUP:
;;         mov     rax,    rsp
;;         push    rax
;;         NEXT
;; EXIT:
;;         POPRSP  rsi
;;         NEXT
;;
;; <<Indirect Threaded Code>>
;; DOUBLE:
;;         DOCOL                   ; codeword
;;         DUP
;;         PLUS
;;         EXIT
;; DUP:
;;         DUP_code                ; codeword
;; DUP_code:
;;         mov     rax,    rsp
;;         push    rax
;;         NEXT
;; EXIT:
;;         EXIT_code               ; codeword
;; EXIT_code:
;;         POPRSP  rsi
;;         NEXT
;; DOCOL:
;;         PUSHRSP rsi
;;         add     rax,    CELLL
;;         mov     rsi,    rax
;;         NEXT
bits 64
%include "syscall.inc"

        CELLL   EQU     8

%macro PUSHRSP 1
        lea     rbp,    [rbp - CELLL]
        mov     [rbp],  %1
%endmacro

%macro POPRSP 1
        mov     %1,     [rbp]
        lea     rbp,    [rbp + CELLL]
%endmacro

%macro NEXT 0
	lodsq
	jmp rax
%endmacro

%macro DOCOL 0
        PUSHRSP rsi
        mov     rsi,    .code + 8
        jmp     [.code]
section .data
align 8
.code:
%endmacro


section .text

align   8

EXIT:
        POPRSP  rsi
        NEXT


message:
        push    msg
        push    len
        NEXT
system_exit:
	mov     rax,    60      ; exit システムコール
	mov     rdi,     0      ; exit コード
	syscall                 ; システムコール実行
say:
        mov     r12,    rsi     ; rsi を退避
        pop     rdx             ; 文字列の長さ
        pop     rsi             ; 文字列のアドレス
        mov     rax,    __NR_write ; 出力システムコール
        mov     rdi,    1       ; 標準出力
        syscall                 ; システムコール実行
        mov     rsi,    r12     ; rsi を復元
        NEXT

hello:
        DOCOL
        dq      message
        dq      say
        dq      EXIT
section .text

double_hello:
        DOCOL
        dq      hello
        dq      hello
        dq      EXIT
section .text


global _start

_start:
        cld                              ; DF(ディレクションフラグ)をクリア
	mov     rbp,    return_stack_top ; リターンスタック初期化
        call    set_up_data_segment      ; メモリのアロケート
        mov     rsi,    entry_point
        NEXT

section .data

msg:
        db 'Hello World!', 20h
        db 'まみむめも♪', 0ah
	len equ $ -msg

align 8
entry_point:
        dq      double_hello
        dq      system_exit


	RETURN_STACK_SIZE       EQU     8192
	BUFFER_SIZE             EQU     4096


section .text
	INITIAL_DATA_SEGMENT_SIZE       EQU     65536
set_up_data_segment:
        mov     rax,    __NR_brk ; brk
	xor     rdi,    rdi      ; Call brk(0)
        syscall
        ;; Initialise HERE to point at beginning of data segment.
	mov     [var_HERE],     rax
        ;; Reserve nn bytes of memory for initial data segment.
	add     rax,    $INITIAL_DATA_SEGMENT_SIZE
        mov     rdi,    rax
	mov     rax,    __NR_brk ;brk
        syscall
	ret

section .data
var_HERE:
        dq      0



section .bss
;; FORTH return stack.
align 4096
return_stack:
	resb    RETURN_STACK_SIZE
return_stack_top:               ; Initial top of return stack.

;;  This is used as a temporary input buffer when reading from files or the terminal.
align 4096
buffer:
        resb    BUFFER_SIZE
