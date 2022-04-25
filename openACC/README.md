# ray-tracing-cuda

This folder contains the OpenACC version code.

## Build

To build the code, run
```
source setup.sh
```

This will setup the environment and build the code.

or manually load the modules:
```
module load cmake-3
module load nvhpc/20.9
```
then
```
cmake -B build
```

## Run

To run the ray-tracer, `cd` into the build folder and run
```
./openACC_ray_tracing [PR|MQ|HQ|SH]

# Example:
.openACC_ray_tracing SH
```
the output image will be `raytrace.png`

Sample output:

![](raytrace.png)

The above sample takes `7m27.479s` with 40 threads.