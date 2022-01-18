**FREE

Ctl-Opt DFTACTGRP(*NO) BNDDIR('GITCM');

// Used to make a commit and merge from a branch library

Dcl-Pi GITCMTMRG;
  LIB Char(10);
  TEXT Char(100);
  AUTHOR Char(30);
  EMAIL Char(50);
  AUTOMERGE Char(4); //*YES or *NO
  SUBMITBRING Char(4); //*YES or *NO
End-Pi;

// ----------------------------------------------------------------------------

/copy 'qrpgleref/utils.rpgle'
/copy 'qrpgleref/dataarea.rpgle'
/copy 'qrpgleref/system.rpgle'
/copy 'qrpgleref/objects.rpgle'
/copy 'qrpgleref/object.rpgle'
/copy 'qrpgleref/members.rpgle'

// ----------------------------------------------------------------------------

Dcl-C BASE_BRANCH 'master';

Dcl-s USERNAME Char(10) Inz(*USER);

Dcl-S  Success Ind;
Dcl-Ds Error LikeDS(Error_T);
Dcl-DS baseRepoPath LikeDs(DSResult_T);
Dcl-DS baseLibrary LikeDs(DSResult_T);
Dcl-DS branchName LikeDs(DSResult_T);
Dcl-S CmdStr  Varchar(256);

Dcl-S lPointer Pointer;
Dcl-S lAuthor Varchar(30);
Dcl-S lEmail Varchar(50);

Dcl-S lMemberTotal Int(5);
Dcl-S lMemberCount Int(5);
Dcl-S lObjectCount Int(5);

Dcl-S lRepoPath Varchar(128);
Dcl-S lDirName Varchar(10);
Dcl-S lFileName Varchar(21);

Select;
  When (AUTHOR = '*JOB');
    lPointer = getenv('GIT_AUTHOR');
    If (lPointer <> *NULL);
      lAuthor = %Str(lPointer);
    Else;
      Utils_Print('GITE005: Cannot use AUTHOR(*JOB). GIT_AUTHOR not set.');
      Return;
    Endif;
  When (lAuthor = '*USER');
    lAuthor = %TrimR(USERNAME);
  Other;
    lAuthor = %Trim(AUTHOR);
Endsl;

Select;
  When (EMAIL = '*JOB');
    lPointer = getenv('GIT_EMAIL');
    If (lPointer <> *NULL);
      lEmail = %Str(lPointer);
    Else;
      Utils_Print('GITE005: Cannot use EMAIL(*JOB). GIT_EMAIL not set.');
      Return;
    Endif;
    
  Other;
    lEmail = %Trim(EMAIL);
Endsl;


// TODO: lock the repo while this happens

system('ADDENVVAR ENVVAR(QIBM_QSH_CMD_OUTPUT) VALUE(NONE) LEVEL(*JOB)');

Success = *On;

getDataArea(baseRepoPath:128:'GITREPODIR' + LIB:-1:128:Error);

