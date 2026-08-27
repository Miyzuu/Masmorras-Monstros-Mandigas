# Masmorras-Monstros-Mandigas

Protótipo de **Pindorama Fantástica**, um RPG tático por turnos em Godot 4,
ambientado numa fantasia histórico-folclórica brasileira.

**Versão atual:** `V.0.1.3`

O escopo aprovado está em [`GDD_MVP.md`](GDD_MVP.md).

## Estado atual

- mapa de exploração isométrico com 16×12 tiles de 64×32 pixels;
- movimentação contínua por clique a 140 px/s;
- novo clique substitui imediatamente o destino anterior;
- busca de caminho que contorna terreno bloqueado;
- câmera seguindo o personagem e visão geral alternada pela tecla **M**;
- Capanga parado no início do caminho, ativado por contato físico;
- fade de 0,5 segundo entre exploração e arena;
- retorno ao mesmo ponto com remoção do Capanga após a vitória real;
- Cangaceiro com 100 HP e Capanga com 60 HP;
- barra de vida do herói no rodapé e barra inimiga acima do alvo;
- Disparo com dano 25, alcance ortogonal 7, 90% de acerto e crítico de 40;
- Peixeira com alcance 1, acerto garantido e dano 20;
- paredes bloqueando tiros e rochas bloqueando apenas movimento;
- Capanga avançando até 3 casas e atacando adjacente por 15 de dano;
- grade de 10×10 casas;
- tiles lógicos de 32×32 pixels;
- movimento de até 4 casas por turno;
- quatro direções ortogonais, sem diagonais;
- busca de rota que respeita obstáculos;
- prévia visual das casas alcançáveis e do caminho;
- seleção de ataque por botão e clique no inimigo;
- derrota reiniciando o encontro com vida cheia;
- arte geométrica temporária, sem assets definitivos.

## Como executar

1. Abra o Godot 4.
2. Importe o arquivo `project.godot` desta pasta.
3. Execute o projeto com **F5** para testar o fluxo completo.

## Controles

- **Clique esquerdo:** definir ou substituir o destino na exploração.
- **M:** alternar entre câmera próxima e visão geral do mapa.
- **Clique em casa verde:** mover na arena.
- **Disparo/Peixeira + clique no Capanga:** executar um ataque.
- **Enter:** encerrar o turno sem atacar.
- **R:** reiniciar o encontro.

## Versionamento

Cada entrega de código recebe uma versão, um commit descritivo e uma tag com o
mesmo identificador. Consulte [`VERSIONAMENTO.md`](VERSIONAMENTO.md) e
[`CHANGELOG.md`](CHANGELOG.md).
