# Convenção de versionamento

## Sequência

O projeto começa em `V.0.1.0`. O último número avança a cada entrega concluída:

`V.0.1.0` → `V.0.1.1` → … → `V.0.1.9` → `V.0.2.0`

O mesmo padrão continua nas séries seguintes. Enquanto o jogo estiver em
protótipo, o primeiro número permanece em `0`.

## Fechamento de uma alteração de código

Somente no fechamento de uma release aprovada:

1. atualizar `VERSION` e `application/config/version` em `project.godot`;
2. exibir a versão atual no protótipo;
3. registrar a entrega no `CHANGELOG.md`;
4. fornecer título e descrição para o usuário criar o commit manualmente;
5. registrar uma tag Git anotada usando exatamente a mesma versão, quando autorizada.

A preferência atual do usuário é fazer os commits manualmente. Não executar
commit, tag ou push por inferência desta convenção. Uma tarefa de revisão ou
correção local não fecha automaticamente uma release nem altera a versão.
Se o usuário autorizar explicitamente o fechamento por Codex, limitar a operação
aos arquivos aprovados; push continua exigindo autorização própria.

Depois de um novo commit confirmado, realizar o backup conforme `AGENTS.md` e
registrar SHA, data e links no Obsidian. Isso não significa que exista um monitor
automático instalado para detectar commits feitos fora de uma tarefa ativa.

## Formato do commit

**Título**

```text
V.0.1.0 — Resumo curto da entrega
```

**Descrição**

```text
- mudança principal realizada
- comportamento adicionado ou corrigido
- verificação executada e limitações conhecidas
```

Cada versão corresponde, portanto, a um commit e a uma tag que podem ser usados
como ponto de retorno.
