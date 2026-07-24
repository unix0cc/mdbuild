# 0 "/git/md/src/OpenSPARC_T1_rebuild/1up.pdesc"
# 0 "<built-in>"
# 0 "<command-line>"
# 1 "/usr/include/stdc-predef.h" 1 3 4

# 17 "/usr/include/stdc-predef.h" 3 4



















# 45 "/usr/include/stdc-predef.h" 3 4

# 55 "/usr/include/stdc-predef.h" 3 4









# 0 "<command-line>" 2
# 1 "/git/md/src/OpenSPARC_T1_rebuild/1up.pdesc"

# 23 "/git/md/src/OpenSPARC_T1_rebuild/1up.pdesc"








# 1 "/git/md/src/OpenSPARC_T1_rebuild/common.pdesc" 1

# 23 "/git/md/src/OpenSPARC_T1_rebuild/common.pdesc"







# 38 "/git/md/src/OpenSPARC_T1_rebuild/common.pdesc"


node options XXoptions {
     input-device = "ttya";
     output-device = "ttya";
     boot-device = "vdisk";
     use-nvramrc? = -1;
}

node devalias XXdevalias {
     net = "/virtual-devices/network@0";
     disk = "/virtual-devices/disk@0";
     vdisk = "/virtual-devices/disk@0";
     nvram = "/virtual-devices/nvram@5";
     ttya = "/virtual-devices/console@1";
     ttyb = "/virtual-devices/console@4";
}

node root root {
	banner-name = "Sun Fire T2000";
	name = "SUNW,Sun-Fire-T2000";
	stick-frequency = 5000000;
	clock-frequency = 5000000;
	board-part# = "000-000-000";
	max-#cpumondo-entries = 256;
	max-#devmondo-entries = 256;
	max-#cpus = 32;                            // XXX
        max-#tsb-entries = 0x2;
	reset-reason = 0;			   // power-on
	fwd -> platform_data;
	fwd -> vdev;
}

node platform platform_data {
     banner-name = "Sun Fire T2000";
     name = "SUNW,Sun-Fire-T2000";
     mac-address = 0x8003dead03;        // mac address
     hostid = 0x80112233;
     serial# = 11223344;
     stick-frequency = 5000000;
     clock-frequency = 5000000;
}


node virtual-devices vdev {
    cfg-handle = 0x100;
}

node virtual-device disk {
	back -> vdev;
	name = "disk";
	fcode-driver-name = "disk-virtual-device";
	my-space = 0;
	intr = 0;
	ino = 0;
	cfg-handle = 0;
}


node virtual-device console {
	back -> vdev;
	name = "console";
	fcode-driver-name = "console-virtual-device";
	intr = 1;
	ino = 0x11;
	compatible = "qcn";
	cfg-handle = 0x1;
	channel# = 0;
}

node virtual-device nvram {
	back -> vdev;
	name = "nvram";
	fcode-driver-name = "nvram-virtual-device";
	intr = 0;
	ino = 0;
	cfg-handle = 0x2;
}

node virtual-device tod {
	back -> vdev;
	name = "rtc";
	fcode-driver-name = "tod-virtual-device";
	intr = 0;
	ino = 0;
	cfg-handle = 0x3;
	compatible = "sun4v-tod";
}
# 31 "/git/md/src/OpenSPARC_T1_rebuild/1up.pdesc" 2

node cpu cpu0 {	    id = 0; 				    clock-frequency = 0x4C4B40;		    isalist = "sparcv9","sparcv8plus","sparcv8","sparcv8-fsmuld","sparcv7","sparc";     compatible = { "SUNW,UltraSPARC-T1", "SUNW,sun4v-cpu", "sun4v" };     max-#tsb-entries = 0x2;     }

node mblock p0_memlist0 {
	base = 0x0000000080000000;
	size = 256M;
}
