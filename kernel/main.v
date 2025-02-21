import lib
import memory
import stivale2
import acpi
import x86
import initramfs
import fs
import sched
import stat

fn C._vinit(argc int, argv voidptr)

fn kmain_thread(stivale2_struct &stivale2.Struct) {
	fs.initialise()

	fs.mount(vfs_root, '', '/', 'tmpfs')
	fs.create(vfs_root, '/dev', 0644 | stat.ifdir)
	fs.mount(vfs_root, '', '/dev', 'devtmpfs')

	modules_tag := unsafe { &stivale2.ModulesTag(stivale2.get_tag(stivale2_struct, stivale2.modules_id)) }
	if modules_tag == 0 {
		panic('Stivale2 modules tag missing')
	}

	initramfs.init(modules_tag)

	panic('End of kmain')
}

pub fn kmain(stivale2_struct &stivale2.Struct) {
	// Initialize the earliest arch structures.
	x86.gdt_init()
	x86.idt_init()

	// Init terminal
	stivale2.terminal_init(stivale2_struct)

	// We're alive
	lib.kprint('Welcome to Vinix\n\n')

	// Initialize the memory allocator.
	memmap_tag := unsafe { &stivale2.MemmapTag(stivale2.get_tag(stivale2_struct, stivale2.memmap_id)) }
	if memmap_tag == 0 {
		lib.kpanic('Stivale2 memmap tag missing')
	}

	memory.pmm_init(memmap_tag)
	memory.vmm_init(memmap_tag)

	// Call Vinit to initialise the runtime
	C._vinit(0, 0)

	// ACPI init
	rsdp_tag := unsafe { &stivale2.RSDPTag(stivale2.get_tag(stivale2_struct, stivale2.rsdp_id)) }
	if rsdp_tag == 0 {
		panic('Stivale2 RSDP tag missing')
	}

	acpi.init(&acpi.RSDP(rsdp_tag.rsdp))

	smp_tag := unsafe { &stivale2.SMPTag(stivale2.get_tag(stivale2_struct, stivale2.smp_id)) }
	if smp_tag == 0 {
		panic('Stivale2 SMP tag missing')
	}

	x86.smp_init(smp_tag)

	sched.initialise()
	sched.new_kernel_thread(voidptr(kmain_thread), voidptr(stivale2_struct), true)
	sched.await()
}
