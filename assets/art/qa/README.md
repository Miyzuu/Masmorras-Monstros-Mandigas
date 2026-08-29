# QA da prova visual de personagens

## Arquivos

- `cena_atual_base.png`: captura da cena `exploration.tscn` em 768×512, sem salvar alterações na engine.
- `personagens_se_48px_16c_zoom8.png`: ampliação nearest-neighbor para inspeção dos pixels.
- `teste_personagens_cena_atual_145x.png`: composição de QA sobre a cena real, usando o zoom atual de 1,45×.

O teste de cena é uma composição externa e não representa integração na Godot. O Cangaceiro foi colocado sobre o ponto inicial do jogador; o Capanga foi colocado em um tile visível apenas para comparação de leitura.

## Critérios de aprovação

1. Conferir o arquivo-fonte em 100%: cada personagem ocupa uma célula 64×64, mede 48 px de altura e usa o ponto dos pés em `(32, 60)`.
2. Conferir a ampliação 8×: os pixels precisam permanecer quadrados, sem suavização nem transparência parcial.
3. Conferir a cena em 768×512: chapéu, postura, rifle e armadura precisam ser distinguíveis sobre chão e estrada.
4. Na futura branch de integração, testar câmera normal, tecla `M`, caminhada e sobreposição com props.
5. O zoom 1,45× atual produz pixels de larguras diferentes. A correção pixel-perfect pertence a uma branch de desenvolvimento, não a esta branch de arte.
