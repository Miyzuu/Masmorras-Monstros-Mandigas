# Procedência e Licença Técnica dos Assets de Arte

- **Projeto:** Monstros, Masmorras e Mandingas / Pindorama Fantástica
- **Autor/Geração Técnica:** Artista Técnico 2D do projeto via scripts determinísticos em Python (Pillow 12.3.0).
- **Paleta Oficial:** `paleta_sertao_16` (16 cores exatas mapeadas em `palette/paleta_sertao_16.gpl`).
- **Assets Externos Incorporados:** Nenhum. Todas as texturas, losangos isométricos, paredes, cactos, arbustos, variações de personagens e sprites de chefão foram produzidos pixel a pixel de forma determinística e procedural interna.

## 1. Pacote de Tilesets Isométricos 64×32
- `tileset_caatinga_terra_rachada.png`: Procedência procedural determinística via `build_tilesets.py`.
- `tileset_caminho_batido.png`: Procedência procedural determinística via `build_tilesets.py`.
- `tileset_masmorra_pedra.png`: Procedência procedural determinística via `build_tilesets.py`.
- `tileset_paredes_taipa.png`: Procedência procedural determinística via `build_tilesets.py`.
- `tileset_vegetacao_caatinga.png`: Procedência procedural determinística via `build_tilesets.py`.
- `tileset_master_sertao_64x32.png`: Montagem determinística de atlas.

## 2. Variação do Cangaceiro com Peixeira & Chefão Cabra-Cabriola
- `cangaceiro_peixeira_se_48px_16c.png` e atlas animado: Derivado e recomposto pixel a pixel a partir do protótipo base aprovado `personagens_se_48px_16c.png` via `build_characters_expanded.py`, mantendo a mesma anatomia, chapéu e paleta, com nova postura e lâmina curva de peixeira.
- `cabra_cabriola_se_64px_16c.png` e atlas animado: Desenho técnico original da besta mitológica brasileira, criado de forma determinística em célula 64×64 px com âncora em `(32, 60)` via `build_characters_expanded.py`.

## 3. Conformidade Técnica
- Todos os arquivos foram auditados e aprovados pela suíte `verify_art_assets.py`.
- 100% dos pixels em conformidade estrita com a `paleta_sertao_16`.
- Contorno preto puro `#000000` estritamente externo (1px).

## 4. HUD v5 modular — 09/09/2026 — aprovado para integração técnica

Esta entrada aplica-se somente a `assets/art/ui/hud_v5/hud_v5_chrome_768.png`,
`hud_v5_content_768.png` e seu README. As afirmações anteriores de geração
exclusivamente procedural, paleta de 16 cores e suíte histórica NÃO se aplicam
a este pacote.

- Responsável técnico: tarefa 40 — Arte, áudio e direção visual, a pedido do
  usuário via Central. Exclusividade de acréscimo neste documento confirmada
  pela Central antes da escrita.
- Base fornecida/aprovada pelo usuário: `HUD base autoritativa v5 —
  2026-09-09.png`, 1022×255, e variantes Rifle/Peixeira, preservadas no vault.
  Chrome e retrato são derivados dessa base por recortes, máscaras e
  redimensionamento modular nearest. Não foram incorporados como fundo único.
- Conteúdo gerado: coração, cristal, Rifle, Peixeira, setas, capacete,
  peitoral, calça, botas, poção, moeda e mapa; imagegen integrada, geração
  `exec-813f41ac-299f-4351-bdf3-a062074f1a82.png`, 1536×1024 RGB. Prompt:
  decompor a referência aprovada em molduras e ícones isolados, sem cenário,
  texto, valores ou marcadores, preservando madeira/cordas e pixel art. A
  solicitação de transparência não foi atendida pela geração; o quadriculado
  pintado foi removido por máscara de fundo conectada às bordas de cada recorte.
