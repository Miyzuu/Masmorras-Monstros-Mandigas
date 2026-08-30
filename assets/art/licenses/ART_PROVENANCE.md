# Procedência e Licença Técnica dos Assets de Arte

- **Projeto:** Monstros, Masmorras e Mandingas / Pindorama Fantástica
- **Autor/Geração Técnica:** Artista Técnico 2D do projeto via scripts determinísticos em Python (Pillow 12.3.0).
- **Paleta Oficial:** `paleta_sertao_16` (16 cores exatas mapeadas em `palette/paleta_sertao_16.gpl`).
- **Assets Externos Incorporados:** Nenhum. Todas as texturas, losangos isométricos, paredes, cactos, arbustos, variações de personagens e sprites de chefão foram produzidos pixel a pixel de forma determinística e procedural interna.

## 1. Pacote de Tilesets Isométricos 64×32
- `tileset_caatinga_terra_rachada.png`: Procedência procedural determinística via `build_tilesets.py`.
- `tileset_caminho_batido.png`: Procedência procedural determinística via `build_tilesets.py`.
- `tileset_masmorra_pedra.png`: Procedência procedural determinística via `build_tilesets.py`.
- `tileset_paredes_taipa.png`: Procedência procedural determinística via `build_tilesets.py`.
- `tileset_vegetacao_caatinga.png`: Procedência procedural determinística via `build_tilesets.py`.
- `tileset_master_sertao_64x32.png`: Montagem determinística de atlas.

## 2. Variação do Cangaceiro com Peixeira & Chefão Cabra-Cabriola
- `cangaceiro_peixeira_se_48px_16c.png` e atlas animado: Derivado e recomposto pixel a pixel a partir do protótipo base aprovado `personagens_se_48px_16c.png` via `build_characters_expanded.py`, mantendo a mesma anatomia, chapéu e paleta, com nova postura e lâmina curva de peixeira.
- `cabra_cabriola_se_64px_16c.png` e atlas animado: Desenho técnico original da besta mitológica brasileira, criado de forma determinística em célula 64×64 px com âncora em `(32, 60)` via `build_characters_expanded.py`.

## 3. Conformidade Técnica
- Todos os arquivos foram auditados e aprovados pela suíte `verify_art_assets.py`.
- 100% dos pixels em conformidade estrita com a `paleta_sertao_16`.
- Contorno preto puro `#000000` estritamente externo (1px).
