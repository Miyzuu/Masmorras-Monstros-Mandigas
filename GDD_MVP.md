# 3M: Monstros Masmorras & Mandingas — GDD do MVP

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

- Novo Jogo iniciando diretamente na Exploração com o Cangaceiro padrão; a
  criação personalizada fica reservada para uma versão futura.
- Página inicial com Novo Jogo, Continuar, Configurações e Sair.
- Três slots locais de save, mostrando local e data, com confirmação para apagar
  ou sobrescrever; Continuar permanece desativado sem saves válidos.
- Checkpoints automáticos somente em transições seguras: encontros concluídos,
  salas, entrada/saída da masmorra, vitória e derrota.
- Configurações globais separadas dos slots: Controles, Áudio e Vídeo.
- O menu de pausa oferece **Sair para o Menu Inicial** após confirmação, sem
  registrar o estado intermediário desde o último checkpoint seguro.
- Um mapa pequeno e linear de exploração em tempo real.
- Mobs comuns enfrentados diretamente no mapa, sem troca para a batalha do chefe.
- Uma entrada separada para a masmorra, com confirmação **Sim/Não**.
- Primeira masmorra implementada com 2 andares e 2 salas por andar.
- Primeira sala funcional implementada: um Capanga Encouraçado em combate em
  tempo real e uma escada selada até a vitória.
- Encadeamento funcional implementado entre `sala_01` e `sala_02`: a escada
  liberada usa fade de 0,5 segundo. A segunda sala possui três blocos de pedras,
  duas rotas transitáveis e um Lobo-guará corrompido próprio.
- A `sala_03`, primeira sala do segundo andar, possui quatro pedras de cobertura
  e uma Rasga-Mortalha. Sua escada liberada conduz à batalha 1×1 da `sala_04`.
- A `sala_04` conclui a masmorra com a Cabra-Cabriola em um combate tático por
  turnos, seguido por tela de vitória e retorno ao mapa externo.
- A implementação usa perfis internos de sala e inimigo para centralizar
  obstáculos, patrulha e estatísticas sem alterar as regras de combate.
- Caminho linear: mobs, escada, mobs e sala do chefe.
- Entrada na sala final iniciando imediatamente a batalha tática.
- Uma tela narrativa final.
- Ouro acumulado como pontuação final, sem função de compra na primeira etapa.

## 3. Exploração

- Um mapa externo linear de 16×12 tiles isométricos.
- Uma sala inicial separada de masmorra, também com 16×12 tiles.
- Cada tile visual mede 64×32 pixels.
- Movimento contínuo a 140 pixels por segundo, sem teleporte entre tiles.
- O jogador usa o botão direito do mouse num ponto caminhável para definir o
  destino.
- Um novo clique substitui imediatamente o destino anterior.
- **WASD** move continuamente nas direções da tela, mantendo 140 px/s e
  respeitando os mesmos limites e obstáculos do caminho por clique.
- Pressionar **WASD** cancela o destino do clique; um novo clique volta a criar
  uma rota normalmente.
- A colisão do herói usa uma pequena área nos pés; ao encontrar uma quina, o
  movimento desliza pelo eixo livre sem preferência fixa por X ou Y.
- A rota do clique é recalculada quando o Capanga passa a ocupar um dos próximos
  passos; sem desvio imediato, o herói espera em segurança e tenta novamente.
- A câmera acompanha o personagem durante a exploração e permanece contida nos
  limites do mapa.
- A tecla **M** alterna entre a câmera próxima e uma visão afastada do mapa
  inteiro.
- Mobs comuns patrulham, detectam e perseguem o personagem no próprio mapa.
- O Cangaceiro ataca automaticamente enquanto continua andando.
- **Q** alterna entre Rifle e Peixeira, com intervalo de 0,5 segundo entre trocas.
- O Rifle começa com 5 balas no pente e 10 na reserva; cada disparo consome uma
  bala do pente, inclusive ao errar.
- **R** inicia uma recarga manual de 1,5 segundo somente nos mapas em tempo real.
- Durante a recarga, o herói pode caminhar e receber dano comum, mas não pode
  atacar, usar a Lapada ou trocar de arma. Espaço cancela a recarga e tenta o
  aparo; a troca de mapa também a cancela.
