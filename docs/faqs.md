### I no longer need my branch.

Just delete the branch library.

### I need to restart my change in my branch. Can I undo it?

Yes! You can just use `GITBRG` (git bring) to revert the source code back to what it is in the base repo.

### How can I view the diff from `WRKMBRPDM`?

You should create a PDM option for the diff: 

```
GITCM/GITDFF LIB(&L) DIR(&F) NAME(&N) ATTR(&S)
```

_Note: this only works when your member belongs to a branch library._

### Can many people work on one branch

Yes, many people can work in one branch, but only one person can make the commit. We recommend against this, and instead developers each make their own branches to work from.

### Is there a way for me to view the source history? (Git log)

Yes. You should know about the `GITLOG` command, where you pass in the base or branch library. This will show the last 50 commits in the repository. Following that, you can also view the files that changed at that commit, as well as diff of how that file changed.

### How do I update the base library in case it is missing changes?

You can use `GITBRN` with `DIR(*ALL)` and `NAME(*ALL)`. This will copy all sources from the repository into the `LIB` parameter you specify - which can be the base.

### How do I know if something passed or failed from the command line?

gitcm is very verbose. Every time you run a command, you should check the job log (`DSPJOBLOG`). Specifically look out for entries that start with `ERROR` and `NOTICE`.

### Environment variables for author and emails

In order for `GITCMTMRG` to know your email and author name, you need to setup two environment variables for your job.

* `GIT_EMAIL` with your email address
* `GIT_AUTHOR` with your choice name (and often username)