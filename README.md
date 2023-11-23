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
