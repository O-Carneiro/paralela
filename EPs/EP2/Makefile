NVCC = /usr/bin/nvcc
CUDAPATH = /usr/local/cuda

NVCCFLAGS = -I$(CUDAPATH)/include
LFLAGS = -L$(CUDAPATH)/lib64 -lcuda -lcudart -lm
TARGETS = heat heatCu heatCu2
CC = gcc
CFLAGS = -Wall -Wextra -O2

all: $(TARGETS)

heat:
	$(CC) $(CFLAGS) $(TARGET) -o heat heat.c

heatCu:
	$(NVCC) $(NVCCFLAGS) $(LFLAGS) -o heatCu heat.cu

heatCu2:
	$(NVCC) $(NVCCFLAGS) $(LFLAGS) -o heatCu2 heat2.cu

clean:
	rm -f $(TARGET) *.png *.txt $(TARGETS)
