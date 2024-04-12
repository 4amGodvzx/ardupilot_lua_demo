# LUA Script
官方文档：\
https://ardupilot.org/dev/docs/common-lua-scripts.html \
启动SITL模拟器后输入 \
```param set SCR_ENABLE 1``` \
然后退出SITL，此时你启动SITL所用的终端所在的目录下会新建一个名为`Scripts`的文件夹，将.lua文件放置在这后启动SITL便会在SITL内自动加载。 \
在飞控内加载LUA脚本的方法参考官方文档 \
在脚本内，SITL模拟器加载的函数入口如下
```lua
function update()
  --主函数内容
  return update,1000
end
return update,1000
```
其中`update()`函数外的`return update,1000`意为这个函数将在加载LUA脚本后1000ms执行，函数外的`return update,1000`意为这个函数每隔1000ms会执行一次，具体参考官方文档 \
ArduPilot提供的API函数接口也在官方文档的首页中。
