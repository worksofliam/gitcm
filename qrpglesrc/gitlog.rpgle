**FREE

Ctl-Opt DFTACTGRP(*No) BNDDIR('GITCM/GITCM');

// Git log for a repo

/COPY 'qrpgleref/git.rpgle'
/COPY 'qrpgleref/dataarea.rpgle'
/COPY 'qrpgleref/funkey.rpgle'
/COPY 'qrpgleref/utils.rpgle'

Dcl-Pr GITCMTINF ExtPgm;
  pLIB Char(10);
  pCommit LikeDS(tLogEntry);
End-Pr;

Dcl-Pi GITLOG;
  LIB Char(10);
End-Pi;
     
Dcl-F gitdsp WORKSTN Sfile(SFLDta:Rrn) IndDS(WkStnInd) InfDS(fileinfo);

// ---------------------------------------------------------------*
      
Dcl-S Exit Ind Inz(*Off);
Dcl-DS WkStnInd;
  SflDspCtl      Ind        Pos(85);
  SflDsp         Ind        Pos(95);
End-DS;

Dcl-S rrn          Zoned(4:0) Inz;
Dcl-S ValidRepo    Ind Inz(*Off); 
 
Dcl-DS FILEINFO;
  FUNKEY         Char(1)    Pos(369);
End-DS;

// ---------------------------------------------------------------*

Dcl-S index        Zoned(2:0) Inz;
Dcl-Ds gLogEntry LikeDS(tLogEntry) Dim(MAX_COMMITS);
Dcl-S  gUser     Char(10) Inz(*USER);
Dcl-S  Refresh   Ind Inz(*On);

Dcl-Ds Error LikeDS(Error_T);
Dcl-DS baseRepoPath LikeDs(DSResult_T);

// -----------------------------------------------------------------*

getDataArea(baseRepoPath:128:'GITREPODIR' + LIB:-1:128:Error);
If (Error.Code = *BLANK);
  Exit = *Off;
  Refresh = *On;
  Dow (Not Exit);
    If (Refresh);
      LoadSubfile(baseRepoPath.Data);
      Refresh = *Off;
    Endif;

    Write HEADER_FMT;
    Write FOOTER_FMT;
    Exfmt SFLCTL;

    Select;
      When (Funkey = F03);
        Exit = *On;
      WHEN (FunKey = F05);
        Refresh = *On;
      When (Funkey = ENTER);
        Exsr HandleInputs;
    Endsl;
  Enddo;
Else;
  Utils_Print('ERROR: Unable to find git path.');
Endif;

Return;

Begsr HandleInputs;
  Dou (%EOF(gitdsp));
    ReadC SFLDTA;
    If (%EOF(gitdsp));
      Iter;
    Endif;

    Select;
      When (@1SEL = '5');
        // Get info about that commit
        GITCMTINF(LIB:gLogEntry(rrn));
    Endsl;

    If (@1SEL <> *Blank);
      @1SEL = *Blank;
      Update SFLDTA;
      SFLRRN = rrn;
    Endif;
  Enddo;
Endsr;

// ------------------------------------------------------------

Dcl-Proc ClearSubfile;
  SflDspCtl = *Off;
  SflDsp = *Off;

  Write SFLCTL;

  SflDspCtl = *On;

  rrn = 0;
End-Proc;

Dcl-Proc LoadSubfile;
  Dcl-Pi *N;
    RepoPath Varchar(128) Const;
  End-Pi;
  Dcl-S lCommits     Int(5);

  ClearSubfile();

  ValidRepo = GitLogParse(RepoPath:'*ALL':gLogEntry);

  lCommits = %Lookup(*blank:gLogEntry(*).hash);
  If (lCommits = 0); //We do this incase the DS is filled
    lCommits = %Elem(gLogEntry); 
  Else;
    lCommits -= 1;
  Endif;

  for index = 1 to lCommits;

    @xcommit = gLogEntry(index).Hash;
    @xuser =  gLogEntry(index).Author;
    @xdate =  gLogEntry(index).Date;
    @xtext =  gLogEntry(index).Text;

    rrn += 1;
    Write SFLDTA;

  endfor;

  If (rrn > 0);
    SflDsp = *On;
    SFLRRN = 1;
  Endif;
End-Proc;
