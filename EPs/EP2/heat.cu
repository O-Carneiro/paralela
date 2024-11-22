#include <cuda_runtime.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <string.h>

#define WALL_TEMP 20.0
#define FIREPLACE_TEMP 100.0

#define FIREPLACE_START 3
#define FIREPLACE_END 7
#define ROOM_SIZE 10

int threads_per_block;
int blocks_in_grid;

typedef struct {
	int blockX;
	int blockY;
	int gridX;
	int gridY;
} cudaData;

void initialize(double **h, int n)
{
    int fireplace_start = (FIREPLACE_START * n) / ROOM_SIZE;
    int fireplace_end = (FIREPLACE_END * n) / ROOM_SIZE;

    for (int i = 0; i < n; i++)
    {
        for (int j = 0; j < n; j++)
        {
            if (i == 0 || i == n - 1 || j == 0 || j == n - 1)
            {
                h[i][j] = (i == n - 1 && j >= fireplace_start && j <= fireplace_end) ? FIREPLACE_TEMP : WALL_TEMP;
            }
            else
            {
                h[i][j] = 0.0;
            }
        }
    }
}

void jacobi_iteration_host(double **h, double **g, int n, int iter_limit)
{
    for (int iter = 0; iter < iter_limit; iter++)
    {
        for (int i = 1; i < n - 1; i++)
        {
            for (int j = 1; j < n - 1; j++)
            {
                g[i][j] = 0.25 * (h[i - 1][j] + h[i + 1][j] + h[i][j - 1] + h[i][j + 1]);
            }
        }
        for (int i = 1; i < n - 1; i++)
        {
            for (int j = 1; j < n - 1; j++)
            {
                h[i][j] = g[i][j];
            }
        }
    }
}

double calculate_elapsed_time(struct timespec start, struct timespec end)
{
    double start_sec = (double)start.tv_sec * 1e9 + (double)start.tv_nsec;
    double end_sec = (double)end.tv_sec * 1e9 + (double)end.tv_nsec;
    return (end_sec - start_sec) / 1e9;
}

void save_to_file(double **h, int n, char *filename)
{
    FILE *file = fopen(filename, "w");
    for (int i = 0; i < n; i++)
    {
        for (int j = 0; j < n; j++)
        {
            fprintf(file, "%lf ", h[i][j]);
        }
        fprintf(file, "\n");
    }
    fclose(file);
}

__global__ void jacobi_kernel(double *d_h, double *d_g, int n) {
    int i = blockIdx.y * blockDim.y + threadIdx.y;
    int j = blockIdx.x * blockDim.x + threadIdx.x;
    if (i > 0 && i < n - 1 && j > 0 && j < n - 1) {
        d_g[i * n + j] = 0.25 * (d_h[(i - 1) * n + j] + d_h[(i + 1) * n + j] +
                                 d_h[i * n + (j - 1)] + d_h[i * n + (j + 1)]);
    }

}

void jacobi_iteration_cu(double **h, double **g, int n, int iter_limit, cudaData arg) {
    double *h_flat = (double *)malloc(n * n * sizeof(double));
    double *g_flat = (double *)malloc(n * n * sizeof(double));
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            h_flat[i * n + j] = h[i][j];
            g_flat[i * n + j] = g[i][j];
        }
    }

    double *d_h, *d_g;
    cudaMalloc(&d_h, n * n * sizeof(double));
    cudaMalloc(&d_g, n * n * sizeof(double));
    cudaMemcpy(d_h, h_flat, n * n * sizeof(double), cudaMemcpyHostToDevice);

	dim3 blockDim(arg.blockX, arg.blockY);
	dim3 gridDim(arg.gridX, arg.gridY);

    for (int iter = 0; iter < iter_limit; iter++) {
        jacobi_kernel<<<gridDim, blockDim>>>(d_h, d_g, n);
        cudaDeviceSynchronize();
        double *temp = d_h;
        d_h = d_g;
        d_g = temp;
    }
    cudaMemcpy(h_flat, d_h, n * n * sizeof(double), cudaMemcpyDeviceToHost);
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            h[i][j] = h_flat[i * n + j];
        }
    }
    free(h_flat);
    free(g_flat);
    cudaFree(d_h);
    cudaFree(d_g);
}

int main(int argc, char *argv[])
{
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

    // Validate block size
    if (block_x <= 0 || block_y <= 0) {
        fprintf(stderr, "Block dimensions must be positive integers.\n");
        return 1;
    }

    // Validate grid size
    if (grid_x <= 0 || grid_y <= 0) {
        fprintf(stderr, "Grid dimensions must be positive integers.\n");
        return 1;
    }

    int total_threads = grid_x * grid_y * block_x * block_y;
    if (total_threads < n*n) {
        fprintf(stderr, "Warning: Not enough threads to cover the problem size.\n");
        return 1;
    }
	cudaData arg;
	arg.blockX = block_x;
	arg.blockY = block_y;
	arg.gridX = grid_x;
	arg.gridY = grid_y;

    double **h = (double **)malloc(n * sizeof(double *));
    double **g = (double **)malloc(n * sizeof(double *));
    if (h == NULL || g == NULL)
    {
        fprintf(stderr, "Erro ao alocar memória para h ou g\n");
        exit(EXIT_FAILURE);
    }

    for (int i = 0; i < n; i++)
    {
        h[i] = (double *)malloc(n * sizeof(double));
        g[i] = (double *)malloc(n * sizeof(double));
        if (h[i] == NULL || g[i] == NULL)
        {
            fprintf(stderr, "Erro ao alocar memória para h[%d] ou g[%d]\n", i, i);
            exit(EXIT_FAILURE);
        }
    }

    struct timespec start, end;
    initialize(h, n);
    char filename[256] = "device.txt";

    clock_gettime(CLOCK_MONOTONIC, &start);
    jacobi_iteration_cu(h, g, n, iter_limit, arg);
    clock_gettime(CLOCK_MONOTONIC, &end);
    save_to_file(h, n, filename);

    double elapsed_time_d = calculate_elapsed_time(start, end);
    printf("%.9f,", elapsed_time_d);

    initialize(h, n);

    strcpy(filename, "host.txt");

    clock_gettime(CLOCK_MONOTONIC, &start);
    jacobi_iteration_host(h, g, n, iter_limit);
    clock_gettime(CLOCK_MONOTONIC, &end);
    save_to_file(h, n, filename);

    double elapsed_time_h = calculate_elapsed_time(start, end);
    printf("%.9f,", elapsed_time_h);
	printf("%.9f\n", elapsed_time_h/elapsed_time_d);

    for (int i = 0; i < n; i++)
    {
        free(h[i]);
        free(g[i]);
    }
    free(h);
    free(g);

    return 0;
}
