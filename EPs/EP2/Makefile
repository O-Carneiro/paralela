NVCC = /usr/local/cuda/bin/nvcc
CUDAPATH = /usr/local/cuda

NVCCFLAGS = -I$(CUDAPATH)/include
LFLAGS = -L$(CUDAPATH)/lib64 -lcuda -lcudart -lm
TARGET = heat
CC = gcc
CFLAGS = -Wall -Wextra -O2

all: $(TARGET)

$(TARGET): heat.o
	$(CC) $(CFLAGS) -o $(TARGET) heat.o
	$(NVCC) $(NVCCFLAGS) $(LFLAGS) -o heatCu heat.cu

heat.o: heat.c
	$(CC) $(CFLAGS) -c heat.c

clean:
	rm -f $(TARGET) heat.o *.png heatCu *.txt
