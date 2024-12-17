TARGETS = 1D_parallel_julia
LIBS = -lm
CC = gcc
CFLAGS = -Wall -Wextra -O2

all: $(TARGETS)

1D_parallel_julia:
	$(CC) $(CFLAGS) $@ -o $@.c $(LIBS) 

clean:
	rm -f $(TARGETS) *.bmp
