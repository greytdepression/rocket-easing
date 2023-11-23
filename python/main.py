import numpy as np
from sympy import symbols, expand, simplify, init_printing

init_printing()

dx, x0, x1, v0, v1, t, d = symbols('dx x_0 x_1 v_0 v_1 T d')

matAInv = 2 / (t**3 * d * (d - 1)) * np.array([[0.5*(1-d)**2*t**2, -(1-d)*t], [-0.5*t**2*d*(2-d), d*t]])

print(dx)

a = simplify(matAInv @ np.array([v1 - v0, dx - t * v0]))
print('a1 =', a[0], 'a2 =', a[1])

exp_a1 = (d-1)/(t*d) * v1 - (d+1)/(t*d) * v0 + 2/(t**2*d)*dx
exp_a2 = (2-d)/(t*(1-d))*v1 + d/(t*(1-d))*v0 - 2/(t**2*(1-d))*dx

a1 = a[0]
a2 = a[1]

print('a1 - exp_a1 =', simplify(a1 - exp_a1), 'a2 - exp_a2 =', simplify(a2 - exp_a2))

norm_a1_sq = expand(a1 * a1)
norm_a2_sq = expand(a2 * a2)

print('|a_1|^2 - |a_2|^2 =', simplify(norm_a1_sq - norm_a2_sq), '\n\n\n')

v0v0, v1v1, v0v1, v0dx, v1dx, dxdx = symbols('v0v0 v1v1 v0v1 v0dx v1dx dxdx')

A = -2*t**2*v0v0 + 2*t**2*v1v1 + 4*t*v0dx - 4*t*v1dx
B = -4*t**2*v1v1 - 8*dxdx - 4*t**2*v0v1 + 4*t*v0dx + 12*t*v1dx
C = t**2*v0v0 + t**2*v1v1 + 4*dxdx + 2*t**2*v0v1 - 4*t*v0dx - 4*t*v1dx

D = B**2 - 4*A*C

print('D =', D, '\n\n  =', simplify(expand(D)), "\n\n")

D = simplify(expand(D))

def dot_prod(alpha):
    return simplify(expand((t**2*v0v0 + 2*t**2*v0v1 + t**2*v1v1 - 2*alpha*t*v0dx - 2*alpha*t*v1dx + alpha**2*dxdx)**2))

print("D - 4|Tv_0 + Tv_1 - 2dx|^4 =", simplify(expand(D - 4*dot_prod(2))), "\n\n")


print("0 =", simplify(expand(D - (4*dot_prod(2) + 4*t**2*(t*(v0v0 - v1v1) -2*v0dx + 2*v1dx)**2))))
