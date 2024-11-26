#include <cuda_runtime.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <string.h>

#define WALL_TEMP 20.0
#define FIREPLACE_TEMP 100.0
#define BODY_TEMP 37.0 // Temperatura do corpo
#define FIREPLACE_START 3
#define FIREPLACE_END 7
#define ROOM_SIZE 10

typedef struct {
    int blockX;
    int blockY;
    int gridX;
    int gridY;
} cudaData;

void initialize(double **matrix, int n, int body_start, int body_end) {
    int fireplace_start = (FIREPLACE_START * n) / ROOM_SIZE;
    int fireplace_end = (FIREPLACE_END * n) / ROOM_SIZE;

    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            if (i == 0 || i == n - 1 || j == 0 || j == n - 1) {
                matrix[i][j] = (i == n - 1 && j >= fireplace_start && j <= fireplace_end) ? FIREPLACE_TEMP : WALL_TEMP;
            } else if (i >= body_start && i <= body_end && j >= body_start && j <= body_end) {
                matrix[i][j] = BODY_TEMP;
            } else {
                matrix[i][j] = 0.0;
            }
        }
    }
}

void jacobi_iteration_host(double **h, double **g, int n, int iter_limit, int body_start, int body_end) {
    for (int iter = 0; iter < iter_limit; iter++) {
        for (int i = 1; i < n - 1; i++) {
            for (int j = 1; j < n - 1; j++) {
                if (!(i >= body_start && i <= body_end && j >= body_start && j <= body_end)) {
                    g[i][j] = 0.25 * (h[i - 1][j] + h[i + 1][j] + h[i][j - 1] + h[i][j + 1]);
                }
            }
        }
        for (int i = 1; i < n - 1; i++) {
            for (int j = 1; j < n - 1; j++) {
                if (!(i >= body_start && i <= body_end && j >= body_start && j <= body_end)) {
                    h[i][j] = g[i][j];
                }
            }
        }
    }
}

__global__ void jacobi_kernel(double *d_h, double *d_g, int n, int body_start, int body_end) {
    int i = blockIdx.y * blockDim.y + threadIdx.y + 1;
    int j = blockIdx.x * blockDim.x + threadIdx.x + 1;
    if (i > 0 && i < n - 1 && j > 0 && j < n - 1) {
        if (!(i >= body_start && i <= body_end && j >= body_start && j <= body_end)) {
            d_g[i * n + j] = 0.25 * (d_h[(i - 1) * n + j] + d_h[(i + 1) * n + j] +
                                     d_h[i * n + (j - 1)] + d_h[i * n + (j + 1)]);
        }
    }
}

__global__ void g_to_h(double *d_h, double *d_g, int n, int body_start, int body_end) {
    int i = blockIdx.y * blockDim.y + threadIdx.y + 1;
    int j = blockIdx.x * blockDim.x + threadIdx.x + 1;
    if (i > 0 && i < n - 1 && j > 0 && j < n - 1) {
        if (!(i >= body_start && i <= body_end && j >= body_start && j <= body_end)) {
            d_h[i * n + j] = d_g[i * n + j];
        }
    }
}

void jacobi_iteration_cu(double **h, double **g, int n, int iter_limit, cudaData arg, int body_start, int body_end) {
    double *h_flat = (double *)malloc(n * n * sizeof(double));
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            h_flat[i * n + j] = h[i][j];
        }
    }

    double *d_h, *d_g;
    cudaMalloc(&d_h, n * n * sizeof(double));
    cudaMalloc(&d_g, n * n * sizeof(double));

    // Create CUDA events for timing
    cudaEvent_t start, stop;
    float elapsedTime;

    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    // Transfer data to device
    cudaEventRecord(start, 0);
    cudaMemcpy(d_h, h_flat, n * n * sizeof(double), cudaMemcpyHostToDevice);
    cudaEventRecord(stop, 0);
    cudaEventSynchronize(stop);
    cudaEventElapsedTime(&elapsedTime, start, stop);
    printf("Data transfer to device: %.2f ms\n", elapsedTime);

    dim3 blockDim(arg.blockX, arg.blockY);
    dim3 gridDim(arg.gridX, arg.gridY);

    // Run Jacobi kernel
    cudaEventRecord(start, 0);
    for (int iter = 0; iter < iter_limit; iter++) {
        jacobi_kernel<<<gridDim, blockDim>>>(d_h, d_g, n, body_start, body_end);
        cudaDeviceSynchronize();
        g_to_h<<<gridDim, blockDim>>>(d_h, d_g, n, body_start, body_end);
        cudaDeviceSynchronize();
    }
    cudaEventRecord(stop, 0);
    cudaEventSynchronize(stop);
    cudaEventElapsedTime(&elapsedTime, start, stop);
    printf("Kernel execution: %.2f ms\n", elapsedTime);

    // Transfer data back to host
    cudaEventRecord(start, 0);
    cudaMemcpy(h_flat, d_h, n * n * sizeof(double), cudaMemcpyDeviceToHost);
    cudaEventRecord(stop, 0);
    cudaEventSynchronize(stop);
    cudaEventElapsedTime(&elapsedTime, start, stop);
    printf("Data transfer to host: %.2f ms\n", elapsedTime);

    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            h[i][j] = h_flat[i * n + j];
        }
    }

    free(h_flat);
    cudaFree(d_h);
    cudaFree(d_g);

    cudaEventDestroy(start);
    cudaEventDestroy(stop);
}

