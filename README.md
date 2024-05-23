# LUA Script
官方文档：\
https://ardupilot.org/dev/docs/common-lua-scripts.html \
启动SITL模拟器后输入 \
```param set SCR_ENABLE 1``` \
然后退出SITL，此时启动SITL所用的终端所在的目录下会新建一个名为`Scripts`的文件夹，将.lua文件放置在这后启动SITL便会在SITL内自动加载。 \
在飞控内加载LUA脚本的方法参考官方文档。 \
在脚本内，SITL模拟器加载的函数入口如下
```lua
function update()
  --主函数内容
  return update,1000
end
return update,1000
```
其中`update()`函数外的`return update,1000`意为这个函数将在加载LUA脚本后1000ms执行，函数外的`return update,1000`意为这个函数每隔1000ms会执行一次，具体参考官方文档 。\
ArduPilot提供的API函数接口也在官方文档的首页中。
# 新的Branch
新的分支里包含了应用了新投弹算法的代码，将飞行姿态考虑了进去。
# 几个不同LUA文件的用法
`demo_without_CV.lua`文件用于在视觉模块还没接入时在SITL上模拟使用的脚本，在代码文件的第10行的`itargetloc = {}`内存储了靶标的坐标，模拟时可以修改。\
`demo_to_test.lua`是用于投弹实测的脚本文件。\
`demo.lua`是完整版的脚本文件，还在修改中。\
`output.lua`用于位置数据输出。
# 投弹脚本待解决问题
## 在ArduPilot中创建靶标数据相关的变量
`create_parameter()`函数用于在ArduPilot中创建接受靶标数据的变量：\
`TARGET_GET = 0`靶标数据未传入为0(默认值)，数据已传入为1\
`TARGET_LAT = 0.000000`靶标纬度\
`TARGET_LNG = 0.000000`靶标经度\
`TARGET_WAYPOINT_CHANGE = 0`航线未改变为0(默认值)，航线已改变为1\
投弹完成后，脚本将`TARGET_GET`和`TARGET_WAYPOINT_CHANGE`改回0。
## GPS与AHRS定位问题
飞控的AHRS系统默认引入了EKF滤波算法。\
在飞控的AHRS相关参数，可以调整AHRS对GPS和陀螺仪、空速管、气压计等设施的采用方案。\
在飞控的EKF3相关参数有非常多的参数可以研究调整。
## 靶标信息和航线信息接口
`target_location()`函数用于获取ArduPilot变量(Parameter)中的，由视觉模块传入的靶标位置数据。数据由(纬度,经度)构成，期望纬度和经度数据精确到小数点后六位。\
此脚本的计算方法期望飞机在到达靶标前有一段时间可以水平姿态向靶标位置直线飞行，达到这一期望后将信息发送到`wait_for_waypoint_change()`供脚本确认。
## 投弹决策
此脚本设置了当计算得投弹落点与标靶距离小于3米时进行投弹操作，且每隔500ms进行一次投弹计算，误差范围为10m。这意味着脚本每隔500ms进行计算并决定此时是否投弹。具体时间的设置需要考虑到脚本的运行速度和飞控数据的传输速度。
## 误差修正函数
`error_correction()`函数用于处理飞机速度和水瓶速度的关系，未来通过实验测试找到一个抵消误差效果较好的处理方法。
## 补救函数
`remedy()`函数用于设定在检测到飞机正在飞离靶标时执行投弹。
