# 0 "/git/md/src/OpenSPARC_T1_rebuild/1up.hdesc"
# 0 "<built-in>"
# 0 "<command-line>"
# 1 "/usr/include/stdc-predef.h" 1 3 4

# 17 "/usr/include/stdc-predef.h" 3 4



















# 45 "/usr/include/stdc-predef.h" 3 4

# 55 "/usr/include/stdc-predef.h" 3 4









# 0 "<command-line>" 2
# 1 "/git/md/src/OpenSPARC_T1_rebuild/1up.hdesc"

# 23 "/git/md/src/OpenSPARC_T1_rebuild/1up.hdesc"







// Hypervisor configuration for 1up.conf


# 1 "/git/md/src/OpenSPARC_T1_rebuild/common.hdesc" 1

# 23 "/git/md/src/OpenSPARC_T1_rebuild/common.hdesc"

















# 51 "/git/md/src/OpenSPARC_T1_rebuild/common.hdesc"

# 33 "/git/md/src/OpenSPARC_T1_rebuild/1up.hdesc" 2

node cpu cpu0 {			pid = 0;			guest -> guest0;			vid = 0;		}
node guest guest0 {					gid = 0;					pid = (0 + 1);					xid = (16 + 0);											cpuset =  0x1;										membase =  0x80000000;				memsize =  256M;				realbase =  0x80000000;				uartbase = (0x1f10000000 + (0 * 0x2000));				nvbase = (0x1f11000000 + (0 * (2 * 0x4000)));				nvsize = 0x2000;				rombase = 0xfff0080000;				romsize = 512k;				diskpa =  0x1f40000000;				pdpa =  0x1f12000000;					bootcpu = 0;					perfctraccess = 1;			}

node cpus cpus {
	cpu -> cpu0;
}

node guests guests {
	guest -> guest0;
}

node root root {
	guests -> guests;
	cpus -> cpus;
	hvuart = 0xfff0c2c000;
	tod = 0xfff0c1fff8;
}
