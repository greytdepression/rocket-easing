import matplotlib.pyplot as plt
import numpy as np
from math import sqrt

def cubic_bezier(x0, x1, v0, v1, steps):
    p0 = x0
    p3 = x1
    p1 = 1/3*(v0 - 3*x0)
    p2 = -1/3*(v1 - 3*x1)

    ts = np.linspace(0, 1, steps)

    x = lambda t: (1-t)**3 * p0 + 3*t*(1-t)**2 * p1 + 3*t**2*(1-t) * p2 + t**3 * p3

    a = lambda t: 6*(1-t)*(p2 - 2*p1 + p0) + 6*t*(p3 - 2*p2 + p1)

    return np.array(list(map(x, ts))), np.array(list(map(a, ts)))

def rocket_easing(x0, x1, v0, v1, steps):
    dx = x1 - x0

    T = 1
    
    w = T*(v0 + v1) - 2*(x1 - x0)
    A = -2*((T*(v0 - v1)) @ w)
    B = -4*((T*v1 - (x1 - x0)) @ w)
    C = w @ w
    D = 4*(C**2 + T**2*((v0 - v1) @ w)**2)
    delta = (-B - sqrt(D)) / (2 * A) if A != 0 else -C/B
    a1 = (delta - 1)/(T*delta) * v1 - (delta + 1)/(T*delta) * v0 + 2/(T**2 * delta) * (x1 - x0)
    a2 = (2 - delta)/(T*(1 - delta)) * v1 + delta/(T*(1 - delta)) * v0 - 2/(T**2 * (1 - delta)) * (x1 - x0)
    
    ts = np.linspace(0, 1, steps)

    x = lambda t: x0 + t*v0 + 0.5*a1*t**2 if t <= delta else x1 - (T - t)*v1 + 0.5*a2*(T - t)**2
    a = lambda t: a1 if t <= delta else a2

    return np.array(list(map(x, ts))), np.array(list(map(a, ts)))

x0 = np.array([0.0, 0.0])
x1 = np.array([0.5, -0.5])
v0 = np.array([-0.5, 1.0])
v1 = np.array([-0.25, 0.5])

steps = 128

cbx, cba = cubic_bezier(x0, x1, v0, v1, steps)
rex, rea = rocket_easing(x0, x1, v0, v1, steps)

plt.figure()
plt.xlabel('$x$')
plt.ylabel('$y$')
plt.plot(cbx[:,0], cbx[:,1], color = 'blue', label = 'Bézier')
plt.plot(rex[:,0], rex[:,1], color = 'orange', label = 'rocket')
plt.legend()
plt.savefig('bezier-rocket-path.png')


ts = np.linspace(0, 1, steps)

plt.figure()
plt.xlabel('t')
plt.ylabel('a')
plt.plot(ts, np.linalg.norm(cba, axis=1), color = 'blue', label = 'Bézier')
plt.plot(ts, np.linalg.norm(rea, axis=1), color = 'orange', label = 'rocket')
plt.legend()
plt.savefig('bezier-rocket-acceleration.png')