If (Error.Code = *BLANK);
  lRepoPath = %Trim(baseRepoPath.Data);

  getDataArea(branchName:128:'BRANCH    ' + LIB:-1:128:Error);
  If (Error.Code = *BLANK);
    If (system('CD DIR(''' + lRepoPath + ''')') = 0);
      // TODO: lock repo?

      // 1. Checkout to new branch
      Success = Utils_Qsh('cd ' + lRepoPath + ' && /QOpenSys/pkgs/bin/git checkout -b ' + %Trim(branchName.Data));


      // 2. Copy over checked out source members
      if (Success);
        // copy members
        Obj_List(LIB:'*ALL':'*FILE');
        For lObjectCount = 1 to Obj_Count();
          ObjectDs = Obj_Next();
          ObjDscDs = Obj_Info(LIB:Object:ObjectType);

          If (OBJATR = 'PF');
            lDirName = %Trim(Utils_Lower(Object));

            // Attempt to create the directory incase it is new
            system('MKDIR DIR(''./' + lDirName + ''')');

            lMemberTotal = Mbrs_List(LIB:Object);
            For lMemberCount = 1 to lMemberTotal;
              ListDS = Mbrs_Next();
              lFileName = %Trim(Utils_Lower(LmMember)) + '.' + %Trim(Utils_Lower(LmType));

              system('RMVLNK OBJLNK(''./' + lDirName + '/' + lFileName + ''')');
              CmdStr = 'CPYTOSTMF FROMMBR('''
                   + '/QSYS.lib/'
                   + %TrimR(LIB) + '.lib/'
                   + %TrimR(Object) + '.file/'
                   + %TrimR(LmMember) + '.mbr'') '
                 + 'TOSTMF(''./' + lDirName + '/' + lFileName + ''') '
                 + 'STMFOPT(*REPLACE) STMFCCSID(1208) ENDLINFMT(*LF)';

              If (system(CmdStr) <> 0);
                // End the for loops
                Success = *Off;
                lMemberCount = *HIVAL;
                lObjectCount = *HIVAL;

                Utils_Print('GITE006: Failed to copy ' + lDirName + '/' + lFileName + x'25');
              Endif;
            Endfor;
          Endif;
        Endfor;

        If (Success = *On);
          Monitor;
            // 3. Stage all changes
            Success = Utils_Qsh('cd ' + lRepoPath + ' && /QOpenSys/pkgs/bin/git add --all');

            If (Success);
              // 4. Do a commit
              Success = Utils_Qsh('cd ' + lRepoPath + ' && /QOpenSys/pkgs/bin/git commit -m "' + %Trim(TEXT) + '" --author "' + lAuthor + ' <' + lEmail + '>" ');
  
              If (Success = *Off);
                Utils_Print('GITE007: Failed to stage changes.');
              Endif;
            Endif;

            If (Success);
              // 5. Check out to the base branch
              Success = Utils_Qsh('cd ' + lRepoPath + ' && /QOpenSys/pkgs/bin/git checkout ' + BASE_BRANCH);
              
              If (Success = *Off);
                Utils_Print('GITE008: Failed to checkout to branch ' + BASE_BRANCH + '.');
              Endif;
            Endif;

            If (Success);
              If (AUTOMERGE = '*YES');
                // 6. Merge the branch into the base branch
                Success = Utils_Qsh('cd ' + lRepoPath + ' && /QOpenSys/pkgs/bin/git merge ' + %Trim(branchName.Data));

                If (Success);
                  Utils_Print('NOTICE: Merged ' + %Trim(branchName.Data) + ' into ' + BASE_BRANCH + x'25');
                Else;
                  Utils_Print('GITE009: Failed to merge ' + %Trim(branchName.Data) + ' into ' + BASE_BRANCH + x'25');
                Endif;
              Else;
                Utils_Print('NOTICE: Created branch ' + %Trim(branchName.Data) + x'25');
              Endif;
            Endif;

          On-Error;
            Utils_Print('GITE010: Failed to commit changes to the repository. Aborting');
          Endmon;

        Else;
          // If it failed to copy the source members:
          Utils_Print('GITE010: Failed to migrate sources. Aborted.' + x'25');
        Endif;

        If (Success = *Off);
          // Undo all changes if there was an error and go back to base branch
          Utils_Qsh('cd ' + lRepoPath + ' && /QOpenSys/pkgs/bin/git clean -f');
          Utils_Qsh('cd ' + lRepoPath + ' && /QOpenSys/pkgs/bin/git checkout -- .');
        Endif;

        // Always Check out to the base branch
        Utils_Qsh('cd ' + lRepoPath + ' && /QOpenSys/pkgs/bin/git checkout ' + BASE_BRANCH);

        // TODO: unlock repo
        If (Success);
          // Clear branch lib and delete the data area.
          
          system('CHGLIB LIB(' + %Trim(LIB) + ') TEXT(''' + %Trim(branchName.Data) + ' (merged)'')');
          system('DLTOBJ OBJ(' + %Trim(LIB) + '/BRANCH) OBJTYPE(*DTAARA)');

          If (SUBMITBRING = '*YES');
            ExSr RunSubmitBring;
          Endif;
        Else;
          // If it failed, delete the branch
          Utils_Qsh('cd ' + lRepoPath + ' && /QOpenSys/pkgs/bin/git branch -D ' + %Trim(branchName.Data));
        Endif;

      Else;
        Utils_Print('GITE011: Failed to checkout branch ' + %Trim(branchName.Data) + x'25');
      Endif;
    Else;
      Utils_Print('GITE012: Unable to find git directory.' + x'25');
    Endif;
  Else;
    Utils_Print('GITE013: Failed to get branch name. Missing BRANCH data area.' + x'25');
  Endif;
Else;
  Utils_Print('GITE002: Failed to get base repo path. Missing GITREPODIR data area.' + x'25');
  // TODO: error handling
Endif;

system('RMVENVVAR ENVVAR(QIBM_QSH_CMD_OUTPUT)');

Return;

Begsr RunSubmitBring;
  getDataArea(baseLibrary:128:'BASE      ' + LIB:-1:128:Error);
  If (Error.Code = *Blank);
    system('SBMJOB CMD(GITCM/GITBRG LIB(' + %Trim(baseLibrary.Data) + ')) JOB(GITBRING)');
  Endif;
Endsr;

Begsr BringFilesBack;
  Obj_List(LIB:'*ALL':'*FILE');
  For lObjectCount = 1 to Obj_Count();
    ObjectDs = Obj_Next();
    ObjDscDs = Obj_Info(LIB:Object:ObjectType);

    If (OBJATR = 'PF');
      lDirName = %Trim(Utils_Lower(Object));

      lMemberTotal = Mbrs_List(LIB:Object);
      For lMemberCount = 1 to lMemberTotal;
        ListDS = Mbrs_Next();
        lFileName = %Trim(Utils_Lower(LmMember)) + '.' + %Trim(Utils_Lower(LmType));

        system('CPYFRMSTMF FROMSTMF(''./' + %Trim(lDirName) + '/' + %Trim(lFileName) + ''') TOMBR(''/QSYS.LIB/' + %Trim(LIB) + '.LIB/' + %Trim(Object) + '.FILE/' + %Trim(LmMember) + '.MBR'') MBROPT(*REPLACE)');
      Endfor;
    Endif;
  Endfor;
Endsr;