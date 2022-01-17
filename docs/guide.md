## Gitcm guide

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

1. **Create a directory for where the repo will be.**
	* e.g. if your library is called `APPLIB`, you might create `/repos/applib`
	* You can use `MKDIR` to create a directory on the IFS.
2. **Use `GITINT` (git initialise) to create the repo and migrate the source source code**
	* `PATH` will be the directory you created for the repo in step 1
	* `LIB` will be the library where the current source code is
	* `INITCOMMIT` should be `*YES`. This will enable the process to copy the source and create the initial commit. If you do not do this, you will have an empty repository.
3. **Done.**
	* The `GITINT` command make take some time depending on how much source code there is.
	* The setup process on happens once per library.

## Development flow

Once you have initialised the library and setup the repo, you can now start writing code. You can create a branch for each feature, fix, etc, you work on. Branches generally are not supposed to contain more than one feature, fix, etc.

1. **Create a branch with `GITBRN`. This will create a new library with empty source files.**
	* `BASE` is the base library
	* `LIB` is the new library for the branch (the branch library)
	* `NAME` is the branch name that will be used in git.
2. **Inside of your new branch library, you will have empty source files.**
	* You can either use `GITBRG` (git bring) to bring source code in to this library, or
	* you can create new members (or new source files!)
3. **After you are done working on your changes, you should always do a diff on the source**
	* This will let you see what changes have happened in the base before you commit and merge. This gives you a chance to bring in changes other people have done before you commit
	* You can use `GITDFF` (git diff) on a source member in a branch library to see a diff in the green screen
4. **When you're happen with your change, you can make a commit & merge**
	* You can use `GITCMTMRG` to make the commit & merge
	* Making a commit means the change you made will be stored into the git log.
	* Git requires a name and author when making a commit. You can supply this on the command or at a job level.
	* `AUTOMERGE(*YES)` will merge the branch back into the base when the commit is done. `*NO` will create the branch and it will have to manually be merged.
	* `SUBMITBRING(*YES)` will update all sources in the base library after the merge using `SBMJOB(GITBRG)`
	* When the merge has been made, the library text will be updated to say it has been merged.
	* The library can be deleted when it is done with / been merged.
