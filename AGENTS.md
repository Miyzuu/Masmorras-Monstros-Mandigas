# Regras de colaboração do projeto

Antes de modificar arquivos, execute `git branch --show-current` e `git status --short`.

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
