# Shell Scripting Task: System Information Script

`system_info.sh` prints out some basic system info and saves the running process list to a file. Covers everything the task asked for: date, hostname, username, disk usage, running processes, variables, `read -p` for input, `mkdir`, `touch`, and `>` redirection.

One thing I changed from what I first tried: the task mentions `ps` for listing processes, and I initially just used `ps aux` like most examples show. But when I actually ran it, the output included the full command line of every process — including a live VS Code Remote-WSL connection token sitting in one of the arguments. Since this whole repo is going up on public GitHub, I didn't want that in there, so I switched to `ps -eo pid,ppid,user,%cpu,%mem,stat,start,time,comm` instead, which only shows the process name and not its full arguments. Still satisfies "print the running processes", just doesn't leak whatever happens to be running on my machine at the time.

## The commands, what they're doing in the script

- `date`, `hostname`, `whoami` → captured into variables and printed
- `df -h` → disk usage, human-readable sizes
- `read -p "prompt" var` → asks for input, stores it in `var`
- `mkdir -p "$dir_name"` → makes the directory the user typed
- `touch "$output_file"` → creates the empty file
- `ps -eo ...` → prints process list to screen
- `ps -eo ... > "$output_file"` → same list, redirected into the file (overwrites it)

## Running it

```bash
chmod +x system_info.sh
./system_info.sh
```

It asks two things:
```
Enter a name for the output directory:
Enter a name for the output file (without extension):
```

## What it actually printed when I ran it

Used `output-data` as the directory and `processes` as the file name:

```
===== System Information =====
Current Date : Sat Sep  5 14:38:40 UTC 2026
Hostname     : Sachith-PC
Username     : sachith

===== Disk Usage =====
Filesystem                                Size  Used Avail Use% Mounted on
/dev/sdd                                 1007G   18G  938G   2% /
C:\                                       352G  234G  119G  67% /mnt/c
D:\                                       600G   43G  558G   8% /mnt/d
... (full df -h output in run-output.log)

Directory 'output-data' created.
File 'output-data/processes.txt' created.

===== Running Processes =====
    PID    PPID USER     %CPU %MEM STAT  STARTED     TIME COMMAND
      1       0 root      0.0  0.1 Ss   21:00:15 00:00:10 systemd
    177       1 systemd+  0.0  0.1 Ss   21:00:17 00:00:02 systemd-resolve
    408     323 sachith   0.0  0.0 S+   21:00:19 00:00:00 bash
   2180    2177 sachith  16.6  0.0 S+   14:38:40 00:00:00 system_info.sh
  28685   28673 sachith   0.3  0.2 Ssl  23:19:38 00:03:25 redis-server
... (full list in run-output.log / output-data/processes.txt)

Running processes information has been saved to: output-data/processes.txt
```

Full untrimmed output is in [`run-output.log`](./run-output.log), the process list on its own is what actually got written to [`output-data/processes.txt`](./output-data/processes.txt) — both from an actual run, not typed up after the fact.

## Done

Covers every requirement from the task — date, hostname, username, disk usage, and running processes are all printed; variables hold all the dynamic values; `read -p` takes the two inputs; `mkdir` and `touch` create the directory and file; and the process list gets written to that file with `>`.
