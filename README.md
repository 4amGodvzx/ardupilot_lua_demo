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
# 投弹脚本待解决问题
## 标靶信息和航线信息接口
`target_location()`函数用于接收从视觉模块传入的靶标位置数据，由(纬度,经度,海拔)构成，期望纬度和经度数据精确到小数点后六位。海拔所用的参考系与飞控有关，此脚本中使用绝对海拔。\
此脚本的计算方法期望飞机在到达靶标前有一段时间可以水平姿态向靶标位置直线飞行，达到这一期望后将信息发送到`wait_for_waypoint_change()`供脚本确认。如果飞行姿态无法保证，需要修改运算代码。
## Hanversine经纬度换算法
地球半径使用6371000米。
经过验证，此算法换算的精度在一米左右。
## 位置与速度信息获取
ArduPilot提供的API有AHRS(Attitude Heading Reference System)和GPS两种获取位置和速度信息的方式。据了解，AHRS通过飞控自身的各种仪器计算自己的位置和速度，在近距离飞行下精度较高，GPS则在远距离飞行下精度较高。后期可以实验测试后选择这两种方式其一。\
此脚本使用的是AHRS。
## 投弹决策
此脚本设置了当计算得投弹落点与标靶距离小于3米时进行投弹操作，且每隔500ms进行一次投弹计算。这意味着脚本每隔500ms进行计算并决定此时是否投弹。具体时间的设置需要考虑到脚本的运行速度和飞控数据的传输速度。
