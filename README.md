# 自定义Common包

### 注意事项

**以下注意事项请严格遵守！！！！！！！**

1. 基础类库有任何修改都需要重新集成Common包至原生APP中，业务包如果更改，可以不重新集成
2. 同一个APP中的所有业务必须使用同一个common包，否则可能出现加载错误
3. 业务拆分包在控制台发布新版本后，需重新打业务拆分包到原生APP中，否则新版本后仍然会触发下载
4. 多个业务公用的组件库，需要下沉至基础组件库，缩小拆分包体积
5. 不要手动修改 `commonBundleConfig.android.json`和`commonBundleConfig.ios.json`
6. Common包集成到原生APP后需回归验证高UV是否可用。
7. 建议单一团队维护Common包，并且使用Jenkins自动化工具实现自动打包并提交到原生工程。


#### 1、 添加自定义Common依赖

执行以下命令安装自定义依赖

```bash
npm install
npm run cp
npm install --save XXX/XXXXX
```

在`jsbundles/JDReactCommon.js`中直接require对应代码库即可。示例如下：

```javescript
var XXXXLib = require('XXX/XXXXX');
```

如需使用自动提交脚本，需配置`jdreact.properties`文件来指定JSBundle以及资源文件的相对路径，如下所示：

```bash
# Android 代码库中 assets文件夹相对路径，用于Jenkins自动提交脚本，如为手动打包，无需配置。
CUSTOM_ANDROID_JDREACT_ASSETS=app/src/main/assets
# Android 代码库中 drawable文件夹相对路径，用于Jenkins自动提交脚本，如为手动打包，无需配置。
CUSTOM_ANDROID_JDREACT_DRAWABLE=app/src/main/res
# iOS 代码库中 react.bundle文件夹相对路径，用于Jenkins自动提交脚本，如为手动打包，无需配置。
CUSTOM_IOS_JDREACT_BUNDLE_PATH=JDReactLiteBaseUpgradeDemo/JDReactLiteBaseUpgradeDemo
# 公共图片库路径
COMMON_ASSETS=@ares/example-core-lib/src/assets
```


#### 2、手动打包JDReactCommon

* 手动打包需要清空本地所有依赖，防止出现缓存问题。

  ```bash
  rm -rf node_module
  rm -rf package-lock.json
  rm -rf yarn.lock
  npm cache clean --force
  npm install
  npm run cp
  ```

* 执行以下命令即可打包，-p 为android或者ios
 
```
./scripts/make-common-jsbundles.sh -p android
```

完成后产物在outputBundle-android或outputBundle-ios中，需将对应产物提交到原生工程代码库中。

* 发布自定义的Common。

  发布npm教程可以参考[点击这里](https://docs.npmjs.com/cli/v6/commands/npm-publish)。执行以下命令进行发布

```bash
npm publish
```

#### 3、配置业务拆分Common包配置文件

注：只有内置包才会使用业务拆分包，热修复使用的是全量包。(内置包为打包进原生工程的jsbundle)

*  在业务代码新增Common包配置文件
  
    在业务RN工程中新增jdreact.config.js。内容示例如下:

```javascript
module.exports = {
    //拆分包npm包名
    commonpack: "libpack",
    //可选参数，业务包id起始值。默认为5000，最小5000，防止出现id冲突
    //如果commonBundleConfig.android.json 或者 commonBundleConfig.ios.json中最大的id超过5000，
    //需要适当设置businessStartID参数大小，默认是5000。并且所有业务需要统一，并且重新打所有业务拆分包。
    //businessStartID: 10000
}
```

* 删除本地缓存，并重新安装(必需，需要用最新的Common包进行拆包)

```bash
rm -rf node_modules
rm -rf package-lock.json
npm install
npm install --save-dev libpack
```
* 提交package.json


#### 4、手动打业务拆分包到原生工程
  
手动打包需要清空本地所有依赖，防止出现缓存问题。

  ```bash
  rm -rf node_module
  rm -rf package-lock.json
  rm -rf yarn.lock
  npm cache clean --force
  npm install
  npm run cp
  ```

执行以下命令即可拆包，-p 为平台，可选参数为android、ios。-m 为模块名字

```bash
./scripts/make-business-jsbundles-standalone.sh -p ios -m JDReactAPIDemos
```

业务拆分包产物在outputBundle中，需将对应产物提交到原生工程代码库中。

#### 5、Jenkins自动集成Common包到原生工程

本脚本主要功能如下：打Common包，并提交至对应平台的原生代码中，并发布npm，将该修改到本git中。
配置如下：
注：需提前clone原生工程到Jenkins机器，并给该git账户push权限。

```bash
export PATH=$PATH:/usr/local/bin
npm cache clean --force
npm install
npm run cp
#auto-build-commonpack-standalone.sh 参数说明
# 参数1：平台 ios或android
# 参数2：git库路径，事先clone的ios或android路径
# 参数3：原生代码分支
# 参数4: 打Common包的JS代码分支
./scripts/auto-build-commonpack-standalone.sh 'ios' 原生工程路径 ${Branch} ${jsBranch}
```

#### 6、Jenkins自动集成业务拆分包到原生工程

本脚本主要功能如下：打业务拆分包，并提交至对应平台的原生代码中。
配置如下：
注：需提前clone原生工程到Jenkins机器，并给该git账户push权限。

```bash
export PATH=$PATH:/usr/local/bin
rm -rf outputBundle
rm -rf node_modules
rm -rf scripts
rm -rf yarn.lock
rm -rf package-lock.json
npm install
#auto-commit-jsbundles-standalone.sh 参数说明
# 参数1：平台 ios或android
# 参数2：git库路径，事先clone的ios或android路径
# 参数3：原生代码分支
# 参数4: 业务包moduleName
./scripts/auto-commit-jsbundles-standalone.sh 'ios' 原生工程路径 $Branch $moduleName

```