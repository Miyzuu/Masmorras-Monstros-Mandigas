# Monstros, Masmorras e Mandingas

Protótipo de **Pindorama Fantástica**, um RPG em Godot 4 com exploração e
combate comum em tempo real, além de batalhas táticas reservadas aos chefes.

**Versão atual:** `V.0.1.9`

O escopo aprovado está em [`GDD_MVP.md`](GDD_MVP.md).

## Estado atual

- mapa de exploração isométrico com 16×12 tiles de 64×32 pixels;
- movimentação contínua por clique a 140 px/s;
- novo clique substitui imediatamente o destino anterior;
- busca de caminho que contorna terreno bloqueado;
- câmera seguindo o personagem e visão geral alternada pela tecla **M**;
- Capanga patrulhando mais adiante, detectando e perseguindo o herói;
- combate contra o Capanga diretamente no mapa, sem troca de cena;
- Cangaceiro com 100 HP e Capanga com 150 HP;
- barra de vida do herói no rodapé e barra inimiga acima do alvo;
- ataques automáticos enquanto o personagem continua andando;
- troca entre Rifle e Peixeira com **Q** e recarga de 0,5 segundo;
- Rifle com 5 balas, alcance 5 tiles, dano 25 e crítico de 40;
- Peixeira com alcance 1 tile, dano 20 e crítico de 30;
- números de dano animados e críticos maiores, vermelhos e em negrito;
- Capanga com patrulha, perseguição, retorno e regeneração de 5 HP/s;
- três ataques básicos de 15 seguidos por um pesado de 30;
- alerta **!**, aparo com Espaço e retorno visual **HÁ**;
- falha de aparo causando stun e perda do próximo ataque;
- derrota retornando ao início com 40% de vida e munição preservada;
- `GameState` como fonte única para vida, munição, arma, ouro, encontros
  derrotados e progresso da masmorra;
- respawn de 40% e transições de mapa sincronizados imediatamente no estado
  global;
- porta no fim do caminho, liberada somente após derrotar o Capanga;
- confirmação **Sim/Não** e fade de 0,5 segundo para entrar na masmorra;
- mapa separado de masmorra com sala de pedra 16×12, saída inicial e escada
  bloqueada;
- saída pela porta ou por **Esc**, apagando o progresso interno sem curar ou
  recarregar e devolvendo o herói diante da entrada externa;
- arena tática da versão anterior preservada para futuros chefes;
- animação de espera com 4 quadros a 4 FPS e caminhada articulada com 6 quadros a 10 FPS;
- caminhada com contato, apoio e passagem alternados, mantendo o pé plantado estável;
- troca imediata entre espera e caminhada conforme o deslocamento real;
- Cangaceiro e Capanga animados na exploração e Cangaceiro animado na masmorra;
- passos sincronizados por distância, com áudio e poeira na exploração e na masmorra;
- disparos do Rifle com faíscas e fumaça, além de hit-flash por shader;
- áudio procedural para tiro, Peixeira, passos, impactos, crítico, aparo, porta e interface;
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

Com a integração audiovisual e a correção do atlas da `V.0.1.9` concluídas, a
próxima decisão retorna à Engine, usando o `GameState` compartilhado como base.

## Como executar

1. Abra o Godot 4.
2. Importe o arquivo `project.godot` desta pasta.
3. Execute o projeto com **F5** para testar o fluxo completo.

## Controles

- **Clique esquerdo:** definir ou substituir o destino na exploração.
- **M:** alternar entre câmera próxima e visão geral do mapa.
- **Q:** alternar entre Rifle e Peixeira.
- **Espaço:** tentar aparar o ataque pesado durante o alerta **!**.
- **Enter ou Espaço:** confirmar uma caixa de entrada ou saída.
- **Esc:** cancelar uma caixa aberta; dentro da masmorra, abrir o aviso de saída.
- **Porta da masmorra:** toque nela após derrotar o Capanga para entrar.
- Os ataques básicos são automáticos quando o Capanga entra no alcance da arma.

## Versionamento

Cada entrega de código recebe uma versão, um commit descritivo e uma tag com o
mesmo identificador. Consulte [`VERSIONAMENTO.md`](VERSIONAMENTO.md) e
[`CHANGELOG.md`](CHANGELOG.md).
