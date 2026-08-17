#include <iostream>
#include <stdexcept>
#include <random>
#include <cuda_runtime.h>

__global__
void matmulKernel(float* A, float* B, float* C, int A_row, int B_cols, int same_dim){
    int row = threadIdx.x + blockDim.x * blockIdx.x;
    int col = threadIdx.y + blockDim.y * blockIdx.y;
    if(row < A_row && col < B_cols){
        float sum = 0.0f;
        for(int i=0;i<same_dim;i++){
            sum += A[row*same_dim+i] * B[i*B_cols + col]; 
        }
        C[row*B_cols+col] = sum;
    }
}

void matrixMultiplication(float *A, float *B, float *C, int A_row, int A_col, int B_row, int B_col, int a_block_size, int b_block_size){
    if(A_col != B_row){
        throw std::runtime_error("A's columns is not same as B's row");
    }
    float *A_d, *B_d, *C_d;
    int size_A = A_row*A_col*sizeof(float);
    int size_B = B_row*B_col*sizeof(float);
    int size_C = A_row*B_col*sizeof(float);
    cudaMalloc((void**) &A_d, size_A);
    cudaMalloc((void**) &B_d, size_B);
    cudaMalloc((void**) &C_d, size_C);

    cudaMemcpy(A_d, A, size_A, cudaMemcpyHostToDevice);
    cudaMemcpy(B_d, B, size_B, cudaMemcpyHostToDevice);

    dim3 dimGrid(ceil((A_row+a_block_size-1)/a_block_size), ceil(B_col+b_block_size-1/b_block_size), 1);
    dim3 dimBlock(a_block_size, b_block_size, 1);
    matmulKernel<<<dimGrid, dimBlock>>>(A_d, B_d, C_d, A_row, B_col, A_col);

    // Error handline
    cudaError_t err = cudaGetLastError();

    if (err != cudaSuccess) {
        throw std::runtime_error(cudaGetErrorString(err));
    }
    
    cudaMemcpy(C, C_d, size_C, cudaMemcpyDeviceToHost);

    cudaFree(A_d);
    cudaFree(B_d);
    cudaFree(C_d);
}

int main(){
    int A_row = 1000, A_col = 500, B_row = 500, B_col = 2000;
    float *A_h = new float[A_row * A_col];
    float *B_h = new float[B_row * B_col];
    float *C_h = new float[A_row * B_col];

    std::random_device rd;
    std::mt19937 gen(rd());
    std::normal_distribution<float> dist(0.0f, 1.0f);

    for (int i = 0; i < A_row; i++) {
        for (int j = 0; j < A_col; j++) {
            A_h[i*A_col+j] = dist(gen);
        }
    }

    for (int i = 0; i < B_row; i++) {
        for (int j = 0; j < B_col; j++) {
            B_h[i*B_col+j] = dist(gen);
        }
    }
    try{
        int a_block_size = 32, b_block_size=32;
        matrixMultiplication(A_h, B_h, C_h, A_row, A_col, B_row, B_col, a_block_size, b_block_size);
        std::cout << "Matrix multplication success"<< "\n";
        for (int i = 0; i < 10; i++) {
            for (int j = 0; j < 10; j++) {
                std::cout << C_h[i*B_col + j] << " ";
            }
            std::cout << "\n";
        }
    }
    catch (const std::exception& e){
        std::cout << "Error: " << e.what() << "\n";
    }
    float *matrix_verify_h = new float[A_row * B_col]();
    for (int i = 0; i < A_row; i++) {
        for (int j = 0; j < B_col; j++) {
            for(int k=0; k<A_col; k++){
                matrix_verify_h[i*B_col+j] += A_h[i*A_col+k] * B_h[k*B_col+j];
            }
        }
    }
    std::cout << "----- Matrix Verify by difference -----"<< "\n";
    for (int i = 0; i < 10; i++) {
        for (int j = 0; j < 10; j++) {
            std::cout << C_h[i*B_col + j] - matrix_verify_h[i*B_col + j] << " ";
        }
        std::cout << "\n";
    }
    delete[] A_h;
    delete[] B_h;
    delete[] C_h;
    return 0;
}