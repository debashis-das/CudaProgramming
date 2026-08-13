# CudaProgramming

Default way of complilation
```
nvcc add_vectors.cu -o add_vectors
```

Nvidia compilation on sm_75
```
nvcc -arch=sm_75 add_vectors.cu -o add_vectors
```

Nvidia compilier smi list for complilations
```
nvcc --list-gpu-code
```

For profiling the kernel
```
ncu ./add_vectors
```


Commands for external libraries

install opencv

```
apt-get update -qq
apt-get install -y libopencv-dev
```

include opencv

```
nvcc -I/usr/include/opencv4 color_to_grayscale.cu -o color_to_grayscale \
    $(pkg-config --cflags --libs opencv4)
```