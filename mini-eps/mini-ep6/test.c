/* Aqui é onde os testes são implementados */

#include "matrix.h"
#include "time_extra.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Se o seu processador tiver pouco cache (muito lento), talvez seja prático
 * diminuir esse número. Use uma pot. de 2
 */
#define ITERACOES 100
#define N 2048

int main()
{
    long long exec_time = 0;
    long long total_time[3] = {0,0,0};
    long long maximo[3] = {0,0,0};
    long long minimo[3] = {1e9,1e9,1e9};
    int nIterações = ITERACOES;
    double *restrict A = aligned_alloc(8, N*N*sizeof(*A));
    double *restrict B = aligned_alloc(8, N*N*sizeof(*B));
    double *restrict C = aligned_alloc(8, N*N*sizeof(*C));
    double *restrict D = aligned_alloc(8, N*N*sizeof(*D));
    double *restrict res[3] = {C, D, D};

    struct timeval t[3];
	struct timeval t1, t2;
    int i;

    srand(1337);
    for(int j = 0; j < ITERACOES; j++){
        matrix_fill_rand(N, A);
        matrix_fill_rand(N, B);
        FOR_EACH_DGEMM(i)
        {
            memset(res[i], 0, N*N*sizeof(*res[i]));
            gettimeofday(&t1, NULL);
            matrix_which_dgemm(i, N, res[i], A, B);
            gettimeofday(&t2, NULL);

            timeval_subtract(&t[i], &t2, &t1);

            exec_time = t[i].tv_sec * 1000000L + t[i].tv_usec;
            if(exec_time < minimo[i]) minimo[i] = exec_time;
            if(exec_time > maximo[i]) maximo[i] = exec_time;
            total_time[i] += exec_time;

            printf("%lu.%06lus\n",
                    t[i].tv_sec,
                    t[i].tv_usec
            );
        }
    }

    for(int i = 0; i < 3; i++) {
        double avg_time = total_time[i]/(double)nIterações;
        printf("dgemm_%d:\n", i);
        printf("Tempo médio: %.06f\n", avg_time/1000000.0);
        printf("Tempo maximo: %.06f\n", maximo[i]/1000000.0);
        printf("Tempo minimo: %.06f\n", minimo[i]/1000000.0);

    }

    free(A);
    free(B);
    free(C);
    free(D);
}
