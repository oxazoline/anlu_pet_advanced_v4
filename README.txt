实时视觉交互电子宠物 V4 使用说明

1. 平台与功能
开发板：HX1P35A；器件：PH1P35MDG324，速度等级 -3。
摄像头：SC520CS；输出：1280×720 HDMI。
功能包括四种图像模式、人脸与表情标签、V形手势、指定“米饭”打印图案识别与跟踪、自动曝光、白平衡、状态和延迟显示，以及静态宠物反馈。

2. 主要目录
user_source：全部RTL源码、IP及引脚/时序约束。
td_project：Tang Dynasty工程和图像初始化数据。
models：定点模型参数、模型资料及第三方许可。
assets：米饭原图和四张宠物PNG原始素材。
release：最终配置文件pet_advanced_v4.bit及SHA256校验值。
scripts：编译、工程准备、仿真和模型数据辅助工具。
sim、validation：126项RTL测试代码及配套固定测试向量。
reports：验证记录、资源/时序数据及离线对比结果。

3. 打开与编译
请先将整个文件夹复制到纯英文路径，例如：
D:/FPGA_HX1P35A/anlu_pet_v4_submit/
不要只复制.al文件，也不要覆盖正在使用的其他工程。
使用Tang Dynasty 6.2打开td_project/basic_sc520.al，顶层为design_top_wrapper。
保留现有IP、约束和td_project目录中的.hex、.dath文件，再执行综合、布局布线和bit生成。
最终检查建立/保持余量均不小于0，建立/保持总负余量均为0。

4. 仿真与命令行编译
仿真使用Python 3和ModelSim；固定向量已随包提供，无需旧版本工程或训练数据目录。
在工程根目录运行：
python scripts/validate_v4.py --modelsim D:/modelsim/win32 --stage-root D:/FPGA_HX1P35A/_work
仿真完成后，可运行：
python scripts/build.py --fresh --td D:/Anlogic/TD_6.2.1_Engineer_6.2.168.116/bin/td_commands_prompt.exe --stage-root D:/FPGA_HX1P35A/_work
工具安装位置不同，请修改命令中的路径。也可设置MODELSIM_BIN、TD_EXE和FPGA_STAGE_ROOT环境变量。
模型与图像辅助工具另需numpy、Pillow。完整工程综合不依赖Python重新训练模型。

5. 下载与操作
通过板卡原有下载接口加载release/pet_advanced_v4.bit。
K1+K2切换自动/手动曝光；自动模式下K1/K2降低/提高目标亮度，手动模式下降低/提高曝光。
K3/K4调节饱和度，K3+K4切换显示模式。组合键操作后先完全松开。
普通宠物显示在右下角；未识别时显示neutral。米饭有效时只显示“饭！”形象，随目标换侧、镜像和跟随。
米饭测试请使用assets/reference_target.jpg的打印件。该功能为指定图案匹配，手势范围为手指大致向上的单手静态V形姿态。

6. 结果说明
RTL验证、离线数据与实机功能观察采用不同口径。LAT/MAX为数字链路延迟，不包含屏幕面板响应。
程序固化及断电上电启动请按板卡工具流程另行验证。第三方版权与许可见models中的LICENSE和SOURCES文件。
