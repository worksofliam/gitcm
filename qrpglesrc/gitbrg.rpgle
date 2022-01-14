**FREE

Ctl-Opt DFTACTGRP(*NO);

// -----------------------------------------------------------------------------

Dcl-PR system Int(10) extproc('system');
  *N Pointer value options(*string);
End-PR;

/copy 'qrpgleref/dataarea.rpgle'

// -----------------------------------------------------------------------------

Dcl-Pi GITBRG;
  LIB Char(10);
  DIR Char(10); // Accepts *ALL or a name
  NAME Char(10); // Accepts *ALL or a name
End-Pi;

Dcl-Ds Error LikeDS(Error_T);

Dcl-DS baseRepoPath LikeDs(DSResult_T);

getDataArea(baseRepoPath:128:'GITREPODIR' + LIB:-1:128:Error);
If (Error.Code = *BLANK);
  If (getSources(baseRepoPath.Data:DIR:NAME));
    // All good
  Else;
    Dsply 'Error';
    // Error!
  Endif;
Else;
  Dsply 'No data area';
  //showMessage('Unable to locate GITREPODIR in ' + %TrimR(BASE) + '.');
Endif;

Return;


// -----------------------------------------------------------------------------

Dcl-Proc getSources;
  Dcl-Pi *N Ind;
    pBaseDir Char(128) Const;
    pDir Char(10) Const;
    pName Char(10) Const;
  End-Pi;

  /COPY 'qrpgleref/ifs.rpgle'

  Dcl-s success ind inz(*on);
  Dcl-S lFolder Varchar(128);
  Dcl-S lDir    Varchar(10);
  Dcl-S lName   Varchar(10);
  Dcl-S Name    Varchar(21);

  Dcl-s index int(5);
  Dcl-s baseName Char(10);
  Dcl-S baseExt Char(10);

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

  lFolder = %Trim(pBaseDir);
  lDir = %Trim(pDir);
  lName = %Trim(pName);

  //  Open up the directory.
  dh = opendir(lFolder);
  if (dh = *NULL);
    return *off;
  endif;

  p_dirent = readdir(dh);

  dow (p_dirent <> *NULL AND success);

    Name = %trim(%str(%addr(d_name)));
    rtnVal = stat(%trim(lFolder + '/' + d_name):%addr(stat_struct));

    if (rtnVal = 0);
      Select;
        When (st_objType = '*DIR');
          // it's a directory, but there are
          // two cases we will ignore...
          if (%Len(Name) >= 1 AND %Len(Name) <= 10);
            if (%Subst(Name:1:1) <> '.');
              if (lDir = '*ALL' OR Name = lDir);
                success = getSources(
                                %trim(lFolder + '/' + Name + '/'):
                                Name:
                                pName);
              Endif;
            endif;
          Endif;

        When (st_objType = '*STMF');
          If (%Subst(Name:1:1) <> '.');
            If (lName = '*ALL' OR %Subst(Name:1:%Len(lName)) = lName);
              index = %ScanR('.':Name);
              If (index > 0);
                baseName = %Subst(Name:1:index - 1);
                baseExt = %Subst(Name:index + 1);
              Else;
                baseName = Name;
                baseExt = '';
              Endif;

              If (system('CPYFRMSTMF FROMSTMF(''' + %Trim(lFolder) + %Trim(Name) + ''') TOMBR(''/QSYS.LIB/' + %Trim(LIB) + '.LIB/' + %Trim(lDir) + '.FILE/' + %Trim(baseName) + '.MBR'') MBROPT(*REPLACE)') <> 0);
                success = *off;
              Endif;

              If (baseExt <> *BLANK);
                system('CHGPFM FILE(' + %Trim(LIB) + '/' + %Trim(lDir) + ') MBR(' + %Trim(baseName) + ') SRCTYPE(' + %Trim(baseExt) + ')');
              Endif;
            Endif;
          Endif;
      Endsl;
    endif;

    p_dirent = readdir(dh);
  enddo;

  closedir(dh);

  Return success;
End-Proc;

// **************
