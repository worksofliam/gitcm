

             CMD        Prompt('Git branch')
             
             PARM       KWD(LIB) TYPE(*CHAR) LEN(10) +
                        PROMPT('Branch Library')
             PARM       KWD(DIR) TYPE(*CHAR) LEN(10) +
                        PROMPT('Directory name') ALWUNPRT(*NO) +
                        DFT(*ALL)
             PARM       KWD(NAME) TYPE(*CHAR) LEN(10) +
                        PROMPT('Source name') ALWUNPRT(*NO) +
                        DFT(*ALL)