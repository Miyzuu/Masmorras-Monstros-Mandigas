# Pindorama Fantástica — GDD do MVP

**Status:** escopo revisado; implementação dividida em versões pequenas

**Plataforma inicial:** navegador em computador

**Tecnologia:** Godot

**Possível destino futuro:** aplicativo Windows (`.exe`)

## 1. Conceito

RPG com exploração isométrica 2D, combate em tempo real contra mobs comuns e
combates táticos por turnos exclusivos para chefes. O jogador controla um
único Cangaceiro que protege uma vila e entra em uma masmorra para caçar a
Cabra-Cabriola.

## 2. Estrutura da partida

- Criação do personagem.
- Um mapa pequeno e linear de exploração em tempo real.
- Mobs comuns enfrentados diretamente no mapa, sem troca para a arena tática.
- Uma entrada separada para a masmorra, com confirmação **Sim/Não**.
- Objetivo futuro da primeira masmorra: 2 andares e 2 salas por andar.
- Primeira etapa implementada: uma sala de pedra vazia com escada bloqueada.
- Caminho linear: mobs, escada, mobs e sala do chefe.
- Entrada na sala final iniciando imediatamente a batalha tática.
- Uma tela narrativa final.
- Ouro acumulado como pontuação final, sem função de compra na primeira etapa.

## 3. Exploração

- Um mapa externo linear de 16×12 tiles isométricos.
- Uma sala inicial separada de masmorra, também com 16×12 tiles.
- Cada tile visual mede 64×32 pixels.
- Movimento contínuo a 140 pixels por segundo, sem teleporte entre tiles.
- O jogador clica num ponto caminhável para definir o destino.
- Um novo clique substitui imediatamente o destino anterior.
- A câmera acompanha o personagem durante a exploração.
- A tecla **M** alterna entre a câmera próxima e uma visão afastada do mapa
  inteiro.
- Mobs comuns patrulham, detectam e perseguem o personagem no próprio mapa.
- O Cangaceiro ataca automaticamente enquanto continua andando.
- **Q** alterna entre Rifle e Peixeira, com recarga de 0,5 segundo para a troca.
- O Rifle começa com 5 balas e cada disparo consome uma, inclusive ao errar.
- Sem munição, o Rifle é bloqueado e o jogador precisa usar **Q**.
- Ao ser derrotado no mapa comum, o herói retorna ao início com 40% da vida e
  preserva a munição restante.
- A porta no fim do caminho permanece trancada até o Capanga ser derrotado.
- Ao tocar a porta liberada, o jogo mostra **Sim/Não**; Enter ou Espaço
  confirmam e Esc cancela.
- Entrada e saída usam fade de 0,5 segundo.

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

## 5. Arena tática dos chefes

- O modo por turnos é usado somente contra chefes de masmorra.
- Grade quadrada de 10×10 casas.
- Base gráfica de 32×32 pixels por tile.
- Movimento somente nas quatro direções ortogonais, sem diagonais.
- Obstáculos bloqueiam movimento; somente paredes bloqueiam linha de visão.
- Disparos atravessam objetos que não sejam paredes.
- Cada unidade age uma vez por rodada.
- A ordem é fixa em cada rodada, do maior para o menor valor de Velocidade.
- Em seu turno, o Cangaceiro pode mover até 4 casas e executar 1 ação.

## 6. Ações do Cangaceiro

### Disparo

- Ataque básico com rifle.
- Alcance máximo de 7 casas na arena tática e 5 tiles no combate em tempo real.
- Exige linha de visão.
- 90% de chance fixa de acerto.
- 25% de chance básica de crítico.
- Crítico comum causa 150% do dano-base, arredondado para 40 no balanceamento
  atual.
- No combate em tempo real, ocorre automaticamente a cada 1,2 segundo.
- Cada disparo consome uma das 5 balas iniciais; não há recarga gratuita.

### Golpe de Peixeira

- Ataque básico corpo a corpo.
- Alcance de 1 casa.
- 100% de chance de acerto.
- No combate em tempo real, ocorre automaticamente a cada 0,8 segundo.
- Possui 25% de crítico, causando 30 de dano.

### Valores do primeiro protótipo de combate

- Cangaceiro: 100 HP.
- Capanga Encouraçado: 150 HP no combate comum em tempo real.
- Disparo: 25 de dano; crítico causa 40.
- Peixeira: 20 de dano.
- Ataques básicos do Capanga: 15 de dano; ataque pesado: 30.
- O ataque válido encerra o turno do Cangaceiro.

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

Os inimigos comuns são enfrentados em tempo real e diferem por atributos,
ataque básico e comportamento.

- **Capanga Encouraçado:** humano corpo a corpo com 150 HP. Patrulha entre dois
  pontos a 70 px/s, detecta em 6 tiles ou ao receber dano e persegue a 150 px/s.
  Desiste acima de 10 tiles, retorna à patrulha e regenera 5 HP/s. Ataca a cada
  1,5 segundo quando está a 1 tile: usa 3 golpes básicos e depois 1 pesado.
  A resistência especial da armadura ainda não é aplicada.
- **Lobo-guará corrompido:** criatura veloz, corpo a corpo; persegue o herói. A
  corrupção sobrenatural justifica sua presença na Caatinga.
- **Rasga-Mortalha:** criatura folclórica de ataque à distância; tenta manter
  distância do herói.

### Aparo contra mobs

- Somente o quarto ataque pesado pode ser aparado.
- Um **!** vermelho e fixo aparece acima do herói por 0,7 segundo.
- Espaço durante a janela anula o dano e mostra **HÁ** em branco.
- Espaço fora da janela cancela o próximo ataque automático e causa stun de
  0,7 segundo, bloqueando movimento, ataques e troca de arma.

## 8. Chefe: Cabra-Cabriola

- Possui ataque básico e uma investida em linha reta.
- Usa a investida a cada 3 turnos próprios.
- Durante a investida, abre uma janela de 0,7 segundo para aparo em tempo real.
- O aparo é acionado pela barra de Espaço.
- Um aparo bem-sucedido apenas anula o dano da investida.

## 9. Vida, derrota e checkpoint

- Não há recuperação automática de vida após vencer um encontro.
- Ao morrer no mapa comum, o herói retorna ao início com 40% da vida e mantém
  a munição; o Capanga preserva a vida atual e regenera somente na patrulha.
- Ao morrer na masmorra, o jogador escolhe **Sair** ou **Voltar do início**.
- Ambas restauram a vida e preservam a munição restante; voltar reinicia toda
  a masmorra e restaura seus mobs.
- A saída voluntária pela porta inicial ou por **Esc** pede confirmação, apaga
  todo o progresso interno e retorna o herói diante da porta externa.
- A saída voluntária preserva a vida e a munição atuais, sem cura ou recarga.
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

- Fórmulas exatas dos cinco atributos e sua relação com os valores-base atuais.
- Atributos, movimento, alcance e dano dos demais inimigos.
- Dano da investida e vida da Cabra-Cabriola.
- Quantidades de ouro, bônus e regra de arredondamento da perda de 25%.
- Consumo ou reinício da carga da Lapada Seca depois do uso.
- Textos narrativos, nome da vila e título definitivo do jogo.
