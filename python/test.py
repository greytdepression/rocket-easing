import numpy as np
from math import sqrt
import matplotlib.pyplot as plt

# Input

x0 = np.array([ 1,  0])
x1 = np.array([ 0,  1])
v0 = np.array([-1,  0])
v1 = np.array([ 1,  1])
T = 10

# Code

def calculate_vals(x0, x1, v0, v1, T):
    dx = x1 - x0
    
    w = T*(v0 + v1) - 2*(x1 - x0)
    A = -2*((T*(v0 - v1)) @ w)
    A_ = -2*T**2*(v0 @ v0) + 2*T**2*(v1 @ v1) + 4*T*(v0 @ dx) - 4*T*(v1 @ dx)
    B = -4*((T*v1 - (x1 - x0)) @ w)
    B_ = -4*T**2*(v1 @ v1) - 8*(dx @ dx) -4*T**2*(v0 @ v1) + 4*T*(v0 @ dx) + 12*T*(v1 @ dx)
    C = w @ w
    C_ = T**2*(v0 @ v0) + T**2*(v1 @ v1) + 4*(dx @ dx) + 2*T**2*(v0 @ v1) - 4*T*(v0 @ dx) - 4*T*(v1 @ dx)
    D = 4*(C**2 + T**2*((v0 - v1) @ w)**2)
    D_ = B_**2 - 4*A_*C_
    D_old = 4*(w @ w)**2 + 4*T**2*(T*(v0 @ v0 - v1 @ v1) - 2*((v0 - v1) @ dx))**2
    D_new = 4*((w @ w)**2 + T**2*((v0 - v1) @ w)**2)
    
    print(f"A = {A} vs. A* = {A_}")
    print(f"B = {B} vs. B* = {B_}")
    print(f"C = {C} vs. C* = {C_}")
    print(f"D = {D} vs. D* = {D_} vs. D_old = {D_old} vs. D_new = {D_new}")
    
    delta = (-B - sqrt(D_)) / (2 * A) if A != 0 else -C/B
    
    print(f"delta* = {delta}")
    f = A*delta**2 + B*delta + C
    # print(f"f(delta*) = {f}")
    
    a1 = (delta - 1)/(T*delta) * v1 - (delta + 1)/(T*delta) * v0 + 2/(T**2 * delta) * (x1 - x0)
    a2 = (2 - delta)/(T*(1 - delta)) * v1 + delta/(T*(1 - delta)) * v0 - 2/(T**2 * (1 - delta)) * (x1 - x0)
    
    n_a1 = sqrt(a1 @ a1)
    n_a2 = sqrt(a2 @ a2)
    
    # print(f"a1 = {a1}, a2 = {a2}\n|a1| = {n_a1}, |a2| = {n_a2}")

    return a1, a2, delta

# Plots

a1, a2, delta = calculate_vals(x0, x1, v0, v1, T)

N = 10
t1s = np.linspace(0, delta*T, N)
t2s = np.linspace(delta*T, T, N)

def x(t):
    if t < 0:
        return x0 + t*v0
    elif t >= 0 and t <= delta*T:
        return x0 + t*v0 + 0.5*a1*t**2
    elif t <= T:
        t = T - t
        return x1 - t*v1 + 0.5*a2*t**2
    else:
        return x1 + (t - T)*v1

tt = np.linspace(0, T, 11);

for t in tt:
    print(f"x({t}) =", x(t))

x1s = np.array(list(map(x, t1s)))
x2s = np.array(list(map(x, t2s)))

print(x1s)
print(x2s)

plt.figure()
plt.plot(x1s[:,0], x1s[:,1])
plt.plot(x2s[:,0], x2s[:,1])

plt.savefig('plot.png')


ts = 2**np.linspace(-10, 10, 11)

an = lambda t: np.linalg.norm(calculate_vals(x0, x1, v0, v1, t)[0])
delta = lambda t: calculate_vals(x0, x1, v0, v1, t)[2]

ans = np.array(list(map(an, ts)))
deltas = np.array(list(map(delta, ts)))

plt.figure()
plt.xlabel('$T$')
plt.ylabel('$a$')
plt.loglog(ts, 50/ts, linestyle = 'dashed', color = 'gray', label = '$\propto 1/T$')
plt.loglog(ts, 100/ts**2, linestyle='dashdot', color = 'gray', label = '$\propto 1/T^2$')
plt.loglog(ts, ans, color = 'orange', label = '$a$')

plt.legend()

plt.savefig('accs.png')

plt.figure()

plt.plot(np.log(ts), deltas, color = 'orange', label = '$\delta^*$')
plt.legend()

plt.savefig('deltas.png')

