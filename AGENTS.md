# Regras de colaboração do projeto

Antes de modificar arquivos, execute `git branch --show-current` e `git status --short`.

## Skills e contexto do jogo

- Para implementar, corrigir, revisar ou validar uma pequena funcionalidade Godot, use `godot-fatia-qa`. Leia `NEXT_SLICE.md` quando existir e mantenha explícitos objetivo, exclusões e critérios de aceite.
- Use `godot-release` somente depois de uma alteração autorizada e validada, quando a tarefa pedir para estabelecer uma versão, atualizar a documentação de release, commitar ou criar tag. Push continua exigindo autorização explícita.
- Para definir ou revisar sprites, tilesets, VFX ou UI antes da produção, use `game-art-brief`. Em trabalho de arte, não crie assets sem aprovação e preserve as restrições das branches `art/`.
- `ponytail:ponytail` é o padrão para tarefas de código: escolha a solução mínima que funciona. Playwright é preferido somente para validação Web/browser relevante; não o use para pesquisa comum ou validação nativa do Godot.
- Notas de Obsidian/GDD são contexto de decisão, não prova de implementação. O vault oficial está em `../3M/Monstros, Masmorras & Mandingas/`. Comece por `00-Contexto/Mapa de chats.md` e pelo contexto da sua vertente; confirme o estado implementado no repositório e nos testes.

## Coordenação e documentação

- O projeto salvo no Codex é a pasta pai `GAME`; o checkout do jogo é esta pasta `Masmorras-Monstros-Mandigas`. Confira o diretório antes de qualquer comando Git.
- Um responsável por tarefa e por conjunto de arquivos. No mesmo checkout, execute escritas em sequência; para trabalho simultâneo use worktrees isoladas ou limites de arquivos explícitos, com integração posterior.
- Central define o encaminhamento; Design especifica; Narrativa produz rascunhos; Arquitetura propõe contratos; Desenvolvimento implementa; QA revisa; Integração fecha a release; Arte produz somente no escopo aprovado; Ferramentas cuida do ambiente. Papéis orientam o trabalho e não substituem instruções explícitas do usuário.
- Após alterações verificadas, atualize as notas afetadas no vault. Registre separadamente proposta, decisão, alteração local, teste executado e commit publicado. Não copie o histórico inteiro de chats para cada tarefa.
- Após cada commit confirmado, gere backup identificado pelo SHA e registre data, hash, conteúdo e links no Obsidian. Confira a pasta e a conta do Drive em `00-Contexto/Google Drive — estrutura.md`. Uma preferência escrita não instala monitor de commits: fora de uma tarefa ativa é necessário iniciar a operação.
- Leitura/revisão não autoriza release. Correções locais permanecem disponíveis para revisão; commit/tag requerem autorização de fechamento de versão. Push exige autorização explícita.

## Branches de arte

Toda branch cujo nome começa com `art/` é exclusiva para trabalho gráfico.

Nessas branches:

- O repositório inteiro pode ser lido para compreender cenas, dimensões e referências da engine.
- Somente arquivos dentro de `assets/art/` podem ser criados, modificados, movidos ou excluídos.
- Não altere `project.godot`, `scenes/`, `scripts/`, `tests/`, `.github/`, `AGENTS.md` ou qualquer outro caminho.
- A engine pode ser executada apenas para validação visual. Não salve cenas, recursos, configurações de importação ou arquivos de projeto.
- Nunca faça commit ou push diretamente na branch `main`.

Antes de uma nova tarefa de arte, verifique que não existem alterações locais, execute `git fetch origin` e crie uma nova branch `art/<descricao>` a partir de `origin/main`. Se houver alterações locais, conflitos ou falha na sincronização, pare e peça orientação; não use reset, stash ou descarte automático.

Antes de concluir, execute `git diff --name-only --no-renames origin/main...HEAD` e `git status --short`. Se qualquer mudança estiver fora de `assets/art/`, não faça commit, push ou Pull Request; informe os caminhos encontrados.

## Demais branches

Branches que não começam com `art/` seguem o fluxo normal de desenvolvimento e não estão limitadas à pasta gráfica por esta regra.
