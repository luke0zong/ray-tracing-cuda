echo "============================================================"
echo "Running tests for [CPU OpenMP]..."

output_dir="openmp_$(hostname -s)_single_output"
mkdir -p ../$output_dir

echo "======== Test 1: PR 400 x 267 ========="
echo "======== Test 1: PR 400 x 267 =========" > ../$output_dir/1-pr-400-267-single.txt
(time ./parallel_ray_tracing 1 --width=400 --sample=100 --depth=10) &>> ../$output_dir/1-pr-400-267-single.txt
(time ./parallel_ray_tracing 1 --width=400 --sample=100 --depth=10) &>> ../$output_dir/1-pr-400-267-single.txt
(time ./parallel_ray_tracing 1 --width=400 --sample=100 --depth=10) &>> ../$output_dir/1-pr-400-267-single.txt


echo "======== Test 2: 560 x 373========="
echo "======== Test 2: 560 x 373=========" > ../$output_dir/2-560-373-single.txt
(time ./parallel_ray_tracing 1 --width=560 --sample=100 --depth=10) &>> ../$output_dir/2-560-373-single.txt
(time ./parallel_ray_tracing 1 --width=560 --sample=100 --depth=10) &>> ../$output_dir/2-560-373-single.txt
(time ./parallel_ray_tracing 1 --width=560 --sample=100 --depth=10) &>> ../$output_dir/2-560-373-single.txt


echo "======== Test 3: MQ 800 x 533 ========="
echo "======== Test 3: MQ 800 x 533 =========" > ../$output_dir/3-mq-800-533-single.txt
(time ./parallel_ray_tracing 1 --width=800 --sample=100 --depth=10) &>> ../$output_dir/3-mq-800-533-single.txt
(time ./parallel_ray_tracing 1 --width=800 --sample=100 --depth=10) &>> ../$output_dir/3-mq-800-533-single.txt
(time ./parallel_ray_tracing 1 --width=800 --sample=100 --depth=10) &>> ../$output_dir/3-mq-800-533-single.txt


echo "======== Test 4: HQ 1200 x 800 ========="
echo "======== Test 4: HQ 1200 x 800 =========" > ../$output_dir/4-hq-1200-800-single.txt
(time ./parallel_ray_tracing 1 --width=1200 --sample=100 --depth=10) &>> ../$output_dir/4-hq-1200-800-single.txt
(time ./parallel_ray_tracing 1 --width=1200 --sample=100 --depth=10) &>> ../$output_dir/4-hq-1200-800-single.txt
(time ./parallel_ray_tracing 1 --width=1200 --sample=100 --depth=10) &>> ../$output_dir/4-hq-1200-800-single.txt


echo "======== Test 5: SH 1600 x 1067 ========="
echo "======== Test 5: SH 1600 x 1067 =========" > ../$output_dir/5-sh-1600-1067-single.txt
(time ./parallel_ray_tracing 1 --width=1600 --sample=100 --depth=10) &>> ../$output_dir/5-sh-1600-1067-single.txt
(time ./parallel_ray_tracing 1 --width=1600 --sample=100 --depth=10) &>> ../$output_dir/5-sh-1600-1067-single.txt
(time ./parallel_ray_tracing 1 --width=1600 --sample=100 --depth=10) &>> ../$output_dir/5-sh-1600-1067-single.txt