#<font style="color:red;">注意</font>
>由于Git不支持上传大于100MB的文件，所以项目源码中不包含 **libHyphenateFullSDK.a** 文件，下载地址https://pan.baidu.com/s/1c1CrKWC ，然后拷贝到目录【/ChatDemo-UI3.0-Sample/ChatDemo-UI3.0/ChatSDK/HyphenateFullSDK/lib】才能正常运行。

###希望支持简版Demo的童鞋能够到Github给我们一个star^_^
https://github.com/mengmakies/ChatDemo-UI3.00-Simple

<img src="http://www.imgeek.org/uploads/article/20161108/903cc20467037cedf6de9eebce7862cd.png" width = "35%" height = "auto" alt="图片名称" align=center /> 
###说明
本项目是基于官方 **ChatDemo-UI3.0** 项目的简化封装，目的是为了让大家更加方便快速地集成环信IM功能。

###其他Git仓库

>国内访问速度比较慢的朋友可以考虑从国内的Git仓库拉取代码:
>开源中国社区-中国:http://git.oschina.net/markies/ChatDemo-UI3.00-Simple


###奋斗目标
1. 分离第三方依赖库，避免与开发者现有项目的其它类库发生冲突；
2. 抽象开发者可定制化的方法或配置参数；
3. 其它未确定的封装工作，最终目的：高内聚，低耦合；
4. 整理开发者开始集成时反馈的常见性问题，从实际项目考虑优化SDK集成的简易度。


###最终成果
1.便于开发者在新项目或现有项目快速集成环信SDK，实现聊天界面和会话列表功能，而且可以灵活地定制化一些基础模块；
2.低耦合，用尽可能少的代码集成环信功能，尽量少污染开发者的项目代码；

![输入图片说明](http://avatar.csdn.net/A/2/1/1_mengmakies.jpg "在这里输入图片标题")
如有任何问题，请联系QQ： **364223587** 
 
----
经过对ChatUIDemo-UI3.0中的源码进行分析可知，用户初次集成EaseUI时，会遇到如下几个常见问题：

###问题1
>引用Parse.framework、Bolts.framework时项目容易出错或出现Not found问题，其实这两个库并不是必须的，而且Facebook已经确定在2017年1月份停止提供Parse服务。  
**解决方案**：删除Parse相关类，用 UserCacheManager替代管理用户本地缓存，用UserWebManager管理后端云缓存。

###问题2
>ChatDemoHelper辅助类集成了很多聊天相关界面的操作方法，开发者一般会直接复用，但是ChatDemoHelper对MainViewController的函数依赖度比较高，比如
```c++
[weakself.mainVC setupUnreadMessageCount];
[self.mainVC networkChanged:connectionState];
```
**解决方案**：（1）将ChatDemoHelper中的mainVC类型更换成UIViewController；（2）.将MainController中的几个方法用通知(NSNotificationCenter)实现；

###问题3
>聊天相关页面与业务逻辑页面放在同一目录中，对于开发者来说，需要分拣；
**解决方案**：将环信相关的文件、资源统一放在【ChatUI】和【ChatSDK】目录中，方便开发者直接拖拽这两个文件夹即可快速集成聊天功能。

###关于昵称和头像的问题
IOS中如何显示开发者服务器上的昵称和头像
http://community.easemob.com/article/825307855

**【最新解决方案】**草草们的忧伤：环信IM昵称和头像（**使用后端云缓存**）
http://www.imgeek.org/article/825308536

>- 如有任何问题，请咨询【环信IM互帮互助群】，群号：340452063
>- 或者加本人QQ：364223587
>- 源码详细说明介绍请看http://community.easemob.com/article/825307886
>-【简书】地址：http://www.jianshu.com/p/c0c30707bf0c  欢迎拍砖！！！

###更新日志（平均每2个月同步更新环信官方SDK）
>2016.12...  敬请期待...
>2016.10.25  同步更新官方V3.2.0版SDK；适配IOS10；使用Leancloud后端云存储用户信息；
