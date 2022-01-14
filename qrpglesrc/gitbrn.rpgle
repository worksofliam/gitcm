**FREE

Ctl-Opt DFTACTGRP(*NO);

// -----------------------------------------------------------------------------

Dcl-PR system Int(10) extproc('system');
  *N Pointer value options(*string);
End-PR;

/copy 'qrpgleref/dataarea.rpgle'

// -----------------------------------------------------------------------------

Dcl-Pi GITBRN;
  BASE Char(10); //Base library
  LIB Char(10); //Branch library 
  NAME Char(50); //Name of the branch
End-Pi;

Dcl-Ds Error LikeDS(Error_T);

Dcl-DS baseRepoPath LikeDs(DSResult_T);

Dcl-S createdSourceFiles Ind;

getDataArea(baseRepoPath:128:'GITREPODIR' + BASE:-1:128:Error);
If (Error.Code = *BLANK);
  If (system('CRTLIB LIB(' + %TrimR(LIB) + ') TYPE(*TEST) TEXT(''' + %Trim(NAME) + ''')') = 0);
    createdSourceFiles = getIFSFolders(baseRepoPath.Data);

    If (createdSourceFiles);
      system('CRTDTAARA DTAARA(' + %TrimR(LIB) + '/GITREPODIR) TYPE(*CHAR) LEN(128) TEXT(''' + %trim(baseRepoPath.Data) + ''')');
      system('CRTDTAARA DTAARA(' + %TrimR(LIB) + '/BRANCH) TYPE(*CHAR) LEN(50) TEXT(''' + %trim(NAME) + ''')');
      showMessage('Branch library ' + %TrimR(LIB) + ' created successfully.');
    Else;
      // Revert!
      system('CLRLIB ' + %TrimR(LIB));
      system('DLTLIB ' + %TrimR(LIB));
      showMessage('Error creating branch library.');
    Endif;
  Else;
    showMessage('Unable to create branch library ' + %TrimR(LIB) + '.');
  Endif;

Else;
  showMessage('Unable to locate GITREPODIR in ' + %TrimR(BASE) + '.');
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

// **************

Dcl-Proc showMessage;
  Dcl-Pi showMessage;
    Text Varchar(8192) Const;
  END-PI;

  Dcl-DS ErrCode;
    BytesIn  Int(10) Inz(0);
    BytesOut Int(10) Inz(0);
  END-DS;

  Dcl-PR QUILNGTX ExtPgm('QUILNGTX');
    MsgText     Char(8192)    Const;
    MsgLength   Int(10)       Const;
    MessageId   Char(7)       Const;
    MessageFile Char(21)      Const;
    dsErrCode   Like(ErrCode);
  END-PR;

  QUILNGTX(Text:%Len(Text):
              '':'':
              ErrCode);

  Return;
END-PROC;