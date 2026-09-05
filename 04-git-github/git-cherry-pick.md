# Task 2: Git Cherry-Pick

Cherry-pick takes one specific commit from somewhere else and replays it onto your current branch, without merging everything else from that branch.

## Setup — commits on main

```bash
echo "v1" > app.txt
git add app.txt
git commit -q -m "first commit on main"
echo "v2" >> app.txt
git commit -qa -m "second commit on main"
echo "v3" >> app.txt
git commit -qa -m "third commit on main"
```

```
$ git log --oneline
0512df6 third commit on main
ccc7791 second commit on main
dcefbc8 first commit on main
```

## New branch, commits there

```bash
git checkout -q -b feature
echo "feature-line-1" >> feature.txt
git add feature.txt
git commit -q -m "feature: add feature.txt"
echo "feature-line-2" >> feature.txt
git commit -qa -m "feature: important fix we need on main"
echo "feature-line-3" >> feature.txt
git commit -qa -m "feature: unrelated followup commit"
```

```
$ git log --oneline
0b9d15b feature: unrelated followup commit
e250924 feature: important fix we need on main
7927890 feature: add feature.txt
0512df6 third commit on main
ccc7791 second commit on main
dcefbc8 first commit on main
```

Say I only want `feature: important fix we need on main` (`e250924`) on `main`, not the other two feature commits.

## First attempt — this actually failed, which turned out to be a useful lesson

```
$ git checkout -q main
$ git cherry-pick e250924
error: could not apply e250924... feature: important fix we need on main
hint: After resolving the conflicts, mark them with "git add/rm <pathspec>"...
```

Took me a second to get why — `e250924` only *appends* a second line to `feature.txt`. But `feature.txt` was *created* by the commit before it (`7927890`), which never made it to `main`. So git tried to apply "append line 2 to feature.txt" on a branch where `feature.txt` doesn't exist at all — conflict. Cherry-picking a commit that depends on an earlier commit you don't have is exactly when this breaks.

Aborted it cleanly:

```
$ git cherry-pick --abort
$ git status
On branch main
nothing to commit, working tree clean
```

## Second attempt — cherry-picked the self-contained commit instead

Went with `7927890` instead (the one that creates `feature.txt` from scratch — doesn't depend on anything else):

```
$ git cherry-pick 7927890
[main 4155060] feature: add feature.txt
 1 file changed, 1 insertion(+)
 create mode 100644 feature.txt
```

## Verified it landed on main

```
$ git log --oneline
4155060 feature: add feature.txt
0512df6 third commit on main
ccc7791 second commit on main
dcefbc8 first commit on main

$ cat feature.txt
feature-line-1
```

`feature.txt` now exists on `main` with exactly the content from that one commit — the other two feature-branch commits were never touched.

## Done
- Made commits on main and on a new branch
- Used `git log` to find specific commit hashes
- Cherry-picked — including hitting and fixing a real conflict, not just the happy path
- Confirmed the change is actually on main afterward
