#include "vec3.cuh"
#include "ray.cuh"
#include "camera.cuh"
#include "texture.cuh"
#include "sphere.cuh"
#include "moving_sphere.cuh"
#include "hittable_list.cuh"
#include "material.cuh"

#include <iostream>
#include <time.h>
#include <float.h>
#include <curand_kernel.h>
#include <vector>

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"
#include <Eigen/Dense>
using namespace Eigen;

// initialize cudaerror checker
#define checkCudaErrors(val) check_cuda( (val), #val, __FILE__, __LINE__ )

void check_cuda(cudaError_t result, char const *const func, const char *const file, int const line) {
  if (result) {
    std::cerr << "CUDA error = " << static_cast<unsigned int>(result) << " at " <<
      file << ":" << line << " '" << func << "' \n";
    // Make sure we call CUDA Device Reset before exiting
    cudaDeviceReset();
    exit(99);
  }
}

// function to write image

unsigned char double_to_unsignedchar(const double d) {
	return round(std::max(std::min(1.,d),0.)*255);
}

void write_matrix_to_uint8(
	const Eigen::MatrixXd& R, const Eigen::MatrixXd& G,
	const Eigen::MatrixXd& B, const Eigen::MatrixXd& A,
	std::vector<uint8_t>& image)
{
	assert(R.rows() == G.rows() && G.rows() == B.rows() && B.rows() == A.rows());
	assert(R.cols() == G.cols() && G.cols() == B.cols() && B.cols() == A.cols());

	const int w = R.rows();                              // Image width
	const int h = R.cols();                              // Image height
	const int comp = 4;                                  // 4 Channels Red, Green, Blue, Alpha
	image.resize(w*h*comp,0);         // The image itself;

	for (unsigned wi = 0; wi < w; ++wi) {
		for (unsigned hi = 0; hi < h; ++hi) {
			image[(hi * w * 4) + (wi * 4) + 0] = double_to_unsignedchar(R(wi,hi));
			image[(hi * w * 4) + (wi * 4) + 1] = double_to_unsignedchar(G(wi,hi));
			image[(hi * w * 4) + (wi * 4) + 2] = double_to_unsignedchar(B(wi,hi));
			image[(hi * w * 4) + (wi * 4) + 3] = double_to_unsignedchar(A(wi,hi));
		}
	}
}
void write_matrix_to_png(
	const Eigen::MatrixXd& R, const Eigen::MatrixXd& G,
	const Eigen::MatrixXd& B, const Eigen::MatrixXd& A,
	const std::string& filename)
{
	const int w = R.rows();                              // Image width
	const int h = R.cols();                              // Image height
	const int comp = 4;                                  // 3 Channels Red, Green, Blue, Alpha
	const int stride_in_bytes = w*comp;                  // Length of one row in bytes

	std::vector<uint8_t> image;
	write_matrix_to_uint8(R,G,B,A,image);
	stbi_write_png(filename.c_str(), w, h, comp, image.data(), stride_in_bytes);

}

// The infinite recursion in C++ version is not suitable for CUDA, so fix the recursion depth
__device__ vec3 color(const ray& r, hittable **world, curandState *local_rand_state) {
  ray cur_ray = r;
  vec3 cur_attenuation(1.0f,1.0f,1.0f);
  for(int i = 0; i < 10; i++) { // max depth set to 10 here
    hit_record rec;
    if ((*world)->hit(cur_ray, 0.001f, FLT_MAX, rec)) {
      ray scattered;
      vec3 attenuation;
      if(rec.mat_ptr->scatter(cur_ray, rec, attenuation, scattered, local_rand_state)) {
        cur_attenuation *= attenuation;
        cur_ray = scattered;
      }
      else {
        return vec3(0.0f,0.0f,0.0f); // black surface
      }
    }
    else {
      vec3 unit_direction = unit_vector(cur_ray.direction());
      float t = 0.5f*(unit_direction.y() + 1.0f);
      vec3 c = (1.0f-t)*vec3(1.0f, 1.0f, 1.0f) + t*vec3(0.5f, 0.7f, 1.0f); // background color
      return cur_attenuation * c;
    }
  }
  return vec3(0.0,0.0,0.0); // exceeded recursion, return black
}

__global__ void render_init(int max_x, int max_y, curandState *rand_state) {
  int i = threadIdx.x + blockIdx.x * blockDim.x;
  int j = threadIdx.y + blockIdx.y * blockDim.y;
  if((i >= max_x) || (j >= max_y)) return;
  int pixel_index = j*max_x + i;
  //Each thread gets same seed, a different sequence number, no offset
  curand_init(2022+pixel_index, 0, 0, &rand_state[pixel_index]);
}

