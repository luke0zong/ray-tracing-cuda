#ifndef TEXTURE_CUH
#define TEXTURE_CUH

#include "vec3.cuh"
#include "ray.cuh"

class Texture {
public:
  __device__ virtual vec3 value(float u, float v, const vec3& p) const = 0;
};

class constant_texture : public Texture {
public:
  __device__ constant_texture() {}
  __device__ constant_texture(vec3 c) : color(c) {}
  __device__ virtual vec3 value(float u, float v, const vec3& p) const {
    (void)u; (void)v; (void)p;
    return color;
  }
  vec3 color;
};

class checker_texture : public Texture {
public:
  __device__ checker_texture() {}
  __device__ checker_texture(Texture *t0, Texture *t1): even(t0), odd(t1) {}
  __device__ virtual vec3 value(float u, float v, const vec3& p) const {
    float sines = sinf(10.f*p.x())*sinf(10.f*p.y())*sinf(10.f*p.z());
    if (sines < 0.f)
      return odd->value(u, v, p);
    else
      return even->value(u, v, p);
  }
  Texture *even;
  Texture *odd;
};

#endif
