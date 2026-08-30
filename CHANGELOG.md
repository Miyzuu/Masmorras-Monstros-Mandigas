# Histórico de versões

## V.0.2.1 — 2026-08-30

### Título do commit

`V.0.2.1 — Masmorra, recarga e Lapada instantânea`

### Descrição

- adiciona um Capanga Encouraçado à primeira sala sem modificar cenas ou arte;
- preserva dentro da masmorra o combate em tempo real, os ataques automáticos,
  críticos, Rifle, Peixeira, Lapada Seca e aparo do ataque pesado;
- permite movimentação por clique e WASD com colisão contra paredes, escada
  selada e posição atual do inimigo;
- move o comando de caminhada para o botão direito do mouse nos mapas em tempo
  real, deixando o botão esquerdo disponível para interações futuras;
- substitui as HUDs inferiores antigas por uma interface compartilhada e
  centralizada nos dois mapas em tempo real;
- apresenta Vida e Mana em barras Fill numéricas, mantendo a Mana cheia e
  somente visual nesta etapa;
- adiciona hotbar Q/E/R para arma, Lapada Seca e recarga manual do Rifle;
- torna a Lapada Seca instantânea ao pressionar **E**, removendo o segundo de
  mira e preservando a rota ou o movimento atual do Cangaceiro;
- mantém Rifle, 3 críticos, 1 bala e alcance como condições; uma condição
  inválida não consome munição nem cargas;
- separa a munição em pente de 5 balas e reserva inicial de 10, ambos
  persistentes no `GameState` durante respawn e troca de mapa;
- implementa recarga manual com **R** em 1,5 segundo nos mapas em tempo real,
  transferindo apenas as balas necessárias quando o temporizador termina;
- permite caminhar e receber dano comum durante a recarga, bloqueia ataques,
  Lapada e troca de arma, e faz Espaço cancelar a recarga para tentar o aparo;
- exibe pente, reserva, tempo restante e preenchimento do slot R na HUD;
- desenha quatro slots de armadura originais no canto inferior esquerdo, em
  ordem de cabeça, busto, pernas e pés, sem criar inventário ou atributos;
- mantém a escada bloqueada enquanto o Capanga estiver vivo e a libera
  imediatamente após a vitória;
- registra a conclusão da sala no `GameState`, mantendo-o como fonte única do
  progresso interno e reiniciando esse progresso ao sair ou voltar do início;
- faz o mob comum externo renascer com vida cheia e patrulha normal ao retornar
  de outra cena, sem duplicar progresso ou recompensa; alternar a visão com M
  não aciona o renascimento;
- reutiliza a caixa existente para oferecer **Voltar** ou **Sair** após derrota,
  com respawn em 40% da vida, pente e reserva preservados;
- valida a carga do projeto e os sete testes automatizados, incluindo Lapada
  instantânea, mob, WASD, recarga, persistência, escada e reinício da sala.

## V.0.2.0 — 2026-08-30

### Título do commit

`V.0.2.0 — Lapada Seca e movimento WASD`

### Descrição

- adiciona ao `GameState` as 3 cargas persistentes da Lapada Seca, acumuladas
  somente por críticos acertados de Rifle;
- permite iniciar a mira com **E** durante 1 segundo, interrompendo movimento e
  ataques automáticos;
- adiciona movimento contínuo por **WASD** nas direções da tela, normalizado em
  140 px/s, com colisão contra limites, terreno, quinas e o Capanga;
- mantém o clique como alternativa e faz o primeiro WASD cancelar somente a
  rota ativa, permitindo definir outro destino depois;
- cancela a mira sem consumir recursos ao clicar, mover, receber dano, trocar
  de arma ou perder o alcance do alvo;
- revalida Rifle, munição, cargas, posição e alcance no instante do disparo;
- elimina instantaneamente o Capanga, consome 1 bala e zera as 3 cargas após o
  uso bem-sucedido;
- adiciona três indicadores de carga ao HUD, muzzle flash, screen shake e áudio
  procedural próprio para o disparo especial;
- preserva o atlas de quatro linhas, o estado global centralizado e os efeitos
  audiovisuais da V.0.1.9;
- adiciona teste dedicado para carga, persistência, cancelamentos, revalidação
  e dano fatal, além de ampliar o teste audiovisual;
- mantém a regra de 300% contra chefes reservada para a futura arena tática.

## V.0.1.9 — 2026-08-30

### Título do commit

`V.0.1.9 — Feedback audiovisual e atlas corrigido`