__global__ void render(vec3 *fb, int max_x, int max_y, int ns, camera **cam, hittable **world, curandState *rand_state, int offset_x) {
  int i = threadIdx.x + blockIdx.x * blockDim.x;
  int j = threadIdx.y + blockIdx.y * blockDim.y;
  if (i < max_x / 2 and j < max_y) {
    int pixel_index = j*max_x + i + offset_x;
    curandState local_rand_state = rand_state[pixel_index];
    vec3 col(0,0,0);

    // get pixel sample for ns times
    for(int s=0; s < ns; s++) {
      float u = float(i + offset_x + curand_uniform(&local_rand_state)) / float(max_x);
      float v = float(j + curand_uniform(&local_rand_state)) / float(max_y);
      ray r = (*cam)->get_ray(u, v, &local_rand_state);
      col += color(r, world, &local_rand_state);
    }

    col /= float(ns);
    col[0] = sqrt(col[0]);
    col[1] = sqrt(col[1]);
    col[2] = sqrt(col[2]);
    fb[j*max_x/2 + i] = col;
  }
}

__global__ void rand_init(curandState *rand_state) {
  if (threadIdx.x == 0 && blockIdx.x == 0) {
    curand_init(2022, 0, 0, rand_state);
  }
}

#define RND (curand_uniform(&local_rand_state))

__global__ void create_world(hittable **d_list, hittable **d_world, camera **d_camera, int nx, int ny, curandState *rand_state) {
  if (threadIdx.x == 0 && blockIdx.x == 0) {
    curandState local_rand_state = *rand_state;
    Texture *checker = new checker_texture(
                                           new constant_texture(vec3(0.2, 0.3, 0.1)),
                                           new constant_texture(vec3(0.9, 0.9, 0.9))
                                           );
    d_list[0] = new moving_sphere(vec3(0,-1000.0,-1), vec3(0,-1000.0,-1),
                                  0.f, 1.f,
                                  1000,
                                  new lambertian(checker));
    int i = 1;
    for(int a = -11; a < 11; a++) {
      for(int b = -11; b < 11; b++) {
        float choose_mat = RND;
        vec3 center(a+RND,0.2,b+RND);
        if(choose_mat < 0.8f) {
          d_list[i++] = new moving_sphere(center, center+vec3(0, 0.5*RND, 0),
                                          0.f, 1.f,
                                          0.2,
                                          new lambertian(new constant_texture(vec3(RND*RND, RND*RND, RND*RND))));
        }
        else if(choose_mat < 0.95f) {
          d_list[i++] = new moving_sphere(center, center,
                                   0.f, 1.f,
                                   0.2,
                                   new metal(vec3(0.5f*(1.0f+RND), 0.5f*(1.0f+RND), 0.5f*(1.0f+RND)), 0.5f*RND));
        }
        else {
          d_list[i++] = new moving_sphere(center, center, 0.f, 1.f, 0.2, new dielectric(1.5));
        }
      }
    }

    d_list[i++] = new moving_sphere(vec3(0, 1,0),  vec3(0, 1,0),   0.f, 1.f, 1.0, new dielectric(1.5));
    d_list[i++] = new moving_sphere(vec3(-4, 1, 0),vec3(-4, 1, 0), 0.f, 1.f, 1.0,
                                    new lambertian(new constant_texture(vec3(0.4, 0.2, 0.1))));
    d_list[i++] = new moving_sphere(vec3(4, 1, 0), vec3(4, 1, 0),  0.f, 1.f, 1.0, new metal(vec3(0.7, 0.6, 0.5), 0.0));
    *rand_state = local_rand_state;
    *d_world  = new hittable_list(d_list, 22*22+1+3);

    vec3 lookfrom(13,2,3);
    vec3 lookat(0,0,0);
    float dist_to_focus = 10.0; (lookfrom-lookat).length();
    float aperture = 0.0f;
    *d_camera   = new camera(lookfrom,
                             lookat,
                             vec3(0,1,0),
                             30.0,
                             float(nx)/float(ny),
                             aperture,
                             dist_to_focus,
                             0.f, 1.f);
  }
}

__global__ void free_world(hittable **d_list, hittable **d_world, camera **d_camera) {
  for(int i=0; i < 22*22+1+3; i++) {
    //delete ((sphere *)d_list[i])->mat_ptr;
    delete ((moving_sphere *)d_list[i])->mat_ptr;
    delete d_list[i];
  }
  delete *d_world;
  delete *d_camera;
}