bool compare_results(double **host_result, double **device_result, int n, double tolerance) {
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            if (fabs(host_result[i][j] - device_result[i][j]) > tolerance) {
                printf("Mismatch at (%d, %d): host = %lf, device = %lf\n", i, j, host_result[i][j], device_result[i][j]);
                return false;
            }
        }
    }
    return true;
}

double calculate_elapsed_time(struct timespec start, struct timespec end) {
    double start_sec = (double)start.tv_sec * 1e9 + (double)start.tv_nsec;
    double end_sec = (double)end.tv_sec * 1e9 + (double)end.tv_nsec;
    return (end_sec - start_sec) / 1e9;
}

void save_to_file(double **matrix, int n, const char *filename) {
    FILE *file = fopen(filename, "w");
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            fprintf(file, "%lf ", matrix[i][j]);
        }
        fprintf(file, "\n");
    }
    fclose(file);
}

int main(int argc, char *argv[]) {
    if (argc < 7) {
        fprintf(stderr, "Usage: %s <number of points> <iteration limit> <block_x> <block_y> <grid_x> <grid_y>\n", argv[0]);
        return 1;
    }

    int n = atoi(argv[1]);
    int iter_limit = atoi(argv[2]);
    int block_x = atoi(argv[3]);
    int block_y = atoi(argv[4]);
    int grid_x = atoi(argv[5]);
    int grid_y = atoi(argv[6]);

    // Validate block and grid sizes
    if (block_x <= 0 || block_y <= 0 || grid_x <= 0 || grid_y <= 0) {
        fprintf(stderr, "Block and grid dimensions must be positive integers.\n");
        return 1;
    }

    // Define the body hot area
    int body_start = n / 4;
    int body_end = n / 4 + n / 10;

    double **h_host = (double **)malloc(n * sizeof(double *));
    double **g_host = (double **)malloc(n * sizeof(double *));
    double **h_device = (double **)malloc(n * sizeof(double *));
    for (int i = 0; i < n; i++) {
        h_host[i] = (double *)malloc(n * sizeof(double));
        g_host[i] = (double *)malloc(n * sizeof(double));
        h_device[i] = (double *)malloc(n * sizeof(double));
        if (!h_host[i] || !g_host[i] || !h_device[i]) {
            fprintf(stderr, "Error allocating memory for matrices\n");
            exit(EXIT_FAILURE);
        }
    }

    cudaData arg = { block_x, block_y, grid_x, grid_y };

    struct timespec start, end;
    initialize(h_host, n, body_start, body_end);
    initialize(h_device, n, body_start, body_end);

    // GPU computation
    clock_gettime(CLOCK_MONOTONIC, &start);
    jacobi_iteration_cu(h_device, g_host, n, iter_limit, arg, body_start, body_end);
    clock_gettime(CLOCK_MONOTONIC, &end);
    double elapsed_time_d = calculate_elapsed_time(start, end);
    printf("GPU Total time: %.9f seconds\n", elapsed_time_d);
    save_to_file(h_device, n, "device.txt");

    // CPU computation
    clock_gettime(CLOCK_MONOTONIC, &start);
    jacobi_iteration_host(h_host, g_host, n, iter_limit, body_start, body_end);
    clock_gettime(CLOCK_MONOTONIC, &end);
    double elapsed_time_h = calculate_elapsed_time(start, end);
    printf("CPU Total time: %.9f seconds\n", elapsed_time_h);
    save_to_file(h_host, n, "host.txt");

    // Compare results
    if (compare_results(h_host, h_device, n, 1e-6)) {
        printf("The results match within the tolerance.\n");
    } else {
        printf("The results do not match!\n");
    }

    printf("Speedup (CPU/GPU): %.2f\n", elapsed_time_h / elapsed_time_d);

    for (int i = 0; i < n; i++) {
        free(h_host[i]);
        free(g_host[i]);
        free(h_device[i]);
    }
    free(h_host);
    free(g_host);
    free(h_device);

    return 0;
}
