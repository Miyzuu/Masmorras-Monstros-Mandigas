# Personagens

## Prova atual

`prototypes/personagens_se_48px_16c.png` contém duas células 64×64:

1. Cangaceiro, direção Sudeste, em `x=0..63`.
2. Capanga, direção Sudeste, em `x=64..127`.

Os dois usam altura visual de 48 px, pés em `(32, 60)`, transparência binária e a paleta `paleta_sertao_16`. A largura visível é 24 px no Cangaceiro e 26 px no Capanga.

Este arquivo valida escala, proporção, contorno, paleta e leitura. Ele não é uma spritesheet de animação final.

Verdes e turquesa ficam reservados a vegetação e feedback de interação; não fazem parte dos personagens. Preto puro é usado somente no contorno externo.

Nos quadros finais, a luz quente do alto à esquerda deve ser reforçada no Cangaceiro sem aumentar a paleta.

## Convenção aprovada para animações futuras

- Canvas por quadro: 64×64.
- Linhas: Sul, Sudoeste, Oeste, Noroeste, Norte, Nordeste, Leste e Sudeste.
- Parado: 4 quadros por direção, 4 FPS.
- Caminhada: 6 quadros por direção, 10 FPS.
- Todas as oito direções serão desenhadas individualmente.
