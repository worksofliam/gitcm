     **-- Header specifications:  --------------------------------------------**
     H NoMain
     **-- Api error data structure:  -----------------------------------------**
     D ApiError        Ds
     D  AeBytPro                     10i 0 Inz( %Size( ApiError ))
     D  AeBytAvl                     10i 0 Inz
     D  AeMsgId                       7a
     D                                1a
     D  AeMsgDta                    128a

     d RtvObjD         Pr                  ExtPgm( 'QUSROBJD' )
     d  RoRcvVar                  32767a         Options( *VarSize )
     d  RoRcvVarLen                  10i 0 Const
     d  RoFmtNam                      8a   Const
     d  RoObjNamQ                    20a   Const
     d  RoObjTyp                     10a   Const
     d  RoError                   32767a         Options( *VarSize )

     D RtvMbrD         PR                  ExtPgm('QUSRMBRD')
     D   RcvVar                       1A
     D   RcvVarLen                   10I 0 Const
     D   Format                       8A   Const
     D   QualDBF                     20A   Const
     D   Member                      10A   Const
     D   UseOvrDbf                    1A   Const
     D   ErrorCode                    1A     
     D dsSM            ds
     D   dsSMBytRtn                  10I 0
     D   dsSMBytAvl                  10I 0
     D   dsSMFilNam                  10A
     D   dsSMFilLib                  10A
     D   dsSMFilMbr                  10A
     D   dsSMFilAtr                  10A
     D   dsSMSrcTyp                  10A
     D   dsSMCrtDat                  13A
     D   dsSMChgDat                  13A
     D   dsSMText                    50A
     D   dsSMSrcFil                   1A

      /COPY 'qrpgleref/object.rpgle'

     P Obj_Info        B                   Export
     D Obj_Info        PI                  LikeDS(ObjDscDs)
     D    pLibrary                   10A   Const
     D    pObject                    10A   Const
     D    pType                      10A   Const

      /FREE

       ObjNam = pObject;
       ObjLib = pLibrary;
       ObjTyp = pType;

       RtvObjD(ObjDscDs:%Size(ObjDscDs):'OBJD0400':
               ObjNam+ObjLib:ObjTyp:ApiError);

       If (AeBytAvl > *Zeros AND AeMsgId = 'CPF9801');
         //Does not exist
       Endif;

       Return ObjDscDs;

      /END-FREE

     P                 E

       Dcl-Proc Obj_IsSourceFile Export;
         Dcl-Pi Obj_IsSourceFile Ind;
           pLibrary Char(10) Const;
           pObject  Char(10) Const;
         End-Pi;


        RtvMbrD(
          dsSM:
          %Size(dsSm):
          'MBRD0100':
          pObject + pLibrary:
          '*FIRST':
          '0':
          ApiError
        );

        Return DSSMSRCFIL = '1';
       End-Proc;