# Checklist

- [ ] `subworkflows/local/eccsplorer_pipeline/` 存在且含 main.nf + meta.yml
- [ ] `subworkflows/local/ecc_finder_pipeline/` 含 meta.yml
- [ ] workflow 名 `ECCSPLORER_PIPELINE`
- [ ] `workflows/circdna.nf` 中无 `ECCDNA_MODE`、`REFERENCE_MODE`、`eccdna_mode`、`reference_mode`
- [ ] mode='reference' → ECCSPLORER_PIPELINE（检测工具全关）
- [ ] 5 个冗余目录已删除
- [ ] `-stub --mode reference` 通过
- [ ] `-stub --circle_identifier eccsplorer,ecc_finder_map_sr` 通过
