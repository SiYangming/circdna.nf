# Tasks

## 阶段一：运行 eccdna 模式真实模式

- [ ] Task 1: 执行 test_local 真实模式 - eccdna 模式
  - [ ] SubTask 1.1: 清理旧产物（如 `/tmp/circdna_test_local_eccdna` 已存在）
  - [ ] SubTask 1.2: 执行 `nextflow run main.nf -profile test_local,docker --outdir /tmp/circdna_test_local_eccdna`（默认 mode=eccdna）
  - [ ] SubTask 1.3: 记录执行结果（成功/失败、任务数、执行时间、失败任务详情）

## 阶段二：验证 eccdna 模式产出

- [ ] Task 2: 验证 eccdna 模式各模块产出真实结果文件
  - [ ] SubTask 2.1: 验证 TRIMGALORE 产出 trimmed FASTQ（`fastqc/`、`trimgalore/` 目录）
  - [ ] SubTask 2.2: 验证 BWA_MEM/SAMTOOLS 产出 sorted BAM + BAI（`bwa/` 目录）
  - [ ] SubTask 2.3: 验证 PICARD_MARKDUPLICATES 产出 dedup BAM + metrics（`markduplicates/` 目录）
  - [ ] SubTask 2.4: 验证 MOSDEPTH 产出区域深度文件（`mosdepth/` 目录）
  - [ ] SubTask 2.5: 验证 ECCSPLORER 产出真实检测结果（`eccsplorer/` 目录，非 0 字节占位文件）
  - [ ] SubTask 2.6: 验证 CIRCLEMAP_REALIGN 产出 realign 结果（`circlemap_realign/` 目录）
  - [ ] SubTask 2.7: 验证 MULTIQC 生成汇总报告（`multiqc/multiqc_report.html`）

## 阶段三：运行 reference 模式真实模式

- [ ] Task 3: 执行 test_local 真实模式 - reference 模式
  - [ ] SubTask 3.1: 清理旧产物（如 `/tmp/circdna_test_local_reference` 已存在）
  - [ ] SubTask 3.2: 执行 `nextflow run main.nf -profile test_local,docker --mode reference --outdir /tmp/circdna_test_local_reference`
  - [ ] SubTask 3.3: 记录执行结果（成功/失败、任务数、执行时间、失败任务详情）

## 阶段四：验证 reference 模式产出

- [ ] Task 4: 验证 reference 模式各模块产出真实结果文件
  - [ ] SubTask 4.1: 验证 TRIMGALORE 产出 trimmed FASTQ
  - [ ] SubTask 4.2: 验证 BWA_MEM/SAMTOOLS 产出 sorted BAM + BAI
  - [ ] SubTask 4.3: 验证 PICARD_MARKDUPLICATES 产出 dedup BAM + metrics
  - [ ] SubTask 4.4: 验证 CIRCEXPLORER2_PARSE 产出解析结果
  - [ ] SubTask 4.5: 验证 CIRCLE_FINDER 产出检测结果（`circlefinder/` 目录）
  - [ ] SubTask 4.6: 验证 AMPLICONARCHITECT 产出结果（`ampliconarchitect/` 目录）
  - [ ] SubTask 4.7: 验证 UNICYCLER 产出组装结果（`unicycler/` 目录）
  - [ ] SubTask 4.8: 验证 MULTIQC 生成汇总报告（`multiqc/multiqc_report.html`）

## 阶段五：汇总结果

- [ ] Task 5: 汇总两种模式验证结果
  - [ ] SubTask 5.1: 若全部通过，记录两种模式的执行时间、任务数、关键产出文件大小
  - [ ] SubTask 5.2: 若有失败，记录错误信息、失败任务、work 目录路径，定位问题原因

# Task Dependencies

- Task 2 依赖 Task 1（eccdna 模式运行完成才能验证产出）
- Task 3 可与 Task 1-2 并行或串行（独立模式，无依赖）
- Task 4 依赖 Task 3（reference 模式运行完成才能验证产出）
- Task 5 依赖 Task 2 和 Task 4（两种模式都验证完成才能汇总）

# 并行化说明

- eccdna 模式（Task 1-2）和 reference 模式（Task 3-4）可并行运行（两种模式独立）
- 但考虑本地资源限制（max_cpus=4, max_memory=8GB），建议串行执行避免资源竞争
- Task 5 必须在所有验证完成后执行
