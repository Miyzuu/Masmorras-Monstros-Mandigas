# Ferramenta da prova de personagens

`build_character_prototype.py` transforma a fonte aprovada em um protótipo técnico reproduzível.

Ambiente validado:

- Python 3.12.13
- Pillow 12.3.0, fixado em `requirements.txt`

Exemplo a partir da raiz do repositório:

```powershell
python assets/art/tools/build_character_prototype.py `
  --input assets/art/source/personagens_conceito_simplificado.png `
  --sprites assets/art/characters/prototypes/personagens_se_48px_16c.png `
  --preview assets/art/qa/personagens_se_48px_16c_zoom8.png `
  --palette assets/art/palette/paleta_sertao_16.png `
  --scene assets/art/qa/cena_atual_base.png `
  --scene-test assets/art/qa/teste_personagens_cena_atual_145x.png
```

O script não usa rede, não altera arquivos da engine e escreve somente nos caminhos fornecidos.

## Atlas animado Sudeste

O mesmo script deriva os 20 quadros da V.0.1.7 a partir do atlas estático aprovado. Ele remove e
reaplica o contorno externo, mede a altura original de cada sola, desloca tronco e pernas em pixels
inteiros e fixa o pé de apoio em `y=60`. A caminhada usa contato, apoio/queda e passagem para cada
perna; no apoio, tronco e quadril descem 1 px e avançam 1 px na direção do pé plantado.

Antes de recompor cada quadro de caminhada, o gerador recorta e remove do bloco-base as camadas de
movimento secundário. No Cangaceiro são `hat_scarf` e `arms_rifle`; no Capanga são `helmet` e
`arms_flaps`, mantendo a armadura central sólida e as mãos sem arma. As caixas são mascaradas pela
alpha original, tornam-se mutuamente exclusivas e precisam reconstruir exatamente o sprite-fonte,
sem perder nem duplicar pixels.

Cada camada secundária fica no máximo 1 px distante do tronco e fecha o loop sem saltos maiores que
1 px. Chapéu/lenço e capacete atingem os extremos horizontais um quadro depois do tronco, enquanto
braços, rifle e abas usam perfis próprios. As quatro poses paradas não usam essa separação e
permanecem iguais às poses aprovadas.

A validação exige dimensões, paleta e alpha corretos, quatro quadros parados distintos, seis quadros
de caminhada distintos, contato contínuo no chão, deriva máxima de 1 px do pé plantado, tronco na
direção correta do apoio, caixas secundárias sem sobreposição, atraso de um quadro e ausência de
peças destacadas. A imagem grande de poses é consultada apenas como referência de cadência; nenhum
pixel dela é copiado para o atlas final.

```powershell
python assets/art/tools/build_character_prototype.py `
  --base-sprites assets/art/characters/prototypes/personagens_se_48px_16c.png `
  --pose-reference assets/art/source/personagens_se_idle4_walk6_referencia_poses_corrigida.png `
  --animation-sprites assets/art/characters/animations/personagens_se_idle4_walk6_64px_16c.png `
  --animation-preview assets/art/qa/personagens_se_idle4_walk6_64px_16c_zoom4.png `
  --idle-preview assets/art/qa/personagens_se_idle4_4fps.gif `
  --walk-preview assets/art/qa/personagens_se_walk6_10fps.gif
```

Uma execução válida imprime `ANIMATION_ATLAS_OK` e um resumo JSON dos limites, cores, transições e
perfis de movimento primário/secundário.
O comando estático anterior continua aceito sem alterações.
