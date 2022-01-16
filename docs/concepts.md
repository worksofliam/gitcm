Gitcm combines two things:

* The please of working with source members
* Git source control.

**You should only use gitcm if you are not ready to make the full move to git.** Gitcm lets developers continue to maintain their source code in source members while keeping the true copy and history of changes in git.

## Before gitcm / without source control

![bad](https://user-images.githubusercontent.com/3708366/149648285-75b75fe4-9e2e-4381-a2bc-78739fe5e2ad.png)

A usual practice for businesses without any change management or source control is usually one or many of the following:

* All developers sharing and working out of one library. E.g. developers all working in `SRCLIB/QRPGLESRC`.
* Developers creating their own 'developer library' to make their changes before merging them back in.
* Relying on source dates to see what changed.

There are some issues with this:

1. Relying on source locks to edit code. This means only one developer can edit one file at the same time
2. While having a 'developer' library does help solve that issue. Most of the time, when pushing changes back to the base library, it is with a force merge and could potentially lose other peoples changes as you copy the member back.
3. Relying on source dates doesn't tell you what changes and why. Only brief history.
4. There is no history of changes. Bad for auditing and bug tracking.

## With gitcm

![good](https://user-images.githubusercontent.com/3708366/149648496-acbae4d0-68d0-4828-ab68-06ed945c531c.png)

With gitcm, developers can develop code in their own branches. Developing in a branch controlled by gitcm would be like traditional IBM i development: inside of a library and source files. **Gitcm treats branch libraries like the working tree for the branch.** _Note: The following text is aimed at doing all development through 5250. Tools like VS Code and RDi will make it even easier._

After the setup for the repository is done (`GITINT` for 'git initialise'), developers will no longer develop out of `SRCLIB` (as in the above diagram). It can still be a point of reference for the source code and objects can still be built and created in there, **but source code should not be altered in this library.** That library is no longer the 'source of truth'. It should be all checked into git by this time.

When a branch is created (using `GITBRN`), it creates a new library and asscicates it with a git branch. That new library will only contain empty source files in it. Developers can create new members, or if they want to bring in existing sources from the repo they can use `GITBRG` (for bring).

While developers write code, they can use `GITDFF` from the command line (even as a custom PDM option) to see a diff between their version of the source code and the HEAD version. This lets developers see changes they have made before making a commit. (p.s. It looks even better from VS Code)

![image](https://user-images.githubusercontent.com/3708366/149648661-f9acb085-a3ad-4078-869b-bff2752177db.png)

From there, developers can finish up their branch by using the `GITCMTMRG` command. This allows developers to commit all their working changes to their branch and then automatically merge it into main (or master, however it was set up). If it turns out there is a source conflict when attempting to merge, the conflicts will be updated in the source members in the branch for the user to resolve them. When the user has resolved them, they can use `GITCMTMRG` again.

There are also commands to view the git log (`GITLOG`), which lets you browse commits and view what files changed at a commit. As well as viewing the diff of a file at a certain point in time, devs can even create a new branch to roll a file back to that point. Developers have full control over their source when they have history.
