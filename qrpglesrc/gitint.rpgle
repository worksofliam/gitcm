**FREE

Ctl-Opt DFTACTGRP(*NO) BNDDIR('GITCM');

// Used to create a repo, push the source code to it and make a commit

Dcl-Pi GITINT;
  REPOPATH Char(128);
  LIB Char(10);
  INITCOMMIT Char(4); //*YES or *NO
End-Pi;

// ----------------------------------------------------------------------------

/copy 'qrpgleref/utils.rpgle'
/copy 'qrpgleref/system.rpgle'
/copy 'qrpgleref/objects.rpgle'
/copy 'qrpgleref/object.rpgle'
/copy 'qrpgleref/members.rpgle'

// ----------------------------------------------------------------------------

Dcl-S lSuccess Ind;

Dcl-S CmdStr  Varchar(256);

Dcl-S lMemberCount Int(5);
Dcl-S lMemberIndex Int(5);
Dcl-S lObjectIndex Int(5);

Dcl-S lRepoPath Varchar(128);
Dcl-S lDirName Varchar(10);
Dcl-S lFileName Varchar(21);

lRepoPath = %Trim(REPOPATH);

If (system('CD DIR(''' + lRepoPath + ''')') = 0);
  lSuccess = Utils_Qsh('cd ' + REPOPATH + ' && /QOpenSys/pkgs/bin/git init');

  If (lSuccess);
    If (INITCOMMIT = '*YES');
      // copy members
      Obj_List(LIB:'*ALL':'*FILE');
      For lObjectIndex = 1 to Obj_Count();
        ObjectDs = Obj_Next();
        ObjDscDs = Obj_Info(LIB:Object:ObjectType);

        If (OBJATR = 'PF');
          lDirName = %Trim(Utils_Lower(Object));

          // Attempt to create the directory incase it is new
          system('MKDIR DIR(''./' + lDirName + ''')');

          lMemberCount = Mbrs_List(LIB:Object);
          For lMemberIndex = 1 to lMemberCount;
            ListDS = Mbrs_Next();
            lFileName = %Trim(Utils_Lower(LmMember)) + '.' + %Trim(Utils_Lower(LmType));

            // Utils_Print('Copying ' + lDirName + '/' + lFileName + ' from ' + %Trim(LIB) + '/' + %Trim(Object) + '/' + %Trim(LmMember));

            CmdStr = 'CPYTOSTMF FROMMBR('''
                   + '/QSYS.lib/'
                   + %TrimR(LIB) + '.lib/'
                   + %TrimR(Object) + '.file/'
                   + %TrimR(LmMember) + '.mbr'') '
                 + 'TOSTMF(''./' + lDirName + '/' + lFileName + ''') '
                 + 'STMFOPT(*REPLACE) STMFCCSID(1208) ENDLINFMT(*LF)';

            If (system(CmdStr) <> 0);
              // End the for loops
              lSuccess = *Off;
              lMemberIndex = *HIVAL;
              lObjectIndex = *HIVAL;

              Utils_Print('GITE006: Failed to copy ' + lDirName + '/' + lFileName);
            Endif;
          Endfor;
        Endif;
      Endfor;

      If (lSuccess);
        lSuccess = Utils_Qsh('cd ' + lRepoPath + ' && /QOpenSys/pkgs/bin/git add --all');

        If (lSuccess);
          lSuccess = Utils_Qsh('cd ' + lRepoPath + ' && /QOpenSys/pkgs/bin/git commit -m "Init commit" --author "gitcm <gitcm@github.com>" ');

          If (lSuccess);
            Utils_Print('NOTICE: Initial commit made.');
          Else;
            Utils_Print('GITE013: Failed to commit to ' + lRepoPath);
          Endif;
        Else;
          Utils_Print('GITE007: Failed to stage changes.');
        Endif;
      Endif;
    Endif;

    If (lSuccess);
      system('CRTDTAARA DTAARA(' + %TrimR(LIB) + '/GITREPODIR) TYPE(*CHAR) LEN(128) VALUE(''' + lRepoPath + ''')');
      system('CRTDTAARA DTAARA(' + %TrimR(LIB) + '/BASEBRANCH) TYPE(*CHAR) LEN(50) VALUE(''master'') TEXT(''Reserved. Not yet used.'')');
    Endif;
  Else;
    Utils_Print('ERROR: Could not initialize repository.');
  Endif;

Else;
  Utils_Print('ERROR: Could CD to directory.');
Endif;

Return;