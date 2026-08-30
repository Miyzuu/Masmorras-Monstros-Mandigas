# Personagens e Criaturas

Esta pasta contém os protótipos estáticos, conceitos visuais e atlas animados de personagens e chefões do projeto, seguindo a projeção isométrica Sudeste (`SE`), células `64×64` px, ponto de contato nos pés em `(32, 60)` e a paleta estrita `paleta_sertao_16`.

## 1. Elenco de Personagens e Chefes

### 1.1. Cangaceiro (Rifle Winchester)
- Protótipo em `prototypes/personagens_se_48px_16c.png` (célula 0).
- Atlas de animação em `animations/personagens_se_idle4_walk6_64px_16c.png` (linha 0).
- Altura visual: ~48 px, largura: ~24 px. Chapéu de couro meia-lua, cartucheiras em X, camisa clara e rifle empunhado.

### 1.2. Capanga Encouraçado
- Protótipo em `prototypes/personagens_se_48px_16c.png` (célula 1).
- Atlas de animação em `animations/personagens_se_idle4_walk6_64px_16c.png` (linha 1).
- Altura visual: ~48 px, largura: ~26 px. Armadura de couro escuro reforçado, capacete colonial e mãos desarmadas.

### 1.3. Cangaceiro (Empunhando Peixeira) — Nova Variação
- Protótipo em `prototypes/cangaceiro_peixeira_se_48px_16c.png`.
- Atlas de animação em `animations/cangaceiro_peixeira_se_idle4_walk6_64px_16c.png`.
- Postura de combate ágil com o braço frontal empunhando uma **Peixeira sertaneja** de lâmina curva em metal fosco (`#5D5547`), fio com brilho em creme (`#F2DFBD`), guarda de latão e cabo de madeira.
- Animação: Colunas 0–3 (Idle a 4 FPS), Colunas 4–9 (Caminhada a 10 FPS com balanço dinâmico da lâmina).

### 1.4. Chefão: Cabra-Cabriola — Concept e Spritesheet
- Protótipo em `prototypes/cabra_cabriola_se_64px_16c.png`.
- Atlas de animação em `animations/cabra_cabriola_se_idle4_attack4_64px_16c.png`.
- Design Folclórico Aterrorizante: Besta caprino-demoníaca musculosa e corcunda, chifres monumentais retorcidos, mandíbula feroz com presas à mostra, pelagem quase preta/marrom profundo, cascos fendidos plantados em `(32, 60)` e olhos/mandíbula emitindo brilho sobrenatural turquesa de mandinga (`#44D6B3`).
- Animação: Colunas 0–3 (Respiração espectral a 4 FPS), Colunas 4–7 (Investida/Golpe de Chifres a 8 FPS), Colunas 8–9 (Rugido/Stun com lampejo místico).

---

## 2. Folhas de Referência e Atlas Mestre

- `prototypes/personagens_completo_se_16c.png` (256×64 px): Reúne os 4 personagens/monstros em uma única folha de validação visual.
- `animations/personagens_completo_se_animacoes_640x256_16c.png` (640×256 px): Atlas mestre de animação com 4 linhas de 10 colunas:
  - **Linha 0:** Cangaceiro (Rifle)
  - **Linha 1:** Capanga Encouraçado
  - **Linha 2:** Cangaceiro (Peixeira)
  - **Linha 3:** Cabra-Cabriola (Chefe)

---

## 3. Regras Técnicas de Pós-Processamento e QA

- Preto puro `#000000` somente no contorno externo de 1px.
- Pés ancorados exatamente em `(32, 60)`.
- Alpha binário (0 ou 255) em 100% dos quadros.
- Todas as 16 cores pertencem rigorosamente à `paleta_sertao_16`.
