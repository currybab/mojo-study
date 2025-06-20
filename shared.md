# 공유 메모리(shared memory)를 할당하는 방법

```
shared = stack_allocation[
    TPB, # Threads Per Block
    Scalar[dtype], # 저장될 타입
    address_space = AddressSpace.SHARED, # 공유 메모리
]()

shared = LayoutTensorBuild[dtype]().row_major[TPB]().shared().alloc() # Allocate shared memory using tensor builder
```

## Memory hierarchy
- Global memory: a and output arrays (slow, visible to all blocks)
- Shared memory: shared array (fast, thread-block local)

## Thread coordination
- barrier() : Wait for all loads

## Index mapping
- Global index: block_dim.x * block_idx.x + thread_idx.x
- Local index: thread_idx.x for shared memory access

## Memory access pattern
- Load: Global → Shared (coalesced reads of 1s)
- Sync: barrier() ensures all loads complete
- Process: Add 10 to shared values
- Store: Write 11s back to global memory

## optimizes performance through: 
- Minimal global memory access
- Fast shared memory neighbor lookups
- Clean boundary handling
- Efficient memory coalescing
