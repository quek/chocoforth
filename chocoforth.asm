;; -*- mode: asm; coding: utf-8; -*-
;; nasm -f elf64 chocoforth.asm
;; ld -s -o chocoforth chocoforth.o
;; ./chocoforth

bits 64
%include "syscall.inc"

        CELLL   EQU     8

        ;; nop x 5 call r15
        DOCOL_CODE      EQU     0xd7ff419090909090

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



        F_IMMED         equ     0x80
	F_HIDDEN        equ     0x20

        %define link    0

%macro defword 3                ; name flags label
%strlen namelen %1
;;section .rodata
section .text
align 8
global name_%3
name_%3:
        dq      link
        %define link    name_%3
        db      %2
        db      namelen
        db      %1
        align   8
global  %3
%3:
        dq      DOCOL_CODE
%endmacro

%macro defcode 3                ; name flags label
        %strlen namelen %1
        ;;section .rodata
        section .text
        align 8
        global name_%3
name_%3:
        dq link
        %define link name_%3
        db      %2
        db      namelen
        db      %1
        align 8
        global %3
%3:
%endmacro

%macro defvar 4                 ; name flags label initial-value
        defcode %1, %2, %3
        push    var_%3
        NEXT
        section .data
        align   8
var_%3:                         ; ここが does に相当するのか？ じゃないね。
        dq      %4
%endmacro

%macro defconst 4               ; name flags label, value
        defcode %1, %2, %3
        push    %4
        NEXT
%endmacro

section .text

align   8

_doLIST:
        PUSHRSP rsi
        pop     rsi
        NEXT

_doCREATE:
        pop     rdi
        mov     rax,    [rdi]
        lea     rbx,    [rdi + CELLL]
        push    rbx
        test    rax,    rax
        jnz     .L1
        NEXT
.L1:
        jmp     rax


%macro p 0
        push    rsi
        push    rdi
        push    rdx
        push    rcx
        push    rax
        mov     rdx,    rcx        ; 文字列の長さ
        mov     rsi,    rdi        ; 文字列のアドレス
        mov     rax,    __NR_write ; 出力システムコール
        mov     rdi,    1          ; 標準出力
        syscall                    ; システムコール実行
        mov     rsi,    errmsgnl
        mov     rdx,    1
        mov     rax,    __NR_write
        syscall
        pop     rax
        pop     rcx
        pop     rdx
        pop     rdi
        pop     rsi
%endmacro


        defvar  "STATE",        0,      state,  0
        defvar  "HERE",         0,      here,   0
        defvar  "LATEST",       0,      latest, name_syscall0
        defvar  "S0",           0,      sz,     0
        defvar  "BASE",         0,      base,   10

        defconst        "R0",           0,      rz,             return_stack_top
        defconst        "F_IMMED",      0,      f_immed,        F_IMMED
        defconst        "F_HIDDEN",     0,      f_hidden,       F_HIDDEN

        defconst "SYS_EXIT", 0, sys_exit, __NR_exit
	defconst "SYS_OPEN", 0, sys_open, __NR_open
	defconst "SYS_CLOSE", 0, sys_close, __NR_close
	defconst "SYS_READ", 0, sys_read, __NR_read
	defconst "SYS_WRITE", 0, sys_write, __NR_write
	defconst "SYS_CREAT", 0, sys_creat, __NR_creat
	defconst "SYS_BRK", 0, sys_brk, __NR_brk

	defconst "O_RDONLY", 0, __o_rdonly, 0
	defconst "O_WRONLY", 0, __o_wronly, 1
	defconst "O_RDWR", 0, __o_rdwr, 2
	defconst "O_CREAT", 0, __o_creat, 0100
	defconst "O_EXCL", 0, __o_excl, 0200
	defconst "O_TRUNC", 0, __o_trunc, 01000
	defconst "O_APPEND", 0, __o_append, 02000
	defconst "O_NONBLOCK", 0, __o_nonblock, 04000

        defcode "DROP", 0,      drop
        pop     rax
        NEXT

        defcode "SWAP", 0,      swap
        pop     rax
        pop     rbx
        push    rax
        push    rbx
        NEXT

        defcode "DUP",  0,      dup
        mov     rax,    [rsp]
        push    rax
        NEXT

        defcode "OVER", 0,      over
        mov     rax,    [rsp+CELLL]
        push    rax
        NEXT

        ;; ( x1 x2 x3 -- x2 x3 x1 )
        defcode "ROT",  0,      rot
        pop     rax
        pop     rbx
        pop     rcx
        push    rbx
        push    rax
        push    rcx
        NEXT

        ;; ( x1 x2 x3 -- x3 x1 x2 )
        defcode "-ROT", 0,      nrot
        pop     rax
        pop     rbx
        pop     rcx
        push    rax
        push    rcx
        push    rbx
        NEXT

        defcode "2DROP",        0,      twodrop
        pop     rax
        pop     rax
        NEXT

        defcode "2DUP", 0,      twodup
        mov     rax,    [rsp]
        mov     rbx,    [rsp + CELLL]
        push    rbx
        push    rax
        NEXT

        defcode "2SWAP",        0,      twoswap
        pop     rax
        pop     rbx
        pop     rcx
        pop     rdx
        push    rbx
        push    rax
        push     rdx
        push     rcx
        NEXT

        defcode "?DUP", 0,      qdup
        mov     rax,    [rsp]
        test    rax,    rax
        jz      .L1
        push    rax
