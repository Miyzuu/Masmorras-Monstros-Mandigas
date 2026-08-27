# Pindorama Fantástica — GDD do MVP

**Status:** escopo mínimo aprovado e congelado

**Plataforma inicial:** navegador em computador

**Tecnologia:** Godot

**Possível destino futuro:** aplicativo Windows (`.exe`)

## 1. Conceito

RPG com exploração isométrica 2D em tempo real e combates táticos por turnos,
ambientado numa fantasia histórico-folclórica brasileira. Nesta primeira
versão, o jogador controla um único Cangaceiro que atravessa três encontros
para proteger uma vila e caçar a Cabra-Cabriola.

## 2. Estrutura da partida

- Criação do personagem.
- Um mapa pequeno e linear de exploração em tempo real.
- Três encontros táticos encadeados.
- Uma tela narrativa curta antes de cada encontro.
- Uma tela narrativa final.
- Vitória em cada encontro ao eliminar todos os inimigos.
- Ouro acumulado como pontuação final, sem função de compra no MVP.

### Quantidade de inimigos

1. Primeiro encontro: 2 a 3 inimigos comuns.
2. Segundo encontro: 3 a 4 inimigos comuns.
3. Terceiro encontro: Cabra-Cabriola e 1 a 2 inimigos comuns.

A quantidade, os tipos e as posições são sorteados dentro dessas faixas, usando
somente os três tipos fixos definidos neste documento.

## 3. Exploração

- Um único mapa linear de 16×12 tiles isométricos.
- Cada tile visual mede 64×32 pixels.
- Movimento contínuo a 140 pixels por segundo, sem teleporte entre tiles.
- O jogador clica num ponto caminhável para definir o destino.
- Um novo clique substitui imediatamente o destino anterior.
- A câmera acompanha o personagem durante a exploração.
- A tecla **M** alterna entre a câmera próxima e uma visão afastada do mapa
  inteiro.
- Inimigos permanecem parados no mapa.
- O contato físico com um inimigo inicia o combate.
- A entrada na arena tática usa um fade curto.
- Após a vitória, o jogador retorna ao mesmo ponto e o inimigo desaparece.
- Os três encontros aparecem em ordem fixa ao longo do caminho linear.

## 4. Criação do personagem

### Identidade e aparência

- Nome digitado pelo jogador, com até 16 caracteres.
- 3 tons de pele.
- 3 paletas de roupa.
- 3 modelos de chapéu.

### Atributos

- **Vigor:** determina a vida máxima.
- **Pontaria:** determina o dano do rifle.
- **Força:** determina o dano da peixeira.
- **Velocidade:** determina a iniciativa.
- **Defesa:** reduz o dano recebido.

Todos começam em 1. O jogador distribui 5 pontos adicionais, respeitando o
máximo de 4 em cada atributo durante a criação.

## 5. Arena, campo e turnos

- Grade quadrada de 10×10 casas.
- Base gráfica de 32×32 pixels por tile.
- Movimento somente nas quatro direções ortogonais, sem diagonais.
- Obstáculos bloqueiam movimento e linha de visão.
- Cada unidade age uma vez por rodada.
- A ordem é fixa em cada rodada, do maior para o menor valor de Velocidade.
- Em seu turno, o Cangaceiro pode mover até 4 casas e executar 1 ação.

## 6. Ações do Cangaceiro

### Disparo

- Ataque básico com rifle.
- Alcance máximo de 7 casas.
- Exige linha de visão.
- 90% de chance fixa de acerto.
- 25% de chance básica de crítico.
- Crítico comum causa 150% do dano-base.

### Golpe de Peixeira

- Ataque básico corpo a corpo.
- Alcance de 1 casa.
- 100% de chance de acerto.

### Lapada Seca

- Habilidade especial de tiro certeiro.
- Elimina instantaneamente inimigos que não sejam chefes.
- Contra chefes, causa 300% do dano-base total, conforme a fórmula registrada:
  200% do ataque mais 100% do ataque-base.
- Requer 3 Disparos críticos acumulados.
- Os críticos acumulados persistem entre encontros.
- Depois de completar a carga, exige 1 turno Mirando sem se mover.
- Buffs e efeitos provenientes de itens, feitiços, magias ou poções ficam fora
  do MVP.

## 7. Inimigos comuns

Os inimigos comuns diferem por atributos, ataque básico e comportamento. Eles
não possuem habilidades especiais no MVP.

- **Capanga Encouraçado:** humano resistente, corpo a corpo; avança em direção
  ao herói.
- **Lobo-guará corrompido:** criatura veloz, corpo a corpo; persegue o herói. A
  corrupção sobrenatural justifica sua presença na Caatinga.
- **Rasga-Mortalha:** criatura folclórica de ataque à distância; tenta manter
  distância do herói.

## 8. Chefe: Cabra-Cabriola

- Possui ataque básico e uma investida em linha reta.
- Usa a investida a cada 3 turnos próprios.
- Durante a investida, abre uma janela de 0,7 segundo para aparo em tempo real.
- O aparo é acionado por clique do mouse ou barra de espaço.
- Um aparo bem-sucedido apenas anula o dano da investida.

## 9. Vida, derrota e checkpoint

- Não há recuperação automática de vida após vencer um encontro.
- Ao ser derrotado, o jogador reinicia o encontro atual com vida cheia.
- A derrota remove 25% do ouro acumulado, representando o saque sofrido.
- Há checkpoint automático entre os encontros.
- O checkpoint guarda personagem, vida, ouro e carga acumulada da Lapada Seca.

## 10. Ouro e pontuação

- Cada inimigo eliminado concede ouro automaticamente.
- Concluir um encontro concede um bônus adicional de ouro.
- O ouro não pode ser gasto no MVP.
- O total restante ao concluir a caçada é a pontuação final.

## 11. Direção visual

- Pixel art isométrica 2D na exploração.
- Pixel art em visão 2D de cima na arena tática.
- Paleta predominantemente terrosa para o Sertão e a Caatinga.
- Cores vibrantes reservadas aos elementos mágicos e sobrenaturais.

## 12. Fora do MVP

- Outras classes, regiões e campanhas.
- Mapa-múndi, exploração livre, navegação e embarcações.
- Lojas, equipamentos, inventário e economia de compra.
- Buffs de itens, feitiços, magias ou poções.
- Habilidades especiais para inimigos comuns.
- Sistema completo de diálogos.
- Versões para celular, PWA e Windows.

## 13. Pontos ainda não balanceados

Estes itens não alteram o escopo, mas precisam ser decididos antes ou durante o
protótipo:

- Valores-base de vida, dano, Defesa e Velocidade.
- Fórmulas exatas dos cinco atributos.
- Atributos, movimento, alcance e dano de cada inimigo.
- Dano da investida e vida da Cabra-Cabriola.
- Quantidades de ouro, bônus e regra de arredondamento da perda de 25%.
- Consumo ou reinício da carga da Lapada Seca depois do uso.
- Textos narrativos, nome da vila e título definitivo do jogo.
