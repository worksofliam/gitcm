**FREE

Ctl-Opt DFTACTGRP(*NO) BNDDIR('GITCM/GITCM');

// -----------------------------------------------------------------------------

/copy 'qrpgleref/system.rpgle'
/copy 'qrpgleref/utils.rpgle'
/copy 'qrpgleref/dataarea.rpgle'

// -----------------------------------------------------------------------------

Dcl-Pi GITBRN;
  BASE Char(10); //Base library
  LIB Char(10); //Branch library 
  NAME Char(50); //Name of the branch
End-Pi;

// TODO: option to set LIB to CURLIB when done

Dcl-Ds Error LikeDS(Error_T);

Dcl-DS baseRepoPath LikeDs(DSResult_T);

Dcl-S createdSourceFiles Ind;

getDataArea(baseRepoPath:128:'GITREPODIR' + BASE:-1:128:Error);
If (Error.Code = *BLANK);
  If (system('CRTLIB LIB(' + %TrimR(LIB) + ') TYPE(*TEST) TEXT(''' + %Trim(NAME) + ''')') = 0);
    createdSourceFiles = getIFSFolders(baseRepoPath.Data);

    If (createdSourceFiles);
      system('CRTDTAARA DTAARA(' + %TrimR(LIB) + '/GITREPODIR) TYPE(*CHAR) LEN(128) VALUE(''' + %trim(baseRepoPath.Data) + ''')');
      system('CRTDTAARA DTAARA(' + %TrimR(LIB) + '/BASE) TYPE(*CHAR) LEN(10) VALUE(''' + %trim(BASE) + ''')');
      system('CRTDTAARA DTAARA(' + %TrimR(LIB) + '/BRANCH) TYPE(*CHAR) LEN(50) VALUE(''' + %trim(NAME) + ''')');
      Utils_Print('NOTICE: Branch library ' + %TrimR(LIB) + ' created successfully.');
    Else;
      // Revert!
      system('CLRLIB ' + %TrimR(LIB));
      system('DLTLIB ' + %TrimR(LIB));
      Utils_Print('ERROR: Error creating branch source files.');
    Endif;
  Else;
    Utils_Print('ERROR: Unable to create branch library ' + %TrimR(LIB) + '.');
  Endif;

Else;
  Utils_Print('ERROR: Unable to locate GITREPODIR in ' + %TrimR(BASE) + '.');
Endif;

Return;

// -----------------------------------------------------------------------------

Dcl-Proc getIFSFolders;
  Dcl-Pi *N Ind;
    pFolderName Char(128) Const;
  End-Pi;

  /COPY 'qrpgleref/ifs.rpgle'

  Dcl-s success ind inz(*on);
  Dcl-S lFolder Varchar(128);
  Dcl-S Name    Varchar(21);

  Dcl-S p_dirent     Pointer;
  Dcl-DS dirent  based( p_dirent );
    d_reserv1      Char(16);
    d_reserv2      Uns(10);
    d_fileno       Uns(10);
    d_reclen       Uns(10);
    d_reserv3      Int(10);
    d_reserv4      Char(8);
    d_nlsinfo      Char(12);
    nls_ccsid      Int(10)    overlay( d_nlsinfo:1 );
    nls_cntry      Char(2)    overlay( d_nlsinfo:5 );
    nls_lang       Char(3)    overlay( d_nlsinfo:7 );
    nls_reserv     Char(3)    overlay( d_nlsinfo:10 );
    d_namelen      Uns(10);
    d_name         Char(640);
  End-DS;

  Dcl-S dh           Pointer;
  Dcl-S rtnVal       Uns(10);

  Dcl-DS stat_struct;
    st_other1      Char(48);
    st_objtype     Char(10);
    st_other2      Char(68);
  End-DS;

  lFolder = %Trim(pFolderName);

  //  Open up the directory.
  dh = opendir(lFolder);
  if (dh = *NULL);
    return *off;
  endif;

  p_dirent = readdir(dh);

  dow (p_dirent <> *NULL AND success);

    Name = %trim(%str(%addr(d_name)));
    rtnVal = stat(%trim(lFolder + '/' + d_name):
                            %addr(stat_struct));

    if (rtnVal = 0);
      if (st_objType = '*DIR');

        // it's a directory, but there are
        // two cases we will ignore...
        if (%Len(Name) >= 1 AND %Len(Name) <= 10);
          if (%Subst(Name:1:1) <> '.');
          
            If (system('CRTSRCPF FILE(' + %TrimR(LIB) + '/' + %TrimR(Name) + ') RCDLEN(112)') <> 0);
              success = *off; //Something went wrong. Abort.
            Endif;

          endif;
        Endif;
      Endif;

      // if (st_objType = '*STMF');
      //   gFiles += 1;

      //   StreamFiles(gFiles).Name = Name;
      // endif;
    endif;

    p_dirent = readdir(dh);
  enddo;

  closedir(dh);

  Return success;
End-Proc;