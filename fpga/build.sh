set -e
dir=`dirname $0`
g++ $dir/controller.cpp -std=c++17 -lserial -o $dir/fpga
