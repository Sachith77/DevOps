# Task 2: adduser vs useradd

## Difference

`useradd` is the low-level command that actually creates the user entry. On its own it doesn't create a home directory, doesn't set a password, doesn't ask you anything — it just does exactly what flags you give it, nothing more. If you forget `-m`, you get an account with no home folder.

`adduser` is a friendlier script built on top of `useradd` (it's a Debian/Ubuntu thing, not universal across all distros). It creates the home directory automatically, copies default files from `/etc/skel`, and walks you through setting a password and some optional info interactively.

On Ubuntu, `adduser` is the recommended one for creating users manually, mainly because it's harder to mess up — you don't have to remember a bunch of flags to end up with a working account.

## What I ran

```bash
sudo adduser testuser
```

It asked for a password twice, then some optional stuff (full name etc.) which I just skipped by hitting Enter, then confirmed with `y`.

```
$ id testuser
uid=1002(testuser) gid=1002(testuser) groups=1002(testuser),100(users)

$ ls /home/testuser
ls: cannot open directory '/home/testuser': Permission denied

$ cat /etc/passwd | grep testuser
testuser:x:1002:1002:,,,:/home/testuser:/bin/bash
```

The "Permission denied" on `ls` threw me off for a second, but it makes sense — `adduser` locks down the new home folder so only that user (and root) can look inside it. I was running `ls` as `sachith`, not `testuser`, so it's Linux permissions working correctly, not a bug. The `/etc/passwd` line confirms the home directory and shell (`/bin/bash`) got set up automatically.

## Then I tried plain useradd to see the actual difference

```bash
sudo useradd useraddtest
```

```
$ id useraddtest
uid=1003(useraddtest) gid=1003(useraddtest) groups=1003(useraddtest)

$ ls /home/useraddtest
ls: cannot access '/home/useraddtest': No such file or directory
```

This is the real contrast — `id` says the account exists either way, but with plain `useradd` there's genuinely **no home directory** (`No such file or directory`, not "permission denied" like before). If I'd actually needed this account to work, I'd have to also run something like `useradd -m -s /bin/bash useraddtest`.

## Cleanup

```bash
sudo deluser --remove-home testuser
sudo userdel useraddtest
```

Removed both test accounts afterward so I'm not leaving random users sitting on my machine.

## Done
- Know the difference and why adduser is the recommended one on Ubuntu
- Made a user with adduser (the recommended way)
- Made one with useradd too just to see the missing-home-directory difference for myself
- Cleaned up both test accounts
