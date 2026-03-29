# DEPLOY

本文档只关注部署、配置和运维，不重复解释项目原理。

目标是让这个项目在 macOS 上稳定运行，并每天自动完成以下流程：

1. 抓取国际媒体 RSS 热点
2. 翻译为中英文对照内容
3. 生成 Excel
4. 发送到指定邮箱

## 1. 部署目标

部署完成后，项目会在每天 `09:00` 自动执行：

- 抓取国际新闻
- 使用 Google Cloud Translation 翻译中文
- 生成双语 Excel
- 发送邮件到目标邮箱

当前默认运行环境基于：

- macOS
- Python 3
- `launchd`
- QQ 邮箱 SMTP
- Google Cloud Translation API

## 2. 目录说明

项目目录：

```text
/Users/Jacob/international_news_digest
```

部署相关关键文件：

- [news_digest.py](/Users/Jacob/international_news_digest/news_digest.py)
  主程序。

- [run_news_digest.sh](/Users/Jacob/international_news_digest/run_news_digest.sh)
  定时任务调用入口。

- [com.jacob.internationalnewsdigest.plist](/Users/Jacob/international_news_digest/com.jacob.internationalnewsdigest.plist)
  macOS `launchd` 配置。

- [.env.example](/Users/Jacob/international_news_digest/.env.example)
  环境变量模板。

- [requirements.txt](/Users/Jacob/international_news_digest/requirements.txt)
  Python 依赖列表。

## 3. 环境要求

部署前请确认：

- 已安装 `python3`
- 已安装 `git`
- 当前机器可访问外网
- 已有 QQ 邮箱 SMTP 授权码
- 已开通 Google Cloud Translation API
- 已准备 Google 服务账号 JSON 文件

## 4. 安装步骤

如果你希望尽量自动化安装，可以直接使用 [setup.sh](/Users/Jacob/international_news_digest/setup.sh)：

```bash
cd /Users/Jacob/international_news_digest
chmod +x setup.sh
./setup.sh
```

它会自动完成：

- 创建虚拟环境
- 安装依赖
- 初始化 `.env`
- 安装并刷新 `launchd`
- 检查 `.env` 必填项是否缺失

首次执行后，你只需要继续编辑 `.env` 补全凭证即可。

### 4.1 克隆代码

```bash
cd /Users/Jacob
git clone https://github.com/renyanxiang/nes-report-task.git international_news_digest
cd /Users/Jacob/international_news_digest
```

如果目录已经存在，可以直接进入项目目录，不需要重复克隆。

### 4.2 创建虚拟环境

```bash
python3 -m venv .venv
source .venv/bin/activate
```

### 4.3 安装依赖

```bash
pip install -r requirements.txt
```

## 5. 配置环境变量

### 5.1 复制模板

```bash
cp .env.example .env
```

### 5.2 编辑 `.env`

参考配置如下：

```env
NEWS_DIGEST_SMTP_HOST=smtp.qq.com
NEWS_DIGEST_SMTP_PORT=465
NEWS_DIGEST_SMTP_USER=your_qq_mail@qq.com
NEWS_DIGEST_SMTP_PASSWORD=your_smtp_authorization_code
NEWS_DIGEST_SENDER=your_qq_mail@qq.com
NEWS_DIGEST_RECIPIENTS=363349082@qq.com
NEWS_DIGEST_SMTP_SSL=true

NEWS_DIGEST_TRANSLATION_PROVIDER=google
GOOGLE_APPLICATION_CREDENTIALS=/absolute/path/to/google-service-account.json
GOOGLE_CLOUD_PROJECT=your_google_cloud_project_id

OPENAI_API_KEY=your_openai_api_key
NEWS_DIGEST_OPENAI_MODEL=gpt-4o-mini
NEWS_DIGEST_TRANSLATION_BATCH_SIZE=8
```

说明：

- 默认翻译提供方是 `google`
- `OPENAI_API_KEY` 仅保留为备用翻译方案
- 使用 Google 方案时，关键字段是：
  - `NEWS_DIGEST_TRANSLATION_PROVIDER=google`
  - `GOOGLE_APPLICATION_CREDENTIALS`
  - `GOOGLE_CLOUD_PROJECT`

## 6. Google Cloud Translation 配置

### 6.1 开通 API

在 Google Cloud 控制台启用：

- Cloud Translation API

### 6.2 创建服务账号

需要创建一个带翻译权限的服务账号，并下载 JSON 凭证文件。

建议把 JSON 文件放到固定路径，例如：

```bash
/Users/Jacob/international_news_digest/google-translate-key.json
```

然后在 `.env` 中填写：

