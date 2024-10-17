import math

n = 500
x0 = t0 = 0
xF = tF = 10
u = [0.0]*n
v = [0.0]*n
a = [0.0]*n
x = [0.0]*n

deltaX = (xF - x0)/(n - 1)
deltaT = deltaX/2;
nT = int(((tF - t0)/deltaT) + 1)
tempos = [0.0]*int(nT)

tempos[0] = 0
tempos[nT-1] = 10
for i in range(1,nT): tempos[i] = tempos[i-1] + deltaT;
for i in range(0, n):
    x[i] = deltaX * i;
    u[i] = math.exp(-1*(x[i] - 5)*(x[i] - 5));
    v[i] = 0;
    a[i] = 0;


for t in tempos:
    if(t == t0): 
        deltaTLeap = deltaT/2
    else:
        deltaTLeap = deltaT
    for i in range(1,n-1):
        a[i] = (u[i-1] + u[i+1] - 2*u[i])/((deltaX)*(deltaX))
    
    for i in range(0,n):
        v[i] = v[i] + (a[i] * deltaTLeap)
        u[i] = u[i] + (v[i] * deltaT)

for i in range(int((n/2)-10), int((n/2)+11)):
    print(f'({x[i]},{u[i]})')
