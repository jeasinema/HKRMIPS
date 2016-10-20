## NaiveMIPS  代码阅读报告
###五级流水
####stage_if
**时序逻辑**
 
每一个时钟周期(【周期1 IF】)，`pc` 模块负责计算`pc`的下一条指令地址，因此输入控制信号（异常，使能等）输出一个地址即可.
然后, 在顶层文件中这个地址被传入`mmu`，`mmu` 完成转换后输出为`ibus_address`作为 `cpu` 顶层的输出，在`spoc` 顶层中被传入 `ibus`.

`ibus` 中通过组合逻辑将`ram`访问地址传入`sram`（作为`address1`）, 下一时钟周期通过 `master_rddata` 传回至`cpu` （`cpu` 内对应的信号 : `ibus_rddata`）作为 `if_inst`，在顶层文件中每一个时钟上升沿压入 `id` 模块中.

####stage_id
**组合逻辑** 
分为 `r` `i` `j` 分三种指令对应三个模块，各自单独解码。解码成功输出`op` , 反之输出 `op_invalid` 。接收的输入为32位指令.

32位指令在`cpu`顶层文件中通过 `ibus` 获取.

```verilog
assign if_inst = (if_iaddr_exp_miss|if_iaddr_exp_illegal|if_iaddr_exp_invalid) ? 32'b0 : ibus_rddata;
```

顶层的 `id` 模块将指令解码成为`reg_s` `reg_t` `reg_d` `immediate`  `op` `op_type`这几部分, 输出至 `ex`

同时在 `cpu` 顶层中把 `reg_t` `reg_s` 的编号分别输出至两个`mux` 中 `mux` 每一个时钟上升沿将寄存器值压入 `ex` 中

####stage_ex 
**组合逻辑+可能的时序逻辑（如除法运算）**
 
解析 `op` 获取 `s` `t` `d` immediate 从 mux 中获取寄存器的值（原因见下） 执行指令.

输出访存指令（访存方向，访存大小），溢出信号，异常/中断信号，协处理器信号等

输出写寄存器操作的写入地址和数据至 `mux`

每周期将访存的地址压入`mm`

####stage_mm 
**组合逻辑**

读操作：类似 `stage_if`  输出 `mem_address` 传入 `mmu`   

完成转换后输出为 `dbus_address` (`cpu` 的输出) 在 `spoc` 中传入 `dbus`（经转换后的地址在 `dbus` 中为 `master_address`） `dbus` 中判断这个地址对应的是哪个外设，使能之，然后转发并传入 `sram/gpio/flash/uart/gpu` （`address2`） 下一周期传回至 `mm`, 然后从 `data_o` 输出至 `mux`, （ `dbus` 输出为 `master_rddata`， 在 `spoc` 顶层中传入 `cpu` 的 `dbus_rdata`）

同时送入`stage_mm` 的 `mem_data_i` 最终输出为 `data_o` （在`cpu`顶层文件中每周期和内存访问方式一起被压入 `wb_data_i/wb_mem_access_op` 输入至 `wb`）

类似的，`mm` 的写操作在 `stage_mm` 中输出为 `mem_data_o` 通过 `dbus_wrdata` 传入 `dbus`（然后转发给 `sram/gpio/flash/uart/ticker/gpu`）. 写入地址同样为 `mem_address` 经过`mmu`转换后传入 `dbus`(然后与读取时的地址转换相同)

####stage_wb（
**组合逻辑**

接收 `mm` 发送的寄存器地址。接收 `mem_access_op` 判断是否需要回写寄存器堆，然后使能相应信号，通过组合逻辑写入寄存器堆。

###小结
1. CPU 中的时序逻辑和组合逻辑
时序逻辑包括：
 - pc 的自增, 同时if 访问内存
 - if 将指令压入id
 - id 将寄存器值 立即数 指令代码 压入ex
 - ex 内部的多周期指令
 - ex 将访存地址压入mm并写 MUX, mm 访问内存并写 MUX
 - mm 将内存访问方式/访问结果压入wb

