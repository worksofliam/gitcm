**FREE

Ctl-Opt DFTACTGRP(*NO) BNDDIR('GITCM');

// Used to copy an file at a specific commit in a repo back to a source member

Dcl-Pi GITRST;
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

Dcl-S gUser  Char(10) Inz(*User);
Dcl-S tempFile Varchar(128);

Dcl-Ds Error LikeDS(Error_T);
Dcl-DS baseRepoPath LikeDs(DSResult_T);
Dcl-DS branchName LikeDs(DSResult_T);

Dcl-s lindex int(5);
Dcl-S filePath Varchar(128);
Dcl-S sourcefile Char(10);
Dcl-S filename Char(10);
Dcl-S extension char(10);

tempFile = '/tmp/' + %TrimR(gUser) + 'git.log';
Error.Code = *BLANK;

getDataArea(baseRepoPath:128:'GITREPODIR' + LIB:-1:128:Error);
If (Error.Code = *BLANK);
  getDataArea(branchName:128:'BRANCH    ' + LIB:-1:128:Error);
  If (Error.Code = *BLANK);
    filePath = %Trim(pFile);
    lindex = %scan('/':filePath);

    If (lindex > 0);
      sourcefile = %subst(filePath :1 :lindex - 1);
      filePath = %subst(filePath:lindex + 1);

      lindex = %scan('.':filePath);

      If (lindex > 0);
        filename = %subst(filePath :1 :lindex - 1);
        extension = %subst(filePath:lindex + 1);
      
        // Reset the file path so we can use it again
        filePath = %Trim(pFile);
        If (Utils_Qsh('cd ' + %Trim(baseRepoPath.Data) + ' && /QOpenSys/pkgs/bin/git --no-pager show ' + pCommit + ':' + filePath + ' > ' + tempFile));
          If (system('CPYFRMSTMF FROMSTMF(''' + tempFile + ''') TOMBR(''/QSYS.LIB/' + %Trim(LIB) + '.LIB/' + %Trim(sourcefile) + '.FILE/' + %Trim(filename) + '.MBR'') MBROPT(*REPLACE)') = 0);
            system('CHGPFM FILE(' + %Trim(LIB) + '/' + %Trim(sourcefile) + ') MBR(' + %Trim(filename) + ') SRCTYPE(' + %Trim(extension) + ') TEXT(''Restored from commit ' + pCommit + ''')');
            Utils_Print('NOTICE: Restored ' + filePath + ' from commit ' + pCommit);
          Else;
            Utils_Print('ERROR: Unable to copy streamfile (' + tempFile + ') to member.');
          Endif;
        Else;
          Utils_Print('ERROR: Unable to get file from commit');
        Endif;
      Else;
        Utils_Print('ERROR: No extension found in file path.');
      EndIf;

    else;
      Utils_Print('ERROR: Path format incorrect. Cannot find directory.');
    Endif;

  Else;
    Utils_Print('ERROR: Library provided (' + %Trim(LIB) + ') is not a branch library. You can only restore to a branch library.');
  Endif;


Else;
  Utils_Print('Error: Unable to find GITREPODIR in ' + %Trim(LIB));
Endif;

Return;