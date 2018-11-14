# Git: Patch

Most developers, add everything all at once in git using `git add .`, or `git add -A` (which is the
same as `git add --all`). But the problem with this is that it in some cases, the commit to be added
is a subset of the file. In these instances, using `--patch` or `-p` becomes especially useful. For
example:

```sh
$ git add -p
diff --git a/README.md b/README.md
index ee98329..6e03ea6 100644
--- a/README.md
+++ b/README.md
@@ -30,7 +30,7 @@ export PATH="$HOME/grimoire/bin:$PATH"
 * [expand directory](./vim/expand_directory.md)

 ## Git
-* [pick](./git/pick.md)
+* [patch](./git/patch.md)

 ## Terminal Productivity
 - https://github.com/junegunn/fzf
Stage this hunk [y,n,q,a,d,e,?]?
```

When there is more than one line or the diff contains several chunks, `s` becomes an option to split
the current diff.
