**FREE

Ctl-Opt DFTACTGRP(*No) BNDDIR('GITCM');

Dcl-Pi GITRPO;
  BASE Char(10);
End-Pi;

/copy 'qrpgleref/objects.rpgle'
/copy 'qrpgleref/dataarea.rpgle'
/COPY 'qrpgleref/funkey.rpgle'
/copy 'qrpgleref/utils.rpgle'
/copy 'qrpgleref/system.rpgle'

Dcl-Ds Error LikeDS(Error_T);
Dcl-DS dataArea LikeDs(DSResult_T);

Dcl-S lObjectCount Int(5);
Dcl-S baseRepoPath Varchar(128);

Dcl-Pr GITLOG ExtPgm;
  LIB Char(10);
End-Pr;

// ---------------------------------------------------------------*

Dcl-F repo WorkStn Sfile(SFLDta:Rrn) IndDS(WkStnInd) InfDS(fileinfo);

Dcl-S Exit Ind Inz(*Off);
Dcl-S Refresh Ind;
Dcl-DS WkStnInd;
  SflDspCtl      Ind        Pos(85);
  SflDsp         Ind        Pos(95);
End-DS;

Dcl-S rrn          Zoned(4:0) Inz;
 
Dcl-DS FILEINFO;
  FUNKEY         Char(1)    Pos(369);
End-DS;

// ---------------------------------------------------------------*

getDataArea(dataArea:128:'GITREPODIR' + BASE:-1:128:Error);
If (Error.Code = *BLANK);
  baseRepoPath = %TrimR(dataArea.Data);
  Exit = *Off;
  Refresh = *On;

  Dow (NOT Exit);
    If (Refresh);
      LoadSubfile();
      Refresh = *Off;
    Endif;

    EvalR @BASEPATH = baseRepoPath;

    Write HEADER_FMT;
    Exfmt SFLCTL;

    Select;
      When (FUNKEY = F02);
        Monitor;
          QCmdExc('?GITBRN BASE(' + %TrimR(BASE) + ')':30);
          Refresh = *On;
        On-Error *All;
        Endmon;
      When (FUNKEY = F07);
        Monitor;
          QCmdExc('?GITBRG LIB(' + %TrimR(BASE) + ')':30);
        On-Error *All;
        Endmon;
      When (FUNKEY = F03 or FUNKEY = F12);
        Exit = *On;
      When (FUNKEY = F04);
        Monitor;
          GITLOG(BASE);
        On-Error *All;
        Endmon;
      When (FUNKEY = F05);
        Refresh = *On;
      When (FUNKEY = ENTER);
        Exsr HandleInputs;
    Endsl;
  Enddo;

Else;
  Utils_Print('ERROR: Not a git library. Launching init.');
  QCmdExc('?GITINT PATH(''/repos/' + %TrimR(Utils_Lower(BASE)) + ''') LIB(' + %TrimR(BASE) + ')':100);
Endif;

Return;

Begsr HandleInputs;
  Dou (%EOF(repo));
    ReadC SFLDTA;
    If (%EOF(repo));
      Iter;
    Endif;

    Monitor;
      Select;
        When (@1SEL = '8');
          QCmdExc('?GITCMTMRG LIBRARY(' + %TrimR(@XLIB) + ')':40);
          Refresh = *On;
        When (@1SEL = '7');
          QCmdExc('?GITBRG LIB(' + %TrimR(@XLIB) + ') DIR(SPF) NAME(MBR)':50);
        When (@1SEL = '4');
          QCmdExc('?DLTLIB ' + %TrimR(@XLIB):20);
          Refresh = *On;
        When (@1SEL = '2');
          QCmdExc('?WRKMBRPDM ' + %TrimR(@XLIB) + '/SPF':30);
      Endsl;
    On-Error *ALL;
    Endmon;

    If (@1SEL <> *Blank);
      @1SEL = *Blank;
      Update SFLDTA;
      SFLRRN = rrn;
    Endif;
  Enddo;
Endsr;

Dcl-Proc LoadSubfile;
  ClearSubfile();

  Obj_List('*ALL':'BRANCH':'*DTAARA');
  For lObjectCount = 1 to Obj_Count();
    ObjectDs = Obj_Next();
    Error.Code = *BLANK;
    getDataArea(dataArea:128:'GITREPODIR' + Library:-1:128:Error);

    If (Error.Code = *BLANK);
      If (dataArea.Data = baseRepoPath);
        getDataArea(dataArea:128:'BRANCH    ' + Library:-1:128:Error);

        If (Error.Code = *BLANK);
          Utils_Print(%Trim(Library) + ',' + %Trim(dataArea.Data));
          @xlib = Library;
          @xbranch = dataArea.Data;

          rrn += 1;
          Write SFLDTA;
        Endif;
      Endif;
    Endif;
  Endfor;

  If (rrn > 0);
    SflDsp = *On;
    SFLRRN = 1;
  Endif;
End-Proc;

Dcl-Proc ClearSubfile;
  SflDspCtl = *Off;
  SflDsp = *Off;

  Write SFLCTL;

  SflDspCtl = *On;

  rrn = 0;
End-Proc;