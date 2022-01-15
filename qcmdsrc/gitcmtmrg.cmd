             CMD        Prompt('Git commit and merge')
             
             PARM       KWD(LIBRARY) TYPE(*CHAR) LEN(10) +
                        PROMPT('Branch Library')
             PARM       KWD(TEXT) TYPE(*CHAR) LEN(100) +
                        PROMPT('Commit message') ALWUNPRT(*NO)
             PARM       KWD(AUTHOR) TYPE(*CHAR) LEN(30)  +
                        PROMPT('Author') ALWUNPRT(*NO) +
                        DFT('*JOB')
             PARM       KWD(EMAIL) TYPE(*CHAR) LEN(50)  +
                        PROMPT('Email') ALWUNPRT(*NO) DFT('*JOB')
             PARM       KWD(AUTOMERGE) TYPE(*CHAR) LEN(4)  +
                        PROMPT('Auto merge') ALWUNPRT(*NO) DFT(*YES)
