: '\n' 10 ;
: ONE  49 ;
'\n' ONE ONE EMIT EMIT EMIT

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
    ' LIT ,                             \ LIT をコンパイル
    ,                                   \ リテラルをコンパイル
;

: ';' [ CHAR ; ] LITERAL ;
';' EMIT CR

: / /MOD SWAP DROP ;
: MOD /MOD DROP ;
: NEGATE
    0 SWAP - ;
