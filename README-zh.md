# 自托管Sentry每日构建版

使用 [Docker](https://www.docker.com/) 运行您自己的 [Sentry](https://sentry.io/) 的官方引导程序。

## 要求

* Docker 19.03.6+
* Compose 2.0.1+
* 4个CPU内核
* 16 GB RAM
* 20 GB可用磁盘空间

## 设置

### 安装

要使用所有默认设置开始,只需克隆存储库并在本地签出中运行`./install.sh`。 请也阅读下面的监控部分。 Sentry默认自2020年12月4日起使用Python 3,Sentry 21.1.0是支持Python 2的最后一个版本。

在安装过程中,会提示是否要创建用户帐户。 如果需要在不创建用户的情况下继续安装,请运行`./install.sh --skip-user-creation`。

不想自己管理这个?查看[SaaS迁移文档](https://docs.sentry.io/product/sentry-basics/migration/)或[联系我们](https://sentry.io/from/self-hosted)寻求帮助。

有关所有其他信息,请访问[我们的文档](https://develop.sentry.dev/self-hosted/)。

### 自定义DotEnv (.env)文件

可以在`.env.custom`文件中进行特定于环境的配置。 它将位于Sentry安装的根目录中,如果它存在,则完全忽略`.env`。

默认情况下,不存在`.env.custom`文件。 在这种情况下,您可以通过将`.env`文件复制到新的`.env.custom`文件并在`.env.custom`文件中调整设置来手动添加此文件。

请记住,当您升级Sentry时要检查`.env`文件中的更改,以便在必要时相应地调整`.env.custom`,因为如果存在`.env.custom`,则完全忽略`.env`。

### 增强Sentry映像

要安装插件及其依赖项或对Sentry基本映像进行其他修改,请将`sentry/enhance-image.example.sh`复制到`sentry/enhance-image.sh`,并在其中添加必要的步骤。 例如,您可以使用`apt-get`安装依赖项,并使用`pip`安装插件。

修改`sentry/enhance-image.sh`后,再次运行`./install.sh`以应用修改。

## 技巧和窍门

### 事件保留

Sentry附带了一个清理定时任务,默认情况下会删除90天以上的事件。如果要更改,可以在`.env`中更改`SENTRY_EVENT_RETENTION_DAYS`环境变量,或者简单地在环境中重写它。 如果您不想要清理定时任务,可以从`docker-compose.yml`文件中删除`sentry-cleanup`服务。

### 安装特定的SHA

如果要安装Sentry的特定版本,请使用此仓库上的标签/版本。

我们会连续地将Docker镜像推送到 [Sentry](https://github.com/getsentry/sentry) 中的每个提交,以及其他服务,例如 [Snuba](https://github.com/getsentry/snuba) 或 [Symbolicator](https://github.com/getsentry/symbolicator) 到[我们的 Docker Hub](https://hub.docker.com/u/getsentry),并将master分支上的最新版本标记为`:nightly`。这通常也是我们在sentry.io上使用的,也是安装脚本使用的。您可以使用自定义Sentry映像,例如您自己构建的修改版本,或者简单地使用特定的提交哈希值,方法是在运行 `./install.sh` 之前将 `SENTRY_IMAGE` 环境变量设置为该图像名称:

```shell
SENTRY_IMAGE=getsentry/sentry:83b1380 ./install.sh
```

请注意,随着此存储库与Sentry及其卫星项目的发展,这可能并不适用于所有提交SHA。强烈建议您查看与要安装的Sentry提交的时间戳接近的此存储库的版本。

### 使用 Linux

如果您使用 Linux 并且在运行 `./install.sh` 时需要使用 `sudo`,请确保将环境变量放在 `sudo` 之后:

```shell  
sudo SENTRY_IMAGE=us.gcr.io/sentryio/sentry:83b1380 ./install.sh
```

将 `83b1380` 替换为您要使用的 sha。

### 自托管监控

我们很乐意在自托管中捕获错误,这样您就不会遇到它们,我们也可以更快地修复它们! 当您运行 `./install.sh` 时,系统会提示您选择加入或退出我们的监控。 如果您选择加入我们的监控,我们将向我们自己的自托管 Sentry 实例发送信息用于开发和调试目的。 我们可能会收集:

- 操作系统用户名
- IP 地址
- 安装日志
- Sentry 中的运行时错误
- 性能数据

保留30天。无营销。隐私政策在 sentry.io/privacy。

从 10 月的 22.10.0 版本开始,我们将要求运行 Sentry 安装程序的用户选择加入或退出。 如果您在自动化下运行安装程序,您可能希望相应地设置 `REPORT_SELF_HOSTED_ISSUES` 或向安装程序传递 `--(no-)report-self-hosted-issues`。
