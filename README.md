# 新的Branch
新的分支里包含了应用了新投弹算法的代码，将飞行姿态考虑了进去。
# LUA文件
`demo_without_CV_new_version.lua`文件用于在视觉模块还没接入时在SITL上模拟使用的脚本，在代码文件的第10行的`itargetloc = {}`内存储了靶标的坐标，模拟时可以修改。\
`demo_to_test_new_version.lua`是用于投弹实测的脚本文件。\
`demo_new_version.lua`是完整版的脚本文件，还在修改中。\
`output.lua`用于位置数据输出。\
`mission_choose_load.lua`用于航点文件加载
# 投弹脚本待解决问题
## 在ArduPilot中创建靶标数据相关的变量
注意：每次测试前都要重置变量\
`create_parameter()`函数用于在ArduPilot中创建接受靶标数据的变量：\
`TARGET_GET = 0`靶标数据未传入为0(默认值)，数据已传入为1\
`TARGET_LAT = 0.000000`靶标纬度\
`TARGET_LNG = 0.000000`靶标经度\
`TARGET_WAYPOINT = 0`未到最后航点为0(默认值)，已到最后航点为1\
`TARGET_NUM = 0`所选择的航线号码,当进入补救航线时值为5\
`TARGET_REMEDY = 0`到达补救航线航线最后航点为1\
投弹完成后，脚本将`TARGET_GET`和`TARGET_WAYPOINT`改回0。
## GPS与AHRS定位问题
飞控的AHRS系统默认引入了EKF滤波算法。\
在飞控的AHRS相关参数，可以调整AHRS对GPS和陀螺仪、空速管、气压计等设施的采用方案。\
在飞控的EKF3相关参数有非常多的参数可以研究调整。
选择GPS速度还是AHRS速度？
## 靶标信息和航线信息接口（需要上飞控测试）
待定：似乎变量精确位数不够\
`target_location()`函数用于获取ArduPilot变量传入的靶标位置数据。数据由(纬度,经度)构成，纬度和经度数据精确到小数点后六位。\
然后飞控将接受靶标号码并载入航线文件。\
航线更改后将信息发送到`wait_for_waypoint_change()`供脚本确认。\
注意：要先把靶标信息的变量更改再把TARGET_GET改成1!
## 投弹决策
设置当计算得投弹落点与标靶距离小于3米时进行投弹操作，且每隔500ms进行一次投弹计算（刷新率），误差范围为10m。（待测试）
## 误差修正函数
`error_correction()`函数用于处理飞机速度和水瓶速度的关系，通过实验测试找到一个抵消误差效果较好的处理方法。
## 航线选择脚本
等待对接投弹航线和补救航线最后一个WAYPOINT的接口。
## 测试准备
设计一个文档记录测试的具体步骤。\
确定实验需要记录的数据。\
确定可以修改与改进的因素。