int main (int argc, char** argv) {

  // default values
  bool SUPER_QUALITY_RENDER = !true;
  bool HIGH_QUALITY_RENDER = !true;
  bool MEDIUM_QUALITY_RENDER = !true;
  bool PROFILE_RENDER = !true;

  // handle command line arguments
  if (argc >= 2) {
    // first command line argument is "PR"?
    if (std::string(argv[1]) == "PR") {
      PROFILE_RENDER = true;
    }
    // first command line argument is "SH"?
    if (std::string(argv[1]) == "SH") {
      SUPER_QUALITY_RENDER = true;
    }
    // first command line argument is "HQ"?
    if (std::string(argv[1]) == "HQ") {
      HIGH_QUALITY_RENDER = true;
    }
    // first command line argument is "MQ"?
    if (std::string(argv[1]) == "MQ") {
      MEDIUM_QUALITY_RENDER = true;
    }
  }

  int nx, ny;
  int tx = 8;
  int ty = 8;
  int ns = 100; // sample per pixel

  if (PROFILE_RENDER) {
    nx = 400;
    ny = 267;
  } else if (SUPER_QUALITY_RENDER) {
    nx = 1600;
    ny = 1067;
  } else if (HIGH_QUALITY_RENDER) {
    nx = 1200;
    ny = 800;
  } else if (MEDIUM_QUALITY_RENDER) {
    nx = 800;
    ny = 533;
  } else {
    nx = 560;
    ny = 373;
  }


  std::cerr << "Rendering a " << nx << "x" << ny << " image with " << ns << " samples per pixel ";
  std::cerr << "in " << tx << "x" << ty << " blocks.\n";

  int num_pixels = nx*ny;
  size_t fb_size = num_pixels*sizeof(vec3);

  // multiplu gpu devices
  int num_devices = 0;
  cudaGetDeviceCount(&num_devices);
  std::cerr << "Found " << num_devices << " GPU devices.\n";

  // allocate FB
  checkCudaErrors(cudaSetDevice(0));
  vec3 *fb;
  checkCudaErrors(cudaMalloc((void **)&fb, fb_size/2));

  checkCudaErrors(cudaSetDevice(1));
  vec3 *fb_copy;
  checkCudaErrors(cudaMalloc((void **)&fb_copy, fb_size/2));
  checkCudaErrors(cudaDeviceSynchronize());

  // allocate random state
  checkCudaErrors(cudaSetDevice(0));
  curandState *d_rand_state;
  checkCudaErrors(cudaMalloc((void **)&d_rand_state, num_pixels*sizeof(curandState)));
  curandState *d_rand_state2;
  checkCudaErrors(cudaMalloc((void **)&d_rand_state2, 1*sizeof(curandState)));
  rand_init<<<1,1>>>(d_rand_state2);
  checkCudaErrors(cudaGetLastError());
  //checkCudaErrors(cudaDeviceSynchronize());

  // copy on device 1
  checkCudaErrors(cudaSetDevice(1));
  curandState *d_rand_state_copy;
  checkCudaErrors(cudaMalloc((void **)&d_rand_state_copy, num_pixels*sizeof(curandState)));
  curandState *d_rand_state2_copy;
  checkCudaErrors(cudaMalloc((void **)&d_rand_state2_copy, 1*sizeof(curandState)));
  rand_init<<<1,1>>>(d_rand_state2_copy);
  checkCudaErrors(cudaGetLastError());
  checkCudaErrors(cudaDeviceSynchronize());

  // make our world of hittables & the camera
  checkCudaErrors(cudaSetDevice(0));
  hittable **d_list;
  int num_hittables = 22*22+1+3;
  checkCudaErrors(cudaMalloc((void **)&d_list, num_hittables*sizeof(hittable *)));
  hittable **d_world;
  checkCudaErrors(cudaMalloc((void **)&d_world, sizeof(hittable *)));
  camera **d_camera;
  checkCudaErrors(cudaMalloc((void **)&d_camera, sizeof(camera *)));
  create_world<<<1,1>>>(d_list, d_world, d_camera, nx, ny, d_rand_state2);
  checkCudaErrors(cudaGetLastError());
  //checkCudaErrors(cudaDeviceSynchronize());

  checkCudaErrors(cudaSetDevice(1));
  hittable **d_list_copy;
  checkCudaErrors(cudaMalloc((void **)&d_list_copy, num_hittables*sizeof(hittable *)));
  hittable **d_world_copy;
  checkCudaErrors(cudaMalloc((void **)&d_world_copy, sizeof(hittable *)));
  camera **d_camera_copy;
  checkCudaErrors(cudaMalloc((void **)&d_camera_copy, sizeof(camera *)));
  create_world<<<1,1>>>(d_list_copy, d_world_copy, d_camera_copy, nx, ny, d_rand_state2_copy);
  checkCudaErrors(cudaGetLastError());
  checkCudaErrors(cudaDeviceSynchronize());

  clock_t start, stop;
  start = clock();


  // Render our buffer
  dim3 blocks(nx/tx+1,ny/ty+1);
  dim3 threads(tx,ty);

  checkCudaErrors(cudaSetDevice(0));
  render_init<<<blocks, threads>>>(nx, ny, d_rand_state);
  checkCudaErrors(cudaGetLastError());
  // checkCudaErrors(cudaDeviceSynchronize());

  checkCudaErrors(cudaSetDevice(1));
  render_init<<<blocks, threads>>>(nx, ny, d_rand_state_copy);
  checkCudaErrors(cudaGetLastError());

  checkCudaErrors(cudaDeviceSynchronize());

  // render_init<<<blocks, threads>>>(nx, ny, 0, d_rand_state);
  // checkCudaErrors(cudaGetLastError());
  // checkCudaErrors(cudaDeviceSynchronize());

  dim3 half_blocks(nx/tx/2+1, ny/ty+1);
  checkCudaErrors(cudaSetDevice(0));
  render<<<half_blocks, threads>>>(fb, nx, ny,  ns, d_camera, d_world, d_rand_state, 0);
  checkCudaErrors(cudaGetLastError());
  checkCudaErrors(cudaSetDevice(1));
  render<<<half_blocks, threads>>>(fb_copy, nx, ny,  ns, d_camera_copy, d_world_copy, d_rand_state_copy, nx/2);
  checkCudaErrors(cudaGetLastError());
  //checkCudaErrors(cudaDeviceSynchronize()); // errors when profiling
  vec3 *fb_host = (vec3*) malloc(fb_size/2);
  vec3 *fb_host_copy = (vec3*) malloc(fb_size/2);
  cudaMemcpy(fb_host, fb, fb_size/2, cudaMemcpyDeviceToHost);
  cudaMemcpy(fb_host_copy, fb_copy, fb_size/2, cudaMemcpyDeviceToHost);

  stop = clock();
  double timer_seconds = ((double)(stop - start)) / CLOCKS_PER_SEC;
  std::cerr << "took " << timer_seconds << " seconds.\n";

  MatrixXd R = MatrixXd::Zero(nx, ny);
	MatrixXd G = MatrixXd::Zero(nx, ny);
	MatrixXd B = MatrixXd::Zero(nx, ny);
	MatrixXd A = MatrixXd::Zero(nx, ny); // Store the alpha mask

  // Output FB as Image
  for (int j = 0; j < ny; j++) {
    for (int i = 0; i < nx/2; i++) {
      size_t pixel_index = j*nx/2 + i;
      double ir_1 = fb_host[pixel_index].r();
      double ig_1 = fb_host[pixel_index].g();
      double ib_1 = fb_host[pixel_index].b();
      double ir_2 = fb_host_copy[pixel_index].r();
      double ig_2 = fb_host_copy[pixel_index].g();
      double ib_2 = fb_host_copy[pixel_index].b();
      R(i, ny-1-j) = ir_1;
      G(i, ny-1-j) = ig_1;
      B(i, ny-1-j) = ib_1;
      A(i, ny-1-j) = 1;
      R(i+nx/2, ny-1-j) = ir_2;
      G(i+nx/2, ny-1-j) = ig_2;
      B(i+nx/2, ny-1-j) = ib_2;
      A(i+nx/2, ny-1-j) = 1;
    }
  }
  const std::string filename("raytrace.png");
	write_matrix_to_png(R, G, B, A, filename);

  // clean up
  checkCudaErrors(cudaDeviceSynchronize());  // errors in profiler
  //cudaDeviceSynchronize();
  free_world<<<1,1>>>(d_list,d_world,d_camera);
  checkCudaErrors(cudaGetLastError());
  //cudaGetLastError();
  checkCudaErrors(cudaFree(d_camera));
  checkCudaErrors(cudaFree(d_world));
  checkCudaErrors(cudaFree(d_list));
  checkCudaErrors(cudaFree(d_rand_state));
  checkCudaErrors(cudaFree(d_rand_state2));
  checkCudaErrors(cudaFree(fb));

  cudaDeviceReset();
}
