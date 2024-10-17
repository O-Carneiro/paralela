#include <iostream>
#include <vector>
#include <utility>
#include <pthread.h>

#define SAPO true
#define RA false
//Os sapinhos e rãs pulam num laguinho : )
std::vector<int> laguinho;
int noJumpCount = 0;
int max = 0;
int n;
std::vector<pthread_t> tids;
pthread_mutex_t pulaMut;
pthread_barrier_t represa;

bool pulaAnfibioPula(bool especie, int &pos){
    int offset=1;
    int jumpPos = 0;
    if(!especie) offset*=-1;
    if((especie && pos + offset < 2*n+1)||
       (!especie && pos + offset >= 0)){
        if(laguinho[pos + offset] == -1){
            jumpPos = pos + offset; 
            laguinho[jumpPos] = especie;
            laguinho[pos] = -1;
            pos = jumpPos;
            return true;
        }
    }
    if((especie && pos + 2*offset < 2*n+1)||
       (!especie && pos + 2*offset >= 0)){
        if(laguinho[pos + 2*offset] == -1){
            jumpPos = pos + 2*offset; 
            laguinho[jumpPos] = especie;
            laguinho[pos] = -1;
            pos = jumpPos;
            return true;
        }
    }
    return false;
}

void *anfibio(void *arg){
    std::pair<bool,int> *args = (std::pair<bool,int> *)arg; 
    bool especie = args->first;
    int pos = args->second;
    delete args;
    laguinho[pos] = especie;
    pthread_barrier_wait(&represa);
    //Pula, sapinho/rãzinha, pula!
    while(true){
        if(noJumpCount >= max) break;
        pthread_mutex_lock(&pulaMut);
        bool pulou; 
        pulou = pulaAnfibioPula(especie, pos);
        if(!pulou) noJumpCount++;
        else noJumpCount = 0;
        pthread_mutex_unlock(&pulaMut);
    }
    return nullptr;
}

int experimento(){
    //se (1000*o número de animais) pulos foram impossíveis, assumimos deadlock.
    noJumpCount = 0;
    max = 1000 * n;
    laguinho.clear();
    laguinho.resize(2*n+1);
    laguinho[n] = -1; //espaço vazio.
    tids.clear();
    tids.resize(2*n);

    //Vamos dar a luz aos anfíbios.
    for(int i = 0; i < n; i++){
        std::pair<bool,int> *argSapo = new std::pair<bool,int>{SAPO,i};
        std::pair<bool,int> *argRa = new std::pair<bool,int>{RA,2*n-i};
        if((pthread_create(&tids[i], NULL, anfibio, (void *)argSapo) != 0))
            perror("Falha ao criar thread.");
        if((pthread_create(&tids[2*n-1-i], NULL, anfibio, (void *)argRa) != 0))
            perror("Falha ao criar thread.");
    }
    //Agora esperamos pela sua morte inevitável.
    for(int i = 0; i < 2*n; i++){
        if(pthread_join(tids[i],NULL) != 0){
            perror("Falha ao dar join nas threads.");
        }
    }
    // std::cout << "deadlock com " << noJumpCount << " pulos impossiveis.\n";
    bool resolveu = true;
    if(laguinho[n] == -1){
        for(int i = 0; i < n; i++){
            if(laguinho[i] != RA && laguinho[2*n-i] != SAPO){
                resolveu = false;
            }
        } 
    } 
    else resolveu = false;

    if (resolveu){
        for(auto i: laguinho)std::cout << ((i>=0)?((i)? "SAPO" : "RA") : "_") << ' ';
        std::cout << '\n';
    }
    return resolveu;
}

int main(){
    pthread_mutex_init(&pulaMut, NULL);
    int times;
    std::cout << "Quantos sapos/rãs?";
    std::cin >> n;
    pthread_barrier_init(&represa, NULL, 2*n);
    std::cout << "Quantas vezes?";
    std::cin >> times;
    int solved = 0;
    while(times--) solved+=experimento();
    std::cout << "foi resolvido " << solved << " vezes.\n";

    pthread_mutex_destroy(&pulaMut);
    //que a água volte a fluir
    pthread_barrier_destroy(&represa);
    return 0;
}
