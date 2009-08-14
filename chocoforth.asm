;; -*- mode: asm; coding: utf-8; -*-
;; nasm -f elf64 chocoforth.asm
;; ld -s -o chocoforth chocoforth.o
;; ./chocoforth

        CELLL   EQU     8

%macro PUSHRSP 1
        lea     rbp,    [rbp - CELLL]
        mov     rbp,    %1
%endmacro

%macro POPRSP 1
        mov     %1,     [rbp]
        lea     rbp,    [rbp + CELLL]
%endmacro

%macro NEXT 0
	lodsq
	jmp rax
%endmacro

section .text

align   8

DOCOL:
        PUSHRSP rsi
        add     rax,    CELLL
        mov     rsi,    rax
        NEXT

;; <<Direct Threaded Code>>
;; DOUBLE:
;;         PUSHRSP rsi
;;         mov     rsi,    DOUBLE_code+8
;;         jmp     [DOUBLE_code]
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
        mov     rax,    1       ; 出力システムコール
        mov     rdi,    1       ; 標準出力
        syscall                 ; システムコール実行
        mov     rsi,    r12     ; ris を復元
        NEXT

global _start

_start:
        mov     rsi,    hello
        NEXT

section .data

msg:
        db 'Hello World!', 0ah
        db 'まみむめも♪', 0ah
	len equ $ -msg

align 8
hello:
        dq      message
        dq      say
        dq      system_exit