```env
GOOGLE_APPLICATION_CREDENTIALS=/Users/Jacob/international_news_digest/google-translate-key.json
GOOGLE_CLOUD_PROJECT=your_google_cloud_project_id
```

## 7. QQ 邮箱 SMTP 配置

### 7.1 开启 SMTP

进入 QQ 邮箱后台，开启 SMTP 服务。

### 7.2 获取授权码

这里使用的不是 QQ 登录密码，而是 SMTP 授权码。

`.env` 中应填写：

```env
NEWS_DIGEST_SMTP_PASSWORD=你的QQ邮箱授权码
```

## 8. 手动验证

在启用定时任务前，先手动跑一次：

```bash
cd /Users/Jacob/international_news_digest
source .venv/bin/activate
set -a
source .env
set +a
python news_digest.py --translate-zh --send-email --recipient 363349082@qq.com
```

验证点：

- 是否成功生成 Excel
- Excel 中是否有中文列
- 邮箱是否收到测试邮件
- 邮件正文是否为中文优先阅读版

## 9. 配置 macOS 定时任务

### 9.1 给启动脚本授权

```bash
chmod +x /Users/Jacob/international_news_digest/run_news_digest.sh
```

### 9.2 安装 LaunchAgent

```bash
mkdir -p ~/Library/LaunchAgents
cp /Users/Jacob/international_news_digest/com.jacob.internationalnewsdigest.plist \
  ~/Library/LaunchAgents/com.jacob.internationalnewsdigest.plist
```

### 9.3 注册并启用

```bash
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.jacob.internationalnewsdigest.plist 2>/dev/null || true
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.jacob.internationalnewsdigest.plist
launchctl enable gui/$(id -u)/com.jacob.internationalnewsdigest
```

### 9.4 手动触发

```bash
launchctl start com.jacob.internationalnewsdigest
```

### 9.5 查看状态

```bash
launchctl print gui/$(id -u)/com.jacob.internationalnewsdigest
```

## 10. 运行结果位置

### Excel 输出

```text
/Users/Jacob/international_news_digest/output
```

### 日志输出

```text
/Users/Jacob/international_news_digest/logs/news_digest.log
/Users/Jacob/international_news_digest/logs/launchd.stdout.log
/Users/Jacob/international_news_digest/logs/launchd.stderr.log
```

## 11. 日常运维命令

### 手动执行一次

```bash
/Users/Jacob/international_news_digest/run_news_digest.sh
```

### 查看最近日志

```bash
tail -n 50 /Users/Jacob/international_news_digest/logs/news_digest.log
tail -n 50 /Users/Jacob/international_news_digest/logs/launchd.stderr.log
```

### 停用定时任务

```bash
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.jacob.internationalnewsdigest.plist
```

### 重新启用定时任务

```bash
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.jacob.internationalnewsdigest.plist
launchctl enable gui/$(id -u)/com.jacob.internationalnewsdigest
```

## 12. 故障排查

### 12.1 邮件发送失败

优先检查：

- QQ 邮箱 SMTP 是否开启
- 授权码是否填写正确
- `NEWS_DIGEST_SMTP_PORT` 是否为 `465`
- `NEWS_DIGEST_SMTP_SSL` 是否为 `true`

### 12.2 翻译失败

优先检查：

- `NEWS_DIGEST_TRANSLATION_PROVIDER` 是否为 `google`
- `GOOGLE_APPLICATION_CREDENTIALS` 路径是否正确
- JSON 文件是否仍然存在
- Google Cloud Translation API 是否开启
- Google 项目是否绑定 billing

### 12.3 没有自动定时执行

优先检查：

- `launchctl print gui/$(id -u)/com.jacob.internationalnewsdigest`
- `plist` 是否在 `~/Library/LaunchAgents`
- `run_news_digest.sh` 是否有执行权限
- 当前机器在 `09:00` 是否处于开机并登录状态

### 12.4 Excel 没有中文内容

优先检查：

- 是否带了 `--translate-zh`
- `.env` 是否正确加载
- 是否调用了正确的翻译提供方

## 13. 安全建议

不要把以下文件提交到 GitHub：

- `.env`
- Google 服务账号 JSON
- `logs/`
- `output/`
- `.venv/`

这些内容已经在 [\.gitignore](/Users/Jacob/international_news_digest/.gitignore) 中排除。

## 14. 部署完成标准

满足以下几点即可认为部署完成：

- 依赖安装成功
- `.env` 配置完成
- Google 翻译能正常调用
- QQ 邮件能正常发送
- 手动运行能成功生成双语 Excel
- `launchd` 已注册成功
- 第二天 `09:00` 自动执行成功
