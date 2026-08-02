# Checklist

## 阶段一：Conda 包与 Docker 镜像

- [x] 已检查 `quay.io/biocontainers/eccsplorer` 是否存在 → 不存在
- [x] 已检查 bioconda 是否有 `eccsplorer` 包 → 不存在
- [x] `conda-recipe/meta.yaml` 已编写，声明所有 Python/R 依赖
- [x] `conda-recipe/build.sh` 已编写，从 GitHub 克隆源码并配置 lib/config.py
- [x] 系统级依赖（blast+、segemehl、samtools、bedtools、RepeatExplorer2、Trimmomatic）已在 meta.yaml run requirements 声明
- [ ] 本地 `conda build conda-recipe/` 成功
- [ ] `conda create -n test --use-local eccsplorer` 创建环境成功
- [ ] conda 包使用 testdata 验证可运行 ECCsplorer.py
- [ ] conda 包已推送至 `https://anaconda.org/siyangming/eccsplorer`
- [x] Dockerfile 已编写（基于 conda 包或直接安装）
- [x] lib/config.py 已配置第三方工具路径（Trimmomatic、RepeatExplorer2）
- [ ] 镜像本地构建成功：`docker build -t eccsplorer:2022.01.1.1 .`
- [ ] 镜像使用 testdata 验证可运行 ECCsplorer.py
- [ ] 镜像已推送至 `quay.io/siyangming/eccsplorer:2022.01.1.1`

## 阶段二：bio.nf 模块

- [ ] bio.nf 已创建 `eccsplorer` 分支（待用户执行 git 操作）
- [x] `bio.nf/modules/eccsplorer/` 目录结构完整
- [x] `main.nf` process 名为 ECCSPLORER，label `process_high`
- [x] `main.nf` 输入：`tuple val(meta), path(reads_r1), path(reads_r2), path(fasta)` + 可选 control
- [x] `main.nf` 输出：candidates_bed、junction_reads、versions
- [x] `main.nf` script 块调用 `python ECCsplorer.py`，支持 mapping 模式
- [x] `main.nf` stub 块生成空输出文件
- [x] `main.nf` container 指向正确镜像
- [x] `main.nf` 支持 `task.ext.args` 和 `task.ext.prefix`
- [x] `environment.yml` channels 含 `siyangming`，依赖 `- siyangming::eccsplorer=2022.01.1.1`
- [x] `meta.yml` 字段完整（name、description、tools、input、output、authors）
- [x] `tests/main.nf.test` 包含 stub 模式测试
- [x] `tests/nextflow.config` 配置 docker + `--platform linux/amd64`
- [ ] `nf-test test` stub 模式测试通过

## 阶段三：circdna.nf 接入

- [ ] `circdna.nf/modules/local/eccsplorer/` 已替换占位实现
- [ ] `environment.yml` 已同步拷贝并指向 `siyangming::eccsplorer`
- [ ] `subworkflows/local/eccdna_mode/main.nf` ECCSPLORER 输入已从 BAM 改为 FASTQ
- [ ] fasta 通道正确传递至 ECCSPLORER
- [ ] control reads 通道支持已添加（可选）
- [ ] emit 通道 candidates_bed 和 junction_reads 正确连接
- [ ] `conf/modules.config` 已添加 ECCSPLORER 资源配置
- [ ] `nextflow.config` 已添加 ECCsplorer 参数
- [ ] `conf/test_local.config` 已添加 ECCsplorer 测试参数

## 阶段四：版本与文档

- [ ] `CHANGELOG.md` 新增 `## v4.1.0` 条目
- [ ] `nextflow.config` version 更新为 `4.1.0`
- [ ] `nextflow_schema.json` 已通过 `nf-core schema build` 重新生成
- [ ] CHANGELOG 描述 ECCsplorer 真实检测实现
- [ ] CHANGELOG 标注输入接口变更（BAM → FASTQ）
- [ ] CHANGELOG 记录 conda 包发布（`siyangming::eccsplorer`）
- [ ] CHANGELOG 记录 Docker 镜像发布（`quay.io/siyangming/eccsplorer`）
- [x] AGENTS.md 新增 "12. 第三方模块构建工作流程" 章节
- [x] AGENTS.md 规则包含 bio.nf 模块构建流程
- [x] AGENTS.md 规则包含自定义 conda 包构建流程（推送至 anaconda.org）
- [x] AGENTS.md 规则包含自定义镜像构建流程（推送至 quay.io）
- [x] AGENTS.md 以 ECCsplorer 实现为示例

## 阶段五：验证与提交

- [ ] `nextflow run main.nf -profile test_local,docker --mode eccdna -stub-run` 成功
- [ ] ECCSPLORER stub 模式正常工作
- [ ] eccsplorer_bed 通道正确输出
- [ ] conda-recipe 已提交至 GitHub
- [ ] bio.nf eccsplorer 分支已推送至 GitHub
- [ ] circdna.nf v4.1.0 已 commit + tag + push
- [ ] AGENTS.md 更新已提交

## 关键验证点

- [ ] ECCSPLORER 不再产出硬编码假数据（占位 cat 已移除）
- [ ] ECCSPLORER 输入为 FASTQ（非 BAM），符合 ECCsplorer 工具要求
- [ ] conda 包可被 `conda install -c siyangming eccsplorer=2022.01.1.1` 正确安装
- [ ] Docker 镜像包含 segemehl（ECCsplorer 关键依赖，非标准 bioconda 包）
- [ ] RepeatExplorer2 已安装并配置 PATH
- [ ] conda 包与 Docker 镜像版本号一致（`2022.01.1.1`）
