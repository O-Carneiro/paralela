TARGETS = sequential_julia
LIBS = -lm
CC = gcc
CFLAGS = -Wall -Wextra -O2

all: $(TARGETS)

sequential_julia:
	$(CC) $(CFLAGS) $(TARGET) -o sequential_julia sequential_julia.c $(LIBS) 

clean:
	rm -f $(TARGETS) *.bmp
