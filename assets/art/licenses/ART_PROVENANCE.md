# Procedência da prova visual

- Personagens: desenhos originais produzidos para este projeto com a ferramenta integrada `imagegen` da OpenAI e pós-processamento local determinístico.
- Referência visual: a captura fornecida pelo usuário foi usada somente para densidade de pixel art, atmosfera terrosa, contraste e leitura isométrica; nenhum personagem, cenário, texto ou ornamento foi copiado como asset.
- Assets externos incorporados: nenhum.
- Fontes incorporadas: nenhuma nesta entrega.
- Pós-processamento: remoção do fundo gerado, recorte, redução nearest-neighbor, remapeamento para a paleta compartilhada e contorno de 1 px.

Este registro documenta procedência técnica. A licença de distribuição do projeto deve ser definida pelo responsável do repositório.

## Atlas animado Sudeste — V.0.1.7

- Origem dos pixels finais: `characters/prototypes/personagens_se_48px_16c.png`, já aprovado na V.0.1.6.
- Referência inicial de movimento: `source/personagens_se_idle4_walk6_referencia_poses.png`, preservada para histórico.
- Referência corrigida: `source/personagens_se_idle4_walk6_referencia_poses_corrigida.png`, produzida com a ferramenta integrada `imagegen` da OpenAI a partir das referências visuais fornecidas e dos personagens já aprovados.
- Uso das referências: somente ordem e cadência das quatro poses paradas e seis poses de caminhada; seus pixels não são copiados ao atlas jogável.
- Pós-processamento: normalização das solas, deslocamentos inteiros de tronco e pernas, recomposição do contorno de 1 px e validação determinística com Pillow 12.3.0.
- Assets externos incorporados: nenhum.

O atlas final preserva a paleta e os personagens aprovados; os GIFs em `qa/` são apenas provas de loop.
