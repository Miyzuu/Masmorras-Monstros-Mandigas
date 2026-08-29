# QA da prova visual de personagens

## Arquivos

- `cena_atual_base.png`: captura da cena `exploration.tscn` em 768×512, sem salvar alterações na engine.
- `personagens_se_48px_16c_zoom8.png`: ampliação nearest-neighbor para inspeção dos pixels.
- `teste_personagens_cena_atual_145x.png`: composição de QA sobre a cena real, usando o zoom atual de 1,45×.

O teste de cena é uma composição externa e não representa integração na Godot. O Cangaceiro foi colocado sobre o ponto inicial do jogador; o Capanga foi colocado em um tile visível apenas para comparação de leitura.

## Critérios de aprovação

1. Conferir o arquivo-fonte em 100%: cada personagem ocupa uma célula 64×64, mede 48 px de altura e usa o ponto dos pés em `(32, 60)`.
2. Conferir a ampliação 8×: os pixels precisam permanecer quadrados, sem suavização nem transparência parcial.
3. Conferir a cena em 768×512: chapéu, postura, rifle e armadura precisam ser distinguíveis sobre chão e estrada.
4. Na futura branch de integração, testar câmera normal, tecla `M`, caminhada e sobreposição com props.
5. O zoom 1,45× atual produz pixels de larguras diferentes. A correção pixel-perfect pertence a uma branch de desenvolvimento, não a esta branch de arte.

## QA do atlas animado — V.0.1.7

- `personagens_se_idle4_walk6_64px_16c_zoom4.png`: atlas completo ampliado 4× por nearest-neighbor.
- `personagens_se_idle4_4fps.gif`: Cangaceiro e Capanga lado a lado, repetindo as quatro poses paradas a 4 FPS.
- `personagens_se_walk6_10fps.gif`: os dois personagens repetindo as seis poses de caminhada a 10 FPS.

Os GIFs usam fundo marrom apenas para inspeção e não são assets da engine. A validação automática
do PNG final confirmou 640×128, 20 quadros preenchidos, 14 valores RGBA, alpha somente 0/255,
altura visual de 46–49 px, base em `y=60`, todas as quatro poses paradas distintas e todas as seis
poses de caminhada distintas para cada personagem.

Critérios visuais desta primeira animação:

1. O Cangaceiro mantém chapéu, postura Sudeste e rifle junto ao corpo durante todo o ciclo.
2. O Capanga mantém silhueta mais larga e combate desarmado.
3. A alternância segue contato → apoio/queda → passagem para cada perna; no apoio, tronco e quadril
   caem 1 px e avançam 1 px na direção do pé plantado.
4. Nenhum quadro introduz suavização, transparência parcial ou cor externa à Sertão 16.
5. Em cada metade do ciclo, um único pé sustenta `y=60` e sua sola deriva no máximo 1 px por quadro.
6. A transição do quadro 6 para o quadro 1 troca o apoio sem soltar equipamentos ou deslocar a âncora.
7. As quatro poses paradas permanecem idênticas às aprovadas antes da correção da caminhada.
8. Chapéu/lenço e braços+rifle do Cangaceiro movem-se em camadas separadas; capacete e braços/abas
   do Capanga também, sem abrir buracos na armadura nem introduzir arma nas mãos.
9. Nenhuma camada secundária se afasta mais de 1 px do tronco; chapéu/lenço e capacete atrasam um
   quadro nos extremos horizontais e todas as peças fecham o loop suavemente.

Além dos critérios anteriores, o gerador recusa caixas vazias, perda/duplicação de pixels na
partição, peças visualmente destacadas e perfis de movimento sem independência ou atraso.
