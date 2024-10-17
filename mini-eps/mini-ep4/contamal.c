#include <stdio.h>
#include <pthread.h>

#define NUM_THREADS 10
#define NUM_INCREMENTS 100000

int cont = 0;

void* increment(void* arg) {
    for (int i = 0; i < NUM_INCREMENTS; ++i) {
        cont++;
    }
    return NULL;
}

int main() {
    pthread_t threads[NUM_THREADS];

    for (int i = 0; i < NUM_THREADS; ++i) {
        pthread_create(&threads[i], NULL, increment, NULL);
    }

    for (int i = 0; i < NUM_THREADS; ++i) {
        pthread_join(threads[i], NULL);
    }

    printf("Contagem final: %d\n", cont);

    return 0;
}

