# Rocket Easing

A mathematical exploration of $n$-dimensional $C_1$ interpolation with low acceleration.

**This repository is VERY MUCH a work-in-progress. In the current form it is mainly meant for me to sync relevant files between computers. Do not expect the code to run on your machine as is.**

This research and included software is in the public domain for jursidictions in which the public domain exists. Alternatively, it is available under the Zero-Clause BSD license.

## Motivation

[Easing functions](https://easings.net/) are ubiquitous in computer graphics and animations. Any time there is a change in a continuous parameter programs need to somehow interpolate between the start and end state. Easing functions only interpret between scalar values 0 and 1 though, so how would we go about interpolating between vectors?

### Composing Linear Interpolation and Easing Functions
If we have two vectors $x_0$ and $x_1$ and want to go from $x_0$ at $t = 0$ and $x_1$ at $t=1$, we can just take our favorite easing function $f \colon \mathbb R \rightarrow \mathbb R$ with $f(0) = 0$ and $f(1) = 1$ to interpolate as follows
$$x(t) = (1 - f(t))x_0 + f(t)x_1.$$
This will work, of course, but there is an issue. If the object whose position we are describing here was moving already, it will now suddenly change its velocity at $t=0$ and then potentially again at $t=1$.
As such, this approach yields us a continuous ($C_0$) interpolation (given that $f$ is $C_0$), but the velocity (i.e. $dx/dt$) will generally not be continuous.

## Comparison to Bézier Curves
An easy and computationally efficent way of $C_1$ interpolating between to points is to use cubic Bézier curves. A cubic Bézier curve is parametrized by four points $p_0, p_1, p_2, p_3$ and of the form
$$b(t) = (1-t)^3p_0 + 3t(1-t)^2p_1 + 3t^2(1-t)p_2 + t^3p_3.$$
By choosing these points as follows
$$p_0 = x_0,\quad p_1 = \frac 13 (v_0 - 3x_0),\quad p_2 = -\frac 13 (v_1 - 3x_1),\quad p_3 = x_1,$$
we get a cubic Bézier curve that smoothly (i.e. $C_\infty$) interpolates between $x_0$ and $x_1$ while respecting start and end velocities $v_0$ and $v_1$.

However, cubic Béziers have a linear second derivative, i.e. linear acceleration, thus we will typically start and end with extrme acceleartions and have zero acceleration somewhere in the middle.
Note that these extreme accelartions are inherent to all Bézier curves independent of degree (if the degree is at least 3). We could choose e.g. a fifth-order Bézier curve and set start and end accelerations to 0, this however would then yield even stronger accelerations on (0, 1).

In comparison, rocket easing uses constant accelerations which minimizes the maximum acceleration overall.
