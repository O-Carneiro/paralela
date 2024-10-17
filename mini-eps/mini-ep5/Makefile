CXX = g++
CXXFLAGS = -Wall -pthread

# Source and executable names
SRC = frogpuzzle.cpp
EXEC = frogpuzzle

# Target to compile and run
all: $(EXEC)

$(EXEC): $(SRC)
	$(CXX) $(CXXFLAGS) -o $(EXEC) $(SRC)

# Run the program after compiling
run: $(EXEC)
	./$(EXEC)

# Clean up the compiled binary
clean:
	rm -f $(EXEC)
