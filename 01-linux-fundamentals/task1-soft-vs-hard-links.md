# Task 1: Soft Link vs Hard Link

## What's the difference

A **hard link** is basically a second name for the exact same file. Both names point to the same inode (the actual data block on disk), so there's no real "original" — they're equal. If you delete one name, the data is still there because the other name still points to it. The data only actually gets removed once every name pointing to it is gone.

A **soft link** (symlink) is a different, tiny file that just stores a path/string pointing at the target. It's more like a Windows shortcut. If the target gets deleted or moved, the symlink doesn't know that — it just becomes "broken" / dangling.

Quick differences I noted:
- Hard links can't point to directories, soft links can.
- Hard links can't cross filesystems/partitions, soft links can.
- `ls -li` shows the inode number — same inode = hard linked, different inode = soft linked.

**For interviews:** if asked, I'd say — hard link shares the inode so it survives the original being deleted, soft link is just a path pointer so it breaks if the target is gone.

## Commands

```bash
mkdir -p links-demo && cd links-demo
echo "Hello Links" > original.txt
ln original.txt hardlink.txt        # hard link
ln -s original.txt softlink.txt     # soft link, needs -s
ls -li                              # -i = show inode numbers
```

`unlink file` also removes a link (same as `rm` but only takes one file at a time).

## What actually happened when I ran it

```
$ ls -li
total 8
109841 -rw-r--r-- 2 sachith sachith 12 Sep  5 14:29 hardlink.txt
109841 -rw-r--r-- 2 sachith sachith 12 Sep  5 14:29 original.txt
109842 lrwxrwxrwx 1 sachith sachith 12 Sep  5 14:29 softlink.txt -> original.txt
```

`original.txt` and `hardlink.txt` both have inode `109841` and the link count column (right after permissions) shows `2` — that's the proof they're the same file under two names. `softlink.txt` got a totally different inode (`109842`) and `ls` shows it with the `->` arrow pointing back to `original.txt`.

Then I deleted the original to see what breaks:

```
$ rm original.txt
$ cat hardlink.txt
Hello Links
$ cat softlink.txt
cat: softlink.txt: No such file or directory
```

`hardlink.txt` still opens fine and shows the content — makes sense, the data wasn't tied to the name `original.txt` specifically. `softlink.txt` is now dangling since the path it stores no longer exists.

```
$ ls -li
109841 -rw-r--r-- 1 sachith sachith 12 Sep  5 14:29 hardlink.txt
109842 lrwxrwxrwx 1 sachith sachith 12 Sep  5 14:29 softlink.txt -> original.txt
```

Link count on `hardlink.txt` dropped to `1` now that only one name points at that inode.

Cleaned up after:

```
$ rm hardlink.txt
$ unlink softlink.txt
```

Both gone, folder's empty again.

## Done
- Understand the concept and can explain it for an interview
- Created both link types
- Deleted both link types
- Saw the inode-sharing and the broken-symlink behavior for myself, not just reading about it
