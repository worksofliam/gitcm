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
