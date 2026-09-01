# 3M: Monstros Masmorras & Mandingas

Protótipo de **Pindorama Fantástica**, um RPG em Godot 4 com exploração e
combate comum em tempo real, além de batalhas táticas reservadas aos chefes.

**Versão atual:** `V.0.3.0`

O escopo aprovado está em [`GDD_MVP.md`](GDD_MVP.md).

## Estado atual

- mapa de exploração isométrico com 16×12 tiles de 64×32 pixels;
- movimentação contínua por clique a 140 px/s;
- novo clique substitui imediatamente o destino anterior;
- movimentação contínua por **WASD** nas direções da tela, também a 140 px/s;
- WASD cancelando a rota atual sem impedir um novo destino por clique;
- busca de caminho que contorna terreno bloqueado;
- câmera seguindo o personagem e visão geral alternada pela tecla **M**;
- Capanga patrulhando mais adiante, detectando e perseguindo o herói;
- combate contra o Capanga diretamente no mapa, sem troca de cena;
- Cangaceiro com 100 HP e Capanga com 150 HP;
- barra de vida do herói no rodapé e barra inimiga acima do alvo;
- HUD compartilhada entre exploração e masmorra, centralizada no rodapé;
- barras Fill numéricas de Vida e Mana, com a Mana ainda apenas visual;
- hotbar de habilidades com Q para arma, E para Lapada e R para recarga;
- quatro slots visuais de armadura no canto inferior esquerdo, na ordem cabeça,
  busto, pernas e pés;
- ataques automáticos enquanto o personagem continua andando;
- troca entre Rifle e Peixeira com **Q** e intervalo de 0,5 segundo;
- Rifle com pente de 5 balas, reserva inicial de 10, alcance 5 tiles, dano 25 e
  crítico de 40;
- recarga manual com **R** em 1,5 segundo, mantendo movimento e bloqueando
  ataques, Lapada e Q até concluir;
- Espaço cancelando a recarga para tentar o aparo, sem consumir a reserva antes
  da conclusão do temporizador;
- Peixeira com alcance 1 tile, dano 20 e crítico de 30;
- Lapada Seca carregada por 3 críticos acertados de Rifle, persistindo entre cenas;
- Lapada Seca disparada instantaneamente com **E**, sem mira e sem interromper o movimento;
- Lapada Seca consumindo 1 bala, zerando as cargas e eliminando o inimigo comum;
- números de dano animados e críticos maiores, vermelhos e em negrito;
- Capanga com patrulha, perseguição, retorno e regeneração de 5 HP/s;
- três ataques básicos de 15 seguidos por um pesado de 30;
- alerta **!**, aparo com Espaço e retorno visual **HÁ**;
- falha de aparo causando stun e perda do próximo ataque;
- derrota retornando ao início com 40% de vida e munição preservada;
- `GameState` como fonte única para vida, pente, reserva, arma, ouro, encontros
  derrotados e progresso da masmorra;
- perfis internos de salas e inimigos centralizando obstáculos, patrulha,
  atributos, ataques e representação visual da masmorra;
- respawn de 40% e transições de mapa sincronizados imediatamente no estado
  global;
- porta no fim do caminho, liberada somente após derrotar o Capanga;
- mob comum externo renascendo com vida cheia e patrulha normal ao retornar de
  outra cena, sem duplicar progresso ou recompensa;
- confirmação **Sim/Não** e fade de 0,5 segundo para entrar na masmorra;
- mapa separado de masmorra com três salas em tempo real de 16×12 e uma batalha
  final 1×1 orientada por menus;
- segunda sala diferenciada por três blocos de pedras que formam duas rotas
  transitáveis até a escada;
- Lobo-guará corrompido na segunda sala, com 70 HP, perseguição a 220 px/s e
  ataque de 10 a cada 0,8 segundo, sem golpe pesado ou regeneração;
- pedras bloqueando movimento e busca de caminho, enquanto tiros do Rifle e a
  Lapada Seca continuam atravessando objetos que não sejam paredes;
- silhueta provisória do Lobo-guará desenhada pelo código, sem novo recurso de
  arte nesta etapa;
- terceira sala iniciando o segundo andar, com quatro pedras espalhadas como
  cobertura e uma Rasga-Mortalha própria;
- Rasga-Mortalha com 60 HP, patrulha entre dois pontos, detecção em 6 tiles,
  desistência acima de 10 tiles e reposicionamento a 120 px/s;
- ataque à distância de 10 a cada 1,2 segundo, usando projétil visível e
  desviável a 300 px/s, bloqueado por paredes e pedras;
- recuo abaixo de 3 tiles, alcance máximo de 5 tiles e continuação dos disparos
  quando não existir rota de fuga;
- projéteis da Rasga-Mortalha não aparáveis e silhueta provisória desenhada por
  código, sem alterar recursos gráficos;
- combate em tempo real da sala preservando Rifle, Peixeira, Lapada Seca,
  aparo, munição, vida e movimentação por clique ou WASD;
- escada selada enquanto o inimigo da sala estiver vivo e liberada após a vitória,
  com a conclusão da sala registrada no `GameState`;
- transições `sala_01 → sala_02 → sala_03 → sala_04` com fade de 0,5 segundo,
  preservando vida, pente, reserva, arma, ouro e cargas da Lapada;
