**FREE

dcl-pr OpenFile pointer extproc('_C_IFS_fopen');
  *n pointer value;  //File name
  *n pointer value;  //File mode
end-pr;

dcl-pr ReadFile pointer extproc('_C_IFS_fgets');
  *n pointer value;  //Retrieved data
  *n int(10) value;  //Data size
  *n pointer value;  //Misc pointer
end-pr;

dcl-pr CloseFile extproc('_C_IFS_fclose');
  *n pointer value;  //Misc pointer
end-pr;

Dcl-C LINE_LEN 128;

Dcl-Ds File_Temp Qualified Template;
  PathFile char(LINE_LEN);
  RtvData  char(LINE_LEN);
  OpenMode char(5);
  FilePtr  pointer inz;
End-ds;

// Open a Directory

Dcl-PR opendir Pointer extproc( 'opendir' );
  dirname        Pointer    value options( *string );
End-PR;

// Read Directory Entry

Dcl-PR readdir Pointer extproc( 'readdir' );
  dirp           Pointer    value options( *string );
End-PR;

// Close a Directory

Dcl-PR closedir Int(10) extproc( 'closedir' );
  dirp           Pointer    value options( *string );
End-PR;

// Check for Sub-directory

Dcl-PR stat Int(10) extproc( 'stat' );
  #sPath         Pointer    value options( *string );
  #sBuf          Pointer    value;
End-PR;
