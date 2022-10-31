// Buffer cache.
//
// The buffer cache is a linked list of buf structures holding
// cached copies of disk block contents.  Caching disk blocks
// in memory reduces the number of disk reads and also provides
// a synchronization point for disk blocks used by multiple processes.
//
// Interface:
// * To get a buffer for a particular disk block, call bread.
// * After changing buffer data, call bwrite to write it to disk.
// * When done with the buffer, call brelse.
// * Do not use the buffer after calling brelse.
// * Only one process at a time can use a buffer,
//     so do not keep them longer than necessary.

#include "types.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"
#include "buf.h"

struct
{
  struct spinlock lock[NBUCKETS];
  struct buf buf[NBUF]; // how to distribute buf[]

  // Linked list of all buffers, through prev/next.
  // Sorted by how recently the buffer was used.
  // head.next is most recent, head.prev is least.
  struct buf heads[NBUCKETS];
} bcache;

int map(int blockno){
  // random one to one cycle mapping
  return blockno%NBUCKETS;
}

void binit(void)
{
  struct buf *b;
  int bid = 0;

  // Create linked list of buffers
  for (bid = 0; bid < NBUCKETS; bid++)
  {
    initlock(&bcache.lock[bid], "bcache");
    bcache.heads[bid].prev = &bcache.heads[bid];
    bcache.heads[bid].next = &bcache.heads[bid];
  }
  int bno = 0;
  for (b = bcache.buf; b < bcache.buf + NBUF; b++)
  {
    // printf("blockno:%d\n", bno);
    int m_no = map(bno);
    b->next = bcache.heads[m_no].next;
    b->prev = &bcache.heads[m_no];
    // b->top = bno;
    initsleeplock(&b->lock, "buffer");
    bcache.heads[m_no].next->prev = b;
    bcache.heads[m_no].next = b;
    bno++;
  }
}

// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
static struct buf *
bget(uint dev, uint blockno)
{
  struct buf *b;
  int bid = map(blockno);

  // Is the block already cached?
  acquire(&bcache.lock[bid]);
  for (b = bcache.heads[bid].next; b != &bcache.heads[bid]; b = b->next)
  {
    // printf("b.dev:%d,in.dev:%d\n", b->dev, dev);
    if (b->dev == dev && b->blockno == blockno)
    {
      b->refcnt++;
      release(&bcache.lock[bid]);
      acquiresleep(&b->lock);
      return b;
    }
  }

  // Not cached.
  // Recycle the least recently used (LRU) unused buffer.
  for (b = bcache.heads[bid].prev; b != &bcache.heads[bid]; b = b->prev)
  {
    if (b->refcnt == 0)
    {
      b->dev = dev;
      b->blockno = blockno;
      b->valid = 0;
      b->refcnt = 1;
      release(&bcache.lock[bid]);
      acquiresleep(&b->lock);
      return b;
    }
  }
  // 当bget()查找数据块未命中时，bget()可从其他哈希桶选择一个未被使用的缓存块，移入到当前的哈希桶链表中使用。 from instruction book
  for (int bkid = map(blockno+1); bkid != bid; bkid=map(bkid+1))
  {
    acquire(&bcache.lock[bkid]);
    for (b = bcache.heads[bkid].next; b != &bcache.heads[bkid]; b = b->next)
    {

      if (b->refcnt == 0)
      { // unused block
        b->valid = 0;
        b->refcnt = 1;
        b->blockno = blockno;
        b->dev = dev;
        b->prev->next = b->next;
        b->next->prev = b->prev; // fetch from ori list
        release(&bcache.lock[bkid]);
        b->next = bcache.heads[bid].next;
        b->prev = &bcache.heads[bid];
        
        bcache.heads[bid].next->prev = b;
        bcache.heads[bid].next = b;

        
        release(&bcache.lock[bid]);
        acquiresleep(&b->lock);
        return b;
      }
    }
    release(&bcache.lock[bkid]);
  }
  // release(&bcache.lock[bid]);

  panic("bget: no buffers");
}

// Return a locked buf with the contents of the indicated block.
struct buf *
bread(uint dev, uint blockno)
{
  struct buf *b;

  b = bget(dev, blockno);
  if (!b->valid)
  {
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}

// Write b's contents to disk.  Must be locked.
void bwrite(struct buf *b)
{
  if (!holdingsleep(&b->lock))
    panic("bwrite");
  virtio_disk_rw(b, 1);
}

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void brelse(struct buf *b)
{
  if (!holdingsleep(&b->lock))
  {
    panic("brelse");
  }

  releasesleep(&b->lock);//lock?

  // acquire(&bcache.lock);
  int bid = map(b->blockno);
  acquire(&bcache.lock[bid]);
  b->refcnt--;

  if (b->refcnt == 0)
  {
    // no one is waiting for it.
    b->next->prev = b->prev;
    b->prev->next = b->next;
    b->next = bcache.heads[bid].next;
    b->prev = &bcache.heads[bid];
    bcache.heads[bid].next->prev = b;
    bcache.heads[bid].next = b;
    // break;
  }
  release(&bcache.lock[bid]);
  // }
}

void bpin(struct buf *b)
{
  int bid = map(b->blockno);
  acquire(&bcache.lock[bid]);
  b->refcnt++;
  release(&bcache.lock[bid]);
}

void bunpin(struct buf *b)
{
  int bid = map(b->blockno);
  acquire(&bcache.lock[bid]);
  b->refcnt--;
  release(&bcache.lock[bid]);
}