- Montagem: Pillow já instalado, RGBA de alpha reto, atlas 768×256,
  coordenadas inteiras e filtro nearest. Retrato circular e trilho usam máscaras
  geométricas. Minis de armas são derivados dos respectivos ícones. Sem
  fontes/textos dinâmicos incorporados, sem downloads de bancos de assets.
- Licença/procedência disponível: autorização expressa do usuário para produzir
  este pacote e derivar as referências fornecidas. Não foi fornecida uma licença
  externa, identificação do autor original de cada componente da referência ou
  autorização pública de redistribuição com termos específicos. Não atribuir
  CC0, domínio público ou licença open source por inferência; confirmação
  documental de direitos de distribuição permanece pendente antes de publicação.
  A aprovação visual não resolve essa lacuna documental.
- Validação própria: dimensões, alpha 0/255, regiões não vazias/sem sobreposição,
  posições e composições estáticas dos dois estados Q. Não foi executada a suíte
  histórica `verify_art_assets.py`, nem testes de engine. Este pacote não declara
  16 cores ou contorno preto de 1px.
- Estado: pacote aprovado explicitamente pelo usuário, copiado localmente para
  `dev/hud-v5-composition`; sem commit, push, PR, merge, tag, backup ou
  publicação.

## 5. HUD v5 modular — revisão visual final 10/09/2026 — validada localmente

Esta entrada aplica-se somente aos dois atlas e ao README em `assets/art/ui/hud_v5/`. As afirmações anteriores de geração exclusivamente procedural, paleta de 16 cores e suíte histórica NÃO se aplicam a esta revisão.

- Responsável técnico: tarefa 40 — Arte, áudio e direção visual, a pedido do usuário via Central.
- Referências fornecidas pelo usuário: composição completa 1536×1024 e recortes dos estados Q com Rifle e Peixeira, usados como direção visual e geometria. As imagens de referência não foram incorporadas aos atlas como fundo ou HUD achatada.
- Conteúdo produzido: sol, relógio, região, coração, cristal de mana, marcador de XP, moeda, Rifle, Peixeira, setas, capacete, peitoral, calça, botas, poção, retrato, mapa e elementos modulares de madeira/corda; imagegen integrada, geração `exec-5893a778-a752-4e51-ab4c-3d48533fc671.png`, 1536×1024 RGB. A geração veio sobre magenta; a cor de recorte foi removida de toda peça antes da montagem e o resultado foi conferido visualmente.
- Montagem: Pillow já instalado, RGBA com alpha reto, atlas 768×256, coordenadas inteiras e filtro `nearest`. Cada peça foi isolada e reduzida individualmente; molduras e interiores foram remontados por módulo. Minis de armas derivam das armas correspondentes. Textos, valores, fonte e preenchimentos não estão incorporados nos atlas.
- Licença/procedência disponível: autorização expressa do usuário para produzir este pacote e derivar as referências fornecidas. Não foi fornecida licença externa, identificação do autor original de cada componente das referências ou autorização pública de redistribuição com termos específicos. Não atribuir CC0, domínio público ou licença open source por inferência; confirmação documental de direitos de distribuição permanece pendente antes de publicação.
- Validação própria de Arte: dimensões e modo, alpha somente 0/255, regiões dentro dos limites, não vazias e sem sobreposição, popup integralmente dentro de Q, separação vertical entre arma/nome, munição exclusiva do Rifle, estados de armadura vazio/equipado e mapa 112×112 na posição final. Os hashes constam no README.
- Limite da validação de Arte: não foi executada a suíte histórica `verify_art_assets.py`; o teste de engine pertence à integração técnica. Este pacote não declara 16 cores ou contorno preto de 1px.
- Estado de origem: arquivos locais no worktree `art/hud-v5-madeira-cordas`, base `5131e9141ae126775a918462b8355c7038d5bb9e`; sem commit ou push na origem.

## 6. Cinco SFX fornecidos e aprovados pelo usuário — 10/09/2026 — locais

