**FREE

Ctl-Opt NoMain BNDDIR('GITCM/GITCM');

// ************************

/COPY 'qrpgleref/git.rpgle'
/COPY 'qrpgleref/ifs.rpgle'
/COPY 'qrpgleref/utils.rpgle'

// ************************

Dcl-S  gRecords Int(5) Inz(0);
Dcl-Ds gGitLog  LikeDS(File_Temp);

// ************************

Dcl-S gUser  Char(10) Inz(*User);

Dcl-Pr get_errno Pointer ExtProc('__errno');
End-Pr;

Dcl-S ptrToErrno Pointer;
Dcl-s errno Int(10) based(ptrToErrno);

Dcl-Proc GitDiffGetter Export;
  Dcl-Pi GitDiffGetter Ind;
    Path  Varchar(128) Const;
    Parms Varchar(256) Const;
    oLines Char(GIT_LINE_LEN) Dim(MAX_LINES);
  End-Pi;

  Dcl-S lSuccess Ind;

  gGitLog.PathFile = '/tmp/' + %TrimR(gUser) + 'git.log';

  lSuccess = Utils_Qsh('cd ' + %Trim(Path) + ' && '
      + '/QOpenSys/pkgs/bin/git --no-pager diff --no-color ' + %Trim(Parms) + ' '
      + x'4F' + ' iconv -f UTF-8 -t ISO8859-1 > ' + %TrimR(gGitLog.PathFile));

  If (lSuccess); 
    // Next we will want to read that stream file
    gGitLog.PathFile = %TrimR(gGitLog.PathFile) + x'00';
    gGitLog.OpenMode = 'r' + x'00';
    gGitLog.FilePtr  = OpenFile(%addr(gGitLog.PathFile)
                             :%addr(gGitLog.OpenMode));

    If (gGitLog.FilePtr = *Null);
      // Failed to open file
      ptrToErrno = get_errno(); 
      Return *Off;
    ENDIF;

    gRecords = 0;

    Dow (ReadFile(%addr(gGitLog.RtvData)
               :%Len(gGitLog.RtvData)
               :gGitLog.FilePtr) <> *null);

      If (%Subst(gGitLog.RtvData:1:1) = x'25');
        Iter;
      ENDIF;

      If (gRecords > MAX_LINES);
        Leave;
      Endif;

      gRecords += 1;

      gGitLog.RtvData = %xlate(x'00':' ':gGitLog.RtvData);//End of record null
      gGitLog.RtvData = %xlate(x'25':' ':gGitLog.RtvData);//Line feed (LF)
      gGitLog.RtvData = %xlate(x'0D':' ':gGitLog.RtvData);//Carriage return (CR)
      gGitLog.RtvData = %xlate(x'05':' ':gGitLog.RtvData);//Tab

      oLines(gRecords) = %TrimR(gGitLog.RtvData);

      gGitLog.RtvData = '';
    Enddo;

    CloseFile(gGitLog.FilePtr);

    If (gRecords = 0);
      ptrToErrno = get_errno(); 
      Return *Off;
    Elseif (gRecords < MAX_LINES);
      gRecords += 1;
      oLines(gRecords) = '*EOF';
    ENDIF;

    Return *On;
  Else;
    Return *Off;
  Endif;
End-Proc;

// ************************

