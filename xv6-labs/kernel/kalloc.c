// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run {
  struct run *next;
};

struct kmem_{
  struct spinlock lock;
  struct run *freelist;
};
struct kmem_ kmem[NCPU];
void
kinit()
{ 
  // push_off();
  // int id = cpuid();
  // pop_off();
  for(int id=0;id<NCPU;id++){
  // char kmemName[5] = "kmem";
  // kmemName[4] = (char)(id+'0');
  initlock(&(kmem[id]).lock, "kmem");
  freerange(end, (void*)PHYSTOP);
  // printf("create %s\n", kmemName);
  }
}

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    kfree(p);
}

// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
  struct run *r;
  push_off();
  int id = cpuid();
  pop_off();
  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);

  r = (struct run*)pa;

  // acquire(&(kmem[id]).lock);
  r->next = kmem[id].freelist;
  kmem[id].freelist = r;
  // release(&(kmem[id]).lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;
  push_off();
  int id = cpuid();
  pop_off();
  
  r = kmem[id].freelist;
  if(r){
    
    acquire(&(kmem[id]).lock);
    kmem[id].freelist = r->next;
    release(&(kmem[id]).lock);
    }
  else
    for(int idx=0;idx<NCPU;idx++){
      if(idx==id) continue;
      
      if(kmem[idx].freelist){
        acquire(&(kmem[idx]).lock);
        r = kmem[idx].freelist;
        // kmem[id].freelist=r->next;
        kmem[idx].freelist=r->next;
        release(&(kmem[idx]).lock);
        break;
      }
      release(&(kmem[idx]).lock);
    }
  

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
  return (void*)r;
}