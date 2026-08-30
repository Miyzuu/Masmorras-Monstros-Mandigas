# Ferramentas Determinísticas de Arte 2D

Esta pasta contém os scripts em Python (Pillow) para geração, pós-processamento, montagem e auditoria de todos os assets gráficos do projeto 'Monstros, Masmorras e Mandingas'.

## 1. Ambiente de Execução

- **Python:** 3.12+ / 3.14+
- **Pillow:** `12.3.0` (definido em `requirements.txt`)
- Os scripts operam de maneira determinística, não usam rede e escrevem exclusivamente dentro de `assets/art/**`.

---

## 2. Scripts Disponíveis

### 2.1. `build_tilesets.py`
Gera os tilesets isométricos de 64×32 px (terra rachada, caminho batido, lajotas de pedra da masmorra), paredes de taipa (64×64 px), vegetação da Caatinga (64×64 px), atlas mestre e imagem de teste de cena isométrica.

**Comando:**
```powershell
python assets/art/tools/build_tilesets.py `
  --output-dir assets/art/tilesets `
  --qa-dir assets/art/qa
```

### 2.2. `build_characters_expanded.py`
Gera os novos assets de personagens e chefões:
- Variação do **Cangaceiro empunhando Peixeira** (protótipo e atlas de animação SE com Idle e Walk).
- Concept e Spritesheet do **Chefão Cabra-Cabriola** (protótipo e atlas com Idle e Investida/Ataque de chifres).
- Folha unificada de 4 personagens (`personagens_completo_se_16c.png`).
- Atlas mestre de animações (`personagens_completo_se_animacoes_640x256_16c.png`).
- GIFs animados de validação e cena de combate tático de boss em `assets/art/qa/`.

**Comando:**
```powershell
python assets/art/tools/build_characters_expanded.py `
  --source-prototype assets/art/characters/prototypes/personagens_se_48px_16c.png `
  --char-dir assets/art/characters `
  --qa-dir assets/art/qa
```

### 2.3. `verify_art_assets.py`
Suíte de testes e auditoria técnica que inspeciona 100% das imagens PNG do repositório em `assets/art/` e verifica:
- Restrição estrita à `paleta_sertao_16` (0 cores inválidas permitidas).
- Preto puro `#000000` apenas como contorno externo.
- Alpha binário (0 ou 255).
- Dimensões e caixas delimitadoras.

**Comando:**
```powershell
python assets/art/tools/verify_art_assets.py `
  --art-root assets/art
```

### 2.4. `build_character_prototype.py`
Script original do protótipo base e atlas animado da V.0.1.7 (Cangaceiro Rifle + Capanga).