Esta entrada cobre somente `lapada_seca.wav`, `rifle_tiro.wav`, `recarregar.wav`, `corpo_caindo_morte.wav` e `bebendo_pocao.wav` em `assets/art/audio/`. Os cinco MP3 originais permanecem fora do repositório, em `Downloads/`, sem alteração.

- Origem declarada: arquivos fornecidos e explicitamente aprovados pelo usuário para uso no projeto. Não foi apresentada documentação de autoria, licença pública ou autorização de redistribuição pública. O aceite para o projeto não deve ser descrito como CC0, domínio público ou licença open source; confirmar os direitos de publicação antes de distribuir.
- Formato final: WAV PCM estéreo, 44.100 Hz, 16-bit, sem compressão. O formato é lido nativamente pelo Godot e evita nova perda com recodificação; o conjunto final ocupa cerca de 1,19 MiB.
- Tratamento comum: decodificação local pelo Godot, remoção de DC por canal, corte apenas de bordas abaixo do limiar documentado, fade linear de 5 ms nas duas extremidades e escrita PCM. Nenhuma camada, síntese, mudança de pitch, reverberação ou efeito novo foi adicionado.

| Uso | Original SHA-256 | Final SHA-256 | Duração original → final | Tratamento específico | Pico final |
|---|---|---|---:|---|---:|
| Lapada Seca | `909d039d9d73b6113b7d4b2f7ea429ca7787fea33e1fa1ac868305a266f5cbaf` | `41a32ded17daef1e447c1ec4483a43bf09df4ea8e48c8794c78dfbf80a6926a8` | 3,082 → 3,053 s | corte inicial 0,030 s; sem ganho | −1,23 dBFS |
| Rifle | `1a547a9ca01969e639a3a89a4549a0da670059b32e50c2ec05b5a017e7790c2b` | `f71e64621962ba2f181e50fa1eeb0519789c18e6e2e737ef25af3e71054aa8c9` | 1,992 → 1,058 s | cortes 0,130/0,805 s a −50 dBFS; sem ganho | −3,67 dBFS |
| Recarga | `dff87d8ed3e14b79718ea8bbed5519682657e7facc944b7dcfef353638b39bf2` | `3a24214b6c55ba88f7d33611420f8d6287ad2f4c7a990660d3f8b274e55d6bf1` | 1,512 → 1,097 s | tratamento anterior mais remoção de 0,120 s de intervalo interno silencioso; crossfade de 5 ms; sem alterar pitch | −3,00 dBFS |
| Corpo caindo | `1d4d3db27ce77d5ee083267b487186853f5dc1c56f76d3cdd7f17ce91a796114` | `69819a3899b46a3ce45465701415850a017d830b1dda849588bfea8b31766d88` | 0,864 → 0,384 s | cortes 0,075/0,405 s; sem ganho | −4,63 dBFS |
| Poção | `22567e532bd34a280206d4b89b873f585fc415ad3faf1918052172054ed0430e` | `52e22edbf8a75b782976e9b1367348dd5bf9587c10b3aa185b334dbceca79dfd` | 1,392 → 1,342 s | cortes 0,035/0,015 s; redução de 3,37 dB | −4,00 dBFS |

- Validação própria: os cinco originais foram reproduzidos uma vez; os cinco finais foram reproduzidos uma vez. Cabeçalhos, duração, pico, RMS, DC, bordas e clipping foram relidos após a escrita. Todos os finais começam e terminam em zero e têm zero amostras saturadas.
- Godot 4.7.2: importação do projeto terminou com exit 0 e listou os cinco WAV; cada recurso foi carregado como `AudioStreamWAV`, instanciado e decodificado com buffer não vazio. Os avisos de certificado e gravação de configuração do editor pertencem ao ambiente e não impediram a importação.
- Estado de origem: pacote local no worktree `art/hud-v5-madeira-cordas`, HEAD/base `5131e9141ae126775a918462b8355c7038d5bb9e`. Nesta cópia, os arquivos foram ligados localmente aos eventos existentes; continuam sem commit, publicação ou liberação.

