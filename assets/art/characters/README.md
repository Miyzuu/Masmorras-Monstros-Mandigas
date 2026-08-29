# Personagens

## Prova atual

`prototypes/personagens_se_48px_16c.png` contém duas células 64×64:

1. Cangaceiro, direção Sudeste, em `x=0..63`.
2. Capanga, direção Sudeste, em `x=64..127`.

Os dois usam altura visual de 48 px, pés em `(32, 60)`, transparência binária e a paleta `paleta_sertao_16`. A largura visível é 24 px no Cangaceiro e 26 px no Capanga.

Este arquivo valida escala, proporção, contorno, paleta e leitura. Ele não é uma spritesheet de animação final.

Verdes e turquesa ficam reservados a vegetação e feedback de interação; não fazem parte dos personagens. Preto puro é usado somente no contorno externo.

Nos quadros finais, a luz quente do alto à esquerda deve ser reforçada no Cangaceiro sem aumentar a paleta.

## Atlas animado Sudeste — V.0.1.7

`animations/personagens_se_idle4_walk6_64px_16c.png` é o primeiro atlas animado jogável.
O protótipo estático acima permanece preservado como origem aprovada e fallback.

- Dimensão total: 640×128, organizada em 10 colunas e 2 linhas.
- Cada quadro: 64×64, com pés ancorados em `(32, 60)` e altura visual entre 46 e 49 px.
- Linha 0: Cangaceiro com o rifle pronto; linha 1: Capanga corpo a corpo, sem arma nova.
- Colunas 0–3: parado em loop, 4 FPS.
- Colunas 4–9: caminhada em loop, 10 FPS.
- Direção desta entrega: somente Sudeste.
- Alpha binário e cores restritas à `paleta_sertao_16`.

Os dois personagens compartilham a mesma fase de passos, mas usam balanços de tronco próprios.
Os quadros foram derivados pixel a pixel do atlas estático; a referência corrigida de poses orientou
apenas a cadência e não foi incorporada diretamente ao atlas final.

Sequência da caminhada nas colunas 4–9:

1. contato da perna à esquerda da célula, avançada para Sudeste;
2. apoio nessa perna, com tronco/quadril 1 px mais baixos e 1 px na direção do pé apoiado;
3. passagem da perna livre, elevada em 2–3 px;
4. contato da perna à direita da célula, avançada para Sudeste;
5. apoio nessa perna, com tronco/quadril 1 px mais baixos e 1 px na direção do pé apoiado;
6. passagem da perna livre antes do retorno ao primeiro contato.

O gerador mede a diferença de altura entre as solas no sprite-base antes de aplicar o ciclo. Assim,
o pé de apoio permanece em `y=60` e deriva no máximo 1 px entre quadros consecutivos da mesma fase.

O movimento secundário é recomposto a partir de caixas removidas do bloco-base, evitando pixels
duplicados: chapéu/lenço e braços+rifle no Cangaceiro; capacete e braços/abas no Capanga. A armadura
central do Capanga permanece sólida e suas mãos continuam vazias. Cada caixa usa offset relativo de
até 1 px, com perfil próprio; chapéu/lenço e capacete atingem os extremos horizontais um quadro após
o tronco. Os quatro idles permanecem sem alteração.

## Convenção aprovada para animações futuras

- Canvas por quadro: 64×64.
- Linhas: Sul, Sudoeste, Oeste, Noroeste, Norte, Nordeste, Leste e Sudeste.
- Parado: 4 quadros por direção, 4 FPS.
- Caminhada: 6 quadros por direção, 10 FPS.
- Todas as oito direções serão desenhadas individualmente.
