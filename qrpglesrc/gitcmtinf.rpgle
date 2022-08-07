**FREE

Ctl-Opt DFTACTGRP(*No) BNDDIR('GITCM');

// Commit info shows what files changed at a commit

/COPY 'qrpgleref/git.rpgle'
/COPY 'qrpgleref/system.rpgle'
/COPY 'qrpgleref/funkey.rpgle'
/COPY 'qrpgleref/dataarea.rpgle'

Dcl-PR GITDFFCMT ExtPgm;
  LIB Char(10);
  pCommit Char(7);
  pFile   Char(128);
End-Pr;

// ---------------------------------------------------------------*

Dcl-Pi GITCMTINF;
  pLIB Char(10);
  pCommit LikeDS(tLogEntry);
End-Pi;
          
Dcl-F commit WORKSTN Sfile(SFLDta:Rrn) IndDS(WkStnInd) InfDS(fileinfo);

Dcl-S Rrn          Zoned(4:0) Inz;

Dcl-DS WkStnInd;
  SflDspCtl      Ind        Pos(85);
  SflDsp         Ind        Pos(95);
End-DS;

Dcl-DS FILEINFO;
  FUNKEY         Char(1)    Pos(369);
End-DS;

// ---------------------------------------------------------------*
      
Dcl-S index        Zoned(2:0) Inz;
          
Dcl-Ds gChangedFiles LikeDS(tChangedFiles) Dim(MAX_FILES);
Dcl-S Exit    Ind Inz(*Off);
Dcl-S Refresh Ind Inz(*Off);

Dcl-Ds Error LikeDS(Error_T);
Dcl-DS baseRepoPath LikeDs(DSResult_T);

// ------------------------------------------------------------

getDataArea(baseRepoPath:128:'GITREPODIR' + pLIB:-1:128:Error);
If (Error.Code = *BLANK);
  Exit = *Off;
  Refresh = *On;
        
  Dow (Not Exit);
    If (Refresh);
      LoadSubfile(baseRepoPath.Data);
      Refresh = *off;
    Endif;

    Write HEADER_FMT;
    Write FOOTER_FMT;
    Exfmt SFLCTL;

    Select;
      When (Funkey = F05);
        Refresh = *On;
                    
      When (Funkey = F12);
        Exit = *On;

      When (Funkey = ENTER);
        Exsr HandleInputs;
    Endsl;
  Enddo;
Endif;

Return;

Begsr HandleInputs;
  Dou (%EOF(commit));
    ReadC SFLDTA;
    If (%EOF(commit));
      Iter;
    Endif;

    Select;
      When (@1SEL = '5');
        ShowDiff(gChangedFiles(Rrn).Path);
      When (@1SEL = 'R');
        Monitor;
          QCmdExc('?GITRST LIB(' + %trim(pLIB) + ') COMMIT(''' + %trim(pCommit.Hash) + ''') PATH(''' + %trim(gChangedFiles(Rrn).Path) + ''')':256);
        On-Error;
        Endmon;
    Endsl;

    If (@1SEL <> *Blank);
      @1SEL = *Blank;
      Update SFLDTA;
      SFLRRN = Rrn;
    Endif;
  Enddo;
Endsr;

// ------------------------------------------------------------

Dcl-Proc ShowDiff;
  Dcl-Pi *N;
    FilePath Char(128) Value;
  End-Pi;

  GITDFFCMT(pLIB:pCommit.Hash:FilePath);
End-Proc;

Dcl-Proc ClearSubfile;
  SflDspCtl = *Off;
  SflDsp = *Off;

  Write SFLCTL;

  SflDspCtl = *On;

  Rrn = 0;
End-Proc;

Dcl-Proc LoadSubfile;
  Dcl-Pi *N;
    Path Varchar(128) Const;
  End-Pi;

  Dcl-S lFiles Int(5);
  Dcl-S name   Varchar(80);

  ClearSubfile();

  @XCOMMIT = pCommit.Hash;
  @XMSG    = pCommit.Text;
  @XDATE   = pCommit.Date;
  GitListCommitFiles(Path:pCommit.Hash:gChangedFiles);

  lFiles = %Lookup(*blank:gChangedFiles(*).Path);
  If (lFiles = 0); //We do this incase the DS is filled
    lFiles = %Elem(gChangedFiles); 
  Else;
    lFiles -= 1;
  Endif;

  for index = 1 to lFiles;

    @xfile = gChangedFiles(index).Path;

    Rrn += 1;
    Write SFLDTA;

  Endfor;

  If (Rrn > 0);
    SflDsp = *On;
    SFLRRN = 1;
  Endif;
End-Proc;