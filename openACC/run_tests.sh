echo "============================================================"
echo "Running tests for [OpenACC]..."

output_dir="openACC_$(hostname -s)_output"
mkdir -p ../$output_dir

echo "======== Test 1: PR 400 x 267 ========="
echo "======== Test 1: PR 400 x 267 =========" > ../$output_dir/1-pr-400-267.txt
(time ./openACC_ray_tracing PR) &>> ../$output_dir/1-pr-400-267.txt
(time ./openACC_ray_tracing PR) &>> ../$output_dir/1-pr-400-267.txt
(time ./openACC_ray_tracing PR) &>> ../$output_dir/1-pr-400-267.txt


echo "======== Test 2: 560 x 373========="
echo "======== Test 2: 560 x 373=========" > ../$output_dir/2-560-373.txt
(time ./openACC_ray_tracing) &>> ../$output_dir/2-560-373.txt
(time ./openACC_ray_tracing) &>> ../$output_dir/2-560-373.txt
(time ./openACC_ray_tracing) &>> ../$output_dir/2-560-373.txt


echo "======== Test 3: MQ 800 x 533 ========="
echo "======== Test 3: MQ 800 x 533 =========" > ../$output_dir/3-mq-800-533.txt
(time ./openACC_ray_tracing MQ) &>> ../$output_dir/3-mq-800-533.txt
(time ./openACC_ray_tracing MQ) &>> ../$output_dir/3-mq-800-533.txt
(time ./openACC_ray_tracing MQ) &>> ../$output_dir/3-mq-800-533.txt


echo "======== Test 4: HQ 1200 x 800 ========="
echo "======== Test 4: HQ 1200 x 800 =========" > ../$output_dir/4-hq-1200-800.txt
(time ./openACC_ray_tracing HQ) &>> ../$output_dir/4-hq-1200-800.txt
(time ./openACC_ray_tracing HQ) &>> ../$output_dir/4-hq-1200-800.txt
(time ./openACC_ray_tracing HQ) &>> ../$output_dir/4-hq-1200-800.txt


echo "======== Test 5: SH 1600 x 1067 ========="
echo "======== Test 5: SH 1600 x 1067 =========" > ../$output_dir/5-sh-1600-1067.txt
(time ./openACC_ray_tracing SH) &>> ../$output_dir/5-sh-1600-1067.txt
(time ./openACC_ray_tracing SH) &>> ../$output_dir/5-sh-1600-1067.txt
(time ./openACC_ray_tracing SH) &>> ../$output_dir/5-sh-1600-1067.txt