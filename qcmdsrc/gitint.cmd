
             CMD        Prompt('Git init')
             
             PARM       KWD(PATH) TYPE(*CHAR) LEN(128) +
                        PROMPT('IFS directory')
             PARM       KWD(LIB) TYPE(*CHAR) LEN(10) +
                        PROMPT('Base library') ALWUNPRT(*NO)
             PARM       KWD(INITCOMMIT) TYPE(*CHAR) LEN(10) +
                        PROMPT('Initialize repo') ALWUNPRT(*NO) +
                        DFT(*YES) SPCVAL(*YES *NO)