## 7. Recarga revisada e três SFX originais — 10/09/2026 — integrados localmente

- `recarregar.wav`: revisão do WAV local aprovado de SHA-256 `537a9e1055b2fc5dd5dd617032a291384e0c1bfc9b088906127dcbd714f992cd`. Foram removidos 0,120 s do intervalo de baixa energia entre 0,330 e 0,450 s, com emenda cruzada de 5 ms. Duração 1,097324 s; não houve time-stretch, mudança de pitch, síntese adicional ou alteração do clique final. SHA-256 final `3a24214b6c55ba88f7d33611420f8d6287ad2f4c7a990660d3f8b274e55d6bf1`.
- `critical_hit.wav`, `peixeira_draw.wav` e `peixeira_hit.wav`: criações originais e determinísticas em Python/NumPy, sem sample, foley, banco, voz ou material externo. Ruído pseudorrandômico usa sementes fixas. Os sinais foram construídos para o projeto com envelopes próprios, síntese tonal/ruído filtrado e pequenas diferenças estéreo.
- Licença/procedência: os três novos sons não incorporam conteúdo de terceiros e foram criados para distribuição pelo titular do projeto. Não atribuir licença pública adicional sem decisão do titular.

| Arquivo | Função sonora | Formato | Duração | Pico / RMS | SHA-256 |
|---|---|---|---:|---:|---|
| `critical_hit.wav` | confirmação brilhante e instantânea sobre um impacto crítico, sem imitar moeda ou XP | WAV PCM estéreo, 44.100 Hz, 16-bit | 0,260 s | −4,50 / −22,52 dBFS | `21ea1f082a98f4a3e767bba2e73ac58ae7a1a0af56f17539bd9dd584ff86319e` |
| `peixeira_draw.wav` | metal deslizando da bainha e pequeno assentamento final, sem golpe | WAV PCM estéreo, 44.100 Hz, 16-bit | 0,410 s | −5,00 / −17,62 dBFS | `bab06f085b4c7f09bf367691b4fe2b7cec67c150460c57f0d1edeb41c511ceb2` |
| `peixeira_hit.wav` | corte/impacto curto e seco, distinto de Rifle e Lapada | WAV PCM estéreo, 44.100 Hz, 16-bit | 0,220 s | −4,00 / −22,63 dBFS | `a05a42c8e60ef373e8460e33317c20ff9bd016bbfbe0a62f9fcfd1599c5193c7` |

- Validação técnica de origem: os quatro WAV foram reabertos após a escrita; todos têm PCM estéreo 44,1 kHz/16-bit, início e fim em zero, DC residual absoluto inferior a `0,00001` e zero amostras saturadas. A reprodução local terminou sem erro.
- Estado desta cópia: os quatro WAV foram importados pelo Godot 4.7.2 e ligados aos eventos existentes de recarga concluída, crítico confirmado, saque da Peixeira e contato confirmado da Peixeira. Integração local, sem commit ou publicação.

## 8. Pacote de 12 SFX fornecidos e aprovados — 10/09/2026 — integrado localmente

Esta entrada registra a versão vigente de 12 arquivos em `assets/art/audio/`: cinco substituições (`rifle_tiro.wav`, `lapada_seca.wav`, `recarregar.wav`, `bebendo_pocao.wav` e `peixeira_hit.wav`) e sete inclusões. As versões homônimas documentadas nas seções 6 e 7 permanecem acima somente como histórico e foram superadas pelos hashes desta seção. `critical_hit.wav`, `peixeira_draw.wav`, `corpo_caindo_morte.wav`, `sfx_xp_gain.wav`, a HUD e os demais áudios não foram substituídos.

