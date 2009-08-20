: ONE
    49 ;
ONE EMIT
10  EMIT

: TRIPLE_HELLO
    DOUBLE_HELLO HELLO ;
TRIPLE_HELLO

: / /MOD SWAP DROP ;
: MOD /MOD DROP ;

: BL 32 ;
: '\N'
    10 ;
: CR
    '\N' EMIT ;
: SPACE
    BL EMIT ;
: NEGATE
    0 SWAP - ;

: TRUE  1 ;
: FALSE 0 ;
: NOT   0= ;

: LITERAL IMMEDIATE
    ' LIT ,
    ,
;

