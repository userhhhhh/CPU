1、sim测试：
(1) makefile testcases采用第一行，第二行注释
(2) 确保Docker容器内的用户具有写权限:
sudo chmod -R 777 /home/hqs123/class_code/CPU/testspace
(3) make run_sim name=000
(4) 波形图：gtkwave testspace/test.vcd 

2、fpga测试:
应该只要打一遍：sudo chmod 777 /dev/ttyUSB1
makefile testcases采用第二行，第一行注释
如果vscode之前已经连接，Powershell管理员模式：usbipd detach --busid 2-2
用vivado将bit文件导入板子
Powershell管理员模式：usbipd attach --wsl --busid 2-2
vscode进入docker：docker run -it --rm --privileged -v $(pwd):/app -w /app test_fpga 
单点测试：make run_fpga name=statement_test
所有测试：make run_fpga_all

3、遇到的问题：
sim测试需要确保 Docker 容器内的用户具有写权限的原因：
先查看testspace下所有文件的权限情况：ls -lR testspace 
发现：-rw-r--r-- 1 root   root        27 Dec 16 20:57 test.ans
-rw-r--r--中，rw-、r--、r--分别代表所有者、所有组、其他用户的读写权限（r读w写x执行）
这时是hqs123用户，只有读权限，但makefile里面有cp指令，需要写权限，所以炸了