# Monstros, Masmorras e Mandingas

Protótipo de **Pindorama Fantástica**, um RPG em Godot 4 com exploração e
combate comum em tempo real, além de batalhas táticas reservadas aos chefes.

**Versão atual:** `V.0.2.2`

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
- Lapada Seca consumindo 1 bala, zerando as cargas e eliminando o Capanga;
- números de dano animados e críticos maiores, vermelhos e em negrito;
- Capanga com patrulha, perseguição, retorno e regeneração de 5 HP/s;
- três ataques básicos de 15 seguidos por um pesado de 30;
- alerta **!**, aparo com Espaço e retorno visual **HÁ**;
- falha de aparo causando stun e perda do próximo ataque;
- derrota retornando ao início com 40% de vida e munição preservada;
- `GameState` como fonte única para vida, pente, reserva, arma, ouro, encontros
  derrotados e progresso da masmorra;
- respawn de 40% e transições de mapa sincronizados imediatamente no estado
  global;
- porta no fim do caminho, liberada somente após derrotar o Capanga;
- mob comum externo renascendo com vida cheia e patrulha normal ao retornar de
  outra cena, sem duplicar progresso ou recompensa;
- confirmação **Sim/Não** e fade de 0,5 segundo para entrar na masmorra;
- mapa separado de masmorra com duas salas encadeadas de 16×12, reutilizando
  temporariamente o mesmo mapa e um Capanga em cada encontro;
- combate em tempo real da sala preservando Rifle, Peixeira, Lapada Seca,
  aparo, munição, vida e movimentação por clique ou WASD;
- escada selada enquanto o Capanga estiver vivo e liberada após a vitória,
  com a conclusão da sala registrada no `GameState`;
- transição `sala_01 → sala_02` com fade de 0,5 segundo, preservando vida,
  pente, reserva, arma, ouro e cargas da Lapada;
- porta de retorno disponível somente na sala inicial; **Esc** continua abrindo
  a saída voluntária em ambas as salas;
- derrota interna oferecendo **Voltar do início** ou **Sair**, reiniciando o
  progresso e restaurando o herói com 40% de vida;
- saída pela porta ou por **Esc**, apagando o progresso interno sem curar ou
  recarregar e devolvendo o herói diante da entrada externa;
- arena tática da versão anterior preservada para futuros chefes;
- animação de espera com 4 quadros a 4 FPS e caminhada articulada com 6 quadros a 10 FPS;
- caminhada com contato, apoio e passagem alternados, mantendo o pé plantado estável;
- troca imediata entre espera e caminhada conforme o deslocamento real;
- Cangaceiro e Capanga animados na exploração e nas duas salas da masmorra;
- passos sincronizados por distância, com áudio e poeira na exploração e na masmorra;
- disparos do Rifle com faíscas e fumaça, além de hit-flash por shader;
- áudio procedural para tiro, Peixeira, Lapada Seca, passos, impactos, crítico, aparo, porta e interface;
- HUD e caixas de diálogo com tema de xilogravura e couro;
- atlas Sudeste de 640×256 com linhas próprias para Rifle, Capanga, Peixeira e
  Cabra-Cabriola;
- troca visual imediata entre Rifle e Peixeira, preservando o quadro da animação;
- gerador corrigido para manter pernas e corpo unidos durante a caminhada da
  Peixeira e a espera da Cabra-Cabriola;
- reprodução determinística da arte, materiais de QA e testes automatizados;
- direção Sudeste única nesta etapa;
- correção pixel-perfect do zoom reservada para uma versão futura.

## Próxima decisão

Com o encadeamento `sala_01 → sala_02` funcional na `V.0.2.2`, a próxima decisão
será definir o conteúdo definitivo da segunda sala sem iniciar o chefe ainda.

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
- **Esc:** cancelar uma caixa aberta; dentro da masmorra, abrir o aviso de saída.
- **Porta da masmorra:** toque nela após derrotar o Capanga para entrar.
- Os ataques básicos são automáticos quando o Capanga entra no alcance da arma.

## Versionamento

Cada entrega de código recebe uma versão, um commit descritivo e uma tag com o
mesmo identificador. Consulte [`VERSIONAMENTO.md`](VERSIONAMENTO.md) e
[`CHANGELOG.md`](CHANGELOG.md).
