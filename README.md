# International News Digest

一个基于 Python 的国际新闻聚合脚本。

项目目标是每天定时抓取多家国际媒体的 RSS 热点资讯，做基础清洗和汇总，并输出为便于查看和归档的 Excel 文档。

当前项目已经支持：

- 抓取多家国际主流媒体 RSS
- 自动清洗标题和摘要中的 HTML
- 汇总文章列表
- 统计各媒体文章数量
- 基于标题词频提取热点主题
- 导出多工作表 Excel
- 支持将 Excel 作为邮件附件自动发送
- 支持通过 Google Cloud Translation 将新闻标题和摘要翻译为中文
- 支持手动执行一次
- 支持脚本内常驻调度
- 支持通过 macOS `launchd` 做系统级定时托管

## 项目结构

工程目录位于 [international_news_digest](/Users/Jacob/international_news_digest)。

主要文件说明：

- [news_digest.py](/Users/Jacob/international_news_digest/news_digest.py)
  核心程序。负责抓取 RSS、解析内容、清洗文本、汇总数据、生成 Excel，并提供命令行入口。

- [requirements.txt](/Users/Jacob/international_news_digest/requirements.txt)
  Python 依赖列表。

- [run_news_digest.sh](/Users/Jacob/international_news_digest/run_news_digest.sh)
  供 `launchd` 调用的启动脚本。固定使用本项目虚拟环境中的 Python，自动加载 `.env` 配置，并将输出写入日志。

- [com.jacob.internationalnewsdigest.plist](/Users/Jacob/international_news_digest/com.jacob.internationalnewsdigest.plist)
  macOS `LaunchAgent` 配置文件。定义每天 `09:00` 的定时触发规则。

- [output](/Users/Jacob/international_news_digest/output)
  Excel 输出目录。每天生成一个按日期命名的汇总文件。

- [logs](/Users/Jacob/international_news_digest/logs)
  运行日志目录。包含脚本执行日志和 `launchd` 标准输出、错误输出日志。

- [.venv](/Users/Jacob/international_news_digest/.venv)
  项目虚拟环境目录。

- [.env.example](/Users/Jacob/international_news_digest/.env.example)
  邮件发送和翻译配置模板。复制为 `.env` 后，填写 SMTP 参数和 Google Cloud 凭证即可启用邮件发送与中文翻译。

## 功能说明

### 1. 新闻抓取

脚本当前会抓取以下媒体源：

- BBC World
- CNN World
- The Guardian World
- Al Jazeera
- DW Top Stories
- Financial Times World
- New York Times World
- France 24

每个媒体源最多抓取最近 `12` 条资讯。

### 2. 文本清洗

脚本会对 RSS 条目中的以下内容进行清洗：

- 去除 HTML 标签
- 反转义 HTML 实体
- 折叠多余空白字符
- 规范化标题和摘要文本

### 3. 热点主题提取

脚本会对新闻标题做简单词频统计：

- 仅提取英文单词
- 过滤常见停用词
- 输出高频关键词及出现次数

这部分结果主要用于快速观察当天热点，不等同于严格的 NLP 主题建模。

### 4. Excel 导出

脚本会生成一个 `.xlsx` 文件，默认命名格式如下：

```text
international_news_digest_YYYYMMDD.xlsx
```

默认输出目录：

```text
/Users/Jacob/international_news_digest/output
```

Excel 包含 3 个工作表：

- `Summary`
  记录生成时间、文章总数、热点主题词频。

- `By Source`
  统计各媒体抓取到的文章数量。

- `Articles`
  保存完整文章列表。

`Articles` 工作表字段如下：

- `Source`
- `Published At`
- `Title`
- `Summary`
- `Link`

### 5. 邮件发送

脚本支持在生成 Excel 后自动发邮件。

邮件内容包括：

- 生成时间
- 文章总数
- 热点关键词
- 部分重点新闻链接
- Excel 附件

默认收件人已经设置为：

```text
363349082@qq.com
```

### 6. 中文翻译

脚本支持通过 Google Cloud Translation 将每条新闻的标题和摘要翻译成简体中文。

翻译结果会以中英文对照方式展示在 Excel 中：

- `Title (EN)`
- `标题（中文）`
- `Summary (EN)`
- `摘要（中文）`

邮件正文中的重点新闻标题也会附带中文译文。

## 技术实现

### 依赖

项目依赖非常轻量：

- `feedparser`
  用于解析 RSS / Atom Feed。

- `openpyxl`
  用于生成 Excel 文件。

- Python 标准库 `smtplib` / `email`
  用于发送带附件的邮件。

- `google-cloud-translate`
  用于调用 Google Cloud Translation API 做中英文翻译。

- `openai`
  作为备用翻译提供方保留在项目中，不作为默认方案。

### 核心实现逻辑

[news_digest.py](/Users/Jacob/international_news_digest/news_digest.py) 的主要逻辑可以概括为以下几个步骤：

1. 定义 RSS 数据源列表。
2. 逐个请求 RSS 源并解析条目。
3. 提取标题、摘要、链接、发布时间。
4. 清洗 HTML 和多余空白字符。
5. 将所有媒体结果合并为统一结构。
6. 对标题做词频统计，生成热点主题摘要。
7. 按发布时间倒序写入 Excel。
8. 输出到 `output` 目录。
9. 如果启用了邮件发送，则将 Excel 作为附件发送到指定邮箱。
10. 如果启用了翻译，则调用翻译 API 生成中文标题和中文摘要，并回写到 Excel。

### 关键函数

- `fetch_feed`
  拉取单个 RSS 源并解析成统一字典结构。

- `strip_html`
  负责文本清洗。

- `build_topic_summary`
  对标题做词频统计，提取热点关键词。

- `write_excel`
  将摘要、来源统计和文章明细写入 Excel。

- `run_once`
  执行一次完整抓取和导出流程。

- `run_scheduler`
  作为常驻进程运行，在指定时间每天执行一次。

- `send_digest_email`
  负责构造邮件、附加 Excel 并通过 SMTP 发信。

- `translate_items_to_chinese`
  负责调用翻译提供方，将新闻标题和摘要翻译成简体中文。

## 运行逻辑

### 模式一：手动执行一次

直接运行：

```bash
cd /Users/Jacob/international_news_digest
source .venv/bin/activate
python3 news_digest.py
```

该模式适合：

- 临时查看当日新闻
- 手动验证脚本是否正常
- 调试抓取结果

### 模式二：脚本内常驻调度

直接让 Python 进程保持运行：

```bash
python3 news_digest.py --daemon --timezone Asia/Shanghai --hour 9 --minute 0
```

该模式下程序会：

- 常驻运行
- 计算距离下一次执行时间的秒数
- 等待到指定时间
- 自动抓取并生成 Excel
- 继续等待下一天

这种方式实现简单，但依赖当前 Python 进程一直存活，不适合长期托管。

### 模式三：macOS `launchd` 托管

这是当前项目推荐的方式。

`launchd` 会在用户登录后托管任务，并在每天上午 `09:00` 调用 [run_news_digest.sh](/Users/Jacob/international_news_digest/run_news_digest.sh)，再由该脚本调用虚拟环境中的 Python 解释器执行 [news_digest.py](/Users/Jacob/international_news_digest/news_digest.py)。

执行链路如下：

```text
launchd
  -> run_news_digest.sh
  -> .env
  -> .venv/bin/python
  -> news_digest.py
  -> output/*.xlsx
  -> SMTP server
  -> Google Cloud Translation API
  -> logs/*.log
```

## 安装与初始化

### 1. 创建虚拟环境并安装依赖

```bash
cd /Users/Jacob/international_news_digest
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 2. 手动执行一次

```bash
python3 news_digest.py
```

### 3. 给启动脚本添加执行权限

```bash
chmod +x /Users/Jacob/international_news_digest/run_news_digest.sh
```

### 4. 配置邮件发送

先复制模板文件：

```bash
cp /Users/Jacob/international_news_digest/.env.example /Users/Jacob/international_news_digest/.env
```

然后编辑 [\.env](/Users/Jacob/international_news_digest/.env) 并填写 SMTP 参数：

```text
NEWS_DIGEST_SMTP_HOST=smtp.qq.com
NEWS_DIGEST_SMTP_PORT=465
NEWS_DIGEST_SMTP_USER=你的QQ邮箱
NEWS_DIGEST_SMTP_PASSWORD=你的QQ邮箱SMTP授权码
NEWS_DIGEST_SENDER=你的QQ邮箱
NEWS_DIGEST_RECIPIENTS=363349082@qq.com
NEWS_DIGEST_SMTP_SSL=true
NEWS_DIGEST_TRANSLATION_PROVIDER=google
GOOGLE_APPLICATION_CREDENTIALS=你的Google服务账号JSON绝对路径
GOOGLE_CLOUD_PROJECT=你的GoogleCloud项目ID
OPENAI_API_KEY=你的OpenAI_API_Key
NEWS_DIGEST_OPENAI_MODEL=gpt-4o-mini
NEWS_DIGEST_TRANSLATION_BATCH_SIZE=8
```

推荐优先使用 Google 翻译。`OPENAI_API_KEY` 仅作为备用翻译方案保留，不是默认必填项。

对 QQ 邮箱要特别注意：

- `NEWS_DIGEST_SMTP_PASSWORD` 不是登录密码
- 这里必须填写 QQ 邮箱后台生成的 SMTP 授权码

## macOS 定时任务配置

### 安装 LaunchAgent

将 `plist` 文件复制到用户级 LaunchAgents 目录：

```bash
mkdir -p ~/Library/LaunchAgents
cp /Users/Jacob/international_news_digest/com.jacob.internationalnewsdigest.plist \
  ~/Library/LaunchAgents/com.jacob.internationalnewsdigest.plist
```

### 注册并启用任务

推荐使用：

```bash
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.jacob.internationalnewsdigest.plist
launchctl enable gui/$(id -u)/com.jacob.internationalnewsdigest
```

如果需要重装：

```bash
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.jacob.internationalnewsdigest.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.jacob.internationalnewsdigest.plist
launchctl enable gui/$(id -u)/com.jacob.internationalnewsdigest
```

### 手动触发一次

```bash
launchctl start com.jacob.internationalnewsdigest
```

只要 [run_news_digest.sh](/Users/Jacob/international_news_digest/run_news_digest.sh) 能读取到完整的 `.env` 配置，定时任务每次执行后都会自动发邮件。

### 查看任务状态

```bash
launchctl print gui/$(id -u)/com.jacob.internationalnewsdigest
```

### 停用任务

```bash
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.jacob.internationalnewsdigest.plist
```

## 日志与输出

日志文件位置：

- [news_digest.log](/Users/Jacob/international_news_digest/logs/news_digest.log)
  记录脚本本身的执行结果。

- [launchd.stdout.log](/Users/Jacob/international_news_digest/logs/launchd.stdout.log)
  记录 `launchd` 标准输出。

- [launchd.stderr.log](/Users/Jacob/international_news_digest/logs/launchd.stderr.log)
  记录 `launchd` 错误输出。

Excel 输出位置：

- [output](/Users/Jacob/international_news_digest/output)

查看最新日志：

```bash
tail -n 50 /Users/Jacob/international_news_digest/logs/news_digest.log
tail -n 50 /Users/Jacob/international_news_digest/logs/launchd.stderr.log
```

邮件发送成功后，日志中会出现类似内容：

```text
[INFO] Email sent to: 363349082@qq.com
```

## 参数说明

脚本支持以下命令行参数：

- `--output-dir`
  指定 Excel 输出目录。

- `--timezone`
  指定时区，默认是 `Asia/Shanghai`。

- `--hour`
  指定调度小时，默认是 `9`。

- `--minute`
  指定调度分钟，默认是 `0`。

- `--daemon`
  启用常驻调度模式。

- `--send-email`
  在生成 Excel 后发送邮件。

- `--recipient`
  指定默认收件人。如果环境变量 `NEWS_DIGEST_RECIPIENTS` 已设置，则以环境变量为准。

- `--translate-zh`
  启用中文翻译，将标题和摘要以中英文对照形式写入 Excel。

示例：

```bash
python3 news_digest.py --output-dir ./output --timezone Asia/Shanghai
python3 news_digest.py --daemon --timezone Asia/Shanghai --hour 9 --minute 0
python3 news_digest.py --send-email --recipient 363349082@qq.com
python3 news_digest.py --translate-zh --send-email --recipient 363349082@qq.com
```

## 运行时行为与容错

项目包含一些基础容错设计：

- 为网络请求设置了默认超时，避免单个 RSS 源长时间卡住整个任务
- 当某个媒体源解析失败时，仅输出警告，不会阻塞全部任务
- 输出目录不存在时会自动创建
- Excel 文件会按当天日期覆盖生成，便于保留每日一份汇总
- 如果启用了邮件发送但 SMTP 配置不完整，会明确提示配置缺失
- 如果启用了翻译但所选翻译提供方的凭证未配置，会明确提示无法翻译

需要注意：

- 如果当天重复执行，多次运行会覆盖同一天的同名 Excel 文件
- 如果需要保留同一天的多个版本，可以后续把文件名改成包含时分秒

## 已知限制

### 1. 关机状态下无法执行

如果电脑在 `09:00` 这一刻处于真正关机状态，macOS 无法替你执行 `LaunchAgent`。这是操作系统层面的限制。

当前方案能够保证的是：

- 开机并登录后自动托管
- 每天 `09:00` 在机器在线时自动运行
- 重启后无需手动重新启动任务

如果你需要更强的连续性，可以考虑：

- 让电脑保持开机或睡眠
- 配置自动唤醒
- 把该脚本迁移到云服务器

### 2. 主题提取较基础

当前热点主题提取基于标题词频，而不是更复杂的语义聚类或多语言主题建模，因此它更适合快速浏览，不适合严格研究分析。

### 3. 数据质量受 RSS 源影响

不同媒体 RSS 的字段完整度不同，发布时间、摘要和链接质量可能不完全一致。

### 4. 邮件发送依赖 SMTP 配置

如果 `.env` 中的 SMTP 参数不完整，脚本无法真正把 Excel 发到邮箱。

对 QQ 邮箱来说，通常需要：

- 开启 SMTP 服务
- 获取授权码
- 正确配置主机、端口和 SSL

### 5. 中文翻译依赖翻译服务配置

默认推荐使用 Google Cloud Translation。

如果未设置 Google Cloud 凭证，脚本不能执行中文翻译，但仍可保留原有英文抓取和邮件发送能力。

Google 方案通常需要：

- 开通 Google Cloud Translation API
- 创建服务账号
- 下载服务账号 JSON 文件
- 在 `.env` 中填写 `GOOGLE_APPLICATION_CREDENTIALS` 和 `GOOGLE_CLOUD_PROJECT`

如果你想使用 OpenAI 作为备用方案，再额外设置：

- `NEWS_DIGEST_TRANSLATION_PROVIDER=openai`
- `OPENAI_API_KEY`

## 可扩展方向

如果后续继续扩展，这个工程比较适合从以下方向演进：

- 增加更多媒体源
- 加入中文翻译
- 对新闻按地区、主题、来源做分类
- 支持去重
- 支持邮件发送或企业微信/钉钉推送
- 支持将结果写入数据库
- 支持保留历史索引并做趋势分析
- 用更强的 NLP 方法提取主题和摘要
- 支持多收件人、抄送和更丰富的邮件模板
- 支持中文摘要二次压缩和按主题自动生成中文晨报

## 当前验证结果

当前工程已经在本机完成验证：

- Python 脚本可正常运行
- Excel 可成功生成到 [output](/Users/Jacob/international_news_digest/output)
- 启动脚本可正常执行
- macOS `launchd` 定时任务已可注册并运行
- 邮件发送逻辑已接入代码，待填写 SMTP 授权配置后即可实发
- Google 翻译逻辑已接入代码，待填写 Google Cloud 凭证后即可实发

最近一次生成文件示例：

- [international_news_digest_20260326.xlsx](/Users/Jacob/international_news_digest/output/international_news_digest_20260326.xlsx)

## 维护建议

建议定期检查以下内容：

- RSS 地址是否仍然可用
- 媒体是否调整了 Feed 结构
- 虚拟环境依赖是否需要升级
- `logs` 目录是否需要轮转清理
- 是否需要保留历史版本输出
- `.env` 中的 SMTP 授权码是否仍然有效
- Google 服务账号 JSON 路径是否仍然有效，项目权限是否完整
- 如果使用 OpenAI 备用方案，`OPENAI_API_KEY` 是否仍然有效

如果你后续要把它交给别人维护，这个 README 已经足够作为入门文档和运行手册使用。

## 修订历史

### 2026-03-26

- 初始化项目，完成国际媒体 RSS 聚合脚本
- 支持抓取 BBC、CNN、The Guardian、Al Jazeera、DW、Financial Times、New York Times、France 24
- 实现新闻标题、摘要、链接和发布时间的统一清洗与汇总
- 实现 Excel 导出，生成 `Summary`、`By Source`、`Articles` 三个工作表
- 增加标题词频统计，用于热点主题提取
- 增加网络超时和单个媒体源失败容错
- 增加常驻调度模式，支持每天指定时间执行
- 增加 macOS `launchd` 托管能力
- 增加 `run_news_digest.sh` 启动脚本和 `LaunchAgent plist` 配置
- 增加日志输出目录与运行日志记录
- 增加 SMTP 邮件发送能力，支持将 Excel 作为附件发送
- 增加翻译能力，支持标题和摘要中英文对照输出
- 新增 `.env.example`，用于邮件发送配置
- 默认收件人设置为 `363349082@qq.com`
- 完整补充 README，覆盖工程结构、功能说明、运行逻辑、部署方式、日志、限制和维护建议
