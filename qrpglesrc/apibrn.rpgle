**FREE

Ctl-Opt DFTACTGRP(*No) BNDDIR('GITCM/GITCM');

Dcl-Pi APIBRN;
  BASE Char(10);
End-Pi;

/copy 'qrpgleref/objects.rpgle'
/copy 'qrpgleref/dataarea.rpgle'
/copy 'qrpgleref/utils.rpgle'

Dcl-Ds Error LikeDS(Error_T);
Dcl-DS dataArea LikeDs(DSResult_T);

Dcl-S lObjectCount Int(5);
Dcl-S baseRepoPath Varchar(128);

getDataArea(dataArea:128:'GITREPODIR' + BASE:-1:128:Error);
If (Error.Code = *BLANK);
  baseRepoPath = %TrimR(dataArea.Data);

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
        Endif;
      Endif;
    Endif;
  Endfor;

Else;
  Utils_Print('ERROR: Not a git library.');
Endif;

Return;