- As balas passam da reserva para o pente apenas quando os 1,5 segundo terminam;
  cancelar não consome munição e o pente vazio nunca recarrega automaticamente.
- Sem balas no pente ou na reserva, o jogador precisa usar **Q** e a Peixeira.
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

## 5. Batalha por turnos dos chefes

- O modo por turnos é usado somente contra chefes de masmorra.
- O encontro atual é 1×1, com Cangaceiro à esquerda e Cabra-Cabriola à direita.
- Não há grade, deslocamento, alcance espacial ou linha de visão nessa batalha.
- O Cangaceiro age primeiro e escolhe uma ação no menu.
- O ciclo é: escolha do jogador → resolução da ação → anúncio do inimigo →
  impacto ou aparo → verificação de derrota → próxima rodada.
- Cada ação válida encerra o turno; ações sem recurso ou condição permanecem no
  menu sem gastar o turno.
- **Q** alterna Rifle e Peixeira; **Enter** confirma o ataque selecionado;
  **E** usa a Lapada Seca e **R** transfere balas da reserva para o pente.
- A reação por Espaço acontece em tempo real somente durante o turno inimigo.
- A preparação da Investida apenas anuncia o perigo; durante a janela ativa a
  arena mostra **APERTE [ESPAÇO] PARA APARAR**, contagem e barra de tempo.

## 6. Ações do Cangaceiro

### Disparo

- Ataque básico com rifle.
- Alcance máximo de 5 tiles no combate em tempo real; a batalha 1×1 do chefe
  não usa distância nem linha de visão.
- 90% de chance fixa de acerto.
- 25% de chance básica de crítico.
- Crítico comum causa 150% do dano-base, arredondado para 40 no balanceamento
  atual.
- No combate em tempo real, ocorre automaticamente a cada 1,2 segundo.
- Cada disparo consome uma bala do pente. Recarregar apenas transfere munição
  existente da reserva e não cria balas gratuitas.

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
- Com a carga completa, o uso é instantâneo e não exige turno de mira nem
  interrompe o movimento. Nos mapas em tempo real, o disparo ocorre ao pressionar **E**.
- O disparo consome 1 bala e zera as 3 cargas acumuladas.
- Rifle equipado, munição e alvo dentro do alcance são revalidados no instante;
  falhar em qualquer condição não consome bala nem cargas.
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
- **Lobo-guará corrompido:** criatura veloz, corpo a corpo, com 70 HP. Persegue
  o herói a 220 px/s e ataca a cada 0,8 segundo, causando 10 de dano. Não usa
  ataque pesado nem regenera vida. A corrupção sobrenatural justifica sua
  presença na Caatinga.
- **Rasga-Mortalha:** criatura folclórica de ataque à distância com 60 HP.
  Patrulha entre dois pontos, detecta em 6 tiles, desiste acima de 10 e se move
  a 120 px/s durante o combate. Ataca até 5 tiles com um projétil desviável a
  300 px/s, causando 10 de dano a cada 1,2 segundo. Recua abaixo de 3 tiles e,
  sem rota de fuga, permanece parada e continua atirando. Paredes e pedras
  destroem seus projéteis; ela não usa ataque pesado nem regenera vida.
- Ao retornar de outra cena ao mapa externo, mobs comuns derrotados reaparecem
  nas posições iniciais, com vida cheia e patrulha normal. A visão geral com
  **M** não aciona esse renascimento.
- Derrotar novamente um mob renascido não repete ouro, pontuação nem progresso.
  As salas concluídas da masmorra permanecem limpas enquanto a sessão interna
  estiver ativa.

### Aparo contra mobs

- Somente o quarto ataque pesado pode ser aparado.
- Um **!** vermelho e fixo aparece acima do herói por 0,7 segundo.
- Espaço durante a janela anula o dano e mostra **HÁ** em branco.
- Espaço fora da janela cancela o próximo ataque automático e causa stun de
  0,7 segundo, bloqueando movimento, ataques e troca de arma.
- Os projéteis comuns da Rasga-Mortalha não podem ser aparados.

## 8. Chefe: Cabra-Cabriola

- Possui 250 HP e causa 20 de dano no ataque básico.
- Executa dois ataques básicos e prepara uma Investida de 40 de dano no terceiro
  turno próprio, reiniciando o ciclo depois do impacto.
