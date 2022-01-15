
             CMD        Prompt('Git branch')
             
             PARM       KWD(BASE) TYPE(*CHAR) LEN(10) +
                        PROMPT('Base Library')
             PARM       KWD(LIB) TYPE(*CHAR) LEN(10) +
                        PROMPT('Branch library') ALWUNPRT(*NO)
             PARM       KWD(NAME) TYPE(*CHAR) LEN(50) +
                        PROMPT('Branch name') ALWUNPRT(*NO)