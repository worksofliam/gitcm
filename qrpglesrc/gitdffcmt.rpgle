**FREE

Ctl-Opt DFTACTGRP(*No) BNDDIR('GITCM/GITCM');

Dcl-Pi GITDFFCMT;
  LIB Char(10);
  pCommit Char(7);
  pFile   Char(128);
End-Pi;

// ************************

/COPY 'qrpgleref/git.rpgle'
/COPY 'qrpgleref/system.rpgle'
/COPY 'qrpgleref/utils.rpgle'
/COPY 'qrpgleref/funkey.rpgle'
/COPY 'qrpgleref/dataarea.rpgle'

// ************************

Dcl-F diffscrn WORKSTN Sfile(SFLDta:Rrn) IndDS(WkStnInd) InfDS(fileinfo);

Dcl-S Exit Ind Inz(*Off);

Dcl-S User Char(10) Inz(*User);
Dcl-S Rrn  Zoned(4:0) Inz;

Dcl-DS WkStnInd;
  ProcessSCF     Ind        Pos(21);
  ReprintScf     Ind        Pos(22);
  ErrorInd       Ind        Pos(25);
  PageDown       Ind        Pos(30);
  PageUp         Ind        Pos(31);
  SflEnd         Ind        Pos(40);
  SflBegin       Ind        Pos(41);
  NoRecord       Ind        Pos(60);
  SflDspCtl      Ind        Pos(85);
  SflClr         Ind        Pos(75);
  SflDsp         Ind        Pos(95);
End-DS;

Dcl-DS FILEINFO;
  FUNKEY         Char(1)    Pos(369);
End-DS;
     
// ---------------------------------------------------------------*

Dcl-S Index Int(5);
Dcl-S Lines Char(GIT_LINE_LEN) Dim(MAX_LINES);

Dcl-Ds Error LikeDS(Error_T);
Dcl-DS baseRepoPath LikeDs(DSResult_T);

getDataArea(baseRepoPath:128:'GITREPODIR' + LIB:-1:128:Error);
If (Error.Code = *BLANK);
  Exit = *Off;
  LoadSubfile(baseRepoPath.Data:%Trim(pCommit) + '~1 -- ' + %Trim(pFile));

  Dow (Not Exit);
    Write HEADER_FMT;
    Write FOOTER_FMT;
    Exfmt SFLCTL;

    Select;
      When (Funkey = F12);
        Exit = *On;
      When (Funkey = ENTER);
        Exit = *On;
    Endsl;
  Enddo;
Endif;

Return;

// ------------------------------------------------------------

Dcl-Proc ClearSubfile;
  SflDspCtl = *Off;
  SflDsp = *Off;

  Write SFLCTL;

  SflDspCtl = *On;

  Rrn = 0;
End-Proc;

Dcl-Proc LoadSubfile;
  Dcl-Pi *N;
    WorkingDirectory Varchar(128) Const;
    Command Varchar(256) Const;
  End-Pi;

  Dcl-S lCount  Int(5);
  Dcl-S Action  Char(1);
  Dcl-S LongAct Char(3);

  ClearSubfile();

  @XCOMMIT = pCommit;
  @XFILE   = pFile;
  GitDiffGetter(WorkingDirectory:Command:Lines);

  lCount = %Lookup('*EOF':Lines);

  for Index = 1 to lCount;
    Action = %Subst(Lines(Index):1:1);
    LongAct = %Subst(Lines(Index):1:3);

    If (LongAct = '+++' OR LongAct = '---');
      Iter;
    Endif;

    @xattr = x'3F';

    Select;
      When (Action = '@');
        @xattr = x'3A';

      When (Action = '+');
        @xattr = x'20';

      When (Action = '-');
        @xattr = x'28';

      When (Action = *Blank);
        @xattr = x'22';
    Endsl;

    If (@xattr <> x'3F');
      @xline = %Subst(Lines(Index):2);
      Rrn += 1;
      Write SFLDTA;
    Endif;

  endfor;

  If (Rrn > 0);
    SflDsp = *On;
    SFLRRN = 1;
  Endif;
End-Proc;