- A Investida possui um telegraph de 0,35 segundo e depois abre uma janela de
  0,7 segundo para aparo em tempo real.
- O aparo é acionado pela barra de Espaço.
- Um aparo bem-sucedido apenas anula o dano da investida.
- Cada golpe aceita apenas uma tentativa de aparo.
- Espaço cedo ou fora da janela causa stun de 0,7 segundo e perde a próxima ação;
  a Investida continua e causa dano normal.
- A Lapada Seca causa 75 de dano, consome 1 bala e zera as 3 cargas.
- A primeira vitória da sessão concede 250 de ouro. Repetir a masmorra mantém o
  registro da conclusão e não duplica essa recompensa.
- A tela final mostra a vitória e o ouro total; sair preserva vida e munição e
  devolve o herói ao mapa externo.

## 9. Vida, derrota e checkpoint

- Não há recuperação automática de vida após vencer um encontro.
- Ao morrer no mapa comum, o herói retorna ao início com 40% da vida e mantém
  pente e reserva; o Capanga preserva a vida atual e regenera somente na patrulha.
- Ao morrer na masmorra, o jogador escolhe **Sair** ou **Voltar do início**.
- Ambas restauram a vida e preservam a munição restante; voltar reinicia toda
  a masmorra e restaura seus mobs.
- A saída voluntária pela porta inicial ou por **Sair da Masmorra** no menu de
  pausa pede confirmação, apaga o progresso e retorna o herói ao mapa externo.
- A saída voluntária preserva vida, pente e reserva atuais, sem cura ou recarga.
- A derrota remove 25% do ouro acumulado, representando o saque sofrido.
- Há checkpoint automático entre os encontros.
- O checkpoint guarda personagem, vida, pente, reserva, ouro e carga acumulada
  da Lapada Seca.

## 10. Ouro e pontuação

- Cada inimigo eliminado concede ouro automaticamente.
- Concluir um encontro concede um bônus adicional de ouro.
- O ouro não pode ser gasto no MVP.
- O total restante ao concluir a caçada é a pontuação final.

## 11. Direção visual

- Pixel art isométrica 2D na exploração.
- Pixel art em visão 2D lateral na batalha 1×1 do chefe.
- Paleta predominantemente terrosa para o Sertão e a Caatinga.
- Cores vibrantes reservadas aos elementos mágicos e sobrenaturais.
- O mapa externo reutiliza os tilesets de chão rachado, caminho, vegetação,
  taipa e pedra da masmorra já aprovados, sem adicionar arte nesta etapa.
- Cacto florido, árvore seca e pilar de taipa identificam respectivamente o
  início, a arena do Capanga e a aproximação da masmorra.
- Nos mapas em tempo real, a HUD principal fica centralizada na parte inferior:
  Vida à esquerda, arma e munição no centro e Mana à direita.
- Vida e Mana usam barras Fill com valores numéricos; a Mana permanece cheia e
  apenas visual até que uma função seja definida em uma versão futura.
- A barra de habilidades possui slots **Q**, **E** e **R**: troca de arma,
  Lapada Seca e recarga. O slot R mostra o tempo e o progresso da recarga; o
  aparo continua no Espaço.
- Quatro slots visuais de armadura ficam no canto inferior esquerdo, em pilha:
  cabeça, busto, pernas e pés. Eles não equipam itens nem alteram atributos.
- A batalha 1×1 separa arena, recursos, mensagens e ações, desativando
  visualmente escolhas indisponíveis.
- Dano normal, crítico, Lapada Seca, dano recebido e aparo possuem retornos
  próprios por números, cores, flashes, impacto, borda e **HÁ!**.
- **Esc** abre o menu de pausa com Continuar e Configurações; dentro da
  masmorra também exibe Sair da Masmorra.
- Configurações apresenta todos os controles ativos e permite voltar à pausa.
- As caixas fixas de atalhos ficam ocultas; permanecem apenas HUD, estado da
  sala e avisos essenciais de combate.

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
- Atributos, movimento, alcance e dano de inimigos futuros.
- Quantidades de ouro, bônus e regra de arredondamento da perda de 25%.
- Textos narrativos, nome da vila e título definitivo do jogo.
