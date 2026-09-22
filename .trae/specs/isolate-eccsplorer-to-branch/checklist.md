# Checklist

- [x] 已定义哪些代码文件和目录属于 ECCsplorer 归属范围
- [x] 已定义哪些配置、样本表、测试数据和脚本属于 ECCsplorer 归属范围
- [x] 已定义哪些规格文档需要跟随 ECCsplorer 分支迁移

- [x] 已明确定义 `master` 的职责边界
- [x] 已明确定义 `ECCsplorer` 分支的职责边界
- [x] 已明确今后 ECCsplorer 相关开发只在 `ECCsplorer` 分支进行

- [x] 已定义 `master` 回退到 pre-ECCsplorer 状态的方案
- [x] 已定义从主线移除 ECCsplorer 内容的规则
- [x] 已定义避免误删非 ECCsplorer 功能的保护规则

- [x] 已定义 `ECCsplorer` 分支如何承接现有模块、参数、测试与数据
- [x] 已定义 `modularize-eccsplorer-modes` 在 `ECCsplorer` 分支上的继续实施方式
- [x] 已定义 `ECCsplorer` 分支的测试与版本策略

- [x] 已定义 branch/worktree 的推荐操作顺序
- [x] 已定义当前脏工作区的处理策略
- [x] 已定义 `master` 的最小验证范围（本次至少执行 `git status --short --branch`、`git rev-parse HEAD` 与 `nextflow config -profile test_local`）
- [x] 已定义 `ECCsplorer` 分支的最小验证范围（本次至少执行 `git status` 与 `nextflow config -profile test_local`）
- [x] 已定义 `test_local`、`-resume`、数据库准备所在分支

- [x] 已定义与现有 spec 的关系和迁移规则
