module fs

import stat
import klock
import memory
import resource

struct TmpFSResource {
pub mut:
	stat     stat.Stat
	refcount int
	l        klock.Lock

	storage  &byte
	capacity u64
}

fn (mut this TmpFSResource) read(buf voidptr, loc u64, count u64) i64 {
	this.l.acquire()

	mut actual_count := u64(0)
	if loc + count > this.stat.size {
		actual_count = count - ((loc + count) - this.stat.size)
	}

	unsafe { C.memcpy(buf, &this.storage[loc], actual_count) }

	this.l.release()

	return i64(count)
}

fn (mut this TmpFSResource) write(buf voidptr, loc u64, count u64) i64 {
	this.l.acquire()

	if loc + count > this.capacity {
		mut new_capacity := this.capacity

		for loc + count > new_capacity {
			new_capacity *= 2
		}

		new_storage := memory.realloc(this.storage, new_capacity)

		if new_storage == 0 {
			return -1
		}

		this.storage = new_storage
		this.capacity = new_capacity
	}

	unsafe { C.memcpy(&this.storage[loc], buf, count) }

	if loc + count > this.stat.size {
		this.stat.size = loc + count
	}

	this.l.release()

	return i64(count)
}

struct TmpFS {
pub mut:
	dev_id u64
	inode_counter u64
}

fn (mut this TmpFS) populate(node &VFSNode) {}

fn (mut this TmpFS) mount(source &VFSNode) &VFSNode {
	this.dev_id = resource.create_dev_id()
	return this.create(&VFSNode(0), '', 0644 | stat.ifdir)
}

fn (mut this TmpFS) create(parent &VFSNode, name string, mode int) &VFSNode {
	mut new_node := create_node(this)

	mut new_resource := &TmpFSResource(memory.malloc(sizeof(TmpFSResource)))

	if stat.isreg(mode) {
		new_resource.capacity = 4096
		new_resource.storage  = memory.malloc(new_resource.capacity)
	}

	new_resource.stat.size = 0
	new_resource.stat.blocks = 0
	new_resource.stat.blksize = 512
	new_resource.stat.dev = this.dev_id
	new_resource.stat.ino = this.inode_counter++
	new_resource.stat.mode = mode
	new_resource.stat.nlink = 1

	new_node.resource = new_resource

	return new_node
}
