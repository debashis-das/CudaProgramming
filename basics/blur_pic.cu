#include <iostream>
#include <cuda_runtime.h>

#define STB_IMAGE_IMPLEMENTATION
#include "../include/stb_image.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "../include/stb_image_write.h"

__global__
void blurPicKernel(unsigned char* PicIn, unsigned char* PicOut, int width, int height, int channels, int blurSize){
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int row = idx / width;
    int col = idx % width;
    if (row < height && col < width){
        int currentIndex = row*width + col;
        int count = 0;
        int *perChannel = new int[channels]();
        for(int r=-blurSize; r<blurSize+1; r++){
            for(int c=-blurSize; c<blurSize+1; c++){
                int current_row = row+r;
                int current_col = col+c;
                if((current_row >= 0 && current_row < height) && (current_col >=0 && current_col < width)){
                    int currentIdx = (current_row*width + current_col)*channels;
                    for(int i=0; i<channels; i++){
                        perChannel[i] += PicIn[currentIdx+i];
                    }
                    count += 1;
                }
            }
        }
        int idxPerChannel = currentIndex*channels;
        for(int i=0;i<channels;i++){
            PicOut[idxPerChannel+i] = (unsigned char)((float)perChannel[i]/count);
        }
    }
}

void blurPic(unsigned char* PicIn_h, unsigned char* PicOut_h, int width, int height, int channels, int blurSize){
    unsigned char *PicIn_d, *PicOut_d;
    int picSizeIn = width * height * channels * sizeof(char);
    int picSizeOut = width * height * channels * sizeof(char);
    cudaMalloc((void**) &PicIn_d, picSizeIn);
    cudaMalloc((void**) &PicOut_d, picSizeOut);

    cudaMemcpy(PicIn_d, PicIn_h, picSizeIn, cudaMemcpyHostToDevice);
    blurPicKernel<<<ceil((width*height)/256.0), 256>>>(PicIn_d, PicOut_d, width, height, channels, blurSize);
    cudaMemcpy(PicOut_h, PicOut_d, picSizeOut, cudaMemcpyDeviceToHost);

    cudaFree(PicIn_d);
    cudaFree(PicOut_d);
}

int main(){
    int width = 4032 , height = 3024, channels = 3;
    int blurSize = 1;
    unsigned char* PicIn_h = stbi_load(
        "../images/image.jpg",
        &width,
        &height,
        &channels,
        0
    );
    if(!PicIn_h){
        std::cerr << "Failed to load image\n";
        return 1;
    }
    unsigned char* PicOut_h = new unsigned char[width*height*channels];
    blurPic(PicIn_h, PicOut_h, width, height, channels, blurSize);
    int success = stbi_write_png(
        "../images/blur.png",
        width,
        height,
        channels,
        PicOut_h,
        width * channels
    );
    if (!success) {
        std::cerr << "Failed to save image\n";
    } else {
        std::cout << "Blur image saved successfully\n";
    }
    delete[] PicOut_h;
    stbi_image_free(PicIn_h);

    return 0;
}

