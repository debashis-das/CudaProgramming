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