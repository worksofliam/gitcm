## Installing gitcm

1. Installs the required deps from yum:
   * `git.ppc64` is required to use git on IBM i
   * `gmake.ppc64` is required to build gitcm from source
3. Get the source code into the IFS
   * Download the repo [as a zip](https://github.com/worksofliam/gitcm/archive/refs/heads/main.zip) and extract on the IFS
   * Clone the repo using git
4. Change directory (`cd`) to the directory where the source code it
5. Run `gmake` to build gitcm into the `GITCM` library
