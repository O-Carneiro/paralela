#include <iostream>
#include <vector>
#include <cmath>

void leapFrog(){
    int n = 500;
    double nT, x0 = 0, t0 = 0,
    xF = 10, tF = 10, deltaX, deltaT, deltaTLeap;
    std::vector<double> u(n), v(n), a(n), x(n);
    
    deltaX = (xF - x0)/(n - 1); 
    deltaT = deltaX/2;
    nT = ((tF - t0)/deltaT) + 1;
    std::vector<double> tempos(nT);
    tempos[0] = 0;
    tempos[nT-1] = 10;
    for(int i = 0; i < n; i++) {
        x[i] = deltaX * i;
        u[i] = std::exp(-1*(x[i] - 5)*(x[i] - 5));
        v[i] = 0;
        a[i] = 0;
    }
    for(int i = 1; i < nT; i++) tempos[i] = i*deltaT;
    for(double t : tempos){
        if(t == t0) deltaTLeap = deltaT/2;
        else deltaTLeap = deltaT;
        for(int i = 1; i < n-1; i++){
            a[i] = (u[i-1] + u[i+1] - 2*u[i])/((deltaX)*(deltaX));
        }
        for(int i = 0; i < n; i++) v[i] = v[i] + (a[i] * deltaTLeap);
        for(int i = 0; i < n; i++) u[i] = u[i] + (v[i] * deltaT);
    }
    for(int i = (n/2) - 10; i <= (n/2)+10; i++)
        std::cout << '(' << x[i] << ',' << u[i] << ")\n";

}

int main(){
    leapFrog();
    return 0;
}
