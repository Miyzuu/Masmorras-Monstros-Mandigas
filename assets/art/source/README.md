# Fontes visuais

Arquivos desta pasta são insumos e referências de produção; `.gdignore` impede sua importação pela engine.

- `personagens_conceito_simplificado.png`: conceito preservado usado na prova estática V.0.1.6.
- `personagens_se_idle4_walk6_referencia_poses.png`: primeira referência de cadência da V.0.1.7, preservada para histórico; SHA-256 `25850DB4CE92E70FC907EF50D83F6C8BB92841988752B36562C2DCD37D7021E8`.
- `personagens_se_idle4_walk6_referencia_poses_corrigida.png`: referência atual de contato, apoio e passagem, gerada a partir das referências visuais fornecidas e dos personagens já aprovados; SHA-256 `D98488D512BC02DFF5144B095355BA649E21BFAE484D415CE781002CF624FA75`.
- `personagens_prova_visual_prompt.md`: prompt e limites da prova visual inicial.

As referências animadas não são usadas diretamente pelo jogo. O atlas final é reconstruído do
protótipo estático por `tools/build_character_prototype.py`.
