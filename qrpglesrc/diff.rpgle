**FREE

Ctl-Opt NoMain BNDDIR('GITCM/GITCM');

// ************************

/COPY 'qrpgleref/diff.rpgle'
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

  // Program will assume CURDIR is git repo

  // First we need to take the content of GIT LOG into a stream file
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
