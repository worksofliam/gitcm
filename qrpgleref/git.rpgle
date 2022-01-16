**FREE

Dcl-C MAX_LINES    1000;
Dcl-C GIT_LINE_LEN 128;

Dcl-Pr GitDiffGetter IND ExtProc;
  Path VARCHAR(128) CONST;
  Parms VARCHAR(256) CONST;
  oLines CHAR(GIT_LINE_LEN) DIM(MAX_LINES);
End-Pr;

Dcl-C MAX_COMMITS 50;

Dcl-Ds tLogEntry Qualified Template;
  Hash   Char(7);
  Author Char(64);
  Date   Char(64);
  Text   Char(128);
End-Ds;

Dcl-Pr GitLogParse IND ExtProc;
  Path VARCHAR(128) CONST;
  pFile CHAR(128) CONST;
  pLogEntry LIKEDS(TLOGENTRY) DIM(MAX_COMMITS);
End-Pr;