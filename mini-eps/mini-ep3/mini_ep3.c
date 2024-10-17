#include <stdio.h>
#include <stdlib.h>

int fibV[36];

void swap(int *i, int *j){
    int aux = *i;
    *i = *j;
    *j = aux;
}

void quicksort(int *arr, int low, int high) {
    if (low < high) {
        int pivot = arr[high];
        int i = low - 1;

        for (int j = low; j < high; j++) {
            if (arr[j] < pivot) {
                i++;
                swap(&arr[i], &arr[j]);
            }
        }
        swap(&arr[i + 1], &arr[high]);

        quicksort(arr, low, i);     
        quicksort(arr, i + 2, high);  
    }
}

void fibonacci() {
    for(int i = 2; i < 36; i++){
        fibV[i] = fibV[i-1] + fibV[i-2];
    }
}

int main() {
    fibV[0] = 0; fibV[1] = 1;//vetor com memoização pro fibonacci eficiente
    const int TAMANHO = 200; // Tamanho do vetor
    const int SEED = 42; // Semente para números aleatórios
    int vetor[TAMANHO];
    int soma = 0;

    // Inicializa o gerador de números aleatórios
    srand(SEED);

    // Preenche o vetor com números aleatórios entre 2^2 e (2^2 + 2^5) - 1
    for (int i = 0; i < TAMANHO; i++) {
        vetor[i] = (rand() % (1 << 5)) + (1 << 2);
    }

    // Ordena o vetor usando Slowsort
    quicksort(vetor, 0, TAMANHO - 1);

    // Calcula o Fibonacci para cada elemento e soma os pares
    fibonacci();
    for (int i = 0; i < TAMANHO; i++) {
        int fib = fibV[vetor[i]];
        if (fib % 2 == 0) {
            soma += fib;
        }
    }

    printf("Soma dos números de Fibonacci pares: %d\n", soma);
    return 0;
}
