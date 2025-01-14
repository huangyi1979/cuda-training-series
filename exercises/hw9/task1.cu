#include <cooperative_groups.h>
#include <stdio.h>
// using namespace cooperative_groups;
const int nTPB = 256;
__device__ int reduce(cooperative_groups::thread_group g, int *x, int val) {
  int lane = g.thread_rank();
  for (int i = g.size() / 2; i > 0; i /= 2) {
    x[lane] = val;
    g.sync();
    if (lane < i)
      val += x[lane + i];
    g.sync();
  }
  if (g.thread_rank() == 0)
    printf("group partial sum: %d\n", val);
  return val;
}

__global__ void my_reduce_kernel(int *data) {

  __shared__ int sdata[nTPB];
  // task 1a: create a proper thread block group below
  auto g1 = cooperative_groups::this_thread_block();
  size_t gindex = g1.group_index().x * nTPB + g1.thread_index().x;
  // task 1b: uncomment and create a proper 32-thread tile below,
  // using group g1 created above
  auto g2 = cooperative_groups::tiled_partition<32>(g1);
  // task 1c: uncomment and create a proper 16-thread tile below,
  // using group g2 created above
  auto g3 = cooperative_groups::tiled_partition<16>(g2);
  // for each task, adjust the group to point to the last group created above
  auto g = g3;
  // Make sure we send in the appropriate patch of shared memory
  int sdata_offset = (g1.thread_index().x / g.size()) * g.size();
  reduce(g, sdata + sdata_offset, data[gindex]);
}

int main() {

  int *data;
  cudaMallocManaged(&data, nTPB * sizeof(data[0]));
  for (int i = 0; i < nTPB; i++)
    data[i] = 1;
  my_reduce_kernel<<<1, nTPB>>>(data);
  cudaError_t err = cudaDeviceSynchronize();
  if (err != cudaSuccess)
    printf("cuda error: %s\n", cudaGetErrorString(err));
}