- porta de retorno disponível somente na sala inicial;
- derrota interna oferecendo **Voltar do início** ou **Sair**, reiniciando o
  progresso e restaurando o herói com 40% de vida;
- saída pela porta ou pela opção **Sair da Masmorra** na pausa, apagando o
  progresso interno sem curar ou recarregar e devolvendo o herói à entrada;
- quarta sala iniciando uma batalha 1×1 por menus contra a Cabra-Cabriola, com
  o Cangaceiro agindo primeiro e sem grade ou movimentação tática;
- ciclo inspirado nos RPGs por turnos clássicos: escolha da ação, resolução do
  jogador, anúncio do inimigo, impacto e retorno ao menu;
- Cabra-Cabriola com 250 HP, dois ataques básicos de 20 e uma Investida de 40
  no terceiro turno próprio;
- Investida precedida por telegraph de 0,35 segundo e janela reativa de 0,7
  segundo para aparo por Espaço;
- preparação da Investida separada visualmente da janela ativa, que mostra
  **APERTE [ESPAÇO] PARA APARAR**, contagem regressiva e barra de tempo;
- aparo bem-sucedido anulando a investida e aparo fora da janela causando stun
  de 0,7 segundo e perda da próxima ação, com uma tentativa por golpe;
- Rifle, Peixeira, munição, recarga tática e Lapada Seca de 75 de dano integrados
  ao combate do chefe;
- interface da batalha 1×1 separando arena, recursos, mensagens e ações, com
  botões indisponíveis visualmente desativados;
- danos com números animados, crítico vermelho destacado, efeito mágico da
  Lapada, flashes de impacto, borda vermelha ao receber dano e **HÁ!** no aparo;
- tela de vitória com ouro total e saída para o mapa externo; primeira conclusão
  concedendo 250 de ouro sem duplicar a recompensa ao repetir a masmorra;
- animação de espera com 4 quadros a 4 FPS e caminhada articulada com 6 quadros a 10 FPS;
- caminhada com contato, apoio e passagem alternados, mantendo o pé plantado estável;
- troca imediata entre espera e caminhada conforme o deslocamento real;
- Cangaceiro animado na exploração e nas três salas; Capanga animado no mapa
  externo e na primeira sala, com Lobo-guará e Rasga-Mortalha ainda usando
  silhuetas provisórias;
- passos sincronizados por distância, com áudio e poeira na exploração e na masmorra;
- disparos do Rifle com faíscas e fumaça, além de hit-flash por shader;
- áudio procedural para tiro, Peixeira, Lapada Seca, passos, impactos, crítico, aparo, porta e interface;
- HUD e caixas de diálogo com tema de xilogravura e couro;
- menu de pausa com Continuar, Configurações, lista completa de Controles e
  saída da masmorra; as caixas fixas de atalhos foram removidas da tela;
- atlas Sudeste de 640×256 com linhas próprias para Rifle, Capanga, Peixeira e
  Cabra-Cabriola;
- troca visual imediata entre Rifle e Peixeira, preservando o quadro da animação;
- gerador corrigido para manter pernas e corpo unidos durante a caminhada da
  Peixeira e a espera da Cabra-Cabriola;
- reprodução determinística da arte, materiais de QA e testes automatizados;
- direção Sudeste única nesta etapa;
- correção pixel-perfect do zoom reservada para uma versão futura.

## Próxima decisão

Com o nome oficial aplicado na `V.0.3.0`, o próximo passo recomendado é retomar
a definição do salvamento persistente local antes de iniciar sua implementação.

## Como executar

1. Abra o Godot 4.
2. Importe o arquivo `project.godot` desta pasta.
3. Execute o projeto com **F5** para testar o fluxo completo.

## Controles

- **Clique direito:** definir ou substituir o destino na exploração e na
  masmorra.
- **WASD:** mover continuamente nas direções da tela e cancelar a rota atual.
- **M:** alternar entre câmera próxima e visão geral do mapa.
- **Q:** alternar entre Rifle e Peixeira.
- **E:** disparar instantaneamente a Lapada Seca quando as 3 cargas estiverem prontas.
- **R:** recarregar manualmente o Rifle usando as balas da reserva.
- **Espaço:** tentar aparar o ataque pesado durante o alerta **!**.
- **Enter ou Espaço:** confirmar uma caixa de entrada ou saída.
- **Esc:** abrir/fechar a pausa ou voltar da tela de Controles; em caixas de
  confirmação, cancelar a ação.
- **Porta da masmorra:** toque nela após derrotar o Capanga para entrar.
- Os ataques básicos são automáticos quando o Capanga entra no alcance da arma.
- **Batalha do chefe:** clique esquerdo escolhe Rifle, Peixeira, Lapada ou
  Recarga; **Q** troca a arma selecionada e **Enter** confirma seu ataque básico.
- **Espaço:** apara durante a janela da Investida; cedo ou tarde demais causa
  stun de 0,7 segundo e perda da próxima ação.
- **Pausa na masmorra:** **Sair da Masmorra** abre a confirmação de saída.

## Versionamento

Cada entrega de código recebe uma versão, um commit descritivo e uma tag com o
mesmo identificador. Consulte [`VERSIONAMENTO.md`](VERSIONAMENTO.md) e
[`CHANGELOG.md`](CHANGELOG.md).
