# HUD v5 — pacote modular nativo 768

Estado: revisão visual final aprovada manualmente e integrada na release local V.0.3.9; tag e publicação pendentes. O pacote contém dois atlas RGBA 768×256 e três prévias QA. O sufixo `768` identifica a escala lógica da tela, não uma HUD achatada.

## Uso e composição

- Desenhar regiões em 1:1, com filtro `nearest` e coordenadas inteiras.
- Usar alpha reto. Os atlas contêm apenas pixels totalmente transparentes ou totalmente opacos; não há cenário incorporado.
- Compor na ordem: fundo do jogo, regiões de `chrome`, preenchimentos das barras, regiões de `content`, textos e valores.
- Não redimensionar nem desenhar o atlas completo. Recortar cada região pelo mapa abaixo.
- `chrome` contém molduras, fundos decorativos, trilhos e slots vazios. `content` contém somente ícones, retrato, armas e mapa.
- Textos, números, preenchimentos e fonte continuam dinâmicos e não estão rasterizados nos atlas.

## Geometria final em 768×512

| Módulo | Retângulo de tela |
|---|---|
| Informações do mundo | `(8, 8, 280, 72)`; interior `(16, 16, 264, 56)` |
| Equipamento | `(8, 346, 58, 142)`; células 58×34 em `y=346,382,418,454`; área interna 34×34 centralizada |
| Poção | `(72, 444, 40, 44)`; ícone até 24×30; `F` no alto à esquerda; `×0` embaixo à direita |
| Retrato/nível | `(112, 346, 108, 142)`; título `(124,360,84,16)`; XP `(124,382,10,88)`; aro `(136,388,80,80)`; arte 68×68 |
| Combate | `(220, 346, 280, 142)` |
| Vida | `(228, 356, 264, 20)`; coração `(232,357,18,18)` |
| Mana | `(228, 380, 264, 20)`; cristal `(234,381,14,18)` |
| Q / E / R | `(228,404,88,72)`, `(320,404,80,72)`, `(404,404,88,72)`; vãos de 4 px |
| Grade/Ouro | `(500,346,124,142)`; slots desde `(510,360)`, 32×32, vão 4 px; botão `(508,444,108,32)` |
| Minimap | `(632,346,128,142)`; mapa `(640,356,112,112)` |

No painel superior, o divisor vertical fica em `x=156`, de `y=18` a `70`. Sol `(36,26,20,20)`, relógio `(36,50,20,20)` e região `(168,28,28,28)`. Os textos ocupam `(64,24,84,20)`, `(64,48,84,20)`, `(202,23,70,18)` e `(202,45,70,18)`. Ouro aparece somente no módulo inferior.

## Estados de Q e equipamento

- Rifle atual: ícone em `(240,426,48,22)`, nome em `(236,450,72,12)` e munição `5 / 5` em `(236,463,72,11)`. O popup `(274,408,38,17)` mostra Peixeira como próxima arma.
- Peixeira atual: ocupa a mesma área do ícone e nome, sem contador de munição. O popup mostra Rifle como próxima arma.
- O popup fica integralmente dentro de Q. O ícone atual termina em `y=448` e o nome começa em `y=450`.
- Slots de equipamento vazios não recebem silhueta. O estado equipado usa os quatro ícones de até 28×28, centralizados nas áreas internas 34×34.
- Medalhão, nível, trilho de XP, seis slots e minimapa são estáticos/inativos nesta entrega.

## Paleta de integração

| Uso | Cor |
|---|---|
| Fundo | `#130D09` |
| Interior | `#281D14` |
| Madeira | `#704522` |
| Corda | `#A96F35` |
| Bronze escuro | `#705033` |
| Bronze claro | `#B07D47` |
| Ferro | `#756B60` |
| Texto principal | `#F2DFBD` |
| Texto secundário | `#9E8563` |
| Vida | `#B94732` |
| Mana | `#307AD1` |
| XP | `#44D6B3` |
| Ouro | `#E6AD37` |

## Atlas `chrome`

| Região | x | y | largura | altura |
|---|---:|---:|---:|---:|
| equipment_panel | 2 | 2 | 58 | 142 |
| portrait_level_panel | 64 | 2 | 108 | 142 |
| combat_panel | 176 | 2 | 280 | 142 |
| grid_gold_panel | 460 | 2 | 124 | 142 |
| minimap_panel | 588 | 2 | 128 | 142 |
| world_info | 2 | 148 | 280 | 72 |
| potion_panel | 286 | 148 | 40 | 44 |
| next_weapon_popup | 330 | 148 | 38 | 17 |

## Atlas `content`

| Região | x | y | largura | altura |
|---|---:|---:|---:|---:|
| sun | 2 | 2 | 20 | 20 |
| clock | 26 | 2 | 20 | 20 |
| region | 50 | 2 | 28 | 28 |
| heart | 82 | 2 | 18 | 18 |
| mana | 104 | 2 | 14 | 18 |
| xp_marker | 122 | 2 | 10 | 18 |
| coin | 136 | 2 | 18 | 18 |
| rifle | 158 | 2 | 48 | 22 |
| peixeira | 210 | 2 | 48 | 22 |
| arrows | 262 | 2 | 12 | 11 |
| helmet | 278 | 2 | 28 | 28 |
| chest | 310 | 2 | 28 | 28 |
| trousers | 342 | 2 | 28 | 28 |
| boots | 374 | 2 | 28 | 28 |
| potion | 406 | 2 | 24 | 30 |
| portrait | 434 | 2 | 68 | 68 |
| map | 506 | 2 | 112 | 112 |
| rifle_mini | 622 | 2 | 18 | 11 |
| peixeira_mini | 644 | 2 | 18 | 11 |

## Prévias QA

- `assets/art/qa/hud_v5_preview_rifle_equipado_768.png`: Rifle atual, Peixeira no popup e quatro armaduras equipadas.
- `assets/art/qa/hud_v5_preview_peixeira_vazio_768.png`: Peixeira atual, Rifle no popup, sem munição e quatro slots vazios.
- `assets/art/qa/hud_v5_preview_comparativo.png`: os dois estados lado a lado.

As prévias são composições estáticas de QA sobre a cena de referência; não comprovam integração com Godot, atualização por dados, entrada, foco, hover ou acessibilidade.

## Procedência e hashes

A direção visual parte das três referências fornecidas para a revisão final. A folha-fonte modular foi produzida com imagegen (`exec-5893a778-a752-4e51-ab4c-3d48533fc671.png`) em fundo magenta removido antes da montagem. Cada peça foi recortada, isolada, reduzida individualmente com `nearest` e remontada por módulo; nenhuma HUD composta foi reduzida para formar um atlas. Consulte `assets/art/licenses/ART_PROVENANCE.md` para os limites de licença.

| Arquivo | SHA-256 |
|---|---|
| `hud_v5_chrome_768.png` | `2fafad69b6bd012fbd4f1331bca4b2e1b487571595e79082694ccdb6af9c8f4e` |
| `hud_v5_content_768.png` | `487bcb858cdcbb64a471e910a21aae03285c7dd607a4d2de4359d2e53f6ba84e` |
| `hud_v5_preview_rifle_equipado_768.png` | `09955abd7d33cd3e5c580c6f4be20edd40306a866c41deefa5e70f71090f568e` |
| `hud_v5_preview_peixeira_vazio_768.png` | `a64a479ad04649b30b898dd817334b7f14140f791a0bd717c0f35f8634087179` |
| `hud_v5_preview_comparativo.png` | `f02bb65ec748d13396b681d5f2465db793b8d861d3e352fb9dea6d0ef465b6cb` |
