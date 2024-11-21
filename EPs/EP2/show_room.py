import numpy as np
import matplotlib.pyplot as plt

def genPNG(file):
    # Load heat data from file
    heat_data = np.loadtxt(f"{file}.txt")

    extent = [0, 10, 0, 10]

    # Plot heatmap
    plt.imshow(
        heat_data, cmap="hot", interpolation="nearest", extent=extent, origin="lower"
    )
    plt.colorbar(label="Temperature")
    plt.title("Heat Distribution")
    plt.xlabel("X Coordinate")
    plt.ylabel("Y Coordinate")
    plt.savefig(f'{file}.png')

if __name__ == "__main__":
    genPNG('device')
    genPNG('host')
