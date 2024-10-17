Para compilar:
gcc -pthread -Wall -o contamal contamal.c

Qual o problema deste código?
    contamal.c tem uma variável global, cont, e
chama 10 threads que incrementam cont 100000 
vezes, e no fim imprime cont.
    Uma implementação correta imprimiria '1000000',
mas isso provavelmente não vai acontecer com contamal.c.
    O problema é que o o incremento implementado
não é atômico. Ao processar "cont++;" o processador 
tem que fazer 3 coisas: ler cont, incrementar o 
valor, e escrever o valor incrementado. No inter-
valo em que uma thread está rodando o incremento,
alguma das outras 9 threads pode ler ou escrever
cont, o que torna o cálculo incorreto.

Como solucionar?
    Para resolver o problema, uma thread teria que 
terminar de rodar um incremento antes de qualquer
outra começar. 
    Isso é possível usando mutex,
também conhecidos como semáforos. Um mutex é um mecanismo
de sincronização que permite que uma parte do código seja 
executada por apenas uma thread simultaneamente.
    Então, podemos colocar antes do "cont++; um mutex lock,
e depois um mutex unlock, garantindo a corretude do incre-
mento, já que a variável não será alterada por outra thread 
atá a liberação do mutex.
