## Repo setup

This guide is to show how to setup the first repository on the system.

### Prereqs

* Have a library of source code you want to start tracking
* Have gitcm setup on the system
* Make sure `GITCM` is on the library list
* Know that this does not delete anything from the library
    * For source to track correctly this library should not be used for development after the initialisation is done.
    * It can still be used for building objects (programs, serivce programs, tables, etc) from source.
* All directories and source in the IFS after initialisation becomes lowercase
* After the library has been initialised, developers should not continue to write code in that library as it won't be tracked in git. See the FAQs for more information.

### Initialisation

1. Create a directory for where the repo will be.
    * e.g. if your library is called `APPLIB`, you might create `/repos/applib`
    * You can use `MKDIR` to create a directory on the IFS.
2. Use `GITINT` (git initialise) to create the repo and migrate the source source code
    * `PATH` will be the directory you created for the repo in step 1
    * `LIB` will be the library where the current source code is
    * `INITCOMMIT` should be `*YES`. This will enable the process to copy the source and create the initial commit. If you do not do this, you will have an empty repository.
3. Done.
    * The `GITINT` command make take some time depending on how much source code there is.
    * The setup process on happens once per library.