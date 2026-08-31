# Checklist

- [x] 已给出四种模式的 Nextflow / Snakemake 归属分析
- [x] 已明确 `PRExer` 哪些步骤适合 Nextflow
- [x] 已明确 `map` 哪些步骤适合 Nextflow
- [x] 已明确 `clu` 哪些步骤适合 Nextflow
- [x] 已明确 `all/comparative` 中哪些步骤适合 Nextflow
- [x] 已明确 `comparative` 之后哪些统计/可视化步骤适合 Snakemake

- [x] 已盘点可直接复用的现有模块
- [x] 已定义哪些现有模块优先迁移 ECCsplorer 参数而不是立即重写
- [x] 已定义参数迁移前后的结果差异对比指标
- [x] 已定义参数迁移前后的性能对比指标

- [x] 已定义 `PRExer` 的标准 Nextflow 替代模块链
- [x] 已定义 `PRExer` 的参数映射与缓存边界

- [x] 已定义 `map` 模式的输入标准化模块
- [x] 已定义 `map` 模式的核心 mapping 模块
- [x] 已定义 `map` 模式的候选提取模块
- [x] 已定义 `map` 模式的 junction / 序列 / 统计提取模块
- [x] 已定义 `map` 模式的可选 BLAST 注释模块

- [x] 已定义 `clu` 模式的 cluster 输入准备模块
- [x] 已定义 `clu` 模式的核心聚类模块
- [x] 已定义 `clu` 模式的 cluster 注释模块
- [x] 已定义 `clu` 模式的候选提取与绘图模块

- [x] 已定义 `all` 模式的 DAG 组合方式
- [x] 已定义 `comparative` 的独立输入输出契约
- [x] 已定义 `comparative` 的独立缓存与重跑策略

- [x] 已定义共享基础模块层
- [x] 已定义 BAM / FASTQ 统一输入接口
- [x] 已定义轻量模块与重型模块的环境拆分策略
- [x] 已定义镜像瘦身原则

- [x] 已定义 `handoff.tsv` 对 `clu` / comparative 的扩展字段
- [x] 已定义 `samples.auto.yaml` 对 `clu` / comparative 的扩展字段
- [x] 已定义 `eccdna.smk` 对扩展字段的消费边界

- [x] 已定义资源标签拆分策略
- [x] 已定义 `-resume` 下的缓存收益验证策略
- [x] 已定义首期必须落地的模块范围
- [x] 已定义可后置的重型模块范围

- [ ] 已实现 `eccsplorer_input_normalize`
- [ ] 已实现 `eccsplorer_map_core`
- [ ] 已实现 `eccsplorer_map_extract`
- [ ] 已实现 `eccsplorer_map_pipeline`
- [ ] `eccdna_mode` 已切换到模块化 `map` 流水线

- [ ] 已集中定义 ECCsplorer 参数入口
- [ ] 已将参数语义迁移到现有模块而不破坏输出兼容性

- [ ] 已新增 `clu` 模块骨架
- [ ] 已新增 `eccsplorer_cluster` 子工作流
- [ ] 已新增 `eccsplorer_all` DAG 骨架
- [ ] `clu` / `all` 默认处于关闭或非阻塞状态

- [ ] 已完成至少一次静态校验
- [ ] 已完成至少一次最小运行路径验证
