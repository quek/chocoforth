: TRUE  1 ;
: FALSE 0 ;
: NOT   0= ;

: IF IMMEDIATE
    LIT 0BRANCH ,         \ 偽の場合のジャンプ
    HERE @                \ 偽の場合のジャンプ開始アドレスをスタックに
    0 ,                   \ あとでこの 0 をオフセットで上書く
;

: THEN IMMEDIATE
    DUP                               \ IF での HERE @ を DUP
    HERE @ SWAP -                     \ オフセットを計算
    SWAP !                            \ IF での HERE @ に オフセットを
;

: ELSE IMMEDIATE
    LIT BRANCH ,                \ 真の場合のジャンプ
    HERE @                      \ 真の場合のジャンプ開始位置
    0 ,                         \ 真の場合のオフセット
    SWAP                        \ IF と ELSE の HERE @ を入れ替え
    DUP                         \ IF の HERE @ を DUP
    HERE @ SWAP -               \ 偽だった場合のオフセット
    SWAP !                      \ DUP した IF の HERE @ にオフセットを
;
: test-if-true 1 IF 49 EMIT ELSE 48 EMIT THEN ;
test-if-true
: test-if-false 0 IF 49 EMIT ELSE 48 EMIT THEN ;
test-if-false

\ ( "<spaces>name" -- xt ) エラーチェックが必要
: '
    WORD FIND >CFA
;

\ Compilation: ( "<spaces>name" -- ) Run-time: ( -- xt )
: ['] IMMEDIATE
    LIT LIT ,                           \ LIT をコンパイル
    ' ,                                 \ ワードをパースしてコンパイル
;

\ 6.2.2530 [COMPILE] Compilation: ( "<spaces>name" -- )
: [COMPILE] IMMEDIATE
    ' ,
;

: RECURSE IMMEDIATE
    LATEST @                            \ コンパイル中のワードの
    >CFA                                \ codewordを
    ,                                   \ コンパイルする。
;
: fib
    DUP 1 > IF
        DUP 1- RECURSE SWAP 2- RECURSE
    THEN
;

\ 6.1.0760 BEGIN Compilation: ( C: -- dest ) Run-time: ( -- )
: BEGIN IMMEDIATE
    HERE @                              \ ループの先頭アドレスをスタックに
;

: UNTIL IMMEDIATE
    LIT 0BRANCH ,
    HERE @ -
    ,
;

: AGAIN IMMEDIATE
    LIT BRANCH ,
    HERE @ -
    ,
;

: WHILE IMMEDIATE
    LIT 0BRANCH ,
    HERE @
    0 ,
;

: REPEAT IMMEDIATE
    LIT BRANCH ,
    SWAP
    HERE @ - ,
    DUP
    HERE @ SWAP -
    SWAP !
;

: UNLESS IMMEDIATE
    LIT NOT ,
    [COMPILE] IF
;
: test-unless
    0 UNLESS
    49 EMIT
ELSE
    50 EMIT
THEN
    1 UNLESS
    49 EMIT
ELSE
    50 EMIT
THEN
;
test-unless

: [CHAR] IMMEDIATE
    LIT LIT ,
    CHAR ,
;

\ 6.1.0080 ( ( "ccc<paren>" -- )
: ( IMMEDIATE
    1                                   \ ネストの深さ
    BEGIN
        KEY
        DUP [CHAR] ( = IF               \ ネストしたコメントの開始
            DROP
            1+                          \ ネスト + 1
        ELSE
            [CHAR] ) = IF               \ コメントの終り
                1-                      \ ネスト - 1
            THEN
        THEN
    DUP 0= UNTIL                        \ ネストが 0 ならおしまい
    DROP
;

: LITERAL IMMEDIATE
    LIT LIT ,                           \ LIT をコンパイル
    ,                                   \ リテラルをコンパイル
;

: '\n' 10 ;
: BL   32 ;
: CR
    '\n' EMIT ;
: SPACE
    BL EMIT ;

: / /MOD SWAP DROP ;
: MOD /MOD DROP ;
: NEGATE
    0 SWAP - ;


\ 6.1.0890 CELLS ( n1 -- n2 )
: CELLS 8 * ;

: TRIPLE_HELLO
    CR DOUBLE_HELLO HELLO ;
TRIPLE_HELLO

( MAMIMUMEMO )
MAMIMUMEMO