由此用**七个周期**实现了**五级流水**
(带* 的其实可以取消时序,变为组合逻辑与上级合并,从而实现真正的5周期)

注意: 压入是时序逻辑,但是输出是组合逻辑,即尚未压入时上一个模块的输出已经是待压入的值了
SRAM 返回访存结果

组合逻辑包括：
 - 读写 SRAM
 - 读写寄存器
 - 通过 MUX 实现寄存器的旁路写入
 - EX 的大部分单周期指令运算
 - MMU 查询
 - 访存地址压入 SRAM
 - 其他

2. 旁路的实现
EX 不直接从寄存器堆中读取寄存器(reg_s/reg_t)的值，而是把需要的寄存器(reg_s reg_t)的编号同时传入一个mux和寄存器堆,
mux同时还接收 ex mm wb 三个阶段写寄存器操作的输出（寄存器编号，内容）和寄存器的输出。
mux 判断是否需要旁路，需要时将相应的寄存器值（来自 ex/mm/wb 的写寄存器输出或真的来自寄存器）输出给 EX
EX 从mux  读取 reg_s/reg_t

3. 阻塞的实现
（目标: mm访存的同时阻塞流水线一个周期即可）
实际实现：实现多种组合的阻塞 （navie_mips.v L345-L360）
分别控制这五个阶段：
     - pc 自增  en_pc  无效时pc 不自增
     - if 压入 id  en_ifid   无效时压入0
     - id 压入 ex  en_idex  同上
     - ex 压入 mm  ex_exmm 同上
     - mm 压入 wb  ex_mmwb 同上
另设一flush 信号，flush 有效时上述各个信号均视为无效 用于异常或调试时清空流水
详细说明：
 (1) 复位时，全部有效(不阻塞)
 (2) 内存阻塞/调试器阻塞时，全部无效(阻塞)
 (3) ex进行多周期运算时(此时ex会通过组合逻辑置位mul_done 进而置位 ex_stall)，除 mm->wb 外均无效 (阻塞)
 (4) 出现 LW 型(装载型)指令(ACCESS_OP_M2R)指令(此时ex会通过组合逻辑置位 ex_mem_access_op)且 ex 输出的寄存器编号ex_reg_addr(即装载的目的寄存 器)与 id 将在下一时刻压入 ex 的 reg_t/reg_s  id_red_s/id_reg_t相同时, 除 mm->wb ex->mm 外无效(阻塞)
 (5) 出现 ibus_stall (事实上这个信号不会发生, 在top 中被固定为0) 对策同(4)

4. 分支的实现
在 `id` 阶段设置一 `branch_detector` 负责计算分支地址`branch_jump_addr`和返回地址`return_addr`, 输出分支信号`do_branch`
5. 中断的实现

6. 五级流水概览
 **(描述的是每一个时钟周期到来后结果是什么)**
 1. PC+4, 访存地址压入 SRAM, IF完成访存拿到指令 inst, 输出inst
 2. ID 拿到 IF 压入的指令, 完成指令解析 输出reg编号等指令细节
 3. EX 拿到 ID压入的指令和寄存器值, 完成运算和寄存器旁路MUX写入(都是组合逻辑)  输出访存细节
 4. MM 拿到 访存的地址和数据, 访存地址压入 SRAM, MM 拿到访存的结果/完成内存写入, 完成旁路MUX写入, 输出WB的寄存器地址和数据
 5. *WB 拿到 MM 回写的寄存器地址和数据, 完成寄存器写入

7. 访存的一些问题
mm 出去的访存地址都需要按字对齐吗?
- `SWL`, `SWR` 需要按字对齐
- `SH` 需要按半字对齐
- `SW` 需要按字对齐
- `SB` 不需要对齐
注意, 计算出来的内存地址并不保证对齐
因此需要在 mm 中进行手工对齐
同时, 由于板子不能写单个字节, 因此 `SB/SH` 需要用一些特殊的办法(先读再写)完成对单个字节和半字的写操作

8. 其他实现细节

mmu/tlb ：组合逻辑！
寄存器堆：同步复位，其余为组合逻辑（读写寄存器为组合逻辑）  需配合一个 mux 使用

