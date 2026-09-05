# Task 1: git commit -a -m vs git commit -m

`git commit -m "msg"` only commits whatever is already in the staging area (whatever you've `git add`ed). If you've modified a tracked file but never staged it, `-m` on its own does nothing to that file.

`git commit -a -m "msg"` auto-stages first — but only for files git is **already tracking** that got modified or deleted. It does **not** pick up brand new untracked files. You still need `git add` for anything new.

## What I actually tested

```bash
git init -q -b main
git config user.name "sachith"
git config user.email "sachithreddy212@gmail.com"

echo "line1" > file1.txt
git add file1.txt
git commit -q -m "initial commit"
```

Modified the tracked file, then tried `commit -m` without staging:

```
$ echo "line2" >> file1.txt
$ git commit -m "trying without -a"
On branch main
Changes not staged for commit:
	modified:   file1.txt
no changes added to commit (use "git add" and/or "git commit -a")
```

Nothing got committed — git flat out refuses since there's nothing staged.

Same change, this time with `-a`:

```
$ git commit -a -m "commit with -a, auto-staged the modified file"
[main 075fb01] commit with -a, auto-staged the modified file
 1 file changed, 1 insertion(+)
```

Worked immediately, no `git add` needed — since `file1.txt` was already a tracked file.

Then tested the part I actually wasn't sure about — does `-a` catch new files too?

```
$ echo "brand new file" > file2.txt
$ git commit -a -m "does -a catch a new untracked file too?"
On branch main
Untracked files:
	file2.txt
nothing added to commit but untracked files present (use "git add" to track)
```

Nope. `file2.txt` is untracked, and `-a` skipped it entirely — confirms `-a` is really just short for "stage every already-tracked file that changed," not "stage everything."

## Done
- Ran both, saw the actual difference instead of just reading about it
- Also checked the edge case (new file vs modified tracked file) since that's the part people usually get wrong in interviews
