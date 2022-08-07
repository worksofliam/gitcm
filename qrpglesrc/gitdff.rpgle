**FREE

Ctl-Opt DFTACTGRP(*No) BNDDIR('GITCM');

// Used to give a diff between the working source member and the repo head version

Dcl-Pi GITDFF;
  LIB Char(10);
  DIR Char(10);
  NAME Char(10);
  ATTR Char(10);
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

Dcl-S memberIfsPath Varchar(128);
Dcl-S lDirName Varchar(10);
Dcl-S lFileName Varchar(10);
Dcl-S lFileAttr Varchar(10);

lDirName = %Trim(Utils_Lower(DIR));
lFileName = %Trim(Utils_Lower(NAME));
lFileAttr = %Trim(Utils_Lower(ATTR));

getDataArea(baseRepoPath:128:'GITREPODIR' + LIB:-1:128:Error);
If (Error.Code = *BLANK);
  memberIfsPath = CopyToIfsTemp(LIB:DIR:NAME);

  If (memberIfsPath <> '');
    Exit = *Off;
    LoadSubfile(baseRepoPath.Data:'--no-index ./' + lDirName + '/' + lFileName + '.' + lFileAttr + ' ' + memberIfsPath);

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
Endif;

Return;

// ------------------------------------------------------------

Dcl-Proc CopyToIfsTemp;
  Dcl-Pi *N Varchar(128);
    Lib Char(10) Const;
    Spf Char(10) Const;
    Mbr Char(10) Const;
  End-Pi;

  Dcl-S CmdStr  Varchar(256);
  Dcl-S lTemp Varchar(128);

  lTemp = '/tmp/gitcm' + '_' + %trim(User) + '.tmp';
  CmdStr = 'CPYTOSTMF FROMMBR('''
         + '/QSYS.lib/'
         + %TrimR(LIB) + '.lib/'
         + %TrimR(Spf) + '.file/'
         + %TrimR(Mbr) + '.mbr'') '
         + 'TOSTMF(''' + lTemp + ''') '
         + 'STMFOPT(*REPLACE) STMFCCSID(1208) ENDLINFMT(*LF)';

  If (system(CmdStr) = 0);
    Return lTemp;
  Else;
    Return '';
  Endif;
End-Proc;

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

  @XCOMMIT = 'working';
  @XFILE   = lDirName + '/' + lFileName + '.' + lFileAttr;
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