### Descrição

- integra em segurança o feedback audiovisual de `origin/main`, preservando o
  `GameState` da V.0.1.8 como fonte única para vida, munição, arma, ouro,
  encontros e progresso da masmorra;
- adiciona passos por distância com som e poeira na exploração e na masmorra;
- conecta faíscas e fumaça aos disparos que consomem munição e aplica hit-flash
  por shader ao Cangaceiro e ao Capanga;
- incorpora áudio procedural, screen shake, barramentos de áudio e interface em
  estilo xilogravura;
- amplia o atlas para 640×256 com linhas distintas para Rifle, Capanga,
  Peixeira e Cabra-Cabriola;
- corrige o gerador que deslocava as pernas da Peixeira durante a caminhada e a
  base da Cabra-Cabriola durante a espera;
- atualiza o nome exibido do projeto para **Monstros, Masmorras e Mandingas**;
- valida 15 imagens, os seis testes automatizados, importação no Godot e um
  probe de passos, hit-flash e partículas em runtime;
- mantém a feature Lapada Seca fora desta versão.

## V.0.1.8 — 2026-08-30

### Título do commit

`V.0.1.8 — Estado global centralizado`

### Descrição

- torna `GameState` a fonte única de verdade para vida, munição, arma equipada, ouro, encontros derrotados e progresso da masmorra;
- adiciona `gold_score` com valor inicial zero e reinício de sessão, sem antecipar valores de recompensa ou penalidade ainda indefinidos no GDD;
- substitui as cópias locais de vida, munição e arma na exploração e na masmorra por propriedades compatíveis que delegam ao estado global;
- centraliza a validação de vida entre 0 e 100, munição não negativa e armas Rifle/Peixeira;
- registra imediatamente o respawn com 40% de vida, preservando munição, arma, ouro e progresso externo;
- mantém os contratos existentes de transição entre mapas e de acesso usados pela suíte automatizada;
- não altera regras de combate em tempo real, arena tática, animações, cenas ou arte;
- preserva os cinco testes automatizados com seus marcadores de sucesso.

## V.0.1.7 — 2026-08-29

### Título do commit

`V.0.1.7 — Espera e caminhada dos personagens`

### Descrição

- adiciona um atlas Sudeste de 640×128 com Cangaceiro e Capanga em células 64×64;
- anima a espera dos dois personagens em 4 quadros a 4 FPS, com respiração e movimento de roupa e equipamento;
- anima a caminhada em 6 quadros a 10 FPS, com contato, apoio e passagem alternados, mantendo a postura de combate;
- limita a deriva do pé de apoio a 1 px por quadro e reforça joelhos, transferência de peso e movimento secundário;
- troca imediatamente entre espera e caminhada conforme o deslocamento real de cada personagem;
- integra as duas animações ao Cangaceiro e ao Capanga na exploração e ao Cangaceiro na masmorra;
- inclui reprodução determinística do atlas, ampliações e GIFs de QA, além de testes automatizados da integração;
- mantém como limitações aprovadas a direção Sudeste única e a ausência de variação visual entre Rifle e Peixeira;
- reserva a correção pixel-perfect do zoom para uma versão futura;
- conclui esta etapa visual e devolve a próxima decisão à Engine.

## V.0.1.6 — 2026-08-29

### Título do commit

`V.0.1.6 — Prova visual inicial dos personagens`

### Descrição

- adiciona a prova técnica do Cangaceiro e do Capanga em células 64×64, voltados para Sudeste;
- define a paleta compartilhada Sertão 16 e registra suas regras de uso;
- documenta procedência, prompts e limites conhecidos da arte gerada;
- inclui ampliações e composição de QA sobre a cena atual do protótipo;
- adiciona uma ferramenta local e reproduzível com Pillow 12.3.0 para gerar os derivados;
- valida os seis PNGs, a reprodução exata dos quatro derivados e a importação no Godot;
- substitui os desenhos geométricos pelo Cangaceiro e Capanga estáticos na exploração;
- usa o mesmo Cangaceiro na masmorra sem alterar anchors, colisões ou regras de combate;
- mantém as animações de parado e caminhada fora desta entrega.

## V.0.1.5 — 2026-08-28

### Título do commit

`V.0.1.5 — Entrada e mapa inicial da masmorra`

### Descrição

