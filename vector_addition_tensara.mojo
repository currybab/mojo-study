from gpu.host import DeviceContext
from gpu.id import block_dim, block_idx, thread_idx
from memory import UnsafePointer
from math import ceildiv

alias block_size = 64

fn vectorAdd(a: UnsafePointer[Float32], b: UnsafePointer[Float32], c: UnsafePointer[Float32], n: Int32):
    var idx = thread_idx.x + block_dim.x * block_idx.x
    if Int32(idx) > n:
        return
    c[idx] = a[idx] + b[idx]


# Note: d_input1, d_input2, d_output are all device pointers to float32 arrays
@export
fn solution(d_input1: UnsafePointer[Float32], d_input2: UnsafePointer[Float32], d_output: UnsafePointer[Float32], n: Int32) raises:
    ctx = DeviceContext()
    ctx.enqueue_function[vectorAdd](d_input1, d_input2, d_output, n, grid_dim=ceildiv(n, block_size), block_dim=block_size)
    ctx.synchronize()
    