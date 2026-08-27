# Histórico de versões

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