Dcl-Proc GitLogParse Export;
  Dcl-Pi GitLogParse Ind;
    Path Varchar(128) Const;
    pFile Char(128) Const;
    pLogEntry LikeDS(tLogEntry) Dim(MAX_COMMITS);
  End-Pi;

  Dcl-S gText   Varchar(128);
  Dcl-S  gRecords Int(5) Inz(0);
  Dcl-Ds gGitLog  LikeDS(File_Temp);
  Dcl-S  gKey     Char(6);

  Dcl-S gIsText Ind;

  // ************************

  Dcl-S gUser  Char(10) Inz(*User);
  Dcl-S gFocus Varchar(128);

  Clear pLogEntry;

  gFocus = %Trim(pFile);
  If (gFocus = '*ALL');
    gFocus = '';
  Elseif (gFocus <> '');
    gFocus = ' -- ' + gFocus;
  Endif;

  gGitLog.PathFile = '/tmp/' + %TrimR(gUser) + 'git.log';

  // Program will assume CURDIR is git repo

  If (Utils_Qsh('cd ' + %Trim(Path) + ' && '
      + '/QOpenSys/pkgs/bin/git --no-pager log -r ' + gFocus + ' '
      + x'4F' + ' iconv -f UTF-8 -t ISO8859-1 > ' + %TrimR(gGitLog.PathFile))
      = *Off);
    // Failed to run git log
    Return *Off;
  Endif;

  // Next we will want to read that stream file
  gGitLog.PathFile = %TrimR(gGitLog.PathFile) + x'00';
  gGitLog.OpenMode = 'r' + x'00';
  gGitLog.FilePtr  = OpenFile(%addr(gGitLog.PathFile)
                             :%addr(gGitLog.OpenMode));

  If (gGitLog.FilePtr = *Null);
    // Failed to open file
    ptrToErrno = get_errno(); 
    Return *Off;
  ENDIF;

  gIsText = *Off;
  gRecords = 0;

  Dow (ReadFile(%addr(gGitLog.RtvData)
               :%Len(gGitLog.RtvData)
               :gGitLog.FilePtr) <> *null);

    If (%Subst(gGitLog.RtvData:1:1) = x'25');
      gIsText = *On;
      Iter;
    ENDIF;

    gGitLog.RtvData = %xlate(x'00':' ':gGitLog.RtvData);//End of record null
    gGitLog.RtvData = %xlate(x'25':' ':gGitLog.RtvData);//Line feed (LF)
    gGitLog.RtvData = %xlate(x'0D':' ':gGitLog.RtvData);//Carriage return (CR)
    gGitLog.RtvData = %xlate(x'05':' ':gGitLog.RtvData);//Tab

    gKey = %Subst(gGitLog.RtvData:1:6);

    Select;
      When (gKey = 'commit');
        if (gIsText = *On);
          // Last commit finished, write to file?
          pLogEntry(gRecords).Text = gText;
        ENDIF;

        gText = '';
        gIsText = *Off;
        gRecords += 1;

        If (gRecords > MAX_COMMITS);
          Leave;
        Endif;

        pLogEntry(gRecords).Hash = %Subst(gGitLog.RtvData:8:7);

      When (gKey = 'Author');
        pLogEntry(gRecords).Author = %Subst(gGitLog.RtvData:9);

      When (gKey = 'Date:');
        pLogEntry(gRecords).Date = %Subst(gGitLog.RtvData:9);

      When (gGitLog.RtvData = *Blank);
        gIsText = *On;

      Other;
        If (gIsText);
          gText += %Trim(gGitLog.RtvData) + ' ';
        ENDIF;

    ENDSL;

    gGitLog.RtvData = '';
  Enddo;


  if (gIsText = *On);
    // Last commit finished, write to file?
    pLogEntry(gRecords).Text = gText;
  ENDIF;

  CloseFile(gGitLog.FilePtr);

  Return gRecords > 0;
End-Proc;

// ************************

Dcl-Proc GitListCommitFiles Export;
  Dcl-Pi GitListCommitFiles Ind;
    Path Varchar(128) Const;
    pCommit Char(128) Const;
    pFiles LikeDS(tChangedFiles) Dim(MAX_FILES);
  End-Pi;

  Dcl-S gIsText Ind;
  Dcl-S gFocus Varchar(128);
  Dcl-S lSuccess Ind;

  Clear pFiles;

  gFocus = %Trim(pCommit);
  gGitLog.PathFile = '/tmp/' + %TrimR(gUser) + 'git.log';

  // First we need to take the content of GIT LOG into a stream file
  lSuccess = Utils_Qsh('cd ' + %Trim(Path) + ' && '
      + '/QOpenSys/pkgs/bin/git diff-tree --no-commit-id --name-only -r ' + gFocus
      + x'4F' + ' iconv -f UTF-8 -t ISO8859-1 > ' + %TrimR(gGitLog.PathFile));

  If (lSuccess);
    // Next we will want to read that stream file
    gGitLog.PathFile = %TrimR(gGitLog.PathFile) + x'00';
    gGitLog.OpenMode = 'r' + x'00';
    gGitLog.FilePtr  = OpenFile(%addr(gGitLog.PathFile)
                             :%addr(gGitLog.OpenMode));

    // sleep(1);

    If (gGitLog.FilePtr = *Null);
      // Failed to open file
      ptrToErrno = get_errno();
      Return *Off;
    ENDIF;

    gIsText = *Off;
    gRecords = 0;

    Dow (ReadFile(%addr(gGitLog.RtvData)
               :%Len(gGitLog.RtvData)
               :gGitLog.FilePtr) <> *null);

      If (%Subst(gGitLog.RtvData:1:1) = x'25');
        gIsText = *On;
        Iter;
      ENDIF;

      If (gRecords > MAX_FILES);
        Leave;
      Endif;

      gRecords += 1;

      gGitLog.RtvData = %xlate(x'00':' ':gGitLog.RtvData);//End of record null
      gGitLog.RtvData = %xlate(x'25':' ':gGitLog.RtvData);//Line feed (LF)
      gGitLog.RtvData = %xlate(x'0D':' ':gGitLog.RtvData);//Carriage return (CR)
      gGitLog.RtvData = %xlate(x'05':' ':gGitLog.RtvData);//Tab

      pFiles(gRecords).Path = %TrimR(gGitLog.RtvData);

      gGitLog.RtvData = '';
    Enddo;

    CloseFile(gGitLog.FilePtr);

    If (gRecords = 0);
      ptrToErrno = get_errno();
      lSuccess = *Off;
    Else;
      lSuccess = *On;
    ENDIF;

  Endif;

  Return lSuccess;
End-Proc;