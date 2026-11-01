# OpenClash + AdGuard Optimizer

[![CI](https://github.com/Mark-Tee/openclash-adguard-toolkit/actions/workflows/ci.yml/badge.svg)](https://github.com/Mark-Tee/openclash-adguard-toolkit/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A Codex skill and safety-first toolkit for auditing and optimizing OpenWrt /
iStoreOS networks that run OpenClash/Mihomo with AdGuard Home.

It helps diagnose DNS loops, Fake-IP mistakes, domestic/foreign routing errors,
Steam/CDN split routing, and unsafe rule updates without exposing router
credentials.

> This is an independent community project. It is not affiliated with OpenWrt,
iStoreOS, OpenClash, Mihomo, AdGuard, Valve, or Tailscale.

一个可被 Codex 直接读取和复用的软路由优化 Skill。适用于 OpenWrt / iStoreOS +
OpenClash / Mihomo + AdGuard Home 的组合。

## 解决什么问题

- AdGuard 绕过 OpenClash DNS，导致 Fake-IP 和分流规则失效
- 国内/国外 DNS 抢答，首次解析慢
- 国内网站误走付费节点，浪费流量
- Dota 2、Steam 国服接受比赛后卡在“正在连接”
- 黑名单过多、重复或误杀关键游戏域名
- AdGuard/OpenClash 双 DNS 环、端口冲突和重复实例

## 推荐拓扑

```text
LAN 客户端
    -> dnsmasq :53
    -> AdGuard Home :5454
    -> OpenClash DNS :7874
    -> Fake-IP + 国内直连 / 国外代理
```

关键点不是“所有 DNS 都走节点”，而是让 AdGuard 完成过滤，再由 OpenClash
决定域名是否需要代理。真实网页和游戏流量的走线仍由 Mihomo 规则决定。

## 使用方式

### 在 Codex 中直接打开

克隆仓库后让 Codex 读取根目录的 `SKILL.md`。仓库里的 `AGENTS.md` 会提醒 Codex
先做只读审计、备份并避免提交敏感信息。

```powershell
git clone <PRIVATE_REPO_URL>
cd openclash-adguard-optimizer
```

然后可以直接对 Codex 说：

```text
使用 $openclash-adguard-optimizer 审计并优化我的 OpenClash + AdGuard。
先只读检查，不要修改 network/dhcp/firewall。
```

### English quick start

```text
Use $openclash-adguard-optimizer to audit my OpenWrt router running
OpenClash/Mihomo and AdGuard Home. Start read-only. Do not change
network, DHCP, firewall, Wi-Fi, or interface configuration.
```

### 安装为本地 Skill

把整个目录放到 Codex 的 skills 目录：

```text
$CODEX_HOME/skills/openclash-adguard-optimizer
```

未设置 `CODEX_HOME` 时通常是：

```text
~/.codex/skills/openclash-adguard-optimizer
```

## 仓库内容

- `SKILL.md`：Codex 使用说明和安全边界
- `references/architecture.md`：DNS/分流拓扑与不变量
- `references/runbook.md`：备份、候选、校验、应用和回滚流程
- `references/troubleshooting.md`：常见 DNS、Fake-IP、游戏连接问题
- `references/metacubexd.md`：MetaCubeXD、健康检查和信息占位节点处理
- `references/case-study.md`：脱敏后的真实优化案例和结果
- `scripts/`：只读审计、候选生成和验证工具
- `assets/`：Steam/Dota 国服直连与 AdGuard 白名单模板

Steam 社区主站和静态资源较慢时，不要在“全部直连”和“全局换节点”之间
二选一。可先审计实际连接链，再为 Steam 网页创建独立选择组，让游戏下载、
Steam CM 和游戏 UDP 继续保持直连。

## 脚本

```text
python scripts/audit_adguard.py <AdGuardHome.yaml>
python scripts/audit_openclash.py <active-openclash.yaml>
python scripts/make_adguard_candidate.py <input.yaml> <output.yaml> <allowlist.txt>
python scripts/make_openclash_candidate.py <active.yaml> <custom.list> <output.yaml>
powershell scripts/Inspect-AdGuard.ps1 -BaseUrl http://ROUTER:3000
powershell scripts/Bootstrap-RouterSshKey.ps1 -Router ROUTER
powershell scripts/Test-Routing.ps1 -DnsServer ROUTER_IP
sh scripts/apply_openclash_custom_rules.sh <candidate.list> <marker-rule>
sh scripts/apply_adguard_config.sh <candidate.yaml>
sh scripts/apply_metacubex_settings.sh
ruby scripts/filter_pseudo_nodes.rb <active-openclash.yaml>
ruby scripts/add_fakeip_filter_entries.rb <active.yaml> '+.example.com'
ruby scripts/add_steam_web_group.rb <active.yaml> <group-name> <node-regex> [preferred-node ...]
```

写操作脚本要求显式环境变量，并默认先备份、后校验、失败回滚。

Python 依赖：

```powershell
python -m pip install -r requirements.txt
```

## 安全

- 仓库只包含通用规则、脚本和脱敏文档
- 不包含订阅地址、节点信息、密码、Token、私钥或原始配置
- 所有改动都应在路由器侧备份
- 不修改 `network`、`dhcp`、`firewall` 系统配置
- 不在 issue、日志或截图中公开订阅地址、节点凭据、密码、Token 或完整配置

安全问题请按 [SECURITY.md](SECURITY.md) 私下报告。

## 许可

本项目使用 MIT License。引用的第三方项目与数据源见 `NOTICE.md` 和
`references/sources.md`。

## 项目续接

[项目交接与验证状态](docs/PROJECT_STATUS.md)：关键规则、已知限制与后续验证。

## 稳定性维护

[稳定性检查与维护指南](references/stability-maintenance.md)：重复服务、计划任务、固定出口及最小变更验证。
