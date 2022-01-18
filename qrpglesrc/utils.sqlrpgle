**FREE

Ctl-Opt NoMain;

/copy 'qrpgleref/system.rpgle'
/copy 'qrpgleref/utils.rpgle'
        
Dcl-Proc Utils_Lower Export;
  Dcl-Pi *N Char(10);
    pValue Char(10) Value;
  End-Pi;
          
  EXEC SQL SET :pValue = LOWER(:pValue);
          
  Return pValue;
End-Proc;

Dcl-Proc Utils_Print Export;
  Dcl-Pi *N;
    Text Varchar(512) Const;
  End-Pi;

  printf(%trim(Text) + x'25');
  printf_jl(%trim(Text) + x'25');
End-Proc;

Dcl-Proc Utils_Qsh Export;
  Dcl-Pi *N Ind;
    Command Varchar(512) Const;
  End-Pi;

  return system('QSH CMD(''' + %Trim(Command) + ''')') = 0;
End-Proc;