.L1:
        NEXT

        defcode "1+",   0,      incr
        inc     qword [rsp]
        NEXT

        defcode "1-",   0,      decr
        dec     qword [rsp]
        NEXT

        defcode "+",    0,      add
        pop     rax
        add     [rsp],    rax
        NEXT

        defcode "-",    0,      sub
        pop     rax
        sub     [rsp],  rax
        NEXT

        defcode "*",    0,      mul
        pop     rax
        pop     rbx
        imul    rax,    rbx
        push    rax
        NEXT

        defcode "/MOD", 0,      divmod
        xor     rdx,    rdx
        pop     rbx
        pop     rax
        idiv    rbx
        push    rdx             ; 剰余 remainder
        push    rax             ; 商   quotient
        NEXT

        defcode "=",    0,      equ
        pop     rax
        pop     rbx
        cmp     rbx,    rax
        sete    al              ; al = 1 if ZF=1
        movzx   rax,    al      ; al -> rax
        push    rax
        NEXT

        defcode "<>",   0,      nequ
        pop     rax
        pop     rbx
        cmp     rbx,    rax
        setne   al
        movzx   rax,    al
        push    rax
        NEXT

        defcode "<",    0,      lt
        pop     rax
        pop     rbx
        cmp     rbx,    rax
        setl    al
        movzx   rax,    al
        push    rax
        NEXT

        defcode ">",    0,      gt
        pop     rax
        pop     rbx
        cmp     rbx,    rax
        setg    al
        movzx   rax,    al
        push    rax
        NEXT

        defcode "<=",   0,      le
        pop     rax
        pop     rbx
        cmp     rbx,    rax
        setle   al
        movzx   rax,    al
        push    rax
        NEXT

        defcode ">=",   0,      ge
        pop     rax
        pop     rbx
        cmp     rbx,    rax
        setge   al
        movzx   rax,    al
        push    rax
        NEXT

        defcode "0=",   0,      zequ
        pop     rax
        test    rax,    rax
        setz    al
        movzx   rax,    al
        push    rax
        NEXT

        defcode "0<>",  0,      nzequ
        pop     rax
        test    rax,    rax
        setnz   al
        movzx   rax,    al
        push    rax
        NEXT

        defcode "0<",   0,      zlt
        pop     rax
        test    rax,    rax
        setl    al
        movzx   rax,    al
        push    rax
        NEXT

        defcode "0>",   0,      zgt
        pop     rax
        test    rax,    rax
        setg    al
        movzx   rax,    al
        push    rax
        NEXT

        defcode "0<=",  0,      zle
        pop     rax
        test    rax,    rax
        setle   al
        movzx   rax,    al
        push    rax
        NEXT

        defcode "0>=",  0,      zge
        pop     rax
        test    rax,    rax
        setge   al
        movzx   rax,    al
        push    rax
        NEXT

        defcode "AND",  0,      and
        pop     rax
        and     [rsp],  rax
        NEXT

        defcode "OR",   0,      or
        pop     rax
        or      [rsp],  rax
        NEXT

        defcode "XOR",  0,      xor
        pop     rax
        xor     [rsp],  rax
        NEXT

        defcode "INVERT",       0,      invert
        not     qword [rsp]
        NEXT

        ;; ( -- x )
        defcode "LIT", 0, lit
        lodsq                   ; rax = [rsi++]
        push    rax             ; リテラルをスタックにプッシュ
        NEXT

        defcode "!",    0,      store
        pop     rbx             ; 変数
        pop     rax             ; 値
        mov     [rbx],  rax     ; 変数のアドレスに値を
        NEXT

        defcode "@",    0,      fetch
        pop     rbx             ; 変数
        mov     rax,    [rbx]   ; 変数のアドレス
        push    rax             ; をスタックに
        NEXT

        defcode "+!",   0,      addstore
        pop     rbx
        pop     rax
        add     [rbx],  rax
        NEXT

        defcode "-!",   0,      substore
        pop     rbx
        pop     rax
        sub     [rbx],  rax
        NEXT

        defcode "C!",   0,      storebyte
        pop     rbx
        pop     rax
        mov     byte [rbx],  al
        NEXT

        defcode "C@",   0,      fetchbyte
        pop     rbx
        xor     rax,    rax
        mov     al,     [rbx]
        NEXT

        defcode "CMOVE",        0,      cmove
        mov     r13,    rsi
        pop     rcx             ; 長さ
        pop     rdi             ; コピー先
        pop     rsi             ; コピー元
        rep     movsb           ; コピー
        mov     rsi,    r13
        NEXT

        defcode ">R",   0,      tor
        pop     rax
        PUSHRSP rax
        NEXT

        defcode "R>",   0,      FROMR
        POPRSP  rax
        push    rax
        NEXT

        defcode "RSP@", 0,      rspfetch
        push    rbp
        NEXT

        defcode "RSP!", 0,      rspstore
        pop     rbp
        NEXT

        defcode "RDROP",        0,      rdrop
        add     rbp,    CELLL
        NEXT

        defcode "DSP@", 0,      dspfetch
        mov     rax,    rsp
        push    rax
        NEXT

        defcode "DSP!", 0,      dspstore
        pop     rsp
        NEXT

        defcode "EMIT", 0,      emit
        pop     rax
        call    _EMIT
        NEXT
_EMIT:
        push    rsi
        mov     rdi,    1            ; 1st param: stdout
        mov     [emit_scratch], al   ; 1バイトのバッファにセット
        mov     rsi,    emit_scratch ; 2nd param: address
        mov     rdx,    1            ; 3rd param: length 1
        mov     rax,    __NR_write   ; write syscall
        syscall
        pop     rsi
        ret

        section .data
emit_scratch:
        db      1


        defcode "KEY",  0,      key
        call    _KEY
        push    rax
        NEXT
_KEY:
        mov     rbx,    [currkey]
        cmp     rbx,    [bufftop]
        jge     .READ
        xor     rax,    rax
        mov     al,     [rbx]
        inc     rbx
        mov     [currkey],      rbx
        ret
.READ:
        push    rsi             ; ris を退避
        xor     rdi,    rdi     ; 1st param: stdin
        mov     rsi,    buffer  ; 2nd param: buffer
        mov     [currkey], rsi
        mov     rdx,    BUFFER_SIZE ; 3rd param: max length of buffer
        mov     rax,    __NR_read   ; syscall: read
        syscall
        test    rax,    rax     ; if rax <= 0 then exit
        jbe     .EOF
        add     rsi,    rax     ; buffer + rax = bufftop
        mov     [bufftop], rsi
        pop     rsi             ; rsi を復元
        jmp     _KEY
