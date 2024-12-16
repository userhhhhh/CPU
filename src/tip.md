运行脚本：
make run_sim name=000

显示波形图：
gtkwave testspace/test.vcd 


fpga not pass:
uartboom   statement_test

fpga:
docker run -it --rm --privileged -v $(pwd):/app -w /app test_fpga
make run_fpga name=array_test1
make run_fpga_all