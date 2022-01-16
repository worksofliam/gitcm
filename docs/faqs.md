
### I've initialised the library. How can I start writing code?

Once you have initialised the library and setup the repo, you can now start writing code. You can create a branch for each feature, fix, etc, you work on. Branches generally are not supposed to contain more than one feature, fix, etc.

1. Create a branch with `GITBRN`. This will create a new library with empty source files.
    * `BASE` is the base library
    * `LIB` is the new library for the branch (the branch library)
    * `NAME` is the branch name that will be used in git.
2. Inside of your new branch library, you will have empty source files.
    * You can either use `GITBRG` (git bring) to bring source code in to this library, or
    * you can create new members (or new source files!)
3. After you are done working on your changes, you should always do a diff on the source
    * This will let you see what changes have happened in the base before you commit and merge. This gives you a chance to bring in changes other people have done before you commit
    * You can use `GITDFF` (git diff) on a source member in a branch library to see a diff in the green screen
        * Protip: Create a PDM option for the diff: `GITCM/GITDFF LIB(&L) DIR(&F) NAME(&N) ATTR(&S)`
4. When you're happen with your change, you can make a commit & merge
    * You can use `GITCMTMRG` to make the commit & merge
    * Making a commit means the change you made will be stored into the git log.
    * Git requires a name and author when making a commit. You can supply this on the command or at a job level.
    * When the commit has been made, the library text will be updated to say it has been merged.
    * The library can be deleted when it is done with / been merged.