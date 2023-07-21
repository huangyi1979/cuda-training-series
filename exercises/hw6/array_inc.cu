#include <cstdio>
#include <cstdlib>
// error checking macro
#define cudaCheckErrors(msg)                                                   \
  do {                                                                         \
    cudaError_t __err = cudaGetLastError();                                    \
    if (__err != cudaSuccess) {                                                \
      fprintf(stderr, "Fatal error: %s (%s at %s:%d)\n", msg,                  \
              cudaGetErrorString(__err), __FILE__, __LINE__);                  \
      fprintf(stderr, "*** FAILED - ABORTING\n");                              \
      exit(1);                                                                 \
    }                                                                          \
  } while (0)

__global__ void inc(int *array, size_t n) {
  size_t idx = threadIdx.x + blockDim.x * blockIdx.x;
  while (idx < n) {
    array[idx]++;
    idx += blockDim.x * gridDim.x; // grid-stride loop
  }
}

const size_t ds = 32ULL * 1024ULL * 1024ULL;

int main() {

  int *h_array;
  const auto size = ds * sizeof(h_array[0]);
  cudaMallocManaged(&h_array, size);
  cudaCheckErrors("cudaMallocManaged Error");
  memset(h_array, 0, size);
  cudaMemPrefetchAsync(h_array, size, 0);
  inc<<<256, 256>>>(h_array, ds);
  cudaCheckErrors("kernel launch error");
  cudaMemPrefetchAsync(h_array, size, cudaCpuDeviceId);
  cudaDeviceSynchronize();
  cudaCheckErrors("kernel execution error");
  for (int i = 0; i < ds; i++)
    if (h_array[i] != 1) {
      printf("mismatch at %d, was: %d, expected: %d\n", i, h_array[i], 1);
      return -1;
    }
  cudaFree(h_array);
  printf("success!\n");
  return 0;
}
