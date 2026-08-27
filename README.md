# Masmorras-Monstros-Mandigas

Protótipo de **Pindorama Fantástica**, um RPG tático por turnos em Godot 4,
ambientado numa fantasia histórico-folclórica brasileira.

**Versão atual:** `V.0.1.1`

O escopo aprovado está em [`GDD_MVP.md`](GDD_MVP.md).

## Estado atual

- mapa de exploração isométrico com 16×12 tiles de 64×32 pixels;
- movimentação contínua por clique a 140 px/s;
- novo clique substitui imediatamente o destino anterior;
- busca de caminho que contorna terreno bloqueado;
- câmera seguindo o personagem e visão geral alternada pela tecla **M**;
- cena tática anterior preservada como protótipo de combate;
- grade de 10×10 casas;
- tiles lógicos de 32×32 pixels;
- movimento de até 4 casas por turno;
- quatro direções ortogonais, sem diagonais;
- busca de rota que respeita obstáculos;
- prévia visual das casas alcançáveis e do caminho;
- encerramento e reinício do turno;
- arte geométrica temporária, sem assets definitivos.

Nenhum valor de vida, dano ou atributo ainda não aprovado foi usado.

## Como executar

1. Abra o Godot 4.
2. Importe o arquivo `project.godot` desta pasta.
3. Execute a cena principal com **F6** ou o projeto com **F5**.

## Controles

- **Clique esquerdo:** definir ou substituir o destino na exploração.
- **M:** alternar entre câmera próxima e visão geral do mapa.
- Na cena tática anterior, **Enter** encerra o turno e **R** reinicia o teste.

> O executável do Godot não estava disponível no terminal durante a criação;
> por isso, a cena precisa ser aberta no editor para a primeira validação real.

## Versionamento

Cada entrega de código recebe uma versão, um commit descritivo e uma tag com o
mesmo identificador. Consulte [`VERSIONAMENTO.md`](VERSIONAMENTO.md) e
[`CHANGELOG.md`](CHANGELOG.md).
