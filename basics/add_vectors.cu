#include <iostream>
#include <cuda_runtime.h>

__global__
void addVectorKernel(float* A, float* B, float* C, int n){
    int idx = threadIdx.x + blockDim.x * blockIdx.x;
    if(idx < n){
        C[idx] = A[idx] + B[idx];
    }
}

void vecAddition(float* A, float* B, float* C, int n){
    float *A_d, *B_d, *C_d;
    int size = n * sizeof(float)
    cudaMalloc((void**) &A_d, size)
    cudaMalloc((void**) &B_d, size)
    cudaMalloc((void**) &C_d, size)

    cudaMemcpy(A_d, A, size, cudaMemcpyHostToDevice);
    cudaMemcpy(B_d, B, size, cudaMemcpyHostToDevice);

    addVectorKernel<<<ceil(n/256.0, 256)>>>(A_d, B_d, C_d, n);

    cudaMemcpy(C, C_d, size, cudaMemcpyDeviceToHost);

    cudaFree(A_d)
    cudaFree(B_d)
    cudaFree(C_d)
}

int main(){
    int n = 1000;
    float *A_h = new float[n];
    float *B_h = new float[n];
    float *C_h = new float[n];

    for(int i=0;i<n;i++){
        A_h[i] = i;
        B_h[i] = i+10
    }
    vecAddition(A_h, B_h, C_h, n);
    std::count << C_h[1] << std::endl;
    return 0;
}