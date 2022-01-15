

     d ObjectDs        ds
     d  Object                       10
     d  Library                      10
     d  ObjectType                   10
     d  InfoStatus                    1
     d  ExtObjAttrib                 10
     d  Description                  50

     D Obj_List        PR
     D    pLibrary                   10A   Const
     D    pObject                    10A   Const
     D    pType                      10A   Const

     D Obj_Count       PR             5i 0

     D Obj_Next        PR                  LikeDS(ObjectDs)
