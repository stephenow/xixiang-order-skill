# 熙香订餐 Skill

这是给 Codex 使用的熙香企业订餐平台 Skill。安装后，同事可以让 Codex 打开熙香订餐网站、查看午餐和晚餐菜单、按明确要求或口味偏好选择餐品，并在下单后核对订单状态。

## 推荐安装方式

推荐直接用 Codex 安装这个 GitHub 仓库里的 Skill。

在 Codex 里对助手说：

```text
安装这个 skill：https://github.com/stephenow/xixiang-order-skill
```

安装完成后，可以这样使用：

```text
使用 xixiang-order-skill，帮我查看下周熙香午餐和晚餐菜单。我偏好清淡、少辣、不要海鲜，先给我推荐方案，确认后再下单。
```

如果已经知道要点什么，也可以直接说：

```text
使用 xixiang-order-skill，帮我订周一午餐的番茄牛腩饭和周一晚餐的鸡腿饭。
```

## 使用前准备

你需要准备熙香企业订餐平台的企业账号和密码。

如果你忘记了，可以在飞书的 2506 群的置顶链接的 PDF 里找到，也可以问 Yu。

## 它会怎么工作

- 登录熙香企业订餐平台。
- 查看目标日期的午餐和晚餐状态。
- 跳过已经订好的餐，除非你明确要求更换或取消。
- 如果你给了明确菜名，它会按你的要求下单并核对结果。
- 如果你只给了口味偏好，它会先整理推荐清单，等你确认后再提交。
- 下单后回到订餐日历，确认目标餐次显示已点餐和对应菜名。

## 示例指令

```text
使用 xixiang-order-skill，帮我订这周剩下所有工作日的午餐。我在减肥，给我热量最低的选项。
```

```text
使用 xixiang-order-skill，看看明天午餐有哪些选项，给我推荐一个重口味的。
```

```text
使用 xixiang-order-skill，检查我下周哪些餐还没订，列出来给我确认。
```

## 仓库内容

- `SKILL.md`：Skill 的主说明，Codex 会读取这里的规则。
- `references/ordering-workflow.md`：熙香订餐页面流程和已知页面行为。
- `agents/openai.yaml`：Codex/OpenAI 相关的展示配置。
