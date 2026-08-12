#include <iostream>
#include <cuda_runtime.h>

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

__global__
void colorToGrayScaleKernel(unsigned char* PicIn, unsigned char* PicOut, int width, int height, int channels){
    // without channels
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int row = idx / width;
    int col = idx % width;
    if (row < height && col < width){
        int grayScaleIdx = row*width + col;
        int idxWithChannels = grayScaleIdx * channels;
        unsigned char r = PicIn[idxWithChannels];
        unsigned char g = PicIn[idxWithChannels+1];
        unsigned char b = Picin[idxWithChannels+2];
        // based on 0.21*red + 0.71*green + 0.07*blue
        PicOut[grayScaleIdx] = (unsigned char) 0.21*r + 0.71*g + 0.07*b;
    }
}

void colorToGrayScaleConverter(unsigned char* PicIn_h, unsigned char* PicOut_h, int width, int height, int channels){
    unsigned char* PicIn_d, PicOut_d;
    int picSizeIn = width * height * channels * sizeof(char);
    int picSizeOut = width * height * sizeof(char);
    cudaMalloc((void**) &PicIn_d, picSizeIn);
    cudaMalloc((void**) &PicOut_d, picSizeOut);

    cudaMemcpy(PicIn_d, PicIn_h, picSizeIn, cudaMemcpyHostToDevice);
    colorToGrayScaleKernel<<<ceil((width*height)/256.0), 256>>>(PicIn_d, PicOut_d, width, height, channels);
    cudaMemcpu(PicOut_h, PicOut_d, picSizeOut, cudaMemcpuDeviceToHost);

    cudaFree(PicIn_d);
    cudaFree(PicOut_d);
}

int main(){
    int width, height, channels;
    unsigned char* PicIn_h = stbi_load(
        "image.jpg",
        &width,
        &height,
        &channels,
        0
    );
    if(!PicIn_h){
        std::cerr << "Failed to load image\n";
        return 1;
    }
    std::cout << "Width : " << width << ", Height : " << height << ", Channels : " << channels << '\n';

    unsigned char* PicOut_h = new char[height][width];
    colorToGrayScaleConverter(PicIn_h, PicOut_h, width, height, channels);
}

