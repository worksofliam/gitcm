             /* GITCM/GITDFF LIB(&L) DIR(&F) NAME(&N) ATTR(&S) */
             CMD        Prompt('Git diff')
             
             PARM       KWD(LIB) TYPE(*CHAR) LEN(10) +
                        PROMPT('Branch library')
             PARM       KWD(DIR) TYPE(*CHAR) LEN(10) +
                        PROMPT('Source file') ALWUNPRT(*NO)
             PARM       KWD(NAME) TYPE(*CHAR) LEN(10) +
                        PROMPT('Source name') ALWUNPRT(*NO)
             PARM       KWD(ATTR) TYPE(*CHAR) LEN(10) +
                        PROMPT('Source attribute/ext') ALWUNPRT(*NO)