check_mem_ng.sh 1.1

Usage:
* check_mem_ng.sh [-w <warnlevel>] [-c <critlevel>] [-v] [-l]
 - checks local host available memory
 - warnlevel and critlevel is percentage value without %
 - defaults being respectively 80 et 90
 - add -v for verbose (debuging purpose)
 - add -l for legacy perfdata mode (or change LEGACY_PERFDATA variable in script)
* check_mem_ng.sh -V
 - prints version
* check_mem_ng.sh -h
 - prints help (this message)

Similarities/differences between check_mem.sh:
- Both don't need much to run: only bash, free and awk
- Compatible with "free" binary from either procps AND procps-ng (newer) whereas check_mem.sh is not
- Same basic syntax, you can exchange both scripts without changing your Nagios(r) configuration much
- You can choose to keep perfdata identical to check_mem.sh OR display a modern graph with min/max bounds and warning/critical lines
- Added defaults to warn and critical, and help/version/verbose/legacy_perfdata flags

Output:

./check_mem_ng.sh

OK: Memory below thresholds. Total: 7984 MB - Used: 288 MB - 3% used. | Memory_Used=302661632;6698119987;7535384985;0;8372649984
 
./check_mem_ng.sh -w 70 -c 85

OK: Memory below thresholds. Total: 7984 MB - Used: 288 MB - 3% used. | Memory_Used=302796800;5860854988;7116752486;0;8372649984

./check_mem_ng.sh -w 70 -c 85 -l

OK: Memory below thresholds. Total: 7984 MB - Used: 289 MB - 3% used. | TOTAL=8372649984;;;; USED=303390720;;;; CACHE=7834243072;;;; BUFFER=613666816;;;;
