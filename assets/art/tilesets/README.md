# Tilesets Isométricos 2D — Masmorras, Monstros e Mandingas

Esta pasta contém os tilesets isométricos desenvolvidos para exploração e masmorras do jogo, seguindo a projeção isométrica 2:1 (`64×32` px) e a paleta estrita `paleta_sertao_16`.

## 1. Padrão Geométrico dos Tiles

- **Tiles de Chão:** Célula base de 64×32 pixels formando um losango isométrico 2:1 perfeito (vértices em `(32, 0)`, `(63, 16)`, `(32, 31)` e `(0, 16)`).
- **Paredes e Estruturas:** Célula de 64×64 pixels com base projetada sobre o losango isométrico inferior e alçado vertical de 28–32 px.
- **Vegetação / Props:** Célula de 64×64 pixels com ponto de contato inferior / âncora em `(32, 60)`.
- **Transparência:** Alpha binário (0 ou 255).
- **Contorno:** Preto puro `#000000` aplicado estritamente no contorno externo de 1px das silhuetas de paredes e vegetação.

---

## 2. Arquivos de Tilesets

| Arquivo | Dimensão | Conteúdo / Variações |
|---|---|---|
| `tileset_caatinga_terra_rachada.png` | 256×32 (4 tiles) | Terra seca da Caatinga: fissuras leves, fendas profundas, placas ressecadas, cascalho e pedregulhos miúdos. |
| `tileset_caminho_batido.png` | 256×32 (4 tiles) | Caminho de terra batida e areia pisada: centro liso, marcas de pegadas/carroça, cascalho miúdo, borda de transição para o sertão. |
| `tileset_masmorra_pedra.png` | 256×32 (4 tiles) | Piso de pedra da masmorra: lajotas 2×2 regulares com juntas profundas, lajotas com desgaste/rachaduras antigas, ladrilho losangular chanfrado, laje com runa de mandinga em turquesa. |
| `tileset_paredes_taipa.png` | 256×64 (4 tiles) | Paredes e estruturas de taipa de mão: parede reta voltada para Nordeste (NE), parede reta voltada para Noroeste (NW), quina/canto Sul, pilar com esteio de madeira e amuleto. |
| `tileset_vegetacao_caatinga.png` | 256×64 (4 tiles) | Flora típica da Caatinga: Mandacaru colunar ramificado, Xique-xique espinhoso em touceira, Arbusto seco de galhos retorcidos, Cacto jovem com flor vermelha. |
| `tileset_master_sertao_64x32.png` | 256×224 | Atlas integrado reunindo todos os terrenos, paredes e vegetação em grade organizada. |

---

## 3. Paleta de Cores Aplicada

Os tiles utilizam os tons terrosos, minerais e vegetais da `paleta_sertao_16`:
- **Chão e Taipa:** Terra e pele (`#A97945`), Terra sombreada (`#9B693D`), Areia e couro claro (`#C49A61`), Creme e brilho (`#F2DFBD`), Marrom profundo (`#33231B`).
- **Pedras da Masmorra:** Metal fosco / pedra (`#5D5547`), Quase preto (`#17120D`), Marrom profundo (`#33231B`).
- **Telhas e Alertas:** Ferrugem escura (`#94452E`), Ferrugem clara (`#D15A3F`).
- **Vegetação:** Vegetação escura (`#42643D`), Vegetação clara (`#668656`), Espinhos em Creme (`#F2DFBD`).
- **Magia e Selos:** Turquesa de interação (`#44D6B3`).