- adiciona uma porta no fim do caminho externo, bloqueada até a derrota do Capanga;
- permite confirmar a entrada por botão, Enter ou Espaço e cancelar por botão ou Esc;
- cria uma sala de pedra isométrica separada de 16×12, vazia e com escada bloqueada;
- preserva vida, munição e arma equipada durante as trocas de mapa;
- permite sair pela porta inicial ou por Esc após confirmação, sem cura ou recarga;
- reinicia somente o progresso interno e retorna o herói diante da porta externa;
- adiciona fades de 0,5 segundo e teste automatizado do fluxo completo;
- mantém inimigos, salas adicionais e chefe fora desta primeira etapa da masmorra.

## V.0.1.4 — 2026-08-27

### Título do commit

`V.0.1.4 — Combate em tempo real contra o Capanga`

### Descrição

- substitui a transição do Capanga comum para a arena por combate direto no mapa isométrico;
- aumenta o Capanga para 150 HP, reposiciona-o e adiciona patrulha, detecção, perseguição, retorno e regeneração gradual;
- permite atacar automaticamente enquanto caminha e alternar Rifle/Peixeira com **Q**;
- limita o Rifle a 5 balas, alcance de 5 tiles e ataques a cada 1,2 segundo;
- configura a Peixeira com alcance de 1 tile e ataques a cada 0,8 segundo;
- adiciona críticos de 25%, números animados e destaque maior, vermelho e em negrito;
- implementa três golpes básicos do Capanga seguidos por um pesado com alerta **!**;
- adiciona aparo com Espaço, retorno **HÁ**, falha com ataque perdido e stun de 0,7 segundo;
- pisca as bordas em vermelho ao sofrer dano e mostra barras de vida e munição;
- respawna o herói com 40% de vida, preserva munição e mantém a vida atual do Capanga;
- preserva a arena tática separada para os futuros combates contra chefes;
- adiciona testes determinísticos do combate em tempo real.

## V.0.1.3 — 2026-08-27

### Título do commit

`V.0.1.3 — Vida e combate básico contra o Capanga`

### Descrição

- adiciona 100 HP ao Cangaceiro e 60 HP ao Capanga, com barras de vida na interface;
- substitui a vitória simulada por seleção de **Disparo** ou **Peixeira** e clique no alvo;
- configura o Rifle com dano 25, alcance ortogonal 7, 90% de acerto e 25% de crítico causando 40;
- configura a Peixeira com alcance 1, acerto garantido e dano 20;
- diferencia paredes, que bloqueiam tiros, de rochas, que bloqueiam apenas o movimento;
- faz o Capanga avançar até 3 casas e atacar adjacente causando 15 de dano;
- encerra o turno após um ataque válido, processa a resposta inimiga e restaura o movimento na rodada seguinte;
- reinicia o encontro com vida cheia após derrota e mantém o retorno real após vitória;
- adiciona testes determinísticos das regras básicas de combate.

## V.0.1.2 — 2026-08-27

### Título do commit

`V.0.1.2 — Primeiro encontro e transição para combate`

### Descrição

- posiciona um Capanga parado no início do caminho de exploração;
- inicia o encontro por contato físico com o personagem;
- adiciona fade de 0,5 segundo na ida e na volta da arena;
- exibe o Capanga como alvo temporário na arena tática;
- adiciona o botão temporário **Vencer encontro**;
- retorna ao mesmo ponto e remove o Capanga após a vitória simulada;
- preserva o estado do encontro entre as duas cenas e adiciona teste do fluxo.

## V.0.1.1 — 2026-08-27

### Título do commit

`V.0.1.1 — Exploração isométrica com movimento contínuo`

### Descrição

- adiciona mapa isométrico temporário de 16×12 tiles com base visual 64×32;
- substitui a movimentação instantânea por caminhada contínua a 140 px/s;
- permite trocar o destino imediatamente com um novo clique;
- adiciona busca de caminho em terreno bloqueado;
- faz a câmera seguir o personagem e alternar a visão geral com **M**;
- preserva a cena anterior como base separada para o combate tático;
- adiciona teste automatizado da rota, caminhada e alternância de câmera;
- atualiza GDD, README e versão exibida pelo projeto.

## V.0.1.0 — 2026-08-26

### Título do commit

`V.0.1.0 — Estrutura inicial do protótipo Godot`

### Descrição

- organiza o projeto Godot na raiz correta do repositório Git;
- adiciona grade 10×10, movimento ortogonal, obstáculos e prévia de rota;
- registra o GDD do MVP e a convenção de versionamento;
- adiciona arquivos de configuração para rastreamento correto no GitHub;
- valida referências internas, mas mantém pendente a execução no editor Godot.