.EOF:
        mov     rdi,    -1      ; 1st param: exit code
        mov     rax,    __NR_exit
        syscall


        defcode "WORD", 0,      _WORD
        call    __WORD
        push    rdi             ; push word name address
        push    rcx             ; push word name length
        NEXT
__WORD:
.L1:
        call    _KEY            ; get next key, returned in rax
        cmp     al,     0x5c    ; start of a comment('\\'(0x5c)?
        je      .L3             ; if so, skip the comment
        cmp     al,     0x20    ; rax <= ' '(0x20)?
        jbe     .L1             ; if so, keep looking
        ;; word を word_buffer に
        mov     rdi, word_buffer
.L2:
        stosb
        call    _KEY
        cmp     al,     ' '     ; is blank?
        ja      .L2             ; if not, keep looping
        ;; ワードとその長さを返す。
        sub     rdi,    word_buffer
        mov     rcx,    rdi
        mov     rdi,    word_buffer
        ret
.L3:
        ;; コメントの読み飛し
        call    _KEY
        cmp     al,     0x0a    ; end of line yet?
        jne     .L3
        jmp     .L1

        defcode "FIND", 0, find
        pop     rcx             ; rcx = length
        pop     rdi             ; rdi = address
        call    _FIND
        push    rax             ; rax = address of dictionary entry (or NULL)
        NEXT
_FIND:
        ;; rcx = length, rdi = address
        push    rsi             ; rsi を退避
        mov     rdx,    [var_latest] ; latest points to name header of the latest word in the dictionary
.LOOP:
        test    rdx,    rdx   ; NULL pointer? (end of the linked list)
        je      .NOT_FOUND
        ;; compare the length
        xor     rax,    rax
        mov     al,     byte [rdx+8]  ; flags
        and     al,     F_HIDDEN ; hidden?
        jnz     .NEXT_LINK       ; if so, next word
        mov     al,     [rdx+9]  ; Get length.
        cmp     al,     cl       ; Length is same?
        jne     .NEXT_LINK       ; if not same, next link
        ;; compare the string
        push    rcx
        push    rdi
        lea     rsi,    [rdx+10] ; Dictionary string we are checking against.
        repe    cmpsb            ; Compare the string
        pop     rdi
        pop     rcx
        jne     .NEXT_LINK      ; Not the same.
        ;; The string are the same - return the header poiner in rax
        pop     rsi             ; rsi を復元
        mov     rax,    rdx
        ret
.NEXT_LINK:
        mov     rdx,    [rdx]   ; Move back through the link field to the previout word
        jmp     .LOOP           ; ... and loop.
.NOT_FOUND:
        ;; Not found.
        pop     rsi             ; rsi を復元
        xor     rax,    rax     ; Return zero to indicate not found.
        ret

        defcode ">CFA", 0, TCFA
        pop     rdi             ; dictionary entry point
        call    _TCFA
        push    rdi             ; codeword
        NEXT
_TCFA:
        ;; rdi = ワードの先頭のポインタ(link を指している)
        xor     rax,    rax
        add     rdi,    9       ; link と flags をスキップ
        mov     al,     [rdi]   ; ワード名の長さを取得
        inc     rdi             ; length 分進む
        add     rdi,    rax     ; ワード名をスキップ
        add     rdi,    7       ; 8バイトアライン
        and     rdi,    ~7
        ret

        defcode "NUMBER", 0, number
        pop     rcx             ; 文字列長
        pop     rdi             ; 文字列のアドレス
        call    _NUMBER
        push    rax             ; パースした数値
        push    rcx             ; パースできなかった文字数(正常時は0)
        NEXT
_NUMBER:
        xor     rax,    rax
        xor     rbx,    rbx
        test    rcx,    rcx     ; 文字列長0なら0をリターンする。
        jz      .RET
        mov     rdx,    [var_base] ; 基数(n進数)を取得
        ;; - で始まるかチェック
        mov     bl,     [rdi]   ; 先頭の1文字
        inc     rdi
        push    rax             ; 0 をスタックにプッシュ
        cmp     bl,     '-'     ; 負？
        jnz     .PARSE_NUM      ; 正の数値のパース
        pop     rax
        push    rbx             ; 負であることを示すためにスタックにプッシュ
        dec     rcx
        jnz     .LOOP
        pop     rbx             ; - だけの場合はエラー
        mov     rcx,    1
        ret
.LOOP:
        imul    rax,    rdx     ; rax *= 基数（var_base）
        mov     bl,     [rdi]   ; bl = 次の1文字
        inc     rdi
.PARSE_NUM:
        sub     bl,     '0'     ; < '0'?
        jb      .RESULT
        cmp     bl,     10      ; <= '9'?
        jb      .VALID_NUM
        sub     bl,     17      ; < 'A'? (17 は 'A' - '0')
        jb      .RESULT
        add     bl,     10
.VALID_NUM:
        cmp     bl,     dl      ; >= BASE?
        jge     .RESULT
        ;; rax に足して次の文字へ
        add     rax,    rbx
        dec     rcx
        jnz     .LOOP
.RESULT:
        pop     rbx             ; 負か否か
        test    rbx,    rbx     ; 0 でない場合は負
        jz      .RET            ; 正の場合
        neg     rax             ; 負の場合
.RET:
        ret

        defcode "HEADER",       0,      header
        pop     rcx             ; rcx = length
        pop     rdx             ; rdx = address of name
        mov     rdi,    [var_here]
        mov     rax,    [var_latest]
        stosq                   ; link を設定
        xor     rax,    rax
        stosb                   ; flags を設定
        mov     al,     cl
        stosb                   ; length を設定
        push    rsi             ; rsi 退避
        mov     rsi,    rdx     ; address of name
        rep     movsb           ; name を設定
        pop     rsi             ; rsi 復元
        add     rdi,    7       ; align 8
        and     rdi,    ~7
        mov     rax,    [var_here]
        mov     [var_latest],   rax
        mov     [var_here],     rdi
        NEXT

        defcode ",", 0, comma
        pop     rax             ; Code pointer to store.
        call    _COMMA
        NEXT
_COMMA:
        mov     rdi,    [var_here]   ; HERE
        stosq                        ; Store it.
        mov     [var_here],      rdi ; Update HERE(incremented)
        ret

        defcode "[",    F_IMMED,        lbrac
        xor     rax,    rax
        mov     [var_state],    rax ; state = 0 immediate mode
        NEXT

        defcode "]",    F_IMMED,        rbrac
        mov     qword [var_state],      1 ; state = 1 compile mode
        NEXT


        defword ":",    0,      colon
        dq      _WORD
        dq      header
        ;; あらかじめ mov r15, _doLIST してある。
        dq      lit
        dq      DOCOL_CODE
        dq      comma
        dq      latest, fetch, hidden
        dq      rbrac
        dq      exit

        defword ";",    F_IMMED,        semicolon
        dq      lit, exit, comma
        dq      latest, fetch, hidden
        dq      lbrac
        dq      exit

        defcode "HIDDEN",       0,      hidden
        pop     rdi
        add     rdi,    CELLL
        xor     byte [rdi],     F_HIDDEN
        NEXT

        defcode "IMMEDIATE",    F_IMMED,        immediate
        mov     rdi,    [var_latest]
        add     rdi,    CELLL
        xor     byte[rdi],      F_IMMED
        NEXT

        defcode "BRANCH",       0,      branch
        add     rsi,    [rsi]   ; オフセットを instruction pointer に足す。
        NEXT

        defcode "0BRANCH",      0,      zbranch
        pop     rax
        test    rax,    rax
        jz      branch          ; 0 なら branch へ
        lodsq                   ; 0 でないならオフセットをスキップする
        NEXT

        ;;      LITSTRING
        ;; rsi  文字列長(n)
        ;;      文字1
        ;;      文字2
        ;;      文字...
        ;;      文字n
        ;;      次のワード
        defcode "LITSTRING",    0,      litstring
        lodsq        ; 文字列長を取得。rsi は1文字目のアドレスを指す。
        push    rsi  ; 1文字目のアドレスをスタックに
        push    rax  ; 文字列長をスタックに
        add     rsi,    rax     ; 文字列長を足して次のワードへ
        add     rsi,    CELLL-1   ; align 8
        and     rsi,    ~(CELLL-1)
        NEXT

        defcode "TYPE", 0,      type
        mov     r13,    rsi
        mov     rdi,    1          ; 1st param: 標準出力
        pop     rdx                ; 3rd paarm: 文字列の長さ
        pop     rsi                ; 2nd param: 文字列のアドレス
        mov     rax,    __NR_write ; 出力システムコール
        syscall                    ; システムコール実行
        mov     rsi,    r13
        NEXT

        defcode "EXIT", 0, exit
        POPRSP  rsi
        NEXT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; テスト用コード
        defcode "MESSAGE", 0, message
        push    msg_hello
        push    msg_hello_len
        NEXT

        defcode "MESSAGE_MAMIMUMEMO", 0, message_mamimumemo
        push    msg_mamimumemo
        push    msg_mamimumemo_len
        NEXT

        defcode "SYSTEM_EXIT", 0, system_exit
	mov     rax,    __NR_exit ; exit システムコール
	mov     rdi,     0      ; exit コード
	syscall                 ; システムコール実行

        defword "HELLO", 0, hello
        dq      message
        dq      type
        dq      exit

        defword "MAMIMUMEMO", 0, mamimumemo
        dq      message_mamimumemo
        dq      type
        dq      exit

        defword "DOUBLE_HELLO", 0, double_hello
        dq      hello
        dq      hello
        dq      exit


        defword "QUIT", 0, quit
        dq      rz              ; r0
        dq      rspstore        ; rsp!
        dq      interpret       ; interpret
        dq      branch          ; goto interpret(loop)
        dq      -2 * CELLL

        defcode "INTERPRET", 0, interpret
        call    __WORD           ; Returns rcx = length, rdi = pointer to word.
        ;; p
        xor     rax,    rax
        mov     [interpret_is_lit],     rax ; interpret_is_lit をリセット（0）
        call    _FIND                    ; Returns rax = pointer to header or 0 if not found.
        test    rax,    rax              ; Found?
        jz      .NOT_FOUND
        ;; In the dirctionary. Is it an IMMEDIATE word?
        mov     rdi,    rax
        xor     rax,    rax
        mov     al,     [rdi + 8] ; Get flags.
        push    rax               ; Just save it for new.
        call    _TCFA             ; Returns rax = flags
        pop     rax
        and     al,    F_IMMED ; IMMED フラグがセットされている？
        mov     rax,    rdi
        jnz     .EXECUTE        ; IMMED なら実行
        jmp     .FOUND
.NOT_FOUND:
        ;; Not in the dirctionray (net a word) so assume it's a literal number.
        inc     qword [interpret_is_lit]
        call    _NUMBER         ; Returns rax = parsed number, rcx > 0 is error
        test    rcx,    rcx
        jnz     .PARSE_NUMBER_ERROR
        mov     rbx,    rax
        mov     rax,    lit
.FOUND:
        mov     rdx,    [var_state]
        test    rdx,    rdx
        jz      .EXECUTE
        ;; コンパイル
        call    _COMMA
        mov     rcx,    [interpret_is_lit]
        test    rcx,    rcx     ; リテラル?
        jz      .END
        mov     rax,    rbx     ; LIT に続いてリテラル（数値）を ,
        call    _COMMA
.END:
        NEXT
.EXECUTE:
        ;; Executing - run it!
        mov     rcx,    [interpret_is_lit] ; リテラル？
        test    rcx,    rcx
        jnz     .LITERAL        ; リテラルの場合
        ;; リテラルでないのでジャンプ
        jmp     rax
.LITERAL:
        ;; リテラルの場合はスタックにプッシュして NEXT
        push    rbx
        NEXT
.PARSE_NUMBER_ERROR:
        ;; _NUMBER でのパースエラー
        push    rsi
        mov     rbx,    2       ; 1st param: stderr
        mov     rsi,    errmsg  ; 2nd param: error message
        mov     rdx,    errmsg_len ; 3rd param: error message length
        mov     rax,    __NR_write ; write syscall
        syscall
        ;; エラーは currkey の直前で発生した
        mov     rsi,    currkey
        mov     rdx,    rsi
        sub     rdx,    buffer  ; rdx = currkey - buffer
        sub     rsi,    rdx
        mov     rax,    __NR_write
        syscall
        mov     rsi,    errmsgnl
        mov     rdx,    1
        mov     rax,    __NR_write
        syscall
        pop     rsi
        NEXT

        defcode "CHAR", 0,      char
        call    __WORD
        xor     rax,    rax
        mov     al,     [rdi]
        push    rax
        NEXT

        defcode "EXECUTE",      0,      execute
        pop     rax
        jmp     rax             ; ジャンプした先のワードの NEXT で戻るので
                                ; ここに NEXT は不要

        defcode "SYSCALL3",     0,      syscall3
        pop     rax
        pop     rdi
        mov     r13,    rsi
        pop     rsi
        pop     rdx
        syscall
        push    rax
        mov     rsi,    r13
        NEXT

        defcode "SYSCALL2",     0,      syscall2
        pop     rax
        pop     rdi
        mov     r13,    rsi
        pop     rsi
        syscall
        push    rax
        mov     rsi,    r13
        NEXT

        defcode "SYSCALL1",     0,      syscall1
        pop     rax
        pop     rdi
        syscall
        push    rax
        NEXT

        defcode "SYSCALL0",     0,      syscall0
        pop     rax
        syscall
        push    rax
        NEXT

        section .data
        align   8
interpret_is_lit:
        dq      0


section .text

global _start
_start:
        mov     r15,    _doLIST
        mov     r14,    _doCREATE
        cld                              ; DF(ディレクションフラグ)をクリア
        mov     [var_sz],       rsp      ; スタックアドレスの初期値
	mov     rbp,    return_stack_top ; リターンスタック初期化
        call    set_up_data_segment      ; メモリのアロケート
        ;;mov     rsi,    entry_point
        mov     rsi,    cold_start
        NEXT


        section .data
        align 8

msg_hello:
        db 'Hello World!', 0ah
	msg_hello_len equ $ - msg_hello
msg_mamimumemo:
        db 'まみむめも♪', 0ah
	msg_mamimumemo_len equ $ - msg_mamimumemo

errmsg:
        db "パース エラー: "
        errmsg_len      equ $ - errmsg
errmsgnl:
        db      0ah

entry_point:
        dq      lit
        dq      49
        dq      emit
        dq      double_hello
        dq      system_exit

cold_start:
        dq      quit

currkey:
        dq      buffer
bufftop:
        dq      buffer


section .text
	INITIAL_DATA_SEGMENT_SIZE       EQU     65536
set_up_data_segment:
        mov     rax,    __NR_brk ; brk
	xor     rdi,    rdi      ; Call brk(0)
        syscall
        ;; Initialise HERE to point at beginning of data segment.
	mov     qword [var_here],       rax
        ;; Reserve nn bytes of memory for initial data segment.
	add     rax,    $INITIAL_DATA_SEGMENT_SIZE
        mov     rdi,    rax
	mov     rax,    __NR_brk ;brk
        syscall
	ret

section .bss
        RETURN_STACK_SIZE       EQU     8192
	BUFFER_SIZE             EQU     8192
;; FORTH return stack.
align 4096
return_stack:
	resb    RETURN_STACK_SIZE
return_stack_top:               ; Initial top of return stack.

;;  This is used as a temporary input buffer when reading from files or the terminal.
align 4096
buffer:
        resb    BUFFER_SIZE

word_buffer:
	resb     256
