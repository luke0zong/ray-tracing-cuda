#ifndef UTILS_H
#define UTILS_H

#include <algorithm>
#include <vector>

unsigned char double_to_unsignedchar(const double d) {
	return round(std::max(std::min(1.,d),0.)*255);
}

void write_matrix_to_uint8(
	const double* R, const double* G,
	const double* B, std::vector<uint8_t>& image,
	const int nx, const int ny)
{
	// assert(R.rows() == G.rows() && G.rows() == B.rows() && B.rows() == A.rows());
	// assert(R.cols() == G.cols() && G.cols() == B.cols() && B.cols() == A.cols());

	// const int w = R.rows();                              // Image width
	// const int h = R.cols();                              // Image height
	const int comp = 4;                                  // 4 Channels Red, Green, Blue, Alpha
	image.resize(nx*ny*comp,0);         // The image itself;

	for (unsigned wi = 0; wi < nx; ++wi) {
		for (unsigned hi = 0; hi < ny; ++hi) {
			int index = wi * ny + hi;
			image[(hi * nx * 4) + (wi * 4) + 0] = double_to_unsignedchar(R[index]);
			image[(hi * nx * 4) + (wi * 4) + 1] = double_to_unsignedchar(G[index]);
			image[(hi * nx * 4) + (wi * 4) + 2] = double_to_unsignedchar(B[index]);
			image[(hi * nx * 4) + (wi * 4) + 3] = double_to_unsignedchar(1.0);
		}
	}
}

void write_matrix_to_png(
	const double* R, const double* G,
	const double* B, const std::string& filename,
	const int nx, const int ny)
{
	// const int w = R.rows();                              // Image width
	// const int h = R.cols();                              // Image height
	const int comp = 4;                                  // 3 Channels Red, Green, Blue, Alpha
	const int stride_in_bytes = nx*comp;                  // Length of one row in bytes

	std::vector<uint8_t> image;
	write_matrix_to_uint8(R,G,B,image,nx,ny);
	stbi_write_png(filename.c_str(), nx, ny, comp, image.data(), stride_in_bytes);

}

#endif
