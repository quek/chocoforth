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
    LIT BRANCH ,                          \ 真の場合のジャンプ
    HERE @                              \ 真の場合のジャンプ開始位置
    0 ,                                 \ 真の場合のオフセット
    SWAP                                \ IF と ELSE の HERE @ を入れ替え
    DUP                                 \ IF の HERE @ を DUP
    HERE @ SWAP -                       \ 偽だった場合のオフセット
    SWAP !                      \ DUP した IF の HERE @ にオフセットを
;
: test-if-true 1 IF 49 EMIT ELSE 48 EMIT THEN ;
test-if-true
: test-if-false 0 IF 49 EMIT ELSE 48 EMIT THEN ;
test-if-false


: '\n' 10 ;
: ONE  49 ;
'\n' ONE ONE '\n' EMIT EMIT EMIT EMIT

: TRIPLE_HELLO
    DOUBLE_HELLO HELLO ;
TRIPLE_HELLO

: BL 32 ;
: CR
    '\n' EMIT ;
: SPACE
    BL EMIT ;

: TRUE  1 ;
: FALSE 0 ;
: NOT   0= ;

: LITERAL IMMEDIATE
    LIT LIT ,                             \ LIT をコンパイル
    ,                                   \ リテラルをコンパイル
;

: ';' [ CHAR ; ] LITERAL ;
';' EMIT CR

: / /MOD SWAP DROP ;
: MOD /MOD DROP ;
: NEGATE
    0 SWAP - ;



