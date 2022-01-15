**FREE

Ctl-Opt DFTACTGRP(*NO) BNDDIR('GITCM');

Dcl-Pi GITCMTMRG;
  LIB Char(10);
  TEXT Char(100);
  AUTHOR Char(30);
  EMAIL Char(50);
  AUTOMERGE Char(4); //*YES or *NO
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

// TODO: get author from job if value is *JOB, or user if value is *USER
// TODO: get email from job if value is *JOB

Dcl-S  HasErrored Ind;
Dcl-Ds Error LikeDS(Error_T);
Dcl-DS baseRepoPath LikeDs(DSResult_T);
Dcl-DS branchName LikeDs(DSResult_T);
Dcl-S CmdStr  Varchar(256);

Dcl-S lAuthor Varchar(30);
Dcl-S lEmail Varchar(50);

Dcl-S lMemberCount Int(5);
Dcl-S lObjectCount Int(5);

Dcl-S lRepoPath Varchar(128);
Dcl-S lDirName Varchar(10);
Dcl-S lFileName Varchar(21);

Select;
  When (AUTHOR = '*JOB');
    lAuthor = %Str(getenv('GIT_AUTHOR'));
  When (lAuthor = '*USER');
    lAuthor = %TrimR(USERNAME);
  Other;
    lAuthor = %Trim(AUTHOR);
Endsl;

Select;
  When (lEmail = '*JOB');
    // TODO: getenv
    lAuthor = %Str(getenv('GIT_EMAIL'));
  Other;
    lEmail = %Trim(EMAIL);
Endsl;


// TODO: lock the repo while this happens

system('ADDENVVAR ENVVAR(QIBM_QSH_CMD_OUTPUT) VALUE(NONE) LEVEL(*JOB)');

HasErrored = *Off;

getDataArea(baseRepoPath:128:'GITREPODIR' + LIB:-1:128:Error);

If (Error.Code = *BLANK);
  lRepoPath = %Trim(baseRepoPath.Data);

  getDataArea(branchName:128:'BRANCH    ' + LIB:-1:128:Error);
  If (Error.Code = *BLANK);
    If (system('CD DIR(''' + lRepoPath + ''')') = 0);
      // TODO: lock repo?

      // checkout
      Utils_Qsh('cd ' + lRepoPath + ' && /QOpenSys/pkgs/bin/git checkout -b ' + %Trim(branchName.Data));

      // copy members
      Obj_List(LIB:'*ALL':'*FILE');
      For lObjectCount = 1 to Obj_Count();
        ObjectDs = Obj_Next();
        ObjDscDs = Obj_Info(LIB:Object:ObjectType);

        If (OBJATR = 'PF');
          lDirName = %Trim(Utils_Lower(Object));

          // Attempt to create the directory incase it is new
          system('MKDIR DIR(''./' + lDirName + ''')');

          For lMemberCount = 1 to Mbrs_List(LIB:Object);
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
              HasErrored = *On;
              lMemberCount = *HIVAL;
              lObjectCount = *HIVAL;

              printf('ERROR: Failed to copy ' + lDirName + '/' + lFileName + x'25');
            Endif;
          Endfor;
        Endif;
      Endfor;

      If (HasErrored = *Off);
        Monitor;
          // Stage all changes
          HasErrored = Utils_Qsh('cd ' + lRepoPath + ' && /QOpenSys/pkgs/bin/git add --all');

          If (HasErrored = *Off);
            // Do a commit
            Utils_Qsh('cd ' + lRepoPath + ' && /QOpenSys/pkgs/bin/git commit -m "' + %Trim(TEXT) + '" --author "' + lAuthor + ' <' + lEmail + '>" ');
          Else;
            printf('ERROR: Failed to stage changes.');
          Endif;

          If (HasErrored = *Off);
            // Check out to the base branch
            Utils_Qsh('cd ' + lRepoPath + ' && /QOpenSys/pkgs/bin/git checkout ' + BASE_BRANCH);
          Else;
            printf('ERROR: Failed to checkout to branch ' + BASE_BRANCH + '. Does it already exist?');
          Endif;

          If (HasErrored = *Off);
            If (AUTOMERGE = '*YES');
              // Merge the branch into the base branch
              HasErrored = Utils_Qsh('cd ' + lRepoPath + ' && /QOpenSys/pkgs/bin/git merge ' + %Trim(branchName.Data));

              If (HasErrored = *Off);
                printf('NOTICE: Merged ' + %Trim(branchName.Data) + ' into ' + BASE_BRANCH + x'25');
              Else;
                printf('ERROR: Failed to merge ' + %Trim(branchName.Data) + ' into ' + BASE_BRANCH + x'25');
              Endif;
            Else;
              printf('NOTICE: Created branch ' + %Trim(branchName.Data) + x'25');
            Endif;
          Endif;
        On-Error;
          Utils_Qsh('cd ' + lRepoPath + ' && /QOpenSys/pkgs/bin/git clean -f');
          printf('ERROR: Failed to commit changes to the repository. Aborting');
        Endmon;

      Else;
        // Undo all changes if there was an error and go back to base branch
        Utils_Qsh('cd ' + lRepoPath + ' && /QOpenSys/pkgs/bin/git checkout -- .');
        
        // Check out to the base branch
        Utils_Qsh('cd ' + lRepoPath + ' && /QOpenSys/pkgs/bin/git checkout ' + BASE_BRANCH);
        printf('ERROR: Failed to migrate sources. Aborted.' + x'25');
      Endif;

      // Always Check out to the base branch
      Utils_Qsh('cd ' + lRepoPath + ' && /QOpenSys/pkgs/bin/git checkout ' + BASE_BRANCH);

      // TODO: unlock repo
      // TODO: clear branch lib
      If (HasErrored = *Off);
        system('CHGLIB LIB(' + %Trim(LIB) + ') TEXT(''' + %Trim(branchName.Data) + ' (merged)'')');
        
      Endif;
    Else;
      printf('ERROR: Unable to find git directory.' + x'25');
    Endif;
  Else;
    printf('ERROR: Failed to get branch name. Missing BRANCH data area.' + x'25');
  Endif;
Else;
  printf('ERROR: Failed to get base repo path. Missing GITREPODIR data area.' + x'25');
  // TODO: error handling
Endif;

system('RMVENVVAR ENVVAR(QIBM_QSH_CMD_OUTPUT)');

Return;