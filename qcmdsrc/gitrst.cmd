
             CMD        Prompt('Git restore')
             
             PARM       KWD(LIB) TYPE(*CHAR) LEN(10) +
                        PROMPT('Branch library')
             PARM       KWD(COMMIT) TYPE(*CHAR) LEN(7) +
                        PROMPT('Commit') ALWUNPRT(*NO)
             PARM       KWD(PATH) TYPE(*CHAR) LEN(128) +
                        PROMPT('Relative path') ALWUNPRT(*NO)
