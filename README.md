# Masmorras-Monstros-Mandigas

Protótipo de **Pindorama Fantástica**, um RPG em Godot 4 com exploração e
combate comum em tempo real, além de batalhas táticas reservadas aos chefes.

**Versão atual:** `V.0.1.4`

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
- arena tática da versão anterior preservada para futuros chefes;
- arte geométrica temporária, sem assets definitivos.

## Como executar

1. Abra o Godot 4.
2. Importe o arquivo `project.godot` desta pasta.
3. Execute o projeto com **F5** para testar o fluxo completo.

## Controles

- **Clique esquerdo:** definir ou substituir o destino na exploração.
- **M:** alternar entre câmera próxima e visão geral do mapa.
- **Q:** alternar entre Rifle e Peixeira.
- **Espaço:** tentar aparar o ataque pesado durante o alerta **!**.
- Os ataques básicos são automáticos quando o Capanga entra no alcance da arma.

## Versionamento

Cada entrega de código recebe uma versão, um commit descritivo e uma tag com o
mesmo identificador. Consulte [`VERSIONAMENTO.md`](VERSIONAMENTO.md) e
[`CHANGELOG.md`](CHANGELOG.md).
