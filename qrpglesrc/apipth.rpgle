**FREE

Ctl-Opt DFTACTGRP(*No) BNDDIR('GITCM');

Dcl-Pi APIPTH;
  BASE Char(10);
End-Pi;

/copy 'qrpgleref/objects.rpgle'
/copy 'qrpgleref/dataarea.rpgle'
/copy 'qrpgleref/utils.rpgle'

Dcl-Ds Error LikeDS(Error_T);
Dcl-DS dataArea LikeDs(DSResult_T);

Dcl-S baseRepoPath Varchar(128);

getDataArea(dataArea:128:'GITREPODIR' + BASE:-1:128:Error);
If (Error.Code = *BLANK);
  baseRepoPath = %TrimR(dataArea.Data);

  Utils_Print(baseRepoPath);

Else;
  Utils_Print('ERROR: Not a git library.');
Endif;

Return;