- Origem declarada: 12 MP3 fornecidos e explicitamente aprovados pelo usuário na pasta `C:\Users\Caio Vilar\Downloads\AUDIOS APROVADOS\`. Os originais foram lidos sem alteração e permanecem fora do repositório.
- Direitos: não foi apresentada documentação de autoria, licença pública ou autorização de redistribuição pública. O aceite para uso no projeto não deve ser descrito como CC0, domínio público ou licença open source; confirmar os direitos de publicação antes de distribuir.
- Formato final: WAV PCM estéreo, 44.100 Hz, 16-bit, sem compressão.
- Tratamento comum: decodificação local pelo Godot; corte somente nas bordas segundo envelope RMS de 10 ms a −60 dBFS, com 10 ms de margem anterior e 30 ms posterior; correção de DC por canal; fades lineares de 5 ms; ajuste de pico por categoria. Não houve mudança de pitch, compressão dinâmica, reverberação, camada, síntese ou recorte interno.

| Original | SHA-256 original | Final | Duração original → final | Pico / RMS final | SHA-256 final |
|---|---|---|---:|---:|---|
| `ABRINDO MASMORRA.mp3` | `ec157bf4d9078f35f50086e4b81024fb4ebcc7a4e9f0ab97fddee24b45e5b8b7` | `abrindo_masmorra.wav` | 1,608 → 1,567 s | −4,00 / −29,87 dBFS | `3704c7f649cd0fff8f00c8bacced06ef13ac336ff450cdfc9c2e227a36cfd33c` |
| `ABRIR LOJA.mp3` | `58582175ff286647c2ffce64aa2c2545721a53070355c01145838662e9c238ab` | `abrir_loja.wav` | 2,795 → 1,992 s | −6,00 / −28,82 dBFS | `ce4fa5a4fe4566c1fccd6107c047f32a71ad3982434c7e9d0703893db8336062` |
| `BEBENDO LIQUIDO (POÇÕES ETC).MP3` | `5276ee8a01e235aecd3d50fa5e0b765da1de1753c1080251e1da30cd37bef8c1` | `bebendo_pocao.wav` | 0,418 → 0,354 s | −5,00 / −23,55 dBFS | `54d51e4bf507c36f2d35848dc3b16072353350b61e7fd48dac64b9f2b45e91e4` |
| `EQUIPANDO ARMADURAS.MP3` | `d5ed7195095a25174940746fea90453f86c5e5f376df77a9447e2f28c82bf549` | `equipando_armadura.wav` | 0,862 → 0,718 s | −6,00 / −26,77 dBFS | `8c6f9323923c7446c98eb96abe9841623bf18ccb3ce3397e351ee2dc68a4b3cf` |
| `EQUIPANDO RIFLE.MP3` | `fdafbbcb8b82200fa647bc5c392567e11d756679d41a5a4e3476650e00e397ab` | `equipando_rifle.wav` | 1,384 → 0,758 s | −6,00 / −28,09 dBFS | `6409f148609111e2b0cf651209ad600be9b9d21a7e90ee116f1198ece3cc31d3` |
| `FACÃO ATACANDO.MP3` | `59270e83fafd876b1de4fae1b86a4c73d8d677fdbacbfb0f28565a2b911d10bf` | `peixeira_hit.wav` | 0,392 → 0,338 s | −4,00 / −25,94 dBFS | `b758f626a1fa54040da47350078e600e9f86772eabc740c4870c27f5d558a732` |
| `LAPADA SECA.mp3` | `5a5ba52000e8ec1b9f7620783710d8a3c100fb706420de6f97c6019d81b16934` | `lapada_seca.wav` | 2,040 → 1,301 s | −3,00 / −17,68 dBFS | `e58d0e632be108a6d161b19ba9038f9bb2654e08723e329a237c9260e716e1b7` |
| `MORREU NA MASMORRA.MP3` | `0d7a6a2c5c459b62ced239a5181b372ef2a1d2d924cf767f390d1328e128c28a` | `morte_jogador_masmorra.wav` | 2,664 → 2,516 s | −4,00 / −18,92 dBFS | `142ebf51b8a5361ca0d7b639835b9478799a31a75a790e641e518cbe79821ffa` |
| `NOTIFICAÇÃO POPUP DE MOEDA.mp3` | `2a2851363cedcf7b2d6093a79f8cbc196a74ad4fa6852b9ea1fc73d80f39f0b3` | `moeda_popup.wav` | 0,288 → 0,271 s | −6,00 / −18,79 dBFS | `8878b7828e637315659bcd6c6a7cfd9a98fac6a2baf023ce85965f0c4026461f` |
| `RECARREGANDO.MP3` | `42aa561e22c53ffcdbcb25618050f3298bce7017c3fa725125d5dd68c49ba22f` | `recarregar.wav` | 1,358 → 1,326 s | −3,00 / −20,99 dBFS | `8f619aee3372607771feb3f217e24ee42b8fddafab8aa2cf8db650342b32ef6a` |
| `RIFLE ATIRANDO.MP3` | `2e8607065b17a874183cb51cbd6cd658fc60649a10345fadce893f1608e2ce2d` | `rifle_tiro.wav` | 1,855 → 1,807 s | −3,00 / −20,53 dBFS | `332c18abee46d3d62bc996fe9dc994dadad0c8955c7dcfef2c0adc913c84f290` |
| `VENCEU A MASMORRA (BOSS).mp3` | `045f999424f6352dccb597cb94139a1ad76394f3bb776bc4ae852148febb85aa` | `vitoria_boss_masmorra.wav` | 3,265 → 1,072 s | −4,00 / −15,98 dBFS | `bc9b3530cb7153caf72b8f7d417d5e6b912eb4a294c265d676f9a243026fe1da` |

- Validação técnica da origem: os 12 WAV foram reabertos após a escrita e confirmados como PCM estéreo 44,1 kHz/16-bit. Os picos permanecem abaixo de 0 dBFS, sem amostras saturadas; o DC residual foi relido após o processamento.
- Validação da integração: os 12 hashes no checkout coincidem com a origem aprovada; o Godot 4.7.2 reimportou os 12 recursos com exit 0. Os métodos e gatilhos foram cobertos pelas suítes de áudio/VFX, combate em tempo real, exploração, inventário/equipamento, masmorra e chefe/arena. A recarga carregada permanece abaixo de 1,5 s.
- Estado de fechamento: pacote incluído na release local V.0.3.9. `abrir_loja.wav` possui método testável no `AudioManager`, mas não tem gatilho porque não existe fluxo de loja no jogo atual. Sem tag, push, PR, merge, publicação ou deploy.

## 9. Revisão do saque da Peixeira — 11/09/2026 — integrada localmente

- Arquivo: `assets/art/audio/peixeira_draw.wav`, substituindo somente a versão histórica da seção 7. O som de impacto `peixeira_hit.wav` não foi alterado.
- Origem operacional: revisão preparada pela tarefa 40 no worktree `art/hud-v5-madeira-cordas`. Nenhuma documentação adicional de autoria ou licença pública acompanhou esta revisão; a autorização de redistribuição pública permanece pendente.
- Validação técnica direta no checkout: WAV PCM estéreo, 44.100 Hz, 16-bit, 0,632426 s, pico −5,24 dBFS, zero amostras saturadas e SHA-256 `d8bdd56779e67479a25023df17a2bc289f13a43402d23374ad88226c1b4d3830`.
- Integração: nome, caminho, volume e API `play_peixeira_draw` foram preservados. Os gatilhos existentes continuam limitados à troca válida de Rifle para Peixeira em exploração, masmorra e chefe/arena.
- Estado de fechamento: revisão aprovada manualmente pelo usuário e incluída na release local V.0.3.9, sem tag, push, PR, merge, publicação ou